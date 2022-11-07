;;; in:
;;; ZP
;;; src
;;; dst

;;; pack with: --max-offset 255 --max-length 255

SHORT	EQU 0

unupkr::
	MOVEI	(upkr_probs_array+$100), upkr_probs
	lda	#$80
	ldy	#255+1+2*32+2*32-256-1
.init1	sta	(upkr_probs),y
	dey
	bpl	.init1
	dec	upkr_probs+1
	iny
.init2	sta	(upkr_probs),y
	iny
	bne	.init2

	stz	upkr_state
	stz	upkr_state+1
	bra	.start
.literal:
	sty	upkr_value
.literal1
	jsr	upkr_getbit
	rol	upkr_value
	ldy	upkr_value
	bcc	.literal1
	tya
	sta	(dst)
	inc	dst
	bne	.start
	inc	dst+1
.start
	stz	upkr_pwm
.loop
	ldy	#0
	jsr	upkr_getbit
	bcc	.literal	; y = 1 !
	inc	upkr_probs+1	; probs[256...]
	bit	upkr_pwm
	bmi	.newoff
	dey
	jsr	upkr_getbit	; index = 256
	bcc	.oldoff
.newoff
	iny
	jsr	upkr_getlen	; y = 1 => index = 257
	dex
	beq	.checkeof
	stx	.smc1+1
.oldoff
	ldy	#257+64-256
	jsr	upkr_getlen
	dec	upkr_pwm
	dec	upkr_probs+1	; probs[0...255]

	sec
	lda	dst
.smc1
	sbc	#0
	sta	upkr_ptr
	lda	dst+1
	sbc	#0
	sta	upkr_ptr+1
	ldy	#0
.cpymatch
	lda	(upkr_ptr),y
 IF SHORT = 1
	sta	(dst)
	inc	dst
	bne	.11
	inc	dst+1
.11
 ELSE
	sta	(dst),y
 ENDIF
	iny
	dex
	bne	.cpymatch
 IF SHORT = 0
	clc
	tya
	adc	dst
	sta	dst
	bcc	.loop
	inc	dst+1
 ENDIF
	bra	.loop

 IF SHORT = 0
upkr_getlen:
	stz	upkr_value
	lda	#1
	sta	upkr_tmp
.gl
	jsr	upkr_getbit
	bcc	.done
	jsr	upkr_getbit
	bcc	.4
	lda	upkr_tmp
	tsb	upkr_value
.4
	asl	upkr_tmp
	bra	.gl
.done
	lda	upkr_value
	ora	upkr_tmp
	tax
.checkeof
	rts
	;; get next bit
.newbyte:
	sta	upkr_state+2
	lda	upkr_state
	sta	upkr_state+1
	lda	(src)
	sta	upkr_state
	inc	src
	bne	upkr_getbit
	inc	src+1
upkr_getbit:
	lda	upkr_state+2
	bne	.3
	lda	upkr_state+1
	bit	#$F0
	beq	.newbyte	; < $1000 => next byte
.3
;;  if ( bit ) {
;;    upkr_state = (upkr_state >> 8)*prob+(upkr_state & 0xff);
;;    prob += (256 + 8 - prob) >> 4;
;;  } else {
;;    upkr_state -= ((upkr_state >> 8) + 1)*prob;
;;    prob -= (prob+8)>>4;
;;  }
	lda	(upkr_probs),y
	sta	MATHD		; prepare: *prob
	ldx	#0
	cmp	upkr_state
	bcc	.zero
	bne	.one
	clc
.zero
	lda	upkr_state+1
	adc	#1
	sta	MATHB
	txa
	adc	upkr_state+2
	sta	MATHA

	sec
	lda	upkr_state

	WAITSUZY

	sbc	MATHH
	sta	upkr_state
	lda	upkr_state+1
	sbc	MATHG
	sta	upkr_state+1
	lda	upkr_state+2
	sbc	MATHF
	sta	upkr_state+2

	lda	(upkr_probs),y
	lsr
	lsr
	lsr
	lsr
	adc	#0
	eor	#$ff
	sec
	adc	(upkr_probs),y
	clc
.exit
	sta	(upkr_probs),y
	iny
	rts
.one:
	lda	upkr_state+1
	sta	MATHB
	lda	upkr_state+2
	sta	MATHA

	clc
	lda	upkr_state

	WAITSUZY

	adc	MATHH
	sta	upkr_state
	txa
	adc	MATHG
	sta	upkr_state+1
	txa
	adc	MATHF
	sta	upkr_state+2

	lda	(upkr_probs),y
	eor	#$ff
	inc
	lsr
	lsr
	lsr
	lsr
	adc	(upkr_probs),y
	sec
	bra	.exit
 ELSE

	;; Shorter but longer execution time
upkr_getlen:
	lda	#$7f
	sta	upkr_value
.gl
	jsr	upkr_getbit
	bcc	.done
	jsr	upkr_getbit
	ror	upkr_value
	bra	.gl
.done
	lda	upkr_value
	sec
	dc.b	$89		; bit #x => skip CLC
.gl2	clc
	ror
	bcs	.gl2
	tax
.checkeof
	rts

	;; get next bit
.newbyte:
	sta	upkr_state+2
	lda	upkr_state
	sta	upkr_state+1
	lda	(src)
	sta	upkr_state
	inc	src
	bne	upkr_getbit
	inc	src+1
upkr_getbit:
	lda	upkr_state+2
	bne	.3
	lda	upkr_state+1
	bit	#$F0
	beq	.newbyte	; < $1000 => next byte
.3
;;;  if ( bit ) prob = -prob;
;;;  upkr_state -= ((upkr_state >> 8)+(bit ^ 1))*prob;
;;;  prob -= (prob + 8)>>4;
;;;  if ( bit ) prob = -prob;

	lda	upkr_state
	cmp	(upkr_probs),y
	lda	(upkr_probs),y
	php
	bcs	.zero1
	eor	#$ff
	inc
.zero1
	tax
	sta	MATHD
	lda	upkr_state+1
	adc	#0
	sta	MATHB
	lda	upkr_state+2
	adc	#0
	sta	MATHA

	sec
	lda	upkr_state

	WAITSUZY

	sbc	MATHH
	sta	upkr_state
	lda	upkr_state+1
	sbc	MATHG
	sta	upkr_state+1
	lda	upkr_state+2
	sbc	MATHF
	sta	upkr_state+2

	txa
	lsr
	lsr
	lsr
	lsr
	adc	#0
	eor	#$ff
	sec
	adc	MATHD		; probs

	plp
	bcs	.zero2
	eor	#$ff
	inc
	sec
	dc.b $89
.zero2
	clc
	sta	(upkr_probs),y
	iny
	rts
 ENDIF

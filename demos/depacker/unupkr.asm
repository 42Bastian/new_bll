;;; in:
;;; ZP
;;; src
;;; dst


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

	HANDY_BRKPT

	stz	upkr_offset
	stz	upkr_offset+1
	stz	upkr_state
	stz	upkr_state+1
	bra	.start
.literal:
	sty	upkr_value
	jsr	upkr_getbit
	lda	upkr_value
	rol
	tay
	bcc	.literal
	sta	(dst)
	inc	dst
	bne	.1
	inc	dst+1
.1
.start
	stz	upkr_pwm
.loop
	ldy	#0
	jsr	upkr_getbit
	bcc	.literal	; y=1 !
	inc	upkr_probs+1	; probs[256...]
	bit	upkr_pwm
	bmi	.newoff
	dey
	jsr	upkr_getbit	; index = 256
	bcc	.oldoff
.newoff
	iny
	jsr	upkr_getlen	; y = 1 => index = 257
	inx
	beq	.checkeof
.noeof
	stx	upkr_offset
	sta	upkr_offset+1
.oldoff
	ldy	#257+64-256
	jsr	upkr_getlen
	dec	upkr_pwm
	dec	upkr_probs+1	; probs[0...255]

	clc
	lda	dst
	adc	upkr_offset
	sta	upkr_ptr
	lda	dst+1
	adc	upkr_offset+1
	sta	upkr_ptr+1
	ldy	#0
.cpymatch
	lda	(upkr_ptr),y
	sta	(dst),y
	iny
	bne	.2
	inc	upkr_ptr+1
	inc	dst+1
.2
	inx
	bne	.cpymatch
	inc	upkr_value+1
	bne	.cpymatch
	clc
	tya
	adc	dst
	sta	dst
	bcc	.loop
	inc	dst+1
	bra	.loop
.checkeof
	inc
	bne	.noeof
	rts

 IF 1
upkr_getlen:
	lda	#upkr_value
	sta	.smc+1
	sta	.smc1+1
	stz	upkr_value
	stz	upkr_value+1
.gl0
	lda	#1
.gl
	pha
	jsr	upkr_getbit
	bcc	.done
	jsr	upkr_getbit
	pla
	bcc	.4
.smc
	tsb	upkr_value
.4
	asl
	bcc	.gl
	inc	.smc+1
	inc	.smc1+1
	bra	.gl0
.done
	pla
.smc1
	tsb	upkr_value
	sec
	lda	#0
	sbc	upkr_value
	tax
	lda	#0
	sbc	upkr_value+1
	sta	upkr_value+1
	rts
 ENDIF

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

 IF 0
	;; Shorter but longer execution time
upkr_getlen:
	lda	#$ff
	sta	upkr_value
	sta	upkr_value+1
	clc
	bra	.into
.gl
	jsr	upkr_getbit
.into
	ror	upkr_value+1
	ror	upkr_value
	jsr	upkr_getbit
	bcs	.gl

	sec
	dc.b	$a9
.gl2	clc
	ror	upkr_value+1
	ror	upkr_value
	bcs	.gl2

	sec
	lda	#0
	sbc	upkr_value
	tax
	lda	#0
	sbc	upkr_value+1
	sta	upkr_value+1
	rts
 ENDIF

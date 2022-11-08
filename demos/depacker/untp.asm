;;; in:
;;; ZP
;;; src
;;; dst
;;; Y:A - size of packed data

CPY8		EQU 0

untp::
	stz	tp_bc		; clear bit count
	eor	#$ff
	sta	tp_end
	tya
	eor	#$ff
	sta	tp_end+1
.loop0
	asl	tp_bc		; get next bit
	bne	.loop1		; not last bit =>
.token
	jsr	tp_getbyte	; get next byte
 IF CPY8 = 1
	tay
	beq	.cpy8
 ENDIF
	sta	tp_token	; and save
	dec	tp_bc		; re-init bit tp_bcer
.loop1
	jsr	tp_getbyte	; literal byte or (count and offset)
	asl	tp_token	; PackByte <<
	bcs	.cont0		; C=1 => match
;-- literal
	sta	(dst)
	inc	dst
	bne	.loop0
.incdst
	inc	dst+1
	bra	.loop0
 IF CPY8 = 1
.cpy8
	ldx	#7
.1
	jsr	tp_getbyte
	sta	(dst)
	inc	dst
	bne	.2
	inc	dst+1
.2
	dex
	bpl	.1
	bra	.token
 ENDIF
;-- match
.cont0
	tay			; save count
	lsr
	lsr
	lsr
	lsr
	tax			; save offset high byte
	jsr	tp_getbyte	; offset low-Byte
	clc			; ptr = (offset ^ $ffff) - dst + 1
	sbc	dst
	eor	#$ff
	sta	.loop2+1
	txa
	sbc	dst+1
	eor	#$ff
	sta	.loop2+2
	tya
	ldy	#0
	and	#$f
	inc
	inc
	tax
.loop2	lda	$1234,y
	sta	(dst),y
	iny
	dex
	bpl .loop2
	clc
	tya
	adc	dst
	sta	dst
	bcc	.loop0
	bra	.incdst

tp_getbyte
	lda	(src)
	inc	src
	bne	.9
	inc	src+1
.9	inc	tp_end
	bne	.99
	inc	tp_end+1
	bne	.99
	pla
	pla
.99
	rts

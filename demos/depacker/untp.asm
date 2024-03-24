;;; in:
;;; ZP
;;; src
;;; dst
;;; Y:A - size of packed data

CPY8		EQU 0

untp::
	eor	#$ff
	sta	tp_end
	tya
	eor	#$ff
	sta	tp_end+1
	stz	tp_token
.loop0
	asl	tp_token
	bne	.loop1		; not last bit =>
.token
	jsr	tp_getbyte	; get next byte
	sec
	rol
	sta	tp_token	; and save
.loop1
	jsr	tp_getbyte	; literal byte or (count and offset)
	bcs	.cont0		; C=1 => match
;-- literal
	sta	(dst)
	inc	dst
	bne	.loop0
.incdst
	inc	dst+1
	bra	.loop0
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


 IF 1=1
tp_getbyte
	lda	(src)
	inc	src
	bne	.9
	inc	src+1
.9
	inc	tp_end
	bne	.91
	inc	tp_end+1
	bne	.91
	pla
	pla
.91	rts
 ELSE
tp_getbyte
	lda	(src)
	inc	src
	beq	.9
	inc	tp_end
	beq	.91
	rts

.9	inc	src+1
	inc	tp_end
	beq	.91
	rts
.91
	inc	tp_end+1
	beq	.99
	rts
.99
	pla
	pla
	rts
 ENDIF

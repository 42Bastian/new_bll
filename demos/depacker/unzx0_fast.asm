;;; in:
;;; ZP
;;; src
;;; dst

zx0_value	equ packer_zp
zx0_bc		equ zx0_value+2
zx0_ptr		equ zx0_bc+1
zx0_offset	equ zx0_ptr+2
zx0_stor	equ zx0_offset+2

unzx0::
	stz	zx0_offset+1
	lda	#1
	sta	zx0_offset
	stz	zx0_bc
.literal
	jsr	zx0_elias
.litcpy
	jsr	zx0_getbyte
	sta	(dst)
	inc	dst
	bne	.9
	inc	dst+1
.9	inx
	bne	.litcpy
	iny
	bne	.litcpy
	jsr	zx0_getbit
	bcc	.old_offset
.new_off
	jsr	zx0_elias
	lda	zx0_value+1
	bne	.99		; > 255 => EOF
	lsr	zx0_value
	ror
	tax
	jsr	zx0_getbyte
	lsr
	php			; save C
	sta	zx0_value+1
	sec
	txa
	sbc	zx0_value+1
	sta	zx0_offset
	lda	zx0_value
	adc	#$ff
	sta	zx0_offset+1
	plp

	ldx	#$fe		; min count = 2
	ldy	#$ff
	bcs	.off

	lda	#1
	stz	zx0_value+1
	sta	zx0_value
	jsr	zx0_elias_pre
	dex			; matchlen + 1
	bne	.off
	dey
	bra	.off

.old_offset
	jsr	zx0_elias
.off
	sec
	lda	dst
	sbc	zx0_offset
	sta	zx0_ptr
	lda	dst+1
	sbc	zx0_offset+1
	sta	zx0_ptr+1
	sty	zx0_value
	ldy	#0
.matchcpy
	lda	(zx0_ptr),y
	sta	(dst),y
	iny
	bne	.3
	inc	zx0_ptr+1
	inc	dst+1
.3
	inx
	bne	.matchcpy
	inc	zx0_value
	bne	.matchcpy
	clc
	tya
	adc	dst
	sta	dst
	bcc	.4
	inc	dst+1
.4
	jsr	zx0_getbit
	bcs	.new_off
	jmp	.literal


zx0_getbit
	lsr	zx0_bc
	bne	.1
	jsr	zx0_getbyte
	sta	zx0_stor
	dec	zx0_bc
.1
	asl	zx0_stor
.99	rts

zx0_getbyte::
	lda	(src)
	inc	src
	bne	.9
	inc	src+1
.9	rts

zx0_elias
	stz	zx0_value+1
	lda	#1
	sta	zx0_value
.el
	jsr	zx0_getbit
	bcs	.done
zx0_elias_pre
	jsr	zx0_getbit
	rol	zx0_value
	rol	zx0_value+1
	bra	.el
.done
	lda	#0
	sbc	zx0_value
	tax
	lda	#0
	sbc	zx0_value+1
	tay
	rts

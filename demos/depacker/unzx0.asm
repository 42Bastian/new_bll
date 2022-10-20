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
	jsr	zx0_storebyte
	inx
	bne	.litcpy
	iny
	bne	.litcpy
	jsr	zx0_getbit
	bcc	.old_offset
.new_off
	jsr	zx0_elias

	txa
	bne	.0
	iny
	beq	.99
.0
	stz	zx0_offset
	lsr	zx0_value
	ror	zx0_offset
	jsr	zx0_getbyte
	lsr
	php
	sta	zx0_value+1
	sec
	lda	zx0_offset
	sbc	zx0_value+1
	sta	zx0_offset
	lda	zx0_value
	bcs	.2
	dec
.2
	sta	zx0_offset+1
	plp
	ldx	#$fe		; min count = 2
	ldy	#$ff
	bcs	.off

	lda	#1
	stz	zx0_value+1
	sta	zx0_value
	jsr	zx0_elias_pre
	dex
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
.matchcpy
	lda	(zx0_ptr)
	inc	zx0_ptr
	bne	.3
	inc	zx0_ptr+1
.3	jsr	zx0_storebyte
	inx
	bne	.matchcpy
	iny
	bne	.matchcpy

	jsr	zx0_getbit
	bcs	.new_off
	bra	.literal

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
	lda	zx0_value
	eor	#$ff
	tax
	lda	zx0_value+1
	eor	#$ff
	tay
	inx
	bne	.99
	iny
.99	rts

zx0_getbit::
	dec	zx0_bc
	bpl	.1
	jsr	zx0_getbyte
	sta	zx0_stor
	lda	#7
	sta	zx0_bc
.1
	asl	zx0_stor
	rts

zx0_getbyte::
	lda	(src)
	inc	src
	bne	.9
	inc	src+1
.9	rts

zx0_storebyte::
	sta	(dst)
	inc	dst
	bne	.9
	inc	dst+1
.9	rts

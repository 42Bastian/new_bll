;;; in:
;;; ZP
;;; src
;;; dst

unzx0::
	stz	zx0_offset+1
	lda	#1
	sta	zx0_offset
	stz	zx0_stor
.literal
	sec
	jsr	zx0_elias
.litcpy
	jsr	zx0_getbyte
	jsr	zx0_storebyte
	bne	.litcpy
	jsr	zx0_getbit
.new_off
	php
	sec
	jsr	zx0_elias
	plp
	bcc	.old_offset

	lda	zx0_value+1
	bne	.99		; > 255 => EOF

	lsr	zx0_value
	ror
	sta	zx0_offset
	jsr	zx0_getbyte
	lsr
	php
	eor	#$ff
	sec
	adc	zx0_offset
	sta	zx0_offset
	lda	zx0_value
	adc	#$ff
	sta	zx0_offset+1

	plp
	ldx	#$fe		; min count = 2
	ldy	#$ff
	bcs	.off2

//->	clc			; C=0 => no bit reading
	jsr	zx0_elias
	dex			; matchlen + 1
	bne	.old_offset
	dey
.old_offset
	sec
.off2
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
	bne	.matchcpy

	jsr	zx0_getbit
	bcs	.new_off
	bra	.literal

zx0_elias
	stz	zx0_value+1
	lda	#1
	bcs	.el
zx0_elias_pre
	jsr	zx0_getbit
	rol
	rol	zx0_value+1
.el
	jsr	zx0_getbit
	bcc	zx0_elias_pre
.done
	sta	zx0_value
	eor	#$ff
	inc
	tax
	lda	zx0_value+1
	eor	#$ff
	tay
.99	rts

zx0_getbit::
	asl	zx0_stor
	bne	.1
	tax
	jsr	zx0_getbyte
	sec
	rol
	sta	zx0_stor
	txa
.1
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
.9	inx
	bne	.99
	iny
.99
	rts

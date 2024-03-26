;;; in:
;;; ZP
;;; src
;;; dst
;;; A:Y packed length

unlz4::
.token
	jsr	lz4_getbyte
	sta	.smc+1
	lsr
	lsr
	lsr
	lsr
	beq	.match
	jsr	lz4_getlen
.litloop
	jsr	lz4_getbyte
	jsr	lz4_storebyte
	bne	.litloop

.match
	jsr	lz4_getbyte
	tay
	clc
	sbc	dst
	eor	#$ff
	sta	lz4_ptr

	jsr	lz4_getbyte
	tax
	sbc	dst+1
	eor	#$ff
	sta	lz4_ptr+1

	tya
	bne	.smc
	txa
	beq	._rts
.smc
	lda	#10
	and	#15
	jsr	lz4_getlen
	sec
	txa
	sbc	#4
	tax
	bcs	.matchloop
	dey
.matchloop
	lda	(lz4_ptr)
	inc	lz4_ptr
	bne	.2
	inc	lz4_ptr+1
.2
	jsr	lz4_storebyte
	bne	.matchloop
	bra	.token

lz4_getlen
	ldy	#$ff
	cmp	#15
	bne	.noext
.loop
	sta	lz4_tmp
	jsr	lz4_getbyte
	tax
	clc
	adc	lz4_tmp
	bcc	.3
	dey
.3
	inx
	beq	.loop
.noext
	eor	#$ff
	tax
	inx
	bne	._rts
	iny
._rts
	rts

lz4_getbyte::
	lda	(src)
	inc	src
	bne	.9
	inc	src+1
.9	rts

lz4_storebyte::
	sta	(dst)
	inc	dst
	bne	.9
	inc	dst+1
.9	inx
	bne	.99
	iny
.99
	rts

	echo "%hunlz4 %hlz4_getlen"

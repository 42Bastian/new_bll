;;; in:
;;; ZP
;;; src
;;; dst
;;; A:Y packed length

lz4_src_e	equ packer_zp
lz4_tmp		equ lz4_src_e+2
lz4_ptr		equ lz4_tmp+1

unlz4::
	clc
	adc	src
	sta	lz4_src_e
	tya
	adc	src+1
	sta	lz4_src_e+1
.token
	jsr	getbyte
	sta	.smc+1
	lsr
	lsr
	lsr
	lsr
	beq	.match
	jsr	getlen
.litloop
	jsr	getbyte
	jsr	storebyte
	inx
	bne	.litloop
	iny
	bne	.litloop
	lda	src
	cmp	lz4_src_e
	bne	.match
	lda	src+1
	cmp	lz4_src_e+1
	beq	._rts

.match
	jsr	getbyte
	sta	lz4_ptr
	jsr	getbyte
	sta	lz4_ptr+1
	sec
	lda	dst
	sbc	lz4_ptr
	sta	lz4_ptr
	lda	dst+1
	sbc	lz4_ptr+1
	sta	lz4_ptr+1
.smc
	lda	#10
	and	#15
	jsr	getlen
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
	jsr	storebyte
	inx
	bne	.matchloop
	iny
	bne	.matchloop
	bra	.token

getlen
	ldy	#$ff
	cmp	#15
	bne	.noext
.loop
	sta	lz4_tmp
	jsr	getbyte
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

getbyte::
	lda	(src)
	inc	src
	bne	.9
	inc	src+1
.9	rts

storebyte::
	sta	(dst)
	inc	dst
	bne	.9
	inc	dst+1
.9	rts

	echo "%hunlz4 %hgetlen"

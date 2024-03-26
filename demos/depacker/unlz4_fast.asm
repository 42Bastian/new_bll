;;; in:
;;; ZP
;;; src
;;; dst
;;; A:Y packed length

LZ4_MAX_LEN_256 EQU 0

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
	lda	(src),y
	sta	(dst),y
	iny
 IF LZ4_MAX_LEN_256 = 0
	beq	.incptrlit
.21
 ENDIF
	inx
	bne	.litloop
	inc	lz4_tmp
	bne	.litloop

	clc
	tya
	adc	dst
	sta	dst
	bcc	.9
	inc	dst+1
.9
	clc
	tya
	adc	src
	sta	src
	bcc	.91
	inc	src+1
.91
.match
	clc
	jsr	lz4_getbyte
	tay
	sbc	dst
	eor	#$ff
	sta	lz4_ptr

	jsr	lz4_getbyte
	tax
	sbc	dst+1
	eor	#$ff
	sta	lz4_ptr+1

	tya
	bne	.notdone
	txa
	beq	._rts
.notdone
.smc
	lda	#10
	and	#15
	jsr	lz4_getlen
	sec
	txa
	sbc	#4
	tax
	bcs	.1
	dec	lz4_tmp
.1
.matchloop
	lda	(lz4_ptr),y
	sta	(dst),y
	iny
 IF LZ4_MAX_LEN_256 = 0
	beq	.incptr
.2
 ENDIF
	inx
	bne	.matchloop
	inc	lz4_tmp
	bne	.matchloop
	clc
	tya
	adc	dst
	sta	dst
	bcc	.token
	inc	dst+1
	bra	.token

 IF LZ4_MAX_LEN_256 = 0
.incptr
	inc	lz4_ptr+1
	inc	dst+1
	bra	.2
.incptrlit
	inc	src+1
	inc	dst+1
	bra	.21
 ENDIF

 ENDIF

lz4_getlen
	ldy	#$ff
	cmp	#15
	bne	.noext
	sta	lz4_tmp
.loop
	jsr	lz4_getbyte
 IF LZ4_MAX_LEN_256 = 0
	cmp	#$ff
	beq	.33
 ENDIF
	clc
	adc	lz4_tmp
	bcc	.3
	dey
.3
.noext
	eor	#$ff
	tax
	inx
	bne	.4
	iny
.4
	sty	lz4_tmp
	ldy	#0
._rts
	rts
 IF LZ4_MAX_LEN_256 = 0
.33
	dec	lz4_tmp
	dey
	bra	.loop
 ENDIF
lz4_getbyte::
	lda	(src)
	inc	src
	beq	.9
	rts
.9
	inc	src+1
	rts

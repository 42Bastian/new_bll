;;; in:
;;; ZP
;;; src
;;; dst

GETBIT_INLINE	EQU 1

 MACRO GETBIT
 IF GETBIT_INLINE
	lsr	zx0_bc
	bne	.\_1
	lda	(src)
	inc	src
	bne	.\_2
	inc	src+1
.\_2	sta	zx0_stor
	dec	zx0_bc
.\_1	asl	zx0_stor
 ELSE
	jsr	zx0_getbit
 ENDIF
 ENDM

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
	GETBIT
	bcc	.old_offset
.new_off
	jsr	zx0_getoff
	lda	zx0_value+1
	bne	._rts		; > 255 => EOF
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
 IF GETBIT_INLINE = 1
._rts:	rts
 ENDIF
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
	bcs	.4
	GETBIT
	bcs	.new_off
	jmp	.literal
.4
	inc	dst+1
	GETBIT
 IF GETBIT_INLINE = 1
	bcs	._new_off
	jmp	.literal
._new_off
	jmp	.new_off
 ELSE
	bcs	.new_off
	jmp	.literal
 ENDIF

 IF GETBIT_INLINE = 0
zx0_getbit
	lsr	zx0_bc
	beq	.1
	asl	zx0_stor
._rts	rts

.1
	lda	(src)
	inc	src
	bne	.91
	inc	src+1
.91
	asl
	sta	zx0_stor
	dec	zx0_bc
	rts
 ENDIF

zx0_getbyte
	lda	(src)
	inc	src
	beq	.9a
	rts
.9a
	inc	src+1
.99
	rts

zx0_getoff
	stz	zx0_value+1
	lda	#1
	sta	zx0_value
.el
	GETBIT
	bcs	.99
	GETBIT
	rol	zx0_value
	rol	zx0_value+1
	bra	.el

zx0_elias::
	stz	zx0_value+1
	lda	#1
	sta	zx0_value
.el
	GETBIT
	bcs	.done
zx0_elias_pre
	GETBIT
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

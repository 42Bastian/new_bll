;;; in:
;;; ZP
;;; src
;;; dst

;;; decruncher for exomizer RAW format with -f (default) and -P39 (default)
;;;
;;; Configuration in unexo.var
;;;

 IFD HANDY
	MACRO _RMB2
	lda	#4
	trb	\0
	nop
	ENDM
 ELSE
	MACRO _RMB2
	rmb2	\0
	ENDM
 ENDIF

decrunch::
	jsr	exo_getbyte
	sta	exo_bitbuf
 IF NO_OFFSET_REUSE = 0
	stz	exo_reuse
 ENDIF
	ldx	#0
	ldy	#0
.init1
	dey
	bpl	.init2
	ldy	#15
	lda	#1
	sta	exo_ptr
	dec
.init2
	sta	exo_ptr+1
	sta	exo_base+52,x
	lda	exo_ptr
	sta	exo_base,x
	phy
	phx
	lda	#3
	jsr	exo_readbits
	tay
	jsr	exo_read1bit
	tya
	plx
	bcc	.init21
	ora	#8
.init21
	sta	exo_bits,x
	tay
	lda	#0
	stz	exo_offset
	sec
.init3	rol
	rol	exo_offset
	dey
	bpl	.init3
//->	clc			; C = 0 from loop
	adc	exo_ptr
	sta	exo_ptr
	lda	exo_offset
	adc	exo_ptr+1
	ply
	inx
	cpx	#52
	bne	.init1
	bra	.literal1	; can be ommitted if eox_read1bit is moved down

	;; Read a single bit
exo_read1bit:
	asl	exo_bitbuf
	beq	.r1b
	rts
.r1b
	jsr	exo_getbyte
	rol
	sta	exo_bitbuf
.ret
	rts
 IF NO_LIT_SEQ = 0
.literal
	jsr	exo_getbyte
	sta	exo_len
	jsr	exo_getbyte
	tax
.litloop
	jsr	exo_getbyte
	sta	(dst),y
	iny
	bne	.l1
	inc	dst+1
	dex
.l1
	cpy	exo_len
	bne	.litloop
	txa
	bne	.litloop
	clc
	tya
	adc	dst
	sta	dst
	bcc	.l2
	inc	dst+1
	bra	.l2
 ENDIF
.literal1
	jsr	exo_getbyte
	sta	(dst)
	inc	dst
	bne	.l2
	inc	dst+1
.l2
 IF NO_OFFSET_REUSE = 0
	sec
.loop
	rol	exo_reuse
	_RMB2	exo_reuse	;exo_reuse &= 3
 ELSE
.loop
 ENDIF
	jsr	exo_read1bit	; bit = 1 literal
	bcs	.literal1
	stz	exo_len
.getindex
	inc	exo_len
	jsr	exo_read1bit
	bcc	.getindex
	ldx	exo_len
	cpx	#16+1
	beq	.ret
 IF NO_LIT_SEQ = 0
	cpx	#17+1
	beq	.literal
 ENDIF
	lda	exo_base-1,x
	sta	exo_len
	lda	exo_base+52-1,x
	sta	exo_len+1
	lda	exo_bits-1,x
	beq	.nobits
	jsr	exo_readbits

	adc	exo_len
	sta	exo_len
 IF NO_OFFSET_REUSE = 1
	tax
 ENDIF
	lda	exo_value+1
	adc	exo_len+1
	sta	exo_len+1
.nobits
 IF NO_OFFSET_REUSE = 0
	lda	exo_reuse
	dec
	bne	.newoff
	jsr	exo_read1bit
	bcs	.nooff
.newoff
 ENDIF
	lda	#4
	ldy	exo_len+1
	bne	.default
 IF NO_OFFSET_REUSE = 0
	ldx	exo_len
 ENDIF
 IF NO_1BYTE_SEQ = 0
	dex
	bne	.no_case1
	lsr			; A = 2
	jsr	exo_readbits
	adc	#48
	bra	.endswitch
.no_case1
	dex
 ELSE
	cpx	#2
 ENDIF
	bne	.default
	jsr	exo_readbits
	adc	#32
	bra	.endswitch
.default:
	jsr	exo_readbits
	adc	#16
.endswitch
	tax
 IF NO_OFFSET_REUSE = 1
	sec
	lda	dst
	sbc	exo_base,x
	sta	exo_ptr
	lda	dst+1
	sbc	exo_base+52,x
	sta	exo_ptr+1
 ELSE ; NO_OFFSET_REUSE = 0
	lda	exo_base,x
	sta	exo_offset
	lda	exo_base+52,x
	sta	exo_offset+1
 ENDIF ; NO_OFFSET_REUSE

	lda	exo_bits,x
	beq	.nobits2

	jsr	exo_readbits
 IF NO_OFFSET_REUSE = 1
	eor	#$ff
	sec
	adc	exo_ptr
	sta	exo_ptr
	lda	exo_ptr+1
	sbc	exo_value+1
	sta	exo_ptr+1
.nobits2
 ELSE ; NO_OFFSET_REUSE = 0
	adc	exo_offset
	sta	exo_offset
	lda	exo_value+1
	adc	exo_offset+1
	sta	exo_offset+1
.nobits2

.nooff
	sec
	lda	dst
	sbc	exo_offset
	sta	exo_ptr
	lda	dst+1
	sbc	exo_offset+1
	sta	exo_ptr+1
 ENDIF ; NO_OFFSET_REUSE
	ldx	exo_len+1
	ldy	#0
.match
	lda	(exo_ptr),y
	sta	(dst),y
	iny
	beq	.m3
.m1	cpy	exo_len
	bne	.match
	txa
	bne	.match
	clc
	tya
	adc	dst
	sta	dst
	bcc	.m2
	inc	dst+1
 IF NO_OFFSET_REUSE = 0
	clc
 ENDIF
.m2
	jmp	.loop
.m3
	inc	exo_ptr+1
	inc	dst+1
	dex
	bra	.m1

;;; --------------------
;; read bits
;;; IN:  Bits to read (> 1!)
;;; OUT: low-byte A, bits == 0 => Z = 1, C = 0
;;; x,y destroyed

exo_readbits:
	stz	exo_value
	tax
	and	#7
	beq	.byte
	tay
.rbloop
	asl	exo_bitbuf
	beq	.newbyte
.rb_cont
	rol	exo_value
	dey
	bne	.rbloop
.rb_byte
	cpx	#8
	lda	exo_value	; Z=1 => bit == 0
	bcs	.byte
	stz	exo_value+1
	rts
.byte
	sta	exo_value+1
	jsr	exo_getbyte
	sta	exo_value
	clc
	rts

.newbyte:
	jsr	exo_getbyte
	rol
	sta	exo_bitbuf
	bra	.rb_cont

	;; Get next packed byte
	;; Must preserve X and Y
	;; C = 1 on entry, must be 1 on exit!
exo_getbyte:
	lda	(src)
	inc	src
	bne	.1
	inc	src+1
.1
	rts

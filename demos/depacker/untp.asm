;;; in:
;;; ZP
;;; src
;;; dst
;;; Y:A - size of packed data

tp_bc		equ packer_zp
tp_ptr		equ tp_bc+1
tp_offset	equ tp_ptr+2
tp_end		equ tp_offset+2
tp_token	equ tp_end+2

untp::
	eor	#$ff
	sta	tp_end
	tya
	eor	#$ff
	sta	tp_end+1
	inc	tp_end
	bne	.1
	inc	tp_end+1
.1
	stz	tp_bc		; clear bit tp_bcer
.loop0	asl	tp_bc		; get next bit
	bne	.loop1		; not last bit =>
	jsr	tp_getbyte	; get next byte
	sta	tp_token	; and save
	dec	tp_bc		; re-init bit tp_bcer
.loop1	asl	tp_token	; PackByte <<
	bcs	.cont0		; C=1 => match
;---------------
	jsr	tp_getbyte	; get literal byte
	beq	.99
	jsr	tp_storebyte
	bra	.loop0
;---------------
.cont0
	jsr	tp_getbyte	; count and offset
	tay			; save
	lsr
	lsr
	lsr
	lsr
	tax			; save
	jsr	tp_getbyte	; offset low-Byte
	clc
	sbc	dst
	eor	#$ff
	sta	tp_ptr
	txa
	sbc	dst+1
	eor	#$ff
	sta	tp_ptr+1
	tya
	ldy	#0
	and	#$f
	inc
	inc
	tax
.loop2	lda	(tp_ptr),y
	jsr	tp_storebyte
	iny
	dex
	bpl .loop2
	bra .loop0

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
	rts
.99
	rts

tp_storebyte::
	sta	(dst)
	inc	dst
	bne	.9
	inc	dst+1
.9	rts

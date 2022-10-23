;;; in:
;;; ZP
;;; src
;;; dst
;;; Y:A - size of packed data

tp_bc		equ packer_zp
tp_offset	equ tp_bc+1
tp_end		equ tp_offset+2
tp_token	equ tp_end+2

untp::
	stz	tp_bc		; clear bit count
	eor	#$ff
	sta	tp_end
	tya
	eor	#$ff
	sta	tp_end+1
	inc	tp_end
	bne	.loop0
	inc	tp_end+1

.loop0
	asl	tp_bc		; get next bit
	bne	.loop1		; not last bit =>
	jsr	tp_getbyte	; get next byte
	sta	tp_token	; and save
	dec	tp_bc		; re-init bit tp_bcer
.loop1
	jsr	tp_getbyte	; literal byte or (count and offset)
	asl	tp_token	; PackByte <<
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
.99
	rts

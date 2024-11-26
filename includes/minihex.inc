;-*-asm-*-
;;; ----------------------------------------
;;; minihex
;;; Non-sprite hex output
;;;
;;; Input: Y:A > 8 bit or A
;;;

minihex16::
	pha
	tya
	jsr	minihex8
;;->	bra	minihex8a
;;->minihex12::
;;->	pha
;;->	tya
;;->	jsr	minihex4
;;->minihex8a
	pla
minihex8::
	pha
	lsr
	lsr
	lsr
	lsr
	jsr	minihex4
	pla
minihex4::
	and	#$f
	tay
	lda	_l_0,y
	sta	mh_low
	lda	_h_0,y
	sta	mh_high

	ldy	#$ff
.loop
	lda	#0
	asl	mh_low
	rol	mh_high
	bcc	.2
	lda	#$f0
.2
	asl	mh_low
	rol	mh_high
	bcc	.3
	ora	#$f
.3
	and	mh_color
	iny
	sta	(mh_screenBase),y
	lda	#0
	asl	mh_low
	rol	mh_high
	bcc	.4
	lda	#$f0
.4
	and	mh_color
	iny
	sta	(mh_screenBase),y
	clc
	lda	mh_screenBase
	adc	#78
	sta	mh_screenBase
	bcc	.5
	inc	mh_screenBase+1
.5
	cpy	#9
	bne	.loop

	sec			; rewind ptr and next char
	lda	mh_screenBase
	sbc	#<(5*78-2)
	sta	mh_screenBase
	lda	mh_screenBase+1
	sbc	#>(5*78-2)
	sta	mh_screenBase+1
	rts

_000	equ %000
_100	equ %100
_010	equ %010
_110	equ %110
_001	equ %001
_101	equ %101
_011	equ %011
_111	equ %111

	MACRO charl
_l_\0
	dc.b <((\1<<13)|(\2<<10)|(\3<<7)|(\4<<4)|(\5<<1))
	ENDM

	MACRO charh
_h_\0
	dc.b >((\1<<13)|(\2<<10)|(\3<<7)|(\4<<4)|(\5<<1))
	ENDM

	charl 0,_010,_101,_101,_101,_010
	charl 1,_010,_110,_010,_010,_010
	charl 2,_010,_101,_001,_010,_111
	charl 3,_110,_001,_010,_001,_110
	charl 4,_100,_101,_111,_001,_001
	charl 5,_111,_100,_110,_001,_110
	charl 6,_011,_100,_110,_101,_010
	charl 7,_111,_001,_001,_010,_010
	charl 8,_010,_101,_010,_101,_010
	charl 9,_010,_101,_011,_001,_110
	charl A,_010,_101,_111,_101,_101
	charl B,_110,_101,_110,_101,_110
	charl C,_010,_101,_100,_101,_010
	charl D,_110,_101,_101,_101,_110
	charl E,_111,_100,_110,_100,_111
	charl F,_111,_100,_110,_100,_100

	charh 0,_010,_101,_101,_101,_010
	charh 1,_010,_110,_010,_010,_010
	charh 2,_010,_101,_001,_010,_111
	charh 3,_110,_001,_010,_001,_110
	charh 4,_100,_101,_111,_001,_001
	charh 5,_111,_100,_110,_001,_110
	charh 6,_011,_100,_110,_101,_010
	charh 7,_111,_001,_001,_010,_010
	charh 8,_010,_101,_010,_101,_010
	charh 9,_010,_101,_011,_001,_110
	charh A,_010,_101,_111,_101,_101
	charh B,_110,_101,_110,_101,_110
	charh C,_010,_101,_100,_101,_010
	charh D,_110,_101,_101,_101,_110
	charh E,_111,_100,_110,_100,_111
	charh F,_111,_100,_110,_100,_100

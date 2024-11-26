;-*-asm-*-
;;; ----------------------------------------
;;; minihex
;;; Non-sprite hex output
;;;
;;; Input:
;;; mh_screenBase
;;; mh_color
;;;
	include <macros/if_while.mac>

minihex16::
	pha
	tya
	jsr	minihex8
	pla
	bra	minihex8
minihex12::
	pha
	tya
	jsr	minihex4
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
	ldy	mh_screenBase+1
	phy
	ldy	mh_screenBase
	phy

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
	_IFCS
	  inc	mh_screenBase+1
	_ENDIF
	cpy	#9
	bne	.loop

	pla
	clc
	adc	#2
	sta	mh_screenBase
	pla
	adc	#0
	sta	mh_screenBase+1
	rts

_0000	equ %000
_1000	equ %100
_0100	equ %010
_1100	equ %110
_0010	equ %001
_1010	equ %101
_0110	equ %011
_1110	equ %111

	MACRO charl
_l_\0
	dc.b <((\1<<13)|(\2<<10)|(\3<<7)|(\4<<4)|(\5<<1))
	ENDM

	MACRO charh
_h_\0
	dc.b >((\1<<13)|(\2<<10)|(\3<<7)|(\4<<4)|(\5<<1))
	ENDM

	charl 0,_0100,_1010,_1010,_1010,_0100
	charl 1,_0100,_1100,_0100,_0100,_0100
	charl 2,_0100,_1010,_0010,_0100,_1110
	charl 3,_1100,_0010,_0100,_0010,_1100
	charl 4,_1000,_1010,_1110,_0010,_0010
	charl 5,_1110,_1000,_1100,_0010,_1100
	charl 6,_0110,_1000,_1100,_1010,_0100
	charl 7,_1110,_0010,_0010,_0100,_0100
	charl 8,_0100,_1010,_0100,_1010,_0100
	charl 9,_0100,_1010,_0110,_0010,_1100
	charl A,_0100,_1010,_1110,_1010,_1010
	charl B,_1100,_1010,_1100,_1010,_1100
	charl C,_0100,_1010,_1000,_1010,_0100
	charl D,_1100,_1010,_1010,_1010,_1100
	charl E,_1110,_1000,_1100,_1000,_1110
	charl F,_1110,_1000,_1100,_1000,_1000

	charh 0,_0100,_1010,_1010,_1010,_0100
	charh 1,_0100,_1100,_0100,_0100,_0100
	charh 2,_0100,_1010,_0010,_0100,_1110
	charh 3,_1100,_0010,_0100,_0010,_1100
	charh 4,_1000,_1010,_1110,_0010,_0010
	charh 5,_1110,_1000,_1100,_0010,_1100
	charh 6,_0110,_1000,_1100,_1010,_0100
	charh 7,_1110,_0010,_0010,_0100,_0100
	charh 8,_0100,_1010,_0100,_1010,_0100
	charh 9,_0100,_1010,_0110,_0010,_1100
	charh A,_0100,_1010,_1110,_1010,_1010
	charh B,_1100,_1010,_1100,_1010,_1100
	charh C,_0100,_1010,_1000,_1010,_0100
	charh D,_1100,_1010,_1010,_1010,_1100
	charh E,_1110,_1000,_1100,_1000,_1110
	charh F,_1110,_1000,_1100,_1000,_1000
;;; 48

* -*-asm-*-
*******************
* PLOT X,Y,A
*******************
Plot::	stx .PLOTx
	sty .PLOTy
	sta .PLOTcolor
	MOVEI .PLOTSCB,$fc10
	jmp _DrawSprite

.PLOTSCB db $c0,$90,00
	dw 0
	dw .PLOTdata
.PLOTx	dw 0
.PLOTy	dw 0
	dw $100,$100
.PLOTcolor
	db $00
.PLOTdata
	db 2,$10,0
*******************
* DrawLine x1,y1,x2,x2
* Color A
* 8 bit coordinates only
*******************
DrawLine::
	sta .dl_scb_color
	lda x1
	cmp x2
	_IFCS
	  ldx x2
	  sta x2
	  stx x1
	  lda y1
	  ldx y2
	  sta y2
	  stx y1
	_ENDIF

	lda x1
	sta .dl_scb_x
	lda y1
	sta .dl_scb_y

	ldx #%11000000
	sec
	lda y2
	sbc y1
	_IFLT
	  eor #$ff
	  inc
	  ldx #%11010000
	_ENDIF

	stx .dl_scb
	inc
	sta .dl_scb_ysize+1
	sta MATHE_B
//->	stz MATHE_B+1

	stz MATHE_A
	stz MATHE_A+2
	sec
	lda x2
	sbc x1
	inc
	sta MATHE_A+3
	WAITSUZY
	MOVE MATHE_D+2,.dl_scb_tilt
	_IFEQ
	  lda #1
	  sta .dl_scb_xsize+1
	_ELSE
	  bit .dl_scb_tilt
	  _IFMI
	    inc
	  _ENDIF
	  sta .dl_scb_xsize+1
	_ENDIF

	MOVEI .dl_scb,$fc10
_DrawSprite:
	stz $fd90
	lda #1

	STA $FC91
.wait	STZ $FD91
	bit $fc92
	bne .wait
	STZ $FD90
	rts

.dl_scb	        dc.b $d0,$80|$30,0
	        dc.w 0,.dlimage
.dl_scb_x       dc.w 0
.dl_scb_y       dc.w 0
.dl_scb_xsize   dc.w $100
.dl_scb_ysize   dc.w $100
.dl_scb_stretch dc.w 0
.dl_scb_tilt    dc.w 0
.dl_scb_color   dc.b $e
.dlimage        dc.b 2,$10,0

*******************
IFD USE_CIRCLE
*******************
* circle x1,y1,x,a (a=color)
* algo by van Dam/Foley
****************
deltaE	equ temp1
deltaSE	equ temp2

circle::
	sta CIRCLEcolor

	stz x2
	stz x2+1
	stx y2
	stz y2+1

	txa
	eor #$ff
	sta temp

	inc			; A = -R
	asl
	tay
	lda #$ff
	sta temp+1		; temp = 1-R

	rol
	tax
	clc
	tya
	adc #5
	sta deltaSE
	txa
	adc #0
	sta deltaSE+1		; deltaSE = -2R+5

	lda #3
	sta deltaE
	stz deltaE+1		; deltaE = 3

.while	jsr circle_points
	CMPW y2,x2
	beq .exit

	inc x2
	_IFEQ
	  inc x2+1
	_ENDIF
	clc
	lda deltaE
	adc #2
	sta deltaE
	_IFCS
	  inc deltaE+1
	_ENDIF

	lda temp+1
	bpl ._3
	  ADDW deltaE,temp
	  clc
	  lda deltaSE
	  adc #2
	  sta deltaSE
	  bcc .while
	  inc deltaSE+1
	bra .while
._3	ADDW deltaSE,temp
	clc
	lda deltaSE
	adc #4
	sta deltaSE
	_IFCS
	  inc deltaSE+1
	_ENDIF
	dec y2
	bne .while
	dec y2+1
	bra .while
.exit	rts

circle_points
	ADDWABC x1,x2,._1x
	ADDWABC y1,y2,._1y	; x,y

	MOVE ._1x,._2x
	SUBWABC y2,y1,._2y	; x,-y

	ADDWABC x1,y2,._3x
	ADDWABC y1,x2,._3y	; y,x

	MOVE ._3x,._4x
	SUBWABC x2,y1,._4y	; y,-x

	SUBWABC x2,x1,._5x
	MOVE ._2y,._5y		; -x,-y

	MOVE ._5x,._6x
	MOVE ._1y,._6y		; -x,y

	SUBWABC y2,x1,._7x
	MOVE ._3y,._7y		; -y,x

	MOVE ._7x,._8x
	MOVE ._4y,._8y		; -y,-x

	MOVEI CIRCLESCB,$fc10
	jmp _DrawSprite

CIRCLESCB
	db $c0,$90,00
	dw CIRCLESCB2,CIRCLEdata
._1x	dw 0
._1y	dw 0
	dw $100,$100
CIRCLEcolor
	db $00
CIRCLEdata
	db 2,$10,0

CIRCLESCB2
	db $c0,$88,00
	dw CIRCLESCB3,CIRCLEdata
._2x	dw 0
._2y	dw 0
CIRCLESCB3
	db $c0,$88,00
	dw CIRCLESCB4,CIRCLEdata
._3x	dw 0
._3y	dw 0
CIRCLESCB4
	db $c0,$88,00
	dw CIRCLESCB5,CIRCLEdata
._4x	dw 0
._4y	dw 0
CIRCLESCB5
	db $c0,$88,00
	dw CIRCLESCB6,CIRCLEdata
._5x	dw 0
._5y	dw 0
CIRCLESCB6
	db $c0,$88,00
	dw CIRCLESCB7,CIRCLEdata
._6x	dw 0
._6y	dw 0
CIRCLESCB7
	db $c0,$88,00
	dw CIRCLESCB8,CIRCLEdata
._7x	dw 0
._7y	dw 0
CIRCLESCB8
	db $c1,$88,00
	dw 0,CIRCLEdata
._8x	dw 0
._8y	dw 0
*******************
ENDIF

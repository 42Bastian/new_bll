* -*-asm-*-
*******************
* PLOT X,Y,A
*******************
Plot::		stx PLOTx
		sty PLOTy
		sta PLOTcolor
		MOVEI PLOTSCB,$fc10

		stz $fd90
		lda #1
		STA $FC91
.WAIT		STZ $FD91
		lda $fc92
		lsr
		bcs .WAIT
		STZ $FD90
		rts

PLOTSCB		db $c0,$90,00
		dw 0
		dw .PLOTdata
PLOTx		dw 0
PLOTy		dw 0
		dw $100,$100
PLOTcolor	db $00
.PLOTdata	db 2,$10,0
*******************
DrawLine::
		sta .dl_scb_color
		stz .dl_scb_xsize
		stz .dl_scb_ysize
		stz .dl_scb_stretch
		stz .dl_scb_stretch+1
		sec
		lda x2
		sbc x1
		lda x2+1
		sbc x1+1
		bpl .ok
		  SWAP x2,x1
		  SWAP y2,y1
.ok		lda #%11000000
		sta .dl_scb
		sec
		lda y2
		sbc y1
		sta y2
		lda y2+1
		sbc y1+1
		sta y2+1
		bpl .ok1
		  sec
		  lda #0
		  sbc y2
		  sta y2
		  lda #0
		  sbc y2+1
		  sta y2+1
		  lda #%11010000
		  sta .dl_scb
.ok1		MOVE x1,.dl_scb_x
		MOVE y1,.dl_scb_y

		lda y2
		inc
		sta .dl_scb_ysize+1
		sta MATHE_B
		stz MATHE_B+1

		stz MATHE_A
		sec
		lda x2
		sbc x1
		inc
		sta MATHE_A+2
		stz MATHE_A+3
		WAITSUZY
		MOVE MATHE_D+1,.dl_scb_tilt
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

;>		  MOVE ScreenBase,$fc08
		MOVEI .dl_scb,$fc10

		stz $fd90
		lda #1

		STA $FC91
.wait		STZ $FD91
		bit $fc92
		bne .wait
		STZ $FD90
		rts

.dl_scb	      dc.b $d0,$80|$30,0
	       dc.w 0,.dlimage
.dl_scb_x     dc.w 0
.dl_scb_y     dc.w 0
.dl_scb_xsize dc.w $100
.dl_scb_ysize dc.w $100
.dl_scb_stretch dc.w 0
.dl_scb_tilt  dc.w 0
.dl_scb_color dc.b $e
.dlimage       dc.b 2,$10,0

*******************
IFD USE_CIRCLE
*******************
* circle x1,y1,x,a (a=color)
* algo by van Dam/Foley
****************
deltaE		equ temp1
deltaSE		equ temp2

circle::	sta CIRCLEcolor

		stz x2
		stz x2+1
		stx y2
		stz y2+1
;>		  MOVE ScreenBase,$fc08

		sec
		lda #1
		sbc y2
		sta temp
		lda #0
		sbc #0
		sta temp+1
		lda #3
		sta deltaE
		stz deltaE+1
		lda y2
		eor #$ff
		inc
		sta deltaSE
		asl deltaSE
		lda #$ff
		rol
		sta deltaSE+1
		tax
		clc
		lda #5
		adc deltaSE
		sta deltaSE
		txa
		adc #0
		sta deltaSE+1

.while		jsr circle_points
		CMPW y2,x2
		beq .exit
		blt ._1
.exit		rts
._1		inc x2
		bne ._2
		  inc x2+1
._2		lda temp+1
		bpl ._3
		  ADDW deltaE,temp
		  clc
		  lda deltaE
		  adc #2
		  sta deltaE
		  _IFCS
		    inc deltaE+1
		  _ENDIF
		  clc
		  lda deltaSE
		  adc #2
		  sta deltaSE
		  bcc .while
		  inc deltaSE+1
		bra .while
._3		ADDW deltaSE,temp
		clc
		lda deltaE
		adc #2
		sta deltaE
		_IFCS
		  inc deltaE+1
		_ENDIF
		clc
		lda deltaSE
		adc #4
		sta deltaSE
		_IFCS
		  inc deltaSE+1
		_ENDIF
		sec
		lda y2
		sbc #1
		sta y2
		bcs .while
		  dec y2+1
		bra .while


circle_points	ADDWABC x1,x2,._1x
		ADDWABC y1,y2,._1y		; x,y

		MOVE ._1x,._2x
		SUBWABC y2,y1,._2y		; x,-y

		ADDWABC x1,y2,._3x
		ADDWABC y1,x2,._3y		; y,x

		MOVE ._3x,._4x
		SUBWABC x2,y1,._4y		; y,-x

		SUBWABC x2,x1,._5x
		MOVE ._2y,._5y			; -x,-y

		MOVE ._5x,._6x
		MOVE ._1y,._6y			; -x,y

		SUBWABC y2,x1,._7x
		MOVE ._3y,._7y			; -y,x

		MOVE ._7x,._8x
		MOVE ._4y,._8y			; -y,-x

		MOVEI CIRCLESCB,$fc10
		stz $fd90
		lda #1
		STA $FC91
.WAIT		STZ $FD91
		lda $fc92
		lsr
		bcs .WAIT
		STZ $FD90
		rts

CIRCLESCB	db $c0,$90,00
		dw CIRCLESCB2,CIRCLEdata
._1x		dw 0
._1y		dw 0
		dw $100,$100
CIRCLEcolor	db $00
CIRCLEdata	db 2,$10,0

CIRCLESCB2	db $c0,$88,00
		dw CIRCLESCB3,CIRCLEdata
._2x		dw 0
._2y		dw 0
CIRCLESCB3	db $c0,$88,00
		dw CIRCLESCB4,CIRCLEdata
._3x		dw 0
._3y		dw 0
CIRCLESCB4	db $c0,$88,00
		dw CIRCLESCB5,CIRCLEdata
._4x		dw 0
._4y		dw 0
CIRCLESCB5	db $c0,$88,00
		dw CIRCLESCB6,CIRCLEdata
._5x		dw 0
._5y		dw 0
CIRCLESCB6	db $c0,$88,00
		dw CIRCLESCB7,CIRCLEdata
._6x		dw 0
._6y		dw 0
CIRCLESCB7	db $c0,$88,00
		dw CIRCLESCB8,CIRCLEdata
._7x		dw 0
._7y		dw 0
CIRCLESCB8	db $c1,$88,00
		dw 0,CIRCLEdata
._8x		dw 0
._8y		dw 0
*******************
ENDIF



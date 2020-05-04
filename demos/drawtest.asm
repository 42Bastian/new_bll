Baudrate	set 62500

IRQ_SWITCHBUF_USR set 1


USE_CIRCLE	set 1

_1000HZ_TIMER	set 7

	include <includes/hardware.inc>
* Macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/font.mac>
	include <macros/window.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/irq.mac>
	include <macros/key.mac>
	include <macros/debug.mac>
* Variablen
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/font.var>
	include <vardefs/window.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/irq.var>
	include <vardefs/key.var>
	include <vardefs/fpolygon.var>
	include <vardefs/draw.var>

	include <vardefs/serial.var>
	include <vardefs/1000Hz.var>
* --------------
* define vars
* --------------
 BEGIN_ZP
counter		ds 1
winkel		ds 1
temp3		ds 2
ax		ds 2
ay		ds 2
bx		ds 2
by		ds 2
cx		ds 2
cy		ds 2
dx		ds 2
dy		ds 2
 END_ZP

 BEGIN_MEM
		ALIGN 4
screen0		ds SCREEN.LEN
screen1		ds SCREEN.LEN
irq_vektoren	ds 16
 END_MEM
* --------------
* MACROs
* --------------

		MACRO SINUS
		ldx \0
		lda SinTab.Lo,x
		sta \1
		lda SinTab.Hi,x
		sta \1+1
		ENDM

		MACRO COSINUS
		clc
		lda \0
		adc #64
		tax
		lda SinTab.Lo,x
		sta \1
		lda SinTab.Hi,x
		sta \1+1
		ENDM

		MACRO SHOW_IT
		IFVAR \1
		lda \0+2
		jsr PrintHex
		ENDIF
		lda \0+1
		jsr PrintHex
		lda \0
		jsr PrintHex
		inc CurrX
		inc CurrX
		ENDM
* --------------
* system init
* --------------
		run $7000

Start::		sei
		cld
		CLEAR_MEM
		CLEAR_ZP
		INITMIKEY
		INITSUZY
		lda _SPRSYS
		ora #USE_AKKU|SIGNED_MATH
		sta _SPRSYS
		sta SPRSYS	; AKKU benutzen

		ldx #$ff
		txs

		FRAMERATE 60
*
* init IRQs
*
		INITIRQ irq_vektoren
		INITKEY
		jsr Init1000Hz
		SETIRQ 2,MyVBL
;>		  SETIRQ 0,MyHBL
		jsr InitComLynx
*
* show Phobyx-logo
*
		SETRGB phobyx_pal
		SCRBASE phobyx
* wait for key
.wait_start	lda $fcb0
		beq .wait_start
		cli

		SCRBASE screen0,screen1
		CLS #0
		SWITCHBUF
		CLS #0
		SET_MINMAX 0,0,160,102
		INITFONT LITTLEFNT,ROT,WEISS
		SETRGB pal
* --------------
* main loop
* --------------
main::
*
* circles
*
		ldx #50
.loop0		phx
		CLS #0
		MOVEI 80,x1
		MOVEI 51,y1
		lda #15
		jsr circle
		SWITCHBUF
		plx
		dex
		bne .loop0

.loop1		phx
		CLS #0
		MOVEI 80,x1
		MOVEI 51,y1
		lda #15
		jsr circle
		SWITCHBUF
		plx
		inx
		cpx #50
		bne .loop1
		lda $fcb0
;>		  beq .loop0

*
* triangles
*
tri::
		lda #0
		sta winkel
.loop		SWITCHBUF
		CLS #0

		MOVEI 80,x1
		MOVEI 51,y1
		ldx #40
		lda #$f
		jsr circle

		MOVEI	0,ax
		MOVEI -40,ay

		MOVEI  40,bx
		MOVEI	0,by

		MOVEI -40,cx
		MOVEI	0,cy

		MOVEI	0,dx
		MOVEI  40,dy

		jsr rotate

		lda #$e
		jsr drawabc
		lda #$e
		jsr drawbcd


if 0
	SHOW_IT x1
	SHOW_IT y1
	SHOW_IT x2
	SHOW_IT y2
	SHOW_IT x3
	SHOW_IT y3
endif
;>		  jsr do
.wait0		lda $fcb0
		beq .cont
.wait1		cmp $fcb0
		beq .wait1
.cont		clc
		lda winkel
		adc #1
		sta winkel
		jmp .loop

********************************
* subroutines
********************************
drawabc::
		pha

		lda #-80
		sta $fc04
		lda #-51
		sta $fc06
		lda #-1
		sta $fc05
		sta $fc07

		ldx #0
.loop		  lda ax,x
		  sta x1,x
		  inx
		  lda ax,x
		  sta x1,x
		  inx
		  lda ax,x
		  sta x1,x
		  inx
		  lda ax,x
		  sta x1,x
		  inx
		  cpx #12
		bne .loop
		pla
		jsr triangle
		stz $fc04
		stz $fc06
		rts

drawbcd::	pha
		lda #-80
		sta $fc04
		lda #-51
		sta $fc06
		lda #-1
		sta $fc05
		sta $fc07

		ldx #0
.loop		  lda bx,x
		  sta x1,x
		  inx
		  lda bx,x
		  sta x1,x
		  inx
		  lda bx,x
		  sta x1,x
		  inx
		  lda bx,x
		  sta x1,x
		  inx
		  cpx #12
		bne .loop
		pla
		jsr triangle
		stz $fc04
		stz $fc06
		rts

rotate::	SINUS winkel,temp1		; temp1 = sin
		COSINUS winkel,temp2		; temp2 = cos
		sec
		lda #0
		sbc temp2
		sta temp3
		lda #0
		sbc temp2+1
		sta temp3+1			; temp3 = -cos
		ldx #0
		ldy #3
.loop		  stz MATHE_AKKU
		  stz MATHE_AKKU+2
		  MOVE {ax,x},MATHE_C
		  MOVE temp1,MATHE_E
		  WAITSUZY
		  MOVE {ay,x},MATHE_C
		  MOVE temp2,MATHE_E
		  WAITSUZY
		  MOVE MATHE_AKKU+1,temp	  ; temp = x*sin+y*cos
		  bit MATHE_AKKU
		  _IFMI
		    inc temp
		    _IFEQ
		      inc temp+1
		    _ENDIF
		  _ENDIF
		  stz MATHE_AKKU
		  stz MATHE_AKKU+2
		  MOVE {ax,x},MATHE_C
		  MOVE temp3,MATHE_E
		  WAITSUZY
		  MOVE {ay,x},MATHE_C
		  MOVE temp1,MATHE_E
		  WAITSUZY
		  MOVE temp,{ax,x}
		  MOVE MATHE_AKKU+1,temp
		  _IFMI
		    inc temp
		    _IFEQ
		      inc temp+1
		    _ENDIF
		  _ENDIF
		  MOVE temp,{ay,x}		  ; ay = -x*cos+y*sin

		  REPT 4
		    inx
		  ENDR
		  dey
		  bmi .exit
		jmp .loop
.exit		rts

****************
Pattern::	 stz x1
		stz x1+1
		stz y1
		stz y1+1

		ldx #159
.loop0		stx x2
		stz y2
		sec
		lda #160
		sbc x2
		sta x1
		lda #101
		sta y1
		phx
		txa
		and #7
		clc
		adc #7

		jsr DrawLine
		plx
		dex
		cpx #$ff
		bne .loop0
		bra .wait

		ldy #101
.loop1		stz x1
		sty y1
		lda #159
		sta x2
		sec
		lda #102
		sbc y1
		sta y2
		tya
		phy
		jsr DrawLine
		ply
		dey
		bpl .loop1

		lda #"A"
		jsr PrintChar
.wait		bra .wait




************************************
MyVBL::		stz $fda0
		IRQ_SWITCHBUF
		END_IRQ


MyHBL		inc $fda0
		END_IRQ
****************
* Sinus-Tabelle
* 8Bit Nachkomma
****************
		align 2
SinTab.Lo	ibytes <bin/sintab_8.o>
SinTab.Hi	equ SinTab.Lo+256
****************
PrintHex::	phx
		pha
		lsr
		lsr
		lsr
		lsr
		tax
		lda digits,x
		jsr PrintChar
nq		pla
		and #$f
		tax
		lda digits,x
		jsr PrintChar
		plx
		rts

digits		db "0123456789ABCDEF"
* --------------
* still picture
* --------------
		align 4
phobyx_pal	DP 000,574,434,555,656,799,A9A,BCC,DCD,EFF,FAF,695,9B7,7A6,AAB,AC9

phobyx		ibytes <etc/phobyx1.o>
* --------------
* INCLUDES
* --------------
	include <includes/1000Hz.inc>
	include <includes/serial.inc>
	include <includes/debug.inc>
	include <includes/font.inc>
	include <includes/window2.inc>
	include <includes/irq.inc>
	include <includes/fpolygon.inc>
	include <includes/draw.inc>
	include <includes/font2.hlp>
	include <includes/key.inc>

pal		STANDARD_PAL

proj_x		dc.w 50,75,50,30
proj_y		dc.w 30,50,70,50
faces		dc.b 0,1,2,3,-1
		dc.b -1

end

***************
* RAW.ASM
* simple body of a Lynx-program
*
* created : 24.04.96
* changed : May 2020
****************


Baudrate	set 62500	; define baudrate for serial.inc

_1000HZ_TIMER	set 7	; timer#

//->BRKuser	set 1		; if defined BRK #x support is enabled
DEBUG	set 1			; if defined BLL loader is included


	include <includes/hardware.inc>
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>

	include <macros/font.mac>
	include <macros/irq.mac>
	include <macros/newkey.mac>
	include <macros/debug.mac>
* variables
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/serial.var>
	include <vardefs/font.var>
	include <vardefs/irq.var>
	include <vardefs/newkey.var>
	include <vardefs/1000Hz.var>
*
* local MACROs
*
	MACRO CLS
	lda \0
	jsr cls
	ENDM

*
* vars only for this program
*

 BEGIN_ZP
counter	ds 1
Save1000Hz	ds 2
 END_ZP

 BEGIN_MEM
	ALIGN 4
screen0	ds SCREEN.LEN
irq_vektoren	ds 16
 END_MEM
	 run  LOMEM		 ; code directly after variables

Start::				; Start-Label needed for reStart
	START_UP		; set's system to a known state
	CLEAR_MEM		; clear used memory(definded with BEGIN/END_MEM)
	CLEAR_ZP		; clear zero-page

	INITMIKEY
	INITSUZY

	INITIRQ irq_vektoren	; set up interrupt-handler
	INITKEY ,_FIREA|_FIREB	; repeat for A & B
	INITFONT SMALLFNT,RED,WHITE
	jsr Init1000Hz
	jsr InitComLynx
	INITBRK			; if we're using BRK #X, init handler

	SETIRQ 2,VBL		; set irq-vector and enable IRQ
	SETIRQ 0,HBL

	MOVEI StartPause,PausePtr	; load ptrs, MOVEI is in HELP.MAC
	MOVEI EndPause,PausePtr+2
	dec PauseEnable		; enable Pause

	cli			; allow interrupts
	SCRBASE screen0		; set screen, single buffering
	CLS #0			; clear screen with color #0
	SETRGB pal		; set palette

	SET_MINMAX 0,0,160,102	; screen-dim. for FONT.INC

.loop	SET_XY 40,40		; set FONT-cursor
	lda _1000Hz+1
	jsr PrintHex
	lda _1000Hz
	jsr PrintHex
	SET_XY 10,10
	jsr ReadKey		; test for key-press
				; and do actions (PAUSE,FLIP,RESTART)
	lda CurrentButton
	jsr PrintHex
	bit #_FIREA|_FIREB
	beq .loop
	bit #_FIREA
	_IFNE
	  inc counter
	_ELSE
	  dec counter
	_ENDIF
	SET_XY 0,0
	lda counter
	jsr PrintHex
	bra .loop
****************

VBL::	jsr Keyboard		; read buttons
	stz $fda0
	END_IRQ

HBL::	inc $fda0
	END_IRQ
****************
StartPause::
	MOVE _1000Hz,Save1000Hz
	SET_XY 40,40
	PRINT "PAUSE",,1
	rts

EndPause::
	MOVE Save1000Hz,_1000Hz
	CLS #0
	rts
****************
cls::	sta cls_color
	LDAY clsSCB
	jmp DrawSprite

clsSCB	dc.b $c0,$90,$00
	dc.w 0,cls_data
	dc.w 0,0		; X,Y
	dc.w 160*$100,102*$100	; size_x,size_y
cls_color
	dc.b $00

cls_data
	dc.b 2,$10,0


****************
* INCLUDES
	include <includes/1000Hz.inc>
	include <includes/debug.inc>
	include <includes/serial.inc>
	include <includes/font.inc>
	include <includes/irq.inc>
	include <includes/font2.hlp>
	include <includes/newkey.inc>
	include <includes/hexdez.inc>
	include <includes/draw_spr.inc>


pal	STANDARD_PAL

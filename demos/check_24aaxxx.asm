***************
* check_24aaxxx.asm
* Test program for 24AAxxx EEPROMs
*
* created : 30.12.2020
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
	include <macros/key.mac>
	include <macros/debug.mac>
* variables
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/serial.var>
	include <vardefs/font.var>
	include <vardefs/irq.var>
	include <vardefs/key.var>
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
page		ds 2
Save1000Hz	ds 2
ee24aaxxx_tmp	ds 1
ptr		ds 2
 END_ZP

 BEGIN_MEM
	ALIGN 4
screen0	ds SCREEN.LEN
irq_vektoren	ds 16
pageBuffer      ds 128
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
	INITFONT LITTLEFNT,RED,WHITE
	jsr Init1000Hz
	jsr InitComLynx
	INITBRK			; if we're using BRK #X, init handler

	cli			; allow interrupts
	SCRBASE screen0		; set screen, single buffering
	CLS #0			; clear screen with color #0
	SETRGB pal		; set palette

	SET_MINMAX 0,0,160,102	; screen-dim. for FONT.INC

	LDAY hallo
	jsr print

	;; ---------------------
	;;  Read/write benchmark
 IF 0 = 1
	ldy	#0
	lda	#$42
.l0	sta	pageBuffer,y
	iny
	bpl	.l0

	sei
	stz	_1000Hz
	stz	_1000Hz+1
	stz	_1000Hz+2
	cli
	stz	page
	stz	page+1
.bench

	lda	page
	ldx	page+1
	jsr	ee24aa512_writePage
.wait
	jsr	ee24aaxxx_check
	bcs	.wait

	inc	page
	bne	.bench
	inc	page+1
	lda	page+1
	cmp	#2
	bne	.bench

	sei
	lda	_1000Hz
	pha
	lda	_1000Hz+1
	pha
	lda	_1000Hz+2
	pha
	cli
	SET_XY	0,90
	pla
	jsr	PrintHex
	pla
	jsr	PrintHex
	pla
	jsr	PrintHex
 ENDIF
	;;  ---------------------

	lda #0
	sta page
	lda #0
	sta page+1
.loop0
	SET_XY 0,10
	lda page+1
	jsr PrintHex
	lda page
	jsr PrintHex

	jsr	dumpPage
.loop
	jsr ReadKey		; test for key-press
				; and do actions (PAUSE,FLIP,RESTART)
	lda Cursor
	beq	.1
	bit #$c0
	beq	.1
	bit #$80
	_IFNE
	  inc page
	  _IFEQ
	    inc page+1
	  _ENDIF
	_ELSE
	  dec page
	  lda page
	  inc
	  _IFEQ
	    dec page+1
	  _ENDIF
	_ENDIF
.0
	lda	page+1
	cmp	#2
	_IFEQ
	  stz page+1
	  stz page
	_ENDIF
	cmp	#$ff
	_IFEQ
	  sta page
	  lda #1
	  sta page+1
	_ENDIF

	bra .loop0
.1
	lda Button
	bit #_FIREA|_FIREB
	beq .loop
	bit #_FIREA
	_IFNE
	  ldy	#0
	  lda	#255
.l2	    sta pageBuffer,y
	    iny
	  bpl .l2

	  ldx page+1
	  lda page
	  jsr ee24aa512_writePage
        _ELSE
	  ldy	#0
.l3	    tya
	    sta pageBuffer,y
	    iny
	  bpl .l3

	  ldx page+1
	  lda page
	  jsr ee24aa512_writePage
	_ENDIF

	bra .loop0

dumpPage::
	lda page
	ldx page+1
	jsr ee24aa512_readPage

	SET_XY 0,20
	ldy   #0
.l1	  lda pageBuffer,y
	  jsr PrintHex
	  iny
	bpl .l1
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

hallo
	dc.b "24AAxxx test : A - clear / B - fill",0

****************
* INCLUDES
	include <includes/1000Hz.inc>
	include <includes/debug.inc>
	include <includes/serial.inc>
	include <includes/font.inc>
	include <includes/irq.inc>
	include <includes/font2.hlp>
	include <includes/key.inc>
	include <includes/hexdez.inc>
	include <includes/draw_spr.inc>
	include <includes/24aaxxx.inc>
pal	STANDARD_PAL

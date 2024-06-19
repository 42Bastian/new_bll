;;; Little overlay/file loading demo
;;; Inspired by Laoo ;-)
;;;

	;; configuration
BlockSize 	equ 1024
LoadDirUser	equ 1		; use LoadDir
LocalDirUser	equ 1		; use directory in RAM not from ROM

IRQ_SWITCHBUF_USR set 1

 IFND LNX
LNX		set 1
 ENDIF
	include <includes/hardware.inc>
* macros
	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/font.mac>
	include <macros/irq.mac>
	include <macros/file.mac>
	include <macros/lnx_header.mac>
	include <macros/cart_header.mac>
	include <macros/overlay.mac>
* variables
	include <vardefs/help.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/font.var>
	include <vardefs/irq.var>
	include <vardefs/file.var>

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
irq_vektoren	ds 16
overlay		ds 1
 END_ZP

screen0		equ $fff0-SCREEN.LEN
screen1		equ screen0-SCREEN.LEN


	CART_HEADER "Overlay Test","42Bastian",0,0

	run $1ff
	dc.b 1+((End-Start)>>8)

Start::				; Start-Label needed for reStart
	jmp	init
main:
	INITFONT SMALLFNT,0,15
main_loop:
	CLS	#2
	SET_XY	10,10		; set FONT-cursor
	LDAY	info1
	jsr	print
	lda	overlay
	bmi	no_overlay
	jsr	overlay_start
no_overlay
	SWITCHBUF
.wait	lda	$fcb0
	beq	.wait
.wait1	ldx	$fcb0
	bne	.wait1

	bit	#JOY_A
	beq	.no_A
	ldx	#0
	bra	.ok
.no_A
	bit	#JOY_B
	beq	.wait
	ldx	#1
.ok
	jsr	LoadOverlay
	jmp	main_loop

info1:	dc.b "Hello Overlay:",0


LoadOverlay::
	stx	overlay
	txa
	LOADFILE
	rts

VBL::
	phy
	_IFMI SWITCHFlag
	stz SWITCHFlag
	ldx ScreenBase
	ldy ScreenBase+1
	lda ScreenBase2
	sta ScreenBase
	sta VIDBAS
	lda ScreenBase2+1
	sta ScreenBase+1
	sta VIDBAS+1
	stx ScreenBase2
	sty ScreenBase2+1
	stx $fd94
	sty $fd95
	_ENDIF

	ply
	END_IRQ

cls::	sta cls_color
	LDAY clsSCB
	jmp DrawSprite

clsSCB	dc.b $c0,$90,$00
	dc.w 0,cls_data
	dc.w 0,0		; X,Y
cls_size:
	dc.w 160*$100
	dc.w 102*$100		; size_x,size_y
cls_color
	dc.b $00

cls_data
	dc.b 2,$10,0

	include <includes/font.inc>
	include <includes/irq.inc>
	include <includes/font2.hlp>
	include <includes/hexdez.inc>
	include <includes/draw_spr.inc>
	include <includes/file.inc>

FileDirectory:
	OVERLAY_DIR_ENTRY overlay1
	OVERLAY_DIR_ENTRY overlay2

	;; Code from here is no longer needed after startup
init:
	START_UP		; set's system to a known state
	CLEAR_ZP		; clear zero-page

	INITMIKEY
	INITSUZY
	INITIRQ irq_vektoren	; set up interrupt-handler
	SETRGB pal		; set palette

        FRAMERATE 60

        SETIRQ 2,VBL
	SCRBASE screen0,screen1
	MOVE	ScreenBase,VIDBAS
	SET_MINMAX 0,0,159,101	; screen-dim. for FONT.INC

	dec	overlay		; flag: no overlay loaded yet
	cli
	jmp	main

pal	STANDARD_PAL
	;; End of main program
End::

	;; move ROM PC behind main program
ROM_PC	set ROM_PC+(End-Start+1)

	;; init code is no longer needed
overlay_start	equ init

	echo "Overlay: %Hoverlay_start"
 IF 0
	ROM_BLOCK_ALIGN $42
 ENDIF
	OVERLAY_BEGIN overlay1, overlay_start
	LDAY	info_ovl1
	jsr	print
	rts
info_ovl1:
	dc.b "Overlay 1",0
	ds	2000		; dummy stuff
	OVERLAY_END overlay1

	OVERLAY_BEGIN overlay2, overlay_start
	LDAY	info_ovl2
	jsr	print
	rts
info_ovl2:
	dc.b "Overlay 2",0
	OVERLAY_END overlay2

	echo "%H ROM_overlay1 %dsize_overlay1"
	echo "%H ROM_overlay2 %dsize_overlay2"

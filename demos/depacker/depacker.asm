***************
* RAW.ASM
* simple body of a Lynx-program
*
* created : 24.04.96
* changed : May 2020
****************

LZ4	EQU 0
ZX0	EQU 1

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
	include <macros/debug.mac>
* variables
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/serial.var>
	include <vardefs/font.var>
	include <vardefs/irq.var>
	include <vardefs/1000Hz.var>
*
* local MACROs
*
	MACRO CLS
	lda \0
	jsr cls
	ENDM

voyager_data	equ $8000
*
* vars only for this program
*

 BEGIN_ZP
src		ds 2
dst		ds 2
packer_zp	ds 12
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

	INITFONT LITTLEFNT,RED,WHITE
	jsr Init1000Hz
	jsr InitComLynx
	INITBRK			; if we're using BRK #X, init handler

	SCRBASE screen0		; set screen, single buffering
	cli
	CLS #0			; clear screen with color #0
	SETRGB pal		; set palette

	SET_MINMAX 0,0,160,102	; screen-dim. for FONT.INC

	stz	_1000Hz
	stz	_1000Hz+1
 IF LZ4 = 1
	MOVEI	packed+8,src
	MOVEI	voyager_data,dst
	LDAY	packed_e-packed-8
 ENDIF
 IF ZX0 = 1
	MOVEI	packed,src
	MOVEI	voyager_data,dst
 ENDIF
	HANDY_BRKPT

	jsr	depacker
	lda	_1000Hz
	pha
	lda	_1000Hz+1
	pha

	LDAY	voyagerSCB
	jsr	DrawSprite

	SET_XY 0,0		; set FONT-cursor
	pla
	jsr PrintHex
	pla
	jsr PrintHex
.loop
	bra .loop
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

voyagerSCB:
	dc.b $c0,$90,$00
	dc.w 0,voyager_data
	dc.w 0,0		; X,Y
	dc.w $100,$100	; size_x,size_y

	include "startrek_voyager.pal"
****************
* INCLUDES
	include <includes/1000Hz.inc>
	include <includes/debug.inc>
	include <includes/serial.inc>
	include <includes/font.inc>
	include <includes/irq.inc>
	include <includes/font2.hlp>
	include <includes/hexdez.inc>
	include <includes/draw_spr.inc>
;;; ----------------------------------------
depacker:
 IF LZ4 = 1
	include "unlz4.asm"
 ENDIF
 IF ZX0 = 1
	include "unzx0.asm"
 ENDIF
depacker_e:
End:

packed:
 IF LZ4 = 1
	ibytes	"startrek_voyager.spr.lz4"
//->	ibytes	"empty.spr.lz4"
 ENDIF
 IF ZX0 = 1
	ibytes	"startrek_voyager.spr.zx0"
 ENDIF

//->	ibytes	"startrek_voyager.spr"
packed_e:

size	set depacker_e - depacker

	echo "Depacker size:%dsize"

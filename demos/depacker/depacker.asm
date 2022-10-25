***************
* depacker.asm
* Depacker test
****************
ASTEROIDS	EQU 0

RAW		EQU 0
LZ4		EQU 0
LZ4_fast	EQU 0
ZX0		EQU 0
ZX0_fast	EQU 0
TP		EQU 0
EXO		EQU 1

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
 IF EXO = 1
	include "krilldecr.var"
 ENDIF
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
tmp		ds 2
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

	lda	_1000Hz		; sync on interrupt
.wait	cmp	_1000Hz
	beq	.wait

	stz	_1000Hz
	stz	_1000Hz+1
 IF RAW = 1
	MOVEI	packed,src
	MOVEI	voyager_data,dst
	ldx	#<(-(packed_e-packed))
	lda	#>(-(packed_e-packed))
	sta	tmp
	ldy	#0
.cpy	lda	(src),y
	sta	(dst),y
	iny
	bne	.1
	inc	dst+1
	inc	src+1
.1
	inx
	bne	.cpy
	inc	tmp
	bne	.cpy
 ENDIF
 IF LZ4 + LZ4_fast > 0
	MOVEI	packed+8,src
	MOVEI	voyager_data,dst
	LDAY	packed_e-packed-8
	jsr	unlz4
 ENDIF
 IF ZX0 + ZX0_fast > 0
	MOVEI	packed,src
	MOVEI	voyager_data,dst
	jsr	unzx0
 ENDIF
 IF TP = 1
	MOVEI	packed,src
	MOVEI	voyager_data,dst
	LDAY	packed_e-packed
	jsr	untp
 ENDIF
	HANDY_BRKPT
 IF EXO = 1
;;; exomizer.exe level -P0 -f infile -o outfile.exo
	MOVEI	packed,src
	MOVEI	(voyager_data+2),zp_dest_lo
	jsr	decrunch
	;; Exomizer does skip the first two bytes when packing!
	;; So either add two dummy bytes to the file to be packed
	;; or - as here - write those by hand.
	lda	#$52
	sta	voyager_data
	stz	voyager_data+1
 ENDIF
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

 IF ASTEROIDS = 1
	include "voyager_asteroids.pal"
 ELSE
	include "startrek_voyager.pal"
 ENDIF
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
 IF LZ4_fast = 1
	include "unlz4_fast.asm"
 ENDIF
 IF ZX0 = 1
	include "unzx0.asm"
 ENDIF
 IF ZX0_fast = 1
	include "unzx0_fast.asm"
 ENDIF
 IF TP = 1
	include "untp.asm"
 ENDIF
 IF EXO = 1
	include "krilldecr.inc"
get_crunched_byte::
	php
	lda	(src)
	inc	src
	bne	.99
	inc	src+1
.99
	plp
	rts
 ENDIF
depacker_e:

packed:
 IF LZ4 + LZ4_fast > 0
 IF ASTEROIDS = 1
	ibytes	"voyager_asteroids.spr.lz4"
 ELSE
	ibytes	"startrek_voyager.spr.lz4"
 ENDIF
//->	ibytes	"empty.spr.lz4"
 ENDIF
 IF ZX0 + ZX0_fast > 0
 IF ASTEROIDS = 1
	ibytes	"voyager_asteroids.spr.zx0"
 ELSE
	ibytes	"startrek_voyager.spr.zx0"
 ENDIF
//->	ibytes	"empty.spr.zx0"
 ENDIF

 IF TP = 1
 IF ASTEROIDS = 1
	ibytes	"voyager_asteroids.pck"
 ELSE
	ibytes	"startrek_voyager.pck"
 ENDIF
//->	ibytes	"empty.pck"
 ENDIF

 IF EXO = 1
 IF ASTEROIDS = 1
	ibytes	"voyager_asteroids.spr.exo"
 ELSE
	ibytes	"startrek_voyager.spr.exo"
 ENDIF
 ENDIF

 IF RAW = 1
 IF ASTEROIDS = 1
	ibytes	"voyager_asteroids.spr"
 ELSE
	ibytes	"startrek_voyager.spr"
 ENDIF
 ENDIF
packed_e:

size		set depacker_e - depacker
packed_size	set packed_e - packed
	echo "Depacker size:%dsize"
	echo "Packed data size:%dpacked_size"


BRKuser	set 1	      ; define if you want to use debugger



Baudrate	set 62500


	include <includes/hardware.inc>

	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/microfnt.mac>

	include <macros/debug.mac>
	include <macros/irq.mac>
	include <macros/newkey.mac>
;
; essential variables
;
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/irq.var>
	include <vardefs/serial.var>

	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/newkey.var>

;
; local MACROs
;
	MACRO CLS
	lda #\0
	jsr cls
	ENDM
;
; zero-page
;
 BEGIN_ZP

cursor_x	ds 1
cursor_y	ds 1
offset	ds 1
shadow	ds 2
hardware	ds 2
value	ds 1
 END_ZP
;
; main-memory variables
;
 BEGIN_MEM
	align 4
screen0	ds SCREEN.LEN
irq_vectors	ds 16
suzy_shadow	ds 256
mikey_shadow	ds 256
 END_MEM
;
; code
;
;
; system-init
;
	run LOMEM

Start::	START_UP
	CLEAR_MEM
	CLEAR_ZP +STACK

	INITMIKEY
	INITSUZY

	INITIRQ irq_vectors
	jsr InitComLynx
	INITBRK

	INITKEY ,0

	INIT_MICROFNT
	SETRGB pal

;>	  SETIRQ 0,HBL
	SETIRQVEC 0,HBL
	SETIRQVEC 1,timer1
	SETIRQVEC 2,timer2
	SETIRQVEC 3,timer3
	SETIRQVEC 5,timer5
	SETIRQVEC 6,timer6
	SETIRQVEC 7,timer7

	cli	; don`t forget this !!!!

	SCRBASE screen0
	MOVE ScreenBase,MFNT_screenbase

	CLS 0
;
;>	  SETRGB pal	  ; set color
;
; main-loop
;

	lda #0
	sta cursor_x
	lda #0
	sta cursor_y

	jsr DrawCursor
	MFNT_PRINTSTRINGXY #54,#7,Help

.loop
	MFNT_PRINTSTRINGXY #10,#0,Mikey
	MOVEI mikey_shadow,shadow
	MOVEI $fd00,hardware

.1
	jsr DumpFD00

	jsr Readkey	    ; see MIKEY.MAC
	beq .1
	lda Button
	bit #OPTION_1
	bne .suzy
	bit #BUTTON_A|BUTTON_B
	_IFNE
	  jsr ChangeValue
	  bra .1
	_ENDIF


	lda Cursor
	_IFNE
	  jsr MoveCursor
	_ENDIF
	bra .1

.suzy
	MFNT_PRINTSTRINGXY #10,#0,Suzy
	MOVEI suzy_shadow,shadow
	MOVEI $fc00,hardware
.2

.3
	jsr DumpFC00
	jsr Readkey	   ; see MIKEY.MAC
	beq .3

	lda Button
	bit #OPTION_1
	_IFNE
	  jmp .loop
	_ENDIF
	bit #BUTTON_A|BUTTON_B
	_IFNE
	  jsr ChangeValue
	  bra .3
	_ENDIF

	lda Cursor
	_IFNE
	  jsr MoveCursor
	_ENDIF
	bra .3

Mikey	dc.b "-- MIKEY --",-1
Suzy	dc.b "-- SUZY -- ",-1

Help	dc.b "OPTION 1 = TOGGLE BASE",13
	dc.b "BUTTON A = CHANGE VALUE",13
	dc.b "BUTTON B = WRITE ZERO",13
	dc.b 13
	dc.b "RIGHT/LEFT = +- 16",13
	dc.b "UP/DOWN	 = +-  1",13
	dc.b -1

ChangeValue::
	bit #BUTTON_B
	_IFNE
	  ldy offset
	  lda #0
	  sta (shadow),y
	  sta (hardware),y
	  rts
	_ENDIF

	sei
	lda $fd09
	pha
	ora #$80
	sta $fd09
	SETIRQVEC 2,VBL
	cli

	lda #$0f
	sta $fdbf
	ldy offset
	lda (shadow),y
	sta value

.0	ldy #50
	ldx #60
	jsr MFNT_PrintHexXY
.1	jsr ReadKey
	beq .1

	lda Button
	bit #BUTTON_A
	_IFNE
	  sei
	  pla
	  sta $fd09
	  ldy offset
	  lda value
	  sta (shadow),y
	  sta (hardware),y
	  SETIRQVEC 2,timer2
	  cli
	  lda #$ff
	  sta $fdbf
	  rts
	_ENDIF
	ldx value
	lda Cursor
	bit #$c0
	_IFNE
	  bit #$80
	  _IFNE
	    inx
	  _ELSE
	    dex
	  _ENDIF
	_ELSE
	  bit #$20
	  _IFNE
	    txa
	    clc
	    adc #$10
	  _ELSE
	    txa
	    sec
	    sbc #$10
	  _ENDIF
	  tax
	_ENDIF
	stx value
	txa
	bra .0

MoveCursor::
	jsr ClearCursor
	ldx cursor_x
	ldy cursor_y
	lda Cursor
	bit #$30
	_IFNE
	  bit #$20
	  _IFNE
	    dex
	  _ELSE
	    inx
	  _ENDIF
	_ELSE
	  bit #$80
	  _IFNE
	    dey
	  _ELSE
	    iny
	  _ENDIF
	_ENDIF
	txa
	and #$f
	sta cursor_x
	tya
	and #$f
	sta cursor_y
	asl
	asl
	asl
	asl
	ora cursor_x
	sta offset
	tay
	lda (shadow),y
	ldy #50
	ldx #60
	jsr MFNT_PrintHexXY
	jmp DrawCursor



Readkey::
	jsr Keyboard
	jmp ReadKey
;---------------
; Mikey
DumpFD00::
	lda #6
	sta MFNT_char_y

	ldx #0
.0
	stz MFNT_char_x
	lda #"F"
	jsr MFNT_PrintChar
	lda #"D"
	jsr MFNT_PrintChar
	txa
	jsr MFNT_PrintHex
	inc MFNT_char_x
.1	lda mikey_rd_regs,x
	_IFNE
	  lda $fd00,x
	  sta mikey_shadow,x
	  jsr MFNT_PrintHex
	_ELSE
	  lda #"-"
	  jsr MFNT_PrintChar
	  lda #"-"
	  jsr MFNT_PrintChar
	_ENDIF
	inc MFNT_char_x
	inx
	txa
	and #$f
	bne .1
	clc
	lda MFNT_char_y
	adc #6
	sta MFNT_char_y
	stz MFNT_char_x
	txa
	bne .0
	rts
mikey_rd_regs:
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	dc.b 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 1,1,0,0,1,1,1,1,1,0,0,1,1,1,0,0
	dc.b 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;---------------
;- SUZY
DumpFC00::
	lda #6
	sta MFNT_char_y

	ldx #0
.0	lda #0
	sta MFNT_char_x
	lda #"F"
	jsr MFNT_PrintChar
	lda #"C"
	jsr MFNT_PrintChar

	txa
	jsr MFNT_PrintHex
	inc MFNT_char_x
.1	lda suzy_rd_regs,x
	_IFNE
	  lda $fc00,x
	  sta suzy_shadow,x
	  jsr MFNT_PrintHex
	_ELSE
	  lda #"-"
	  jsr MFNT_PrintChar
	  lda #"-"
	  jsr MFNT_PrintChar
	_ENDIF
	inc MFNT_char_x
	inx
	txa
	and #$f
	bne .1
	clc
	lda MFNT_char_y
	adc #6
	sta MFNT_char_y
	txa
	bne .0
	rts

suzy_rd_regs:
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0
	dc.b 1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0
	dc.b 0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;---------------
;- ShowCursor
;
ClearCursor::
	ldx cursor_y
	ldy real_cur_y,x
	ldx cursor_x
	lda real_cur_x,x
	tax
	lda #0
	bra DrawCursor2

DrawCursor::
	ldx cursor_y
	ldy real_cur_y,x
	ldx cursor_x
	lda real_cur_x,x
	tax
	lda #$ff
DrawCursor2
	pha
	clc
	txa
	adc screen_offlo,y
	tax
	lda #0
	adc screen_offhi,y
	tay
	clc
	txa
	adc ScreenBase
	sta temp
	tya
	adc ScreenBase+1
	sta temp+1

	pla
	tax
	and #$0f
	sta (temp)
	txa
	ldy #1
	sta (temp),y
	iny
	sta (temp),y
	iny
	and #$f0
	sta (temp),y

	ldy #80
	txa
	and #$f
	sta (temp),y
	ldy #160
	sta (temp),y
	ldy #240
	sta (temp),y

	txa
	and #$f0
	ldy #83
	sta (temp),y
	ldy #163
	sta (temp),y
	ldy #243
	sta (temp),y

	clc
	lda temp
	adc #240
	sta temp
	lda temp+1
	adc #0
	sta temp+1

	txa
	and #$f
	sta (temp)
	ldy #80
	sta (temp),y
	ldy #160
	sta (temp),y
	ldy #240
	sta (temp),y

	txa
	iny
	sta (temp),y
	iny
	sta (temp),y
	and #$f0
	iny
	sta (temp),y

	ldy #83
	sta (temp),y
	ldy #163
	sta (temp),y

	rts

real_cur_x:
s	set 4
	REPT 16
	dc.b s
s	set s+3
	ENDR

real_cur_y
s	set 5
	REPT 16
	dc.b s
s	set s+6
	ENDR

screen_offlo:
s	set 0
	REPT 102
	dc.b <s
s	set s+80
	ENDR

screen_offhi:
s	set 0
	REPT 102
	dc.b >s
s	set s+80
	ENDR


; HBL-routine
;
; shows three color-bars
;
HBL::
	inc $fdb0
	END_IRQ

_red_sinus::	 dc.b 2,5,7,9,11,13,15,13,11,9,7,5,2
_green_sinus::	 dc.b 2,5,7,9,11,13,15,13,11,9,7,5,2
_blue_sinus::	 dc.b $20,$50,$70,$90,$c0,$d0,$f0,$d0,$c0,$90,$70,$50,$20

;
timer2::	stz $fda0
	stz $fdb0
	END_IRQ

timer1::
timer3::
timer5::
timer6::
timer7::
	inc $fda0
	inc $fdb0
	END_IRQ
;
; VBL - routine
;
; re-inits vars for the HBL-routine
;

VBL::	stz $fda0
	stz $fdb0
	jsr Keyboard

	END_IRQ
;
; clear screen
;
cls::	sta cls_color
	LDAY clsSCB
	jmp DrawSprite

clsSCB	dc.b $c0,$90,$00
	dc.w 0,cls_data
	dc.w 0,0
	dc.w 160*$100,102*$100
cls_color
	dc.b 00

cls_data
	dc.b 2,$10,0

;

	include <includes/irq.inc>
	include <includes/debug.inc>
	include <includes/serial.inc>

	include <includes/draw_spr.inc>
	include <includes/newkey.inc>


pal
;;;       GBR
;         000 100 010 110 001 101 011 111
       DP 000,00B,B00,BB0,0B0,0BB,BB0,BBB,000,000,000,000,000,000,000,FFF

//->  char F,_111,_100, _100,_000, _111,_000, _100,_000, _100,_000

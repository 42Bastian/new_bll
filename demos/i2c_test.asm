Baudrate        equ 62500
DEBUG		set 1
_1000HZ_TIMER   set 7

* Macros
	include <includes/hardware.inc>

	include <macros/help.mac>
	include <macros/if_while.mac>
	include <macros/font.mac>
	include <macros/window.mac>
	include <macros/mikey.mac>
	include <macros/suzy.mac>
	include <macros/irq.mac>
	include <macros/key.mac>
	include <macros/debug.mac>
	include <macros/file.mac>
* Variablen
	include <vardefs/debug.var>
	include <vardefs/help.var>
	include <vardefs/font.var>
	include <vardefs/window.var>
	include <vardefs/mikey.var>
	include <vardefs/suzy.var>
	include <vardefs/irq.var>
	include <vardefs/key.var>
	include <vardefs/file.var>
	include <vardefs/serial.var>
	include <vardefs/1000Hz.var>
	include <vardefs/eeprom.var>

 BEGIN_ZP
counter         ds 1
address         ds 1
 END_ZP

 BEGIN_MEM
screen0         ds SCREEN.LEN
irq_vektoren    ds 16

eeprom          ds 128
DefaultSaveGame ds 128
 END_MEM
	run LOMEM

Start::
        sei
	CLEAR_MEM
	CLEAR_ZP
	INITMIKEY
	INITSUZY
	SETRGB pal
	INITIRQ irq_vektoren
	INITKEY
	INITFONT LITTLEFNT,ROT,WEISS
	jsr Init1000Hz
	jsr InitComLynx
	cli
	SCRBASE screen0
	CLS #0
	SET_MINMAX 0,0,160,102
	LDAY hallo
	jsr print
.loop00
        jsr ReadKey
	beq .cont0
	lda Button
	cmp #_FIREA
	bne .cont
	ldx #127
.1
        stz eeprom,x
	dex
	bpl .1
	LDAY eeprom
	jsr WriteSaveGame
	bra .cont0
.cont
        cmp #_FIREB
	bne .cont0
	jsr FillEEPROM

.cont0
        stz CurrX
	lda #6
	sta CurrY
	lda counter
	inc counter
	jsr PrintHex
	stz CurrX
	lda #12
	sta CurrY
	stz address
	stz temp
	stz temp+1
	ldx #8
.loop01
        phx
	  ldx #8
.loop02
          phx
	  lda address
	  jsr EE_Read

	  lda I2Cword
	  jsr PrintHex
	  lda I2Cword+1
	  jsr PrintHex

	  inc address
	lda address
	cmp #$40
	beq .cont1
	clc
	lda temp
	adc I2Cword
	sta temp
	lda temp+1
	adc I2Cword+1
	sta temp+1
.cont1
          inc CurrX
	  inc CurrX
	  plx
	  dex
	 bne .loop02
	 stz CurrX
	 clc
	 lda CurrY
	 adc #6
	 sta CurrY
	 plx
	 dex
	bne .loop01
	LDAY checktxt
	jsr print
	lda temp
	jsr PrintHex
	lda temp+1
	jsr PrintHex
	jmp .loop00

hallo
	dc.b "TEST-EERPOM : A - clear / B - fill",0
checktxt
	dc.b "Checksum:",0

FillEEPROM::
	ldx #125
.loop
        txa
	 lsr
;-->	 lda #$ff
	 sta eeprom,x
	 lda counter
	 dex
;-->	 lda #$ff
	 sta eeprom,x
	 dex
	bpl .loop
	LDAY eeprom
	jmp WriteSaveGame
****************
PrintHex::
	phx
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda digits,x
	jsr PrintChar
	pla
	and #$f
	tax
	lda digits,x
	jsr PrintChar
	plx
	rts

***************
digits	db "0123456789ABCDEF"



* INCLUDES
	include <includes/1000Hz.inc>
	include <includes/serial.inc>
	include <includes/debug.inc>
	include <includes/font.inc>
	include <includes/window2.inc>
	include <includes/irq.inc>
	include <includes/font2.hlp>
	include <includes/key.inc>
	include <includes/eeprom.inc>
	include <includes/savegame.inc>

pal	STANDARD_PAL

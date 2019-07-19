* -*-asm-*-
****************
* EEPROM-routines
* for 93C46A (1024bit => 128 8-bit words)
*
* created : 11.05.95
* last modified :
*
* 16.02.96	leaner (thanks to Harry)
* 12.03.96	test for busy after write and erase (well, Harry ;)) )
* 11.01.99	new EEPROMs need DO to be set to 0 command write!
* 22.04.04      Version for 8 bit organized EEPROMS
*
*
*
* (c) 1995 Bastian Schick
* CS	= A7 (18)
* CLK	= A1 (11)
* DI/DO = AUDIN (32)
*
*And now how to contact the EEPROM :
*
*CARD
*PORT	    	    ----\/----	    93C46(SMD too)
*(18)  A7   --------| CS     |- +5V
*(11)  A1   --------| CLK    |- NC
*		+---| DI     |- NC
*(32) AUDIN ----+---| DO     |- GND
*	    	    ----------
*
****************

* -------------------
* EEPROM command list
* -------------------
EE_C_WRITE	EQU    $40
EE_C_READ	EQU    $80
EE_C_ERASE	EQU    $C0
EE_C_EWEN	EQU    $60
EE_C_EWDS	EQU    $00


	MACRO EE_TOGGLE_CLK
	stz $fcb2
	stz $fcb2
	ENDM

	MACRO EE_SET_CS_HIGH	; CS = 1
	ldx #63
.\ee1	  stz $fcb2
	  stz $fcb2
	  dex
	bpl .\ee1
	ENDM

	MACRO EE_SET_CS_LOW	; CS = 0 and CLK = 0
	ldx #3
	stx $fd87
	dex
	stx $fd87
	ENDM

****************
* read 16bit Wort from address A
****************
EE_Read::
	pha			; save address
	clc
	jsr EE_ReadHigh

	lda I2Cword
	sta I2Cword+1

	pla
	sec
EE_ReadHigh:
	and #$3f
	rol			; odd address
	sec
	jsr EE_Send10Bit
****************
* reads EEPROM-word to I2Cword
* A,Y destroyed
****************
EE_Read8Bit::
	lda #$a
	sta $fd8A	; set AUDIN to Input

	clc
	stz I2Cword
	ldy #7
.loop
	EE_TOGGLE_CLK	; CLK = 1
	EE_TOGGLE_CLK	; CLK = 0
	lda $fd8b
	and #$10	; mask bit
	adc #$f0	; C=1 if A=$10
	rol I2Cword
	dey
	bpl .loop

	ldx #$1a
	stx $fd8a	; set AUDIN for output

	EE_SET_CS_LOW

	rts
 IF 0
****************
* clear word at address A
****************
EE_Erase::
	pha
	lda #EE_C_EWEN	; EWEN
	jsr EE_Send10Bit
	pla
	and #$3f
	ora #EE_C_ERASE ; clear cell A
	jsr EE_Send10Bit
	bra EE_wait
 ENDIF
****************
* write word at address A
****************

EE_Write8:
	and #$3f
	rol
	ora #$80
	clc
	jsr EE_Send10Bit
	jsr EE_Send8Bit

EE_wait
	EE_SET_CS_HIGH
	lda #$0A
	sta $fd8a	; AUDIN to input
	lda #$10
.wait	bit $fd8b	; 'til ready :D0-read is /D0-written
	beq .wait
	lda #$1a	; AUDIN to output
	sta $fd8a
	rts

EE_Write::
	pha			; save address
	clc
	lda #EE_C_EWEN
	jsr EE_Send10Bit	; enable write/erase
	pla
	pha
	sec
	jsr EE_Write8
	lda I2Cword+1
	sta I2Cword
	clc
	pla
	jsr EE_Write8
	clc
	lda #EE_C_EWDS		; disable write/erase
****************
* send A via I2C
* A,Y destroyed
****************
EE_Send10Bit::
	ror
	ror
	ror
	ror		; bit 8 at pos. 4
	php

	EE_SET_CS_LOW	; CLK = 0 / CS = 0
	EE_SET_CS_HIGH

	ldx #$1b	; start-bit
	stx $fd8b
	EE_TOGGLE_CLK	; CLK = 1
	EE_TOGGLE_CLK	; CLK = 0

	plp
	ldy #8

	;; send y+1 bits
EE_send:
.loop
	 tax
	 and #$10
	 ora #$b
	 sta $fd8b
	 EE_TOGGLE_CLK	; CLK = 1
	 EE_TOGGLE_CLK	; CLK = 0
	 txa
	 rol
	 dey
	bpl .loop

	lda #$b
	sta $fd8b

	rts
****************
* send I2Cword to EEPROM
* A,Y detroyed
****************
EE_Send8Bit::
	lda I2Cword
	ror
	ror
	ror

	ldy #7
	jsr EE_send

	EE_SET_CS_LOW

	rts

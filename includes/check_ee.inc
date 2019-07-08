****************
* CHECK_EE.INC
* routine to check if there's a EEPROM and working correct
*
* first version : 25.04.96 by Bastian Schick
*
* last modified :
*
****************
	
okEEPROM	EQU $0
noEEPROM	EQU $1
koEEPROM	EQU $2


****************
* IN : -
* OUT: A = EEPROM's state
*
* detroys all registers
*
* to be called once in a games live ;)
****************
CheckEEPROM::	ldx #127-2
.1	  lda $fd02
	  sta EEPROMbuffer,x
.2	  dec
	  bpl .2
	  dex
	bpl .1
	lda #<EEPROMbuffer
	ldy #>EEPROMbuffer
	jsr WriteSaveGame	; EEPROM = RND
	
	lda #<EEPROMbuffer
	ldy #>EEPROMbuffer
	jsr LoadSaveGame	; check it
	tay		; Save Flag
	ldx #127-2		; all cell execept Checksum
	lda #$ff
.3	  cmp EEPROMbuffer,x
	  bne .90
	  dex
	bpl .3
	lda #noEEPROM		; all cells = $FF !
	rts

.90	tya
	bne .ko
	ldx #127-2
.91	  stz EEPROMbuffer,x
	  dex
	bpl .91
	lda #<EEPROMbuffer
	ldy #>EEPROMbuffer
	jsr WriteSaveGame	; EEPROM = 0
	
	lda #<EEPROMbuffer
	ldy #>EEPROMbuffer
	jsr LoadSaveGame	; check again
	beq .ok
.ko	lda #koEEPROM
	rts
.ok	lda #okEEPROM
	rts
	
*****
*EOF*
*****

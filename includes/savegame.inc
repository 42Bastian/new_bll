* -*-asm-*-
***********
* SAVEGAME
* created : 11.5.95
* (c) 1995 Bastian Schick
*
* WriteSaveGame	- writes EEPROM
* LoadSaveGame  - reads total EEPROM to memory
*
* last modified :
*
* 18.03.96	removed self-modifying code (make's hacking , sorry debuging
*	 easier ;)) (Hi Harry )



****************
* IN : Y:A address of 128byte default
* byte 126/127 are used for checksum
****************
WriteSaveGame::
	stz temp
	stz temp+1
	sta temp1
	sty temp1+1

	ldy #0
	ldx #0
.loop	phx
	clc
	lda (temp1),y
	sta I2Cword
	adc temp
	sta temp
	iny
	lda (temp1),y
	sta I2Cword+1
	adc temp+1
	sta temp+1
	iny
	txa
	phy
	jsr EE_Write
	ply
	plx
	inx
	cpx #$3f
	bne .loop
	MOVE temp,I2Cword
	txa
	jmp EE_Write
****************
* IN : Y:A adress of 128 free space
* OUT : X:Y = checksum
* A = 0 => OK
* A # 0 => checksum error
****************
LoadSaveGame::	sta temp1
	sty temp1+1

	stz temp
	stz temp+1
	ldy #0
	ldx #0
.loop	phx
	phy

	txa
	jsr EE_Read	; Read from address X
	ply
	clc
	lda I2Cword
	sta (temp1),y
	adc temp
	sta temp
	iny
	lda I2Cword+1
	sta (temp1),y
	adc temp+1
	sta temp+1
	iny
	plx
	inx
	cpx #$3f
	bne .loop
	txa
	jsr EE_Read
	lda temp
	tax
	eor I2Cword
	sta temp
	lda temp+1
	tay
	eor I2Cword+1
	ora temp
	beq .exit
	lda #$ff
.exit	rts

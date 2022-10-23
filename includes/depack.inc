* -*-asm-*-
* depacker for TP packed files
* (c) 1994 Bastian Schick
* Last change : 25.4.94
* Size : 119 Bytes
*
* Variablen (in ZP)
IF 0
org $0
byte	ds 1
count	ds 1
HelpPtr	ds 2
laenge	ds 2
offset	ds 2
run $1000
ENDIF

***************
* read TP packed file
* Size of the unpacked file is store in <laenge>
***************
ReadPackedBytes::
	jsr ReadByte	; get 1st Byte
	tax
	bne .packed	; <>0 => file packed
	ldx laenge	; else get size into Y:X
	ldy laenge+1
	jmp ReadBytes	; and read all

.packed	stz count	; clear bit counter
.loop0	asl count	; get next bit
	bne .loop1	; not last bit =>
	jsr ReadByte	; get next byte
	sta byte	; and save
	dec count	; re-init bit counter
.loop1	asl byte	; PackByte <<
	bcs .cont0	; C=1 => match
;---------------
	jsr ReadByte	; get literal byte
	sta (DestPtr)
	inc DestPtr
	bne .cont3
	inc DestPtr+1
.cont3	inc laenge
	bne .loop0
	inc laenge+1
	bne .loop0
	rts
;---------------
.cont0	jsr ReadByte	; counter and offset
	tay	; save
	REPT 4
	  lsr
	ENDR
	tax		; save
	jsr ReadByte	; offset low-Byte
	clc
	sbc DestPtr
	eor #$ff
	sta TempPtr
	txa
	sbc DestPtr+1
	eor #$ff
	sta TempPtr+1
	tya
	ldy #0
	and #$f
	inc
	inc
	tax
.loop2	lda (TempPtr),y
	sta (DestPtr)
	inc DestPtr
	bne .cont
	inc DestPtr+1
.cont	inc laenge
	bne .cont2
	inc laenge+1
	beq .ende
.cont2	iny
	dex
	bpl .loop2
	bra .loop0
.ende	rts

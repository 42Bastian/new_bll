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
* geTPackte Datei lesen
* Anzahl (ungepackt) in laenge
***************
ReadPackedBytes::
	jsr ReadByte	; 1. Byte holen
	tax
	bne .packed	; <>0 => Datei ist gepackt
	ldx laenge	; ansonsten Länge nach Y:X
	ldy laenge+1
	jmp ReadBytes	; und lesen

.packed	stz count	; Bit-Zähler löschen
.loop0	asl count	; nächstes Bit
	bne .loop1	; nicht letztes =>
	jsr ReadByte	; nächstes PackByte
	sta byte	; und merken
	dec count	; Bit-Zähler init
.loop1	asl byte	; PackByte <<
	bcs .cont0	; C=1 => Sequenz
;---------------
	jsr ReadByte	; ansonsten nächstes Byte holen
	sta (DestPtr)	; und speichern
	inc DestPtr
	bne .cont3
	inc DestPtr+1
.cont3	inc laenge
	bne .loop0
	inc laenge+1
	bne .loop0
	rts
;---------------
.cont0	jsr ReadByte	; Zähler und Offset für Sequenz
	tay	; holen,merken
	REPT 4	; und
	  lsr	; ausrichten
	ENDR
	tax
	jsr ReadByte	; low-Byte des Offsets (0..$FFF)
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

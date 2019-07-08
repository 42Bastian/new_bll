;*********************
;* Fensterfunktionen *
;*********************

;****************
;* Fenster îffnen
;****************
OpenWindow::	phx
	pha
	phy
	sta ptr
	sty ptr+1
	ldy #WCBDest
	lda (ptr),y
	iny
	ora (ptr),y
	beq .NoSave
	ply
	pla
	pha
	phy
	jsr WindSaveBack
.NoSave	sta ptr
	sty ptr+1
	lda (ptr)
	sta BorderBox
	ldy #1
	lda (ptr),y
	sta BorderBox+1
	iny
	lda (ptr),y
	sta BorderBox+2
	iny
	lda (ptr),y
	sta BorderBox+3
	iny	; WCBCol
	iny	; WCBBorder
	lda (ptr),y
	sta BorderBox+4	; Rahmenfarbe
	lda #<BorderBox
	ldy #>BorderBox
	jsr DrawBox
	bra contCLW

.NoBorder	ds 1
BorderBox	ds 5
WindBox	ds 5
;***************
;* Fenterinhalt lîschen
;***************
ClearWindow::	phx
	pha
	phy
	sta ptr
	sty ptr+1
contCLW	ldy #WCBCol
	lda (ptr),y
	sta WindBox+4	; Farbe setzen
	sta BG_Color
	iny	; WCBBorder
	iny	; WSBW
	lda (ptr),y	; Rahmen-Dicke in Pixels
	tax	; merken
	clc
	adc (ptr)	; WCBX
	sta WindBox
	ldy #WCBY
	clc
	txa
	adc (ptr),y	; WCBY
	sta WindBox+1
	iny	; WCBW
	txa
	asl	; * 2
	tax
	sec
	sbc (ptr),y	; - WCBW
	eor #$ff
	inc
	sta WindBox+2
	iny	; WCBH
	sec
	txa
	sbc (ptr),y
	eor #$ff
	inc
	sta WindBox+3
	lda #<WindBox
	ldy #>WindBox
	jsr DrawBox
	lda WindBox
	sta MinX
	sta CurrX
	clc
	adc WindBox+2
	dec
	sta MaxX
	lda WindBox+1
	sta MinY
	sta CurrY
	clc
	adc WindBox+3
	dec
	sta MaxY
	ply
	pla
	plx
	rts
;***************
;* rechteckigen Bildschirmausschnitt retten
;***************
WindSaveBack::	pha
	phx
	phy
	sta ptr
	sty ptr+1
	ldy #1
	lda (ptr),y	; y-Koordinate
	sta $fc52
	lda #80
	sta $fc54
	stz $fc55
.wait	bit $fc92
	bmi .wait
	lda (ptr)
	lsr
	php
	clc
	adc $fc60
	sta ptr2
	lda #0
	adc $fc61
	sta ptr2+1
	lda ScreenBase
	adc ptr2
	sta ptr2
	lda ScreenBase+1
	adc ptr2+1
	sta ptr2+1
	iny	; breite
	lda (ptr),y
	lsr
	adc #1
	plp
	adc #0
	sta .ByteCounter
	iny
	lda (ptr),y
	sta .LineCounter ; Hîhe in Pixeln
	ldy #WCBDest
	lda (ptr),y
	tax
	iny
	lda (ptr),y	; Zieladresse
	stx ptr
	sta ptr+1
.loop0	ldy #0
	lda .ByteCounter
	tax
	inc
.loop1	sta (ptr),y
	lda (ptr2),y
	iny
	dex
	bne .loop1	
	sta (ptr),y
	clc
	tya
	inc
	adc ptr
	sta ptr
	lda #0
	adc ptr+1
	sta ptr+1
	lda #80
	adc ptr2
	sta ptr2
	lda #0
	adc ptr2+1
	sta ptr2+1
	dec .LineCounter
	bne .loop0
	lda #0
	sta (ptr)
	ply
	plx
	pla
	rts
.ByteCounter	ds 1
.LineCounter	ds 1
;***************
;* Hintergrund zurÅck
;***************
CloseWindow
WindRestoreBack:: pha
	phx
	phy
	sta ptr
	sty ptr+1
	ldy #WCBDest
	lda (ptr),y
	sta WBSData
	iny
	lda (ptr),y
	sta WBSData+1
	ora WBSData
	beq .NoSave
	ldy #1
	lda (ptr)
	and #$fe
	sta WBSX
	lda (ptr),y
	sta WBSY
	lda #<WBS
	ldy #>WBS
	jsr DrawSprite
.NoSave	ply
	plx
	pla
	rts
	
WBS	db $c1,$90,$00
	dw 0
WBSData	dw 0
WBSX	db 0,0
WBSY	db 0,0
	dw $100
	dw $100
	db $01,$23,$45,$67
	db $89,$ab,$cd,$ef
;***************
;* DrawBox
;***************
DrawBox::	pha
	phy
	sta ptr2
	sty ptr2+1
	ldy #1
	lda (ptr2)
	sta BSX
	lda (ptr2),y
	sta BSY
	iny
	lda (ptr2),y
	sta BSXsize
	iny
	lda (ptr2),y
	sta BSYsize
	iny
	lda (ptr2),y
	and #$0f
	sta BScol
	lda #<BS
	ldy #>BS
	jsr DrawSprite
	ply
	pla
	rts
	
BS	db $c1,$90,00
	dw 0
	dw BSpixel
BSX	db 0,0
BSY	db 0,0
	db 0
BSXsize	db 0
	db 0
BSYsize	db 0
BScol	db 0
BSpixel	db 2,$10,0
;***************
;* einezelnes Sprite zeichnen

DrawSprite::	pha
	sta $fc10
	sty $fc11
	lda ScreenBase
	sta $fc08
	lda ScreenBase+1
	sta $fc09
	lda #1
	STA $FC91
	STZ $FD90
.WAIT	STZ $FD91
	BIT $FC92
	BNE .WAIT
	STZ $FD90
	pla
	rts

* -*-asm-*-
****************
PrintHex::	phx
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
digits	db "0123456789ABCDEF"
****************
* IN : A
PrintDezA::
****************
	phx
	phy
	pha
	ldy #"0"-1
.loop1	iny
	sec
	sbc #100
	bcs .loop1
	adc #100

	ldx #"0"-1
.loop2	inx
	sec
	sbc #10
	bcs .loop2
	adc #10
	clc
	adc #"0"
	pha
	tya
	jsr PrintChar
	txa
	jsr PrintChar
	pla
	jsr PrintChar
	pla
	ply
	plx
	rts

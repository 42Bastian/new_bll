; Eingabe von Texten Åber JoyPad
;
	macro WaitJoy
	ldx #12
	jsr 0
	lda $eb
	endm

;***************
;* Einzelnes Zeichen holen
;* A  letztes Zeichen 
;* X:Y = Zeiger auf WCB
;***************
;* <- = BackSpace
;* -> = OK
;* A  = Return
;* B  = ESC
;***************
GetChar::	phx
	phy
	sta .Char
	txa
	sta .MyWCB
	sty .MyWCB+1
	jsr OpenWindow
.loop	lda MinX
	sta CurrX
	lda MinY
	inc
	sta CurrY
 	lda #<.Char
	ldy #>.Char
	jsr Print	; Zeichen ausgeben
	WaitJoy
	_SWITCH
	_BCASE #JoyRight
	  lda .Char
	  bra .exit
	_BCASE #JoyLeft
	  lda #8
	  bra .exit
	_BCASE #JoyA
	  lda #13
	  bra .exit
	_BCASE #JoyB
	  lda #27
	  bra .exit
	_BCASE #JoyUp
	  lda .Char
	  tax
	  sec
	  sbc CurrFirst
	  tay
.loop1	    iny
	    inx
	    cpx CurrLast
	    bcc .cont1
	    beq .cont1
	      ldy #0
	      ldx CurrFirst
.cont1	    lda (CurrLen),y
	    cmp #2
	  bcc .loop1
	_BCASE #JoyDown
	  lda .Char
	  tax
	  sec
	  sbc CurrFirst
	  tay
.loop2	    dey
	    dex
	    cpy #$ff
	    bne .cont2
	      ldx CurrLast
	      txa
	      sec
	      sbc CurrFirst
	      tay
.cont2	    lda (CurrLen),y
	    cmp #2
	  bcc .loop2
	_ENDS
	stx .Char
	lda .MyWCB
	ldy .MyWCB+1
	jsr ClearWindow
	jmp .loop
.exit	pha
	lda .MyWCB
	ldy .MyWCB+1
	jsr CloseWindow
	pla
	ply
	plx
	rts
.MyWCB	dw 0
.Char	db 0,0
;***************

* -*-asm-*-
IFND DrawSprite
***************
* draw a single Sprite
***************
DrawSprite::
	pha
	sta SCBNEXT
	sty SCBNEXT+1
	MOVE ScreenBase,VIDBAS
	lda #1
	STA SPRGO
	STZ SDONEACK
.WAIT	STZ CPUSLEEP
	bit SPRSYS
	bne .WAIT
	STZ SDONEACK
	pla
	rts
ENDIF

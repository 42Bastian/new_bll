* Draw.inc
* draws Sprites ;)
*
* created : 19.11.95 ..
*

*****************
* IN : nix
*****************
DrawField::
	lda #8
	sta temp
	ldy #0
.loopy	  lda #16
	  sta temp+1
	  ldx #0
.loopx	    lda #LEER
	    phx
	    phy
	    jsr Sprite
	    ply
	    plx
	    inx
	    dec temp+1
	  bne .loopx
	  iny
	  dec temp
	bne .loopy
	lda #FAHNE
	ldx #15
	ldy #7
	jsr Sprite
	lda #TANK
	ldx #0
	ldy #0
;	jmp Sprite
*****************
* IN : A   - Sprite-Nummer
*      X,Y - Position
*****************
Sprite::	pha
	lda _10,x
	sta .scb_xpos
	clc
	lda _10,y
	adc #11
	sta .scb_ypos
	plx
	lda SprPtrLo,x
	sta .scb_data
	lda SprPtrHi,x
	sta .scb_data+1
	lda SprColor01,x
	sta .scb_color
	lda SprColor23,x
	sta .scb_color+1
	lda SprColor45,x
	sta .scb_color+2
	LDAY .scb
	jmp DrawSprite
*****************
* IN : A   - Sprite-Nummer
*      X,Y - Position
*****************
Sprite2	pha
	lda _10,x
	sta .scb_xpos
	stz .scb_ypos
	plx
	lda SprPtrLo,x
	sta .scb_data
	lda SprPtrHi,x
	sta .scb_data+1
	lda SprColor01,x
	sta .scb_color
	lda SprColor23,x
	sta .scb_color+1
	lda SprColor45,x
	sta .scb_color+2
	LDAY .scb
	jmp DrawSprite

.scb	dc.b $84,$90,$00
	dc.w 0
.scb_data	dc.w 0
.scb_xpos	dc.w 0
.scb_ypos	dc.w 0
	dc.w $100,$100
.scb_color	dc.b $01,$23,$45

TANK	equ 0
BOMBE	equ 1
GRAS	equ 2
LEER	equ 3
FAHNE	equ 4
DEAD	equ 5
BULLET	equ 6
CLOCK	equ 7
BOMBE2	equ 8

SprPtrLo	dc.b <Tank,<Bombe,<Gras,<Leer,<Fahne,<Dead,<Bullet,<Clock
	dc.b <Bombe
SprPtrHi	dc.b >Tank,>Bombe,>Gras,>Leer,>Fahne,>Dead,>Bullet,>Clock
	dc.b >Bombe

SprColor01	dc.b $03,$03,$03,$07,$03,$0f,$00,$00,$07
SprColor23	dc.b $17,$19,$33,$27,$81,$91,$17,$F7,$19
SprColor45	dc.b $00,$70,$00,$00,$9E,$00,$f0,$90,$70

_10	dc.b 0,10,20,30,40,50,60,70,80,90
	dc.b 100,110,120,130,140,150
	
; 3Bit and unpacked
	
	path "sprites\"
Tank	ibytes "tank.o"
Bombe	ibytes "bombe.o"
Gras	ibytes "gras.o"
Leer	ibytes "leer.o"
Fahne	ibytes "fahne.o"
Dead	ibytes "dead.o"
Bullet	ibytes "bullet.o"
Clock	ibytes "clock.o"
	path ".."


****************************************************************
* MINES : inspired by a game on the HP48
*
* created : 19.11.95
*
* last modified:
*
* 19.04.96      SCORE-bug reported by Harry
* xx.xx.96      (most of the) comments added by Harry
*
****************************************************************
* TABsize = 8

TEST            set 1

                
		include <macros/hardware.asm>
* Macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/window.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/debug.mac>
* Variablen
                include <vardefs/debug.var>
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/window.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/serial.var>
                
 BEGIN_ZP
x_pos           ds 1                            ; current tank position
y_pos           ds 1
x_pos_alt       ds 1                            ; old tank position
y_pos_alt       ds 1

cnt_bombs       ds 1                            ; number of bombs
score           ds 2                            ; points earned so far
shots           ds 1                            ; number of shots remaining
boom            ds 1                            ; number of bombs remaining
bombs_init      ds 1                            ; number of bombs at start of game (20-38)
VBLcnt          ds 1                            ; VBL counter (60 Hz) - used for seconds and Vsync
VBLcntOn        ds 1                            ; VBL count flag (0 = enabled)
minutes         ds 1
seconds         ds 1
 END_ZP


 BEGIN_MEM
screen0         ds SCREEN.LEN                   ; screen display - single buffered
irq_vektoren    ds 16                           ; IRQ vector list
bombs           ds 128                          ; array of bombs
explored        ds 128                          ; array of screen seen
 END_MEM
                MACRO _VSYNC
                lda VBLcnt
.\_01           cmp VBLcnt
                beq .\_01
                ENDM

*
* terms
* -----
* System - done once
* Game - restarts when you die
* Round - restarts when you win
*


* ************************************************************************************************
* game main routine
*

* --------------------------
* System initialization code
* --------------------------

                run LOMEM

                sei
                cld
                CLEAR_MEM
                CLEAR_ZP
                INITMIKEY
                INITSUZY
                SETRGB pal
                INITIRQ irq_vektoren
                INITFONT SMALLFNT,ROT,WEISS
                jsr InitComLynx
                jsr InitRandom
                cli
                SCRBASE screen0
                SET_MINMAX 0,0,160,102
                lda #60
                sta VBLcnt
                lda #$ff
                sta VBLcntOn                    ;counter OFF
                SETIRQ 2,VBLint

* ------------------------
* game initialization code
* ------------------------

Start::
restart VSYNC
                CLS #0
                lda #$f
                sta FG_Color

*
* display icons and static text
*
                lda #BOMBE2
                ldx #0
                jsr Sprite2
                lda #BULLET
                ldx #3
                jsr Sprite2
                lda #CLOCK
                ldx #6
                jsr Sprite2
                
                SET_XY 110-6,2
                PRINT "SCORE:",,1
                
                SET_XY 10,92
                lda #9
                sta FG_Color
                PRINT "written 11.95   42Bastian Schick",,1
                lda #15
                sta FG_Color
*
* initialize game variables
*
                stz score
                stz score+1
                lda #20
                sta bombs_init
                lda #9                                          ; 9 shots per game, not round!
                sta shots

* -------------------------
* round initialization code
* -------------------------

again
                lda #$2
                sta minutes
                stz seconds
                stz VBLcntOn                    ;counter ON
                jsr DrawField
                jsr InitArrays
                IF TEST
                  jsr ShowBombs
                ENDIF

* ----------
* round loop
* ----------

.loop           jsr CountBombs

* display game statistics
                SET_XY 12,2
                lda cnt_bombs
                clc
                adc #"0"
                jsr PrintChar                   ; display bombs remaining - should be 2 chars ***
                lda #42
                sta CurrX
                lda shots
                clc
                adc #"0"
                jsr PrintChar                   ; display shots remaining
                jsr PrintMinutes                ; display elapsed time
                jsr PrintSecondes
                jsr PrintScore                  ; display score

* get user input
                jsr Move
                beq .loop                       ; returns 0 if tank is not moved
                _VSYNC
* move tank from old spot
                ldx x_pos_alt                   ; get old x,y
                ldy y_pos_alt
                lda #GRAS                       ; get empty sprite
                jsr Sprite
* see if tank hit mine
                lda boom
                bne .exit                       ; if boom == 0 then not on mine
* put tank at new spot
                ldx x_pos                       ; get new x,y
                ldy y_pos
                lda #TANK                       ; get tank sprite
                jsr Sprite
* see if at flag
                lda x_pos                       
                cmp #15
                bne .loop
                lda y_pos
                cmp #7
                bne .loop
* at flag so we are done with this round
                dec VBLcntOn                    ; turn VBL second counter off
                jsr ShowBombs

* add remaining time to score
                clc
                sed
                lda seconds
                adc score
                sta score
                lda minutes
                adc score+1
                sta score+1
                cld
                jsr PrintScore

* wait for any button press/release
.wait           lda $fcb0
                and #3
                beq .wait
.wait2          lda $fcb0
                bne .wait2

* increase number of bombs for next round
                lda bombs_init
                cmp #38
                beq .goon
                inc
                sta bombs_init
.goon           jmp again

* hit a mine
.exit           dec VBLcntOn                    ; turn VBL second counter off
                jsr ShowBombs
                ldx x_pos
                ldy y_pos
                lda #DEAD                       ; get exploded sprite
                jsr Sprite

* wait for any button press/release
.wait0          lda $fcb0
                and #3
                beq .wait0
.wait1          lda $fcb0
                bne .wait1
                jmp restart


* ************************************************************************************************
* game subroutines
*

****************
* clear array and place bombs
****************
InitArrays::
                ldx #0
.loop0            stz bombs,x
                  inx
                bpl .loop0
                sec
                lda bombs_init
                sbc #20
                lsr
                inc
.loop01   sta bombs,x
                  inx
                bne .loop01
                
                lda bombs_init
                sta temp
.loop1          jsr Random
                and #$f                         ; x
                tax
                jsr Random
                and #$7                         ; y
                tay
                bne .ok
                txa
                beq .loop1
                
.ok             cpy #7
                bne .ok1
                cpx #15
                beq .loop1
.ok1            

                if 0
                  phx
                  phy
                  lda #BOMBE
                  jsr Sprite
                  ply
                  plx
                endif

                tya
                asl
                asl
                asl
                asl
                clc
                stx temp+1
                adc temp+1
                tax
                lda bombs,x
                bne .loop1
                inc bombs,x
                dec temp
                bne .loop1
                stz explored
                stz x_pos
                stz y_pos
                stz boom
                rts

****************
CountBombs::
                lda y_pos
                asl
                asl
                asl
                asl
                clc
                adc x_pos
                tax                                ; Ptr auf bombs[x][y]

                lda #0
                ldy x_pos
                beq .cont2
                  clc
                  adc bombs-1,x
                  ldy y_pos
                  beq .cont1
                    clc
                    adc bombs-1-16,x
.cont1            cpy #7
                  beq .cont2
                    clc
                    adc bombs-1+16,x
.cont2          ldy x_pos
                cpy #15
                beq .cont4
                  clc
                  adc bombs+1,x
                  ldy y_pos
                  beq .cont3
                    clc
                    adc bombs+1-16,x
.cont3            cpy #7
                  beq .cont4
                    clc
                    adc bombs+1+16,x
.cont4          ldy y_pos
                beq .cont5
                  clc
                  adc bombs-16,x
.cont5          cpy #7
                beq .cont6
                  clc
                  adc bombs+16,x
.cont6          sta cnt_bombs
                rts

*
* reveal location of all bombs 
*
ShowBombs::
                ldx #127
                lda #7
                sta temp

.loop0          lda #15
                sta temp+1
.loop1          lda bombs,x
                beq .cont
                  phx
                  ldx temp+1
                  ldy temp
                  lda #BOMBE
                  jsr Sprite
                  plx
.cont           dex
                dec temp+1
                bpl .loop1
                dec temp
                bpl .loop0
                rts
* -------
Move::
* -------
                lda $fcb0       ; read joypad
                beq Move        ; loop until something pressed
                sta temp        ; save value

.wait           lda $fcb0       ; read joypad
                beq .ok0        ; if all released. continue
                ora temp        ; this collects multiple buttons down
                sta temp
                bra .wait

.ok0            lda temp        ; get buttons down
                ldx x_pos       ; load position into registers
                ldy y_pos

* check up or down (takes priority over left/right if diagonal)
                bit #$c0
                beq .cont1
                bit #$80
                beq .cont
* move down - stopping at 0
                  dey
                  bpl .cont3
                  iny
                  bra .cont3
* move up - stopping at 7
.cont           iny
                cpy #8
                bne .cont3
                dey
                bra .cont3
* check right and move stopping at 0
.cont1          bit #$20
                beq .cont2
                  dex
                  bpl .cont3
                  inx
                  bra .cont3
* check left and move stopping at 15
.cont2          bit #$10
                beq .cont3
                  inx
                  cpx #16
                  bne .cont3
                  dex

* shoots to your right only
.cont3          bit #$1         ; A ?
                beq .cont30
                bit #$F0        ; moved ?
                bne .cont30
                cpx #15         ; X = max ?
                beq .cont30     ; yes => no shooting
                jsr Shoot

* check option buttons
.cont30 bit #$c                 ; OPT 1 or OPT 2
                beq .cont4
                bit #$8         ; OPT 1 ?
                beq .cont31
                lda $fcb1       ; check pause down and OPT 1 released
                lsr
                bcc .cont4
                jmp restart

.cont31 lda $fcb1
                lsr
                bcc .cont4      ; check pause down and OPT 2 released
                _VSYNC
                FLIP

* wait for all buttons released
.wait1          lda $fcb1
                and #1
                ora $fcb0
                bne .wait1

* see if tank moved
.cont4          cpx x_pos
                bne .cont5
                cpy y_pos
                bne .cont5
                lda #0
                rts

* save old position before moving
.cont5          lda x_pos
                sta x_pos_alt
                stx x_pos
                lda y_pos
                sta y_pos_alt
                sty y_pos

* see if on a bomb              
                tya
                asl
                asl
                asl
                asl
                clc
                adc x_pos
                tax
                lda bombs,x
                
                beq .ok
                dec boom        ; reduce bomb count
                lda #$ff        ; set hit bomb flag
                rts

* increase score
.ok             clc
                sed
                lda score
                adc explored,x
                sta score
                stz explored,x
                bcc .ok1
                  lda #0
                  adc score+1
                  sta score+1
.ok1            cld
                lda #$ff
                rts

Shoot::
                phx
                phy
                pha
                lda shots
                beq .exit
                
                dec shots
                
                lda y_pos
                asl
                asl
                asl
                asl
                sec
                adc x_pos       ; 16*y+x+1
                tax
                stz bombs,x     ; clear bomb whether exists or not

* something here about shooting the exit?
                lda y_pos
                cmp #7
                bne .exit
                lda x_pos
                cmp #14
                bne .exit
                dec boom
                inc x_pos
.exit           pla
                ply
                plx
                rts
                
****************
PrintMinutes::
                SET_XY 72,2
                lda minutes
                tax
                lsr
                lsr
                lsr
                lsr
                ora #"0"
                jsr PrintChar
                txa
                and #$f
                ora #"0"
                jsr PrintChar
                lda #":"
                jmp PrintChar
                
PrintSecondes::
                SET_XY 72+12,2
                lda seconds
                tax
                lsr
                lsr
                lsr
                lsr
                ora #"0"
                jsr PrintChar
                txa
                and #$f
                ora #"0"
                jmp PrintChar
                
PrintScore::
                SET_XY 110+33-6,2
                lda score+1
                stz temp
                ldx #" "
                lsr
                lsr
                lsr
                lsr
                beq .ok1
                clc
                adc #"0"
                tax
                dec temp
.ok1            txa
                jsr PrintChar
                ldx #" "
                lda score+1
                and #$f
                cmp temp
                beq .ok3
.ok2              clc
                  adc #"0"
                  tax
                  dec temp
.ok3            txa
                jsr PrintChar
                lda score
                ldx #" "
                lsr
                lsr
                lsr
                lsr
                cmp temp
                beq .ok5
.ok4            clc
                adc #"0"
                tax
.ok5            txa
                jsr PrintChar
                lda score
                and #$f
                clc
                adc #"0"
                jmp PrintChar

PrintDez::
                phx
                phy
                pha
                ldx #0
                ldy #"0"-1
                sec
.loop1          iny
                sbc #100
                bcs .loop1
                adc #100
                pha
                lda #" "
                cpy #"0"
                beq .ok
                inx
                tya
.ok             jsr PrintChar
                pla
                ldy #"0"-1
                sec
.loop2          iny
                sbc #10
                bcs .loop2
                adc #10
                pha
                tya
                cpy #"0"
                bne .ok1
                cpx #0
                bne .ok1
                lda #" "
.ok1            jsr PrintChar
                pla
                clc
                adc #"0"
                jsr PrintChar
                pla
                ply
                plx
                rts
                
                
                if 1
PrintHex::
                phx
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

digits          db "0123456789ABCDEF"
                endif

VBLint::
                lda VBLcntOn    ; <>0 => don't count
                bne .exit
                dec VBLcnt
                bne .exit
                lda #60
                sta VBLcnt
                cli
                sed
                sec
                lda seconds
                sbc #1
                sta seconds
                bcs .exit1
                lda #$59
                sta seconds
                sec
                lda minutes
                sbc #1
                sta minutes
                bcs .exit0
                stz minutes
                dec VBLcntOn
.exit0          cld
                jsr PrintMinutes
.exit1          cld
                jsr PrintSecondes
.exit           END_IRQ
                                                
                include "draw.inc"
                
* INCLUDES
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/window2.inc>
                include <includes/irq.inc>
                include <includes/font2.hlp>
                include <includes/random.inc>

* Color Palette

pal DP 000,000,600,D00,077,770,707,777,333,00F,0F0,F00,0FF,FF0,F0F,FFF


        	lynx

Baudrate        set 62500
BRKuser         set 1
DEBUG		set 1

	include <includes/hardware.inc>
* macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/suzy.mac>
                include <macros/mikey.mac>
                include <macros/font.mac>
                include <macros/irq.mac>
                include <macros/debug.mac>
* vars
                include <vardefs/debug.var>
                include <vardefs/help.var>
                include <vardefs/suzy.var>
                include <vardefs/mikey.var>
                include <vardefs/font.var>
                include <vardefs/irq.var>
                include <vardefs/serial.var>

                MACRO TOHEX
                ldx #<(\0)
                stx temp
                ldx #>(\0)
                stx temp+1
                jsr PrintHex
                ENDM

*
* local MACROs
*
                MACRO CLS
                lda \0
                jsr cls
                ENDM

max_ball        equ 3-1

 BEGIN_ZP
count           ds 2
wcount          ds 2
delay_count     ds 1
 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
coll            ds SCREEN.LEN

irq_vectors     ds 16
x_pos           ds max_ball+1
x_posfrac       ds max_ball+1
y_pos           ds max_ball+1
y_posfrac       ds max_ball+1
addx            ds max_ball+1
addxfrac        ds max_ball+1
addy            ds max_ball+1
addyfrac        ds max_ball+1
color           ds max_ball+1

 END_MEM

                RUN LOMEM
Start::
                START_UP
                CLEAR_MEM
                CLEAR_ZP
                ldx #$ff
                txs
                INITMIKEY
                INITSUZY
                FRAMERATE 60
                INITIRQ irq_vectors
                jsr InitComLynx
                INITBRK
                SCRBASE screen0,screen1
                INITFONT BIGFNT,1,15
                SET_MINMAX 0,0,160,102
xx::
                SETRGB pal
                HOME
                MOVEI coll,$fc0a
                lda #$ff
                sta $fc24
                sta $fc25       ; collide-offset = -1

                lda #2
                sta $fc92
                sta _SPRSYS

                stz count
                stz count+1
                stz wcount
                stz wcount+1

                cli

                CLS #15
                SWITCHBUF
;
; Positionen belegen
;
                ldx #max_ball
.loop_init       lda $fd02
                 adc $fd0a
                 and #$7f
                 adc #4
                 sta x_pos,x
                 lda $fd02
                 sbc $fd0a
                 and #$3f
                 adc #4
                 sta y_pos,x
                 lda $fd02
                 and #7
                 dec
                 dec
                 dec
                 cmp #$80
                 ror
                 sta addx,x
                 lda #0
                 ror
                 sta addxfrac,x
                 lda $fd02
                 and #7
                 dec
                 dec
                 dec
                 cmp #$80
                 ror
                 sta addy,x
                 lda #0
                 ror
                 sta addyfrac,x
                 lda #1
                 sta color,x
                 dex
                bpl .loop_init
;
; main-loop
;
.loop           CLS #0
                LDAY Rahmen
                jsr DrawSprite
.loop01
                ldx #max_ball
.loop0          phx

                jsr Plot
                _IFNE
                  cmp #3
                  _IFGE
                    jsr Collide
                    inc color,x

                    sed
                    lda count
                    adc #1
                    sta count
                    lda count+1
                    adc #0
                    sta count+1
                    cld
                  _ELSE
                    jsr Reflect
                    sed
                    lda wcount
                    adc #1
                    sta wcount
                    lda wcount+1
                    adc #0
                    sta wcount+1
                    cld
                  _ENDIF
                _ENDIF

.cont           plx
                dex
                bpl .loop0

                SET_XY 100,0
                lda count+1
                jsr PrintHex
                lda count
                jsr PrintHex

                SET_XY 20,0
                lda wcount+1
                jsr PrintHex
                lda wcount
                jsr PrintHex

.cont2          SWITCHBUF
                ldx #max_ball
.loop_add        clc
                 lda x_posfrac,x
                 adc addxfrac,x
                 sta x_posfrac,x
                 lda addx,x
                 adc x_pos,x
                 sta x_pos,x
                 clc
                 lda y_posfrac,x
                 adc addyfrac,x
                 sta y_posfrac,x
                 lda addy,x
                 adc y_pos,x
                 sta y_pos,x
                 dex
                bpl .loop_add
                lda $fcb0
                beq .no_flip
                 MOVEI coll,$fd94
.l lda $fcb0
cmp #1
bne .l
;>                VSYNC
;>                FLIP
.no_flip        jmp .loop
;
; Collide
;
Collide::
                lda addx,x
                eor #$ff
                tay
                lda addxfrac,x
                eor #$ff
                clc
                adc #1
                sta addxfrac,x
                tya
                adc #0
                sta addx,x
                clc
                lda addxfrac,x
                adc x_posfrac,x
                sta x_posfrac,x
                lda addx,x
                adc x_pos,x
                sta x_pos,x


                lda addy,x
                eor #$ff
                tay
                lda addyfrac,x
                eor #$ff
                clc
                adc #1
                sta addyfrac,x
                tya
                adc #0
                sta addy,x
                clc
                lda addyfrac,x
                adc y_posfrac,x
                sta y_posfrac,x
                lda addy,x
                adc y_pos,x
                sta y_pos,x
                rts


;
; Reflect at walls
;
Reflect::       dec
                bne ._y

                lda addx,x
                eor #$ff
                tay
                lda addxfrac,x
                eor #$ff
                clc
                adc #1
                sta addxfrac,x
                tya
                adc #0
                sta addx,x
                clc
                lda addxfrac,x
                adc x_posfrac,x
                sta x_posfrac,x
                lda addx,x
                adc x_pos,x
                sta x_pos,x
                rts

._y
                lda addy,x
                eor #$ff
                tay
                lda addyfrac,x
                eor #$ff
                clc
                adc #1
                sta addyfrac,x
                tya
                adc #0
                sta addy,x
                clc
                lda addyfrac,x
                adc y_posfrac,x
                sta y_posfrac,x
                lda addy,x
                adc y_pos,x
                sta y_pos,x
                rts
;
; Draw Ball
;
Plot::          clc
                lda y_pos,x
                adc #15
                sta PltSCBy
                lda x_pos,x
                sta PltSCBx
                lda color,x
                and #$F
                ora #1
                sta PltColor
                stz col
                LDAY PltSCB
                jsr DrawSprite
                lda col
                rts


col             db 0
PltSCB          db $C4,$90,$03
                dw 0,PltData
PltSCBx         dw 0
PltSCBy         dw 0
                dw $180,$180
PltColor        db $0A,$DB
PltData         db 3,$11,$10
                db 3,$11,$10
                db 3,$11,$10
                db 0
;

                db 0
Rahmen          db $c2,$90,$01  ; rechts/links
                dw rechts,data
                dw 1,15
                dw $200,$100*(101-15)
                db $0A,$E0
                db 0

rechts          db $c2,$88,$01
                dw oben,data
                dw 157,15
                db 0

oben            db $c2,$98,$02
                dw unten,data
                dw 1,15
                dw $100*158,$200
                db 0

unten           db $c2|$10,$88,$02
                dw mitte,data
                dw 1,100

mitte           dc.b $c2,$98,$01
                dc.w 0,data
                dc.w 80,30
                dc.w $100,60*$100


data            db $2,$10,0
*
*
*
cls::           sta cls_color
                LDAY clsSCB
                jmp DrawSprite

clsSCB          dc.b $c0,$90,$00
                dc.w 0,cls_data
                dc.w 0,0                        ; X,Y
                dc.w 160*$100,102*$100          ; size_x,size_y
cls_color       dc.b $00

cls_data        dc.b 2,$10,0


                include <includes/irq.inc>
                include <includes/debug.inc>
                include <includes/serial.inc>
                include <includes/hexdez.inc>
                include <includes/font.inc>
                include <includes/draw_spr.inc>
                include <includes/font2.hlp>

pal             STANDARD_PAL

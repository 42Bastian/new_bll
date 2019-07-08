***************
* RAW.ASM
* simple body of a Lynx-program
*
* created : 24.04.96
* changed : 13.07.97
****************

_1000HZ_TIMER   set 7
Baudrate        set 62500
BRKuser          set 1
DEBUG		set 1

                include <macros/hardware.asm>
*
* macros
*
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/debug.mac>
                
* variables
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/serial.var>
                include <vardefs/debug.var>

	macro	_VSYNC
	dec	VBLflag
.\_0
	bit	VBLflag
	bmi	.\_0
	endm

 BEGIN_ZP
VBLflag         ds 1
col_ptr         ds 2
LastButton      ds 1
LastCursor      ds 1
 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
irqs            ds 16
line            ds 60
 END_MEM
                run LOMEM       ; code directly after variables

Start::         START_UP             ; Start-Label needed for reStart
                CLEAR_MEM
                CLEAR_ZP

                INITMIKEY
                INITSUZY
                jsr SetMyIRQ

                SCRBASE screen0
                cli
                INITFONT SMALLFNT,0,1
                lda #$ff
                sta $fda1
                sta $fdb1
                SET_MINMAX 0,0,59,101
                SET_XY 3,10
                PRINT "Hallo",,1
restart::
.again
;>                lda #1|$20
;>                sta $fd9d
                jsr fill2a
;>                jsr fill_colors
                lda #$80
                tsb $fd09
                tsb $fd01

.w0             jsr Getkey
                beq .w0
.w1             lda $fcb0
                bne .w1

.loop

                dec VBLflag
.vblw           bit VBLflag
                bmi .vblw

;>                jsr fill2a
;>                LDAY ph
;>                jsr DrawSprite

.w3             jsr Getkey
                beq .loop
.w2             lda $fcb0
                bne .w2
;>                bra .again
        sei
        lda #$80
        trb $fd01
        trb $fd09
        INITIRQ irqs
        INITBRK
        jsr InitComLynx
        cli
.l      bra .l


****************
fill::
                ldx #8
.0              lda fill_data,x
                sta fill_col-1,x
                dex
                bne .0
                stz  fill_y
                ldy #19
.1              phy
                LDAY fillSCB
                jsr DrawSprite

                ldy fill_col+7
                ldx #7
.2                lda fill_col-1,x
                  sta fill_col,x
                  dex
                bne .2
                sty fill_col

                clc
                lda fill_y
                adc #5
                sta fill_y
                ply
                dey
                bpl .1
                rts



fillSCB         dc.b $c0,$90,$00
                dc.w 0,fill_data
fill_x          dc.w 60
fill_y          dc.w 0
                dc.w $100,$100
fill_col        dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF

fill_data       dc.b 13*5+3
                dc.b $fe
                REPT 4
                dc.b $DC,$BA,$98,$76,$54,$32,$34,$56,$78,$9a,$bc,$de,$fe
                ENDR
                dc.b 0
                dc.b 0

add     equ temp+1
fill2::
                lda #53
                sta line
                lda #$22
                sta add
                ldx #1
                ldy #51
                lda #$12
.0              sta line,x

                clc
                adc add
                beq .1
                cmp #$f0
                bne .1a
.1              pha
                lda add
                eor #$ff
                inc
                sta add
                pla
                clc
                adc add

.1a             inx
                dey
                bpl .0
                lda #0
                sta line,x
fill2a
                stz fill_y
                ldx #101
.2              LDAY fillSCB
                jsr DrawSprite
;>                lda fill_x
;>                eor #1
;>                sta fill_x
                inc fill_y
                dex
                bpl .2
                rts


fill3::           stz temp
                lda #1
                sta add
                ldy #101
.1              ldx #101
.2              lda temp
                and #$f
                bne .3
                clc
                lda add
                eor #$fe
                sta add
                adc temp
                sta temp
.3              jsr plot
                clc
                lda add
                adc temp
                sta temp
                dex
                bpl .2
                stz temp
                lda #1
                sta add
;>                clc
;>                lda add
;>                adc temp
;>                sta temp
                dey
                bpl .1
                rts

fill3a::           stz temp
                lda #1
                sta add
                ldy #101
.1              ldx #101
.2              lda temp
                and #$f
                beq .2a
                cmp #1
                bne .3
.2a                clc
                lda add
                eor #$fe
                sta add
                adc temp
                sta temp
                bra .2
.3
                jsr plot
                clc
                lda add
                adc temp
                sta temp
                dex
                bpl .2
                stz temp
                lda #1
                sta add
;>                clc
;>                lda add
;>                adc temp
;>                sta temp
                dey
                bpl .1
                rts
***************
plot::
                phy
;>                stx plotx
                sty ploty
                and #$f
                sta plotcol
                txa
                clc
                adc #60
                sta plotx
                LDAY plotSCB
                jsr DrawSprite
                ply
                rts

plotSCB         dc.b $c0,$90,$00
                dc.w 0,plotDATA
plotx           dc.w 0
ploty           dc.w 0
                dc.w $100,$100
plotcol         dc.b $10
plotDATA        dc.b 2,$10,0
****************
                align 256
                path
colors          ibytes "colors.dax"
****************
SetMyIRQ::      php
                sei
                MOVEI myIRQ,$fffe
                plp
                rts
*****************
* interrupts
                align 256
VBL::
                inc
                sta $fd80
                stz VBLflag
                pla
                rti


myIRQ::
                pha
                lda $fd81
                dec
                bne VBL



                
HBL::
                phx
                phy

                ldx $fd0a

s               set 2
s1              set $100
                rept 14

                lda colors+s1,x
                ldy colors+s1+$1000,x
                sta $fda0+s
                sty $fdb0+s

s               set s+1
s1              set s1+$100
                endr

                lda #1
                sta $fd80
                ply
                plx
                pla
                rti
*****************

if 0
**************
fill_colors::
                MOVEI colors,col_ptr
                stz temp
                stz temp+1
                ldx #15
.2                phx
                  MOVE temp,col
                  ldx #9
                  ldy #0
.3                 phx
                   ldx #9

.4                  lda col+1
                    sta (col_ptr),y
                    iny
                    dex
                   bpl .4
                   clc
                   lda #<(16*8)
                   adc col
                   sta col
                   lda #>(16*8)
                   adc col+1
                   sta col+1
                   plx
                   dex
                  bpl .3

                  lda #0
                  sta (col_ptr),y
                  iny
                  sta (col_ptr),y
                  clc
                  lda col_ptr
                  adc #102
                  sta col_ptr
                  _IFCS
                    inc col_ptr+1
                  _ENDIF
                 clc
                 lda #8
                 adc temp
                 sta temp
                 _IFCS
                  clc
                  lda temp+1
                  adc #8
                  sta temp+1
                 _ENDIF
                 plx
                 dex
                bpl .2

                stz temp
                stz temp+1
                ldx #15
.11              phx
                MOVE temp,col
                ldx #9
                ldy #0
.31              phx
                ldx #9
.41             lda col
                sta (col_ptr),y
                iny
                dex
                bpl .41

                clc
                lda #<(16*8)
                adc col
                sta col
                lda #>(16*8)
                adc col+1
                sta col+1
                plx
                dex
                bpl .31
                lda #0
                sta (col_ptr),y
                iny
                sta (col_ptr),y
                clc
                lda col_ptr
                adc #102
                sta col_ptr
                _IFCS
                inc col_ptr+1
                _ENDIF
                clc
                lda #8
                adc temp
                sta temp
                _IFCS
                  clc
                  lda temp+1
                  adc #8
                  sta temp+1
                _ENDIF
                plx
                dex
                bpl .11
                rts
**************
endif
****************
* INCLUDES

                include <includes/draw_spr.inc>
                include <includes/irq.inc>
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/font2.hlp>

;>                include "random2.inc"
*****************
Readkey::
                jsr Keyboard
                beq .99
                lda Button
                cmp #OPTION_1|PAUSE
                _IFEQ
.1                lda $fcb1
                  and #1
                  ora $fcb0
                  bne .1
                  jmp restart
                _ENDIF
                cmp #OPTION_2|PAUSE
                _IFEQ
                  _VSYNC
                  FLIP
.2                lda $fcb1
                  and #1
                  ora $fcb0
                  bne .2
                  stz Button
                  lda Cursor
                  rts
                _ENDIF
                ora Cursor
.99             rts
****************
Getkey
Keyboard::
                phx
                lda $fcb0
                pha
                and #$f0
                sta Cursor

                lda $fcb1
                and #1
                sta Button
                pla
                asl
                ora Button

                tax
                and LastButton
                sta Button
                txa
                eor #$fe
                sta LastButton

                lda Cursor
                tax
                and LastCursor
                sta Cursor
                txa
                eor #$ff
                sta LastCursor
                plx
                lda Cursor
                ora Button
                rts
****************

                path


ph              dc.b $c0,$90,0
                dc.w 0,cls_data
                dc.w 0,0,160*$100,102*$100
                dc.b 0
cls_data        dc.b 2,0
                dc.b 0

        end

ph2             dc.b $c0,$10,0
                dc.w 0,ph_data
                dc.w 0,0
ph_x            dc.w $100
ph_y            dc.w $100
                dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF

ph_data
;>                ibytes "cloud256.spr"

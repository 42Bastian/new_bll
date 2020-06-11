***************
* FEUER.ASM
* simple body of a Lynx-program
*
* created : 06.12.97
* change  :
****************

BRKuser         set 1
Baudrate        set 62500
DEBUG	set 1			; if defined BLL loader is included
_1000HZ_TIMER   set 7


	include <includes/hardware.inc>
* macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/newkey.mac>
                include <macros/debug.mac>
* variables
                include <vardefs/debug.var>
                include <vardefs/serial.var>

                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/newkey.var>
 BEGIN_ZP
ptr0            ds 2
ptr1            ds 2
ptr2            ds 2
 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
irq_vektoren    ds 16
                ALIGN 256
nexttab         ds 256

line0           ds 80
line1           ds 80
line2           ds 80
                ds 4
image           ds 80
                ds 4

LSRtab          ds 256
 END_MEM

        global nexttab
        global line0,line1,line2,image
        global ptr0,ptr1,ptr2

                run LOMEM       ; code directly after variables

Start::         START_UP             ; Start-Label needed for reStart
                CLEAR_MEM
                CLEAR_ZP

                INITMIKEY
                INITSUZY
                SETRGB pal
                INITIRQ irq_vektoren
                INITBRK
                INITKEY ,_FIREA|_FIREB          ; repeat for A & B
                INITFONT BIGFNT,0,15
                SET_MINMAX 0,0,160,102
                jsr InitComLynx
                SETIRQ 2,VBL
;>                SETIRQ 0,HBL

                lda #%11000
                sta $fd25
                lda #1
                sta $fd24
                lda #$81
                sta $fd21

                cli
                SCRBASE screen0
                stz $fc04
                stz $fc06

                jsr InitNextTab
                jsr InitLSRtab

;                jsr InitScreen

                SET_XY 20,80
                PRINT Hallo
.loop
                jsr ReadKey
                _IFNE
.0                jsr ReadKey
                  bne .0
.1                jsr ReadKey
                  beq .1
                _ENDIF

                jsr Fire
;;->                jsr FireBall
                bra .loop
Hallo: dc.b "HOT!",0
****************
FireBall::
                jsr Random
                and #$7f
                clc
                adc ScreenBase
                sta ptr1
                jsr Random
                and #$0f
                adc #$10
                adc ScreenBase+1
                sta ptr1+1
                jsr Random
                lsr
                and #1
                _IFNE
                  lda #$ff
                _ENDIF

                sta (ptr1)
                ldy #1
                sta (ptr1),y
                iny
                sta (ptr1),y
                ldy #80
                sta (ptr1),y
                iny
                sta (ptr1),y
                iny
                sta (ptr1),y
                ldy #160
                sta (ptr1),y
                iny
                sta (ptr1),y
                iny
                sta (ptr1),y
                rts
****************
Fire::
                jsr FillLine0

                clc
                lda ScreenBase
                adc #<(101*80)
                sta ptr0
                lda ScreenBase+1
                adc #>(101*80)
                sta ptr0+1

                lda #101
                sta image_y
                inc
                sta image2_y

                stz image3_y
                lda #1
                sta image4_y

                lda #82
                sta image-1
                stz image+81
                stz image+82
*
*
*
                lda #25
                sta temp

.loop

                ldy #39
                ldx #79
.0                lda (ptr0),y
                  pha
                  lsr
                  lsr
                  lsr
                  lsr
                  sta line0,x
                  pla
                  and #$f
                  sta line0+1,x
                  dex
                  dex
                  dey
                bpl .0


*
* left border
*
                clc
                lda line1
                adc line1+1
                adc line1+79
                adc line2
                adc line2+1
                adc line2+79
                tay
                lda nexttab,y
                sta image
*
* 158 pixels
*
;>s       set 1
;>                REPT 78
;>                  clc
;>                  lda line1-1+s
;>                  adc line1+s
;>                  adc line1+1+s
;>                  adc line2-1+s
;>                  adc line2+s
;>                  adc line2+1+s
;>                  tay
;>                  lda nexttab,y
;>                  sta image+s
;>s       set s+1
;>                ENDR

                ldx #78
.1                clc
                  lda line1-1,x
                  adc line1,x
                  adc line1+1,x
                  adc line2-1,x
                  adc line2,x
                  adc line2+1,x
                  tay
                  lda nexttab,y
                  sta image,x
                  dex
                bne .1
*
* right border
*

                clc
                lda line1+79
                adc line1
                adc line1+78
                adc line2+79
                adc line2
                adc line2+78
                tay
                lda nexttab,y

                sta image+79
*
* write image back
*
                LDAY image_scb
                jsr DrawSprite
                dec image_y
                dec image_y
                dec image2_y
                dec image2_y
                inc image3_y
                inc image3_y
                inc image4_y
                inc image4_y

*
* shift lines
*
s       set 0
                REPT 80
                lda line1+s
                sta line2+s
                lda line0+s
                sta line1+s
s       set s+1
                ENDR

;>                ldy #79
;>.3                lda line1,y
;>                  sta line2,y
;>                  lda line0,y
;>                  sta line1,y
;>                  dey
;>                bpl .3
*
*
*
                sec
                lda ptr0
                sbc #160
                sta ptr0
                lda ptr0+1
                sbc #0
                sta ptr0+1

                dec temp
                beq .9
                jmp .loop
.9              rts

highnibble:     dc.b 0,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0,$C0,$D0,$E0,$F0

image_scb       dc.b $c0,$90,$0
                dc.w image2_scb,image-1
image_x         dc.w 0
image_y         dc.w 0
                dc.w $80,$200
                dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF

image2_scb      dc.b $c0|$10,$88,0
                dc.w image3_scb,image-1
image2_x        dc.w 80
image2_y        dc.w 0

image3_scb      dc.b $c0|$20,$88,0
                dc.w image4_scb,image-1
                dc.w 80
image3_y        dc.w 0

image4_scb      dc.b $c0|$30,$88,0
                dc.w 0,image-1
                dc.w 160
image4_y        dc.w 0


*****************
FillLine0::
                ldx #79
                lda #$f
.0                sta line1,x
                  sta line2,x
                  dex
                bpl .0


                ldx #79
.1
;>                jsr Random
                lda $fd23
                and #2
                _IFNE
                  stz line1-1,x
                  stz line1,x
                  stz line2-1,x
                  stz line2,x
                _ENDIF
                dex
                dex
                bpl .1
;>        stz line1+80
;>        stz line1+82
;>        stz line1+83
;>        stz line1+85
;>        stz line1+84
.9                rts
*****************
* InitNextTab

                MACRO fill
                ldx #(\0)-1
                lda #(\1)<<4|(\1)
.\__0             sta nexttab+nextadr,x
                  dex
                bpl .\__0

nextadr set nextadr+\0
                ENDM
nextadr set 0
InitNextTab::
                fill 9,0
                fill 7,1
                fill 7,2
                fill 6,3
                fill 6,4
                fill 5,5        ;8,5
                fill 5,6        ;6,6
                fill 5,7
                fill 5,8
                fill 5,9
                fill 5,10
                fill 5,11
                fill 6,12
                fill 7,13
                fill 8,14
                fill 40,15
                rts

                fill 10,0
                fill 9,1
                fill 9,2
                fill 9,3
                fill 9,4
                fill 9,5        ;8,5
                fill 9,6       ;6,6
                fill 9,7
                fill 9,8
                fill 9,9
                fill 9,10
                fill 9,11
                fill 9,12       ; 6
                fill 9,13
                fill 9,14
                fill 9,15
                rts
*****************
* fill Screen
InitScreen::
                MOVEI screen0+2048,ptr1
                ldx #$1e-8
                ldy #0
.0                jsr Random
                  sta (ptr1),y
                  iny
                bne .0
                inc ptr1+1
                dex
                bpl .0
                rts
*****************
InitLSRtab::     ldx #0
                ldy #16
                lda #0
.0              sta LSRtab,x
                dey
                _IFEQ
                  ldy #16
                  inc
                _ENDIF
                inx
                bne .0
                rts

****************

VBL::           jsr Keyboard                    ; read buttons
                stz $fda0
                END_IRQ

HBL::           inc $fda0
                END_IRQ
****************
* INCLUDES
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/irq.inc>
                include <includes/font2.hlp>
                include <includes/newkey.inc>
                include <includes/hexdez.inc>
                include <includes/random2.inc>
                include <includes/draw_spr.inc>

;>pal             DP 000,040,003,005,006,007,008,009,00A,00B,00C,109,30b,60D,90E,F0F
pal             DP 000,040,003,005,006,007,008,009,00A,00B,00C,00D,10E,30D,70E,F0F

***************
* RAW.ASM
* simple body of a Lynx-program
*
* created : 24.04.96
* changed : 13.07.97
****************

_1000HZ_TIMER   set 7
Baudrate        set 62500
BRKuser         set 1
DBUFuser        set 0
DEBUG		set 1


                macro fmove
                MOVE \0,\1
                MOVE \0+2,\1+2
                endm

                macro fadd
                phx
                phy
                ldx #\1
                ldy #\0
                jsr add32
                ply
                plx
                endm

                macro fsub
                phx
                phy
                ldx #\1
                ldy #\0
                jsr sub32
                ply
                plx
                endm

                macro fneg
                phx
                phy
                IFVAR \1
                  switch "\1"
                  case "y"
                    plx
                    phx
                  ends
                else
                  ldx \0
                endif
                jsr neg32
                ply
                plx
                endm

	macro	_VSYNC
	dec	VBLflag
.\_0
	bit	VBLflag
	bmi	.\_0
	endm

                include <includes/hardware.inc>
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
 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
 END_MEM
                include <vardefs/debug.var>
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/serial.var>
                include <vardefs/1000Hz.var>


 BEGIN_ZP
VBLflag         ds 1
col_ptr         ds 2
LastButton      ds 1
LastCursor      ds 1
flag            ds 1
vblen           ds 1
****************
R0              DS 4
I0              DS 4
R               DS 4
I               DS 4
R2              ds 4
I2              ds 4
_ABBRUCH        ds 4
BETRAG          DS 4

RMAX            DS 4
IMAX            DS 4
DELTA           DS 4
ZOOM            ds 2

MAX_ITER        DS 1

LOX             ds 1
LOY             ds 1
Width           ds 1
COUNTER         ds 2
DUMMY           ds 4

ftemp           ds 8
f0              ds 4
f1              ds 4
f2              ds 4
f3              ds 4

 END_ZP

 BEGIN_MEM
irqs            ds 16
line            ds 60
 END_MEM
                run LOMEM       ; code directly after variables

Start::         START_UP             ; Start-Label needed for reStart
                CLEAR_MEM
                CLEAR_ZP

                INITMIKEY
                INITSUZY
                lda _SPRSYS
                ora #USE_AKKU
                sta _SPRSYS
                sta SPRSYS
                FRAMERATE 75

                INITIRQ irqs
                INITBRK
                jsr InitComLynx
                jsr Init1000Hz
                SETIRQ 2,VBL

                INITFONT LITTLEFNT,1,8
                MOVEI screen0,ScreenBase

                cli

;>                jsr fill2c


restart::
                jsr APFEL

.w0             jsr Getkey
                beq .w0

.w1             lda $fcb0
                bne .w1
                lda Button
                bit #OPTION_1
                _IFNE
                  lda vblen
                  eor #1
                  sta vblen
                  bra .w0
                _ENDIF
                bit #BUTTON_B
                bne restart
                bit #BUTTON_A
                beq .w0


        cli
.l      bra .l


; JOYPAD-Werte

UP              EQU $80
DOWN            EQU $40
LEFT            EQU $20
RIGHT           EQU $10
OPT1            EQU $08*2
OPT2            EQU $04*2
FIRE_B          EQU $02*2
FIRE_A          EQU $01*2

;>box             DEFLCB 102,0,58,160,1
;*******************************

R_MAX           dc.l -34728837
I_MAX           dc.l -26675773
DELTA0          dc.l 548615
ABBRUCH         dc.l 67108864

APFEL::
                MOVEB #60,MAX_ITER
                fmove R_MAX,RMAX
                fmove I_MAX,IMAX
                fmove DELTA0,DELTA
                fmove ABBRUCH,_ABBRUCH
***************
* info
                MOVEI screen1,ScreenBase
                SET_MINMAX 52*2,0,159,101
                lda #104
                sta CurrX
                stz CurrY
                PRINT {"MANDELBROT",13,"by B.Schick",13},1,0
                PRINT {"(c) 1992..98",13},1,0
                PRINT {13},1,0
                PRINT {"LENGTH = 5KB",13,"ITER = 50",13},1,0
                PRINT {"PREC = 11BIT",13,"TIME =",13},1,0
                PRINT  "X,Y  =",1,0
                MOVEI screen0,ScreenBase
                SET_MINMAX 52*2,0,159,101
                lda #104
                sta CurrX
                stz CurrY
                PRINT {"MANDELBROT",13,"by B.Schick",13},1,0
                PRINT {"(c) 1992..98",13},1,0
                PRINT {13},1,0
                PRINT {"LENGTH = 5KB",13,"ITER = 50",13},1,0
                PRINT {"PREC = 11BIT",13,"TIME =",13},1,0
                PRINT  "X,Y  =",1,0
***************
APFEL2
                SET_XY 52*2+8*4,49
                stz seconds
                stz minutes
                JSR APFEL_MAIN  ; draw
                lda minutes
                jsr PrintHex
                lda #":"
                jsr PrintChar
                lda seconds
                jsr PrintHex

                LDX #51         ; Cursor
                LDY #51         ; positionieren
                LDA #$FF        ; Flag setzen
                STA LOX
WAIT_IT0        JSR DRAW_CROSS  ; Fadenreuz zeichnen
WAIT_IT
                jsr Getkey
                BEQ WAIT_IT     ; keine Taste => warten

                JSR DRAW_CROSS  ; Fadenkreuz l”schen
                SET_XY 52*2+7*4,56
                txa
                jsr PrintDezA
                lda #","
                jsr PrintChar
                tya
                jsr PrintDezA
                lda Button
                BIT #OPTION_2   ; Option 2 ?
                BEQ NO_2        ; nein =>
                rts
                BRA WAIT_IT0    ; und wieder warten

NO_2            BIT #BUTTON_A
                _IFNE
                  JSR SET_LO
                  BRA WAIT_IT0
                _ENDIF

NO_A            BIT #BUTTON_B
                _IFNE
                  JSR COMPUTE
                  beq .exit
                  bra APFEL2
.exit           rts
                _ENDIF
                bit #OPTION_1
                _IFNE
                  jmp APFEL
                _ENDIF


NO_B            lda Cursor
                BIT LOX
                BMI MOVE_CROSS

                BIT #LEFT+UP
                BEQ *+5
                JSR SMALL_CROSS
                BIT #RIGHT+DOWN
                BEQ WAIT_IT0
                JSR WIDE_CROSS
                BRA WAIT_IT0

WIDE_CROSS::
                CPX #101
                BEQ .exit
                CPY #101
                BEQ .exit
                INX
                INY
.exit           RTS

SMALL_CROSS::
                cpx #0
                BEQ .exit
                cpy #0
                BEQ .exit
                DEX
                DEY
.exit           RTS

MOVE_CROSS
                BIT #UP
                BEQ NO_UP
                CPY #0
                BEQ NO_DOWN
                DEY
                BRA NO_DOWN
NO_UP           BIT #DOWN
                BEQ NO_DOWN
                CPY #101
                BEQ *+3
                INY
NO_DOWN         BIT #LEFT
                BEQ NO_LEFT
                CPX #0
                BEQ *+3
                DEX
                JMP WAIT_IT0
NO_LEFT         BIT #RIGHT
                BEQ NO_RIGHT    ; ??
                CPX #101
                BEQ *+3
                INX
NO_RIGHT        JMP WAIT_IT0
;***************
SET_LO
                LDA LOX         ; war schon einer gesetzt ?
                inc
                beq SET_LO2     ; MI => NEIN
                PHX
                PHY
                LDX LOX
                LDY LOY
                JSR DRAW_CROSS  ; altes l”schen
                PLY
                PLX
                LDA #$FF
                STA LOX
                RTS

SET_LO2         JSR DRAW_CROSS
                STX LOX
                CPX #101
                BEQ *+3
                INX
                STY LOY
                CPY #101
                BEQ *+3
                INY
                lda #1
                RTS
;***************
COMPUTE::
                LDA LOX
                inc
                Beq SET_LO2
                TXA
                SEC
                SBC LOX
                BNE .cont
                LDA #1
                RTS
.cont           BPL .ok
                LDA LOX
                STX LOX
                TAX
                LDA LOY
                STY LOY
                TAY
                SEC
                SBC LOY
.ok             sta Width       ; save width
                TXA             ; value left re-calc
                SEC
                SBC #101
                EOR #$FF
                INC
                sta f0
                stz f0+1
                stz f0+2
                stz f0+3
                phy

                fmove DELTA,f1
                ldx #f0
                ldy #f1
                jsr mul32
                fadd f0,RMAX

                ply
                TYA             ; value left-down re-calc
                SEC
                SBC #101
                EOR #$FF
                INC
                sta f0
                stz f0+1
                stz f0+2
                stz f0+3
                ldx #f0
                ldy #f1
                jsr mul32
                fadd f0,IMAX

                lda Width
                sta f0
                stz f0+1
                stz f0+2
                stz f0+3
                ldx #f0
                ldy #f1
                jsr mul32

                lda #102
                sta $fc56
                stz $fc57
                MOVE f0,$fc60
                MOVE f0+2,$fc62
                WAITSUZY
                fmove $fc52,DELTA

                lda DELTA
                ora DELTA+1
                ora DELTA+2
                ora DELTA+3
                RTS

;***************
APFEL_MAIN::

                fmove RMAX,R0
                LDX #101
LOOPX           fmove IMAX,I0
                  LDY #101
LOOPY               PHY
                    PHX
                    JSR ITER
                    PLX
                    PLY
                    JSR plot32

                    fadd DELTA,I0
                    DEY
                  BPL LOOPY

                  fadd DELTA,R0
                  DEX
                bpl LOOPX
                rts

ITER            LDA MAX_ITER    ; ITERATIONSTIEFE
                STA COUNTER

                fmove I0,I       ; I=I0
                fmove R0,R

LOOP_ITER
                fmove R,f0
                ldx #f0
                ldy #f0
                jsr fmul32

                fmove I,f1
                ldx #f1
                ldy #f1
                jsr fmul32

                fmove f1,f2
                fadd f0,f2
                fsub _ABBRUCH,f2
                BCC CONT_ITER
 lda COUNTER
.0 cmp #29
 _IFGE
   sec
   sbc #29
   bra .0
 _ENDIF
 tax
 lda i2c,x
                rts

i2c
;>     dc.b  1, 2, 3, 4, 5, 6, 7, 8, 9,10,11
                dc.b 11,10,9,8,7,6,5,4,3,2,1
                dc.b 12,13,14,15,16,17,18,19,20,21,22
;>                dc.b 24,25,26,27,28,29,30
                dc.b 30,29,28,27,26,25,24


CONT_ITER       fmove R,f2
                fmove I,f3
                ldx #f2
                ldy #f3
                jsr fmul32
                fadd f2,f2
                fadd I0,f2
                fmove f2,I

                fsub f1,f0
                fadd R0,f0
                fmove f0,R


                DEC COUNTER
                BEQ END_ITER
                JMP LOOP_ITER
END_ITER        LDA #0
                RTS
****************
* Draw cross   *
*****************************
DRAW_CROSS      PHA
                PHX
                PHY             ; Mittelpunktskoordinaten retten
                LDY #101
LOOPY_DC        LDA #23
                JSR plot
                DEY
                BPL LOOPY_DC
                PLY
                LDX #101
LOOPX_DC        LDA #23
                JSR plot
                DEX
                BPL LOOPX_DC
                PLX
                PLA
                RTS
****************
* PrintHex
* IN : A
PrintHex::      phx
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
****************
* PrintDezA
* IN : A
****************
PrintDezA::     phx
                phy
                pha
                ldy #-1
.loop0          sta temp
.loop1          iny
                sec
                sbc #100
                bcs .loop1
                adc #100

                ldx #-1
.loop2          inx
                sec
                sbc #10
                bcs .loop2
                adc #10
                clc
                adc #"0"
                pha
                tya
                beq .cont
                adc #"0"
                jsr PrintChar
                txa
                bra .ok
.cont           txa
                beq .cont1
.ok             adc #"0"
                jsr PrintChar
.cont1          pla
                jsr PrintChar
                pla
                ply
                plx
                rts
***************
fill2b::
                ldy #0
.1              ldx #0
                stz temp
                stz temp+1
                lda #1
                sta temp1
.2
                lda temp
.2a             clc
                adc temp1
                beq .3
                cmp #7
                _IFEQ
.3                pha
                  lda temp1
                  eor #$fe
                  sta temp1
                  dec
                  _IFEQ
                    clc
                    lda temp+1
                    adc #7
                    sta temp+1
                    cmp #21
                    _IFEQ
                      stz temp+1
                    _ENDIF
                  _ENDIF
                  pla
                  beq .2a
                _ENDIF
                sta temp
                clc
                adc temp+1

                phx
                phy
                jsr plot32
                ply
                plx
                inx
                cpx #160
                bne .2
                iny
                cpy #102
                bne .1
                rts


***************
fill2c::
                ldy #0
.1              ldx #0
                stz temp
                stz temp+1
                lda #1
                sta temp1
.2
                lda temp
.2a             clc
                adc temp1
                beq .3
                cmp #99
                _IFEQ
.3                pha
                  lda temp1
                  eor #$fe
                  sta temp1
                  dec
                  _IFEQ
                    clc
                    lda temp+1
                    adc #11
                    sta temp+1
                    cmp #22
                    _IFEQ
                      stz temp+1
                    _ENDIF
                  _ENDIF
                  pla
                  beq .2a
                _ENDIF
                sta temp
                clc
                adc temp+1

                phx
                phy
                jsr plot32
                ply
                plx
                inx
                cpx #160
                bne .2
                iny
                cpy #102
                bne .1
                rts


***************
plot::
                phx
                stx plot1x
                sty plot1y
                tax
                lda colortab2,x
                sta plot1col
                MOVEI screen1,$fc08
                MOVEI plot1SCB,$fc10
                jsr _DrawSprite
                lda colortab,x
                sta plotcol
                MOVEI screen0,$fc08
                MOVEI plot1SCB,$fc10
                plx
                bra _DrawSprite

plot1SCB        dc.b $c6,$90,$00
                dc.w 0,plotDATA
plot1x          dc.w 0
plot1y          dc.w 0
                dc.w $100,$100
plot1col        dc.b $10

plotSCB         dc.b $c0,$90,$00
                dc.w 0,plotDATA
plotx           dc.w 0
ploty           dc.w 0
                dc.w $100,$100
plotcol         dc.b $10
plotDATA        dc.b 2,$10,0

plot32
                phx
                stx plotx
                sty ploty
                tax
                lda colortab2,x
                sta plotcol
                MOVEI screen1,$fc08
                MOVEI plotSCB,$fc10
                jsr _DrawSprite
                lda colortab,x
                sta plotcol
                MOVEI screen0,$fc08
                MOVEI plotSCB,$fc10
                plx
_DrawSprite::
                lda #1
                STA $FC91
                STZ $FD90
.WAIT           STZ $FD91
                lda $fc92
                lsr
                bcs .WAIT
                STZ $FD90
                rts

colortab        dc.b 0
                dc.b 1, 2, 3, 4, 5, 6, 3, 4, 5, 6, 7
                dc.b 9,10,11,12,13,14,11,12,13,14,15
                dc.b 8
                dc.b 1,2,3,4,5,6,7
                dc.b 1,2,3,4,5,6,7
                dc.b 9,10,11,12,13,14,15


colortab2       dc.b 0                                   ; 1
                dc.b 0, 0, 0, 0, 0, 0, 3, 4, 5, 6, 7     ; 11
                dc.b 0, 0, 0, 0, 0, 0,11,12,13,14,15     ; 11
                dc.b 8                                   ; 1
                dc.b 9,10,11,12,13,14,15                 ; 7
                dc.b 8,8,8,8,8,8,8                       ; 7
                dc.b 8,8,8,8,8,8,8

                dc.b 1, 2, 3, 4, 5, 6,19,20,21,22,23
                dc.b 9,10,11,12,13,14,27,28,29,30,31
                dc.b 8,8,8,8,8,8,8,8,8,8

;>colortab        dc.b 0
;>                dc.b 1, 2, 3, 4, 5, 6,19,20,21,22,23
;>                dc.b 9,10,11,12,13,14,27,28,29,30,31
;>                dc.b 8,8,8,8,8,8,8,8,8,8

;>                dc.b 1,2,3,4,18,19,20
;>                dc.b 5,6,7,8,22,23,24
;>                dc.b 9,10,11,12,26,27,28
;>                dc.b 13,14,15,29,30,31
;>                dc.b 0,0,0,0


****************
* interrupts
VBL::
                stz VBLflag
                lda vblen
                bne .11

                lda flag
                eor #1
                sta flag
                beq .11

                MOVEI screen1,$fd94
                SETRGB pal
                END_IRQ

.11             MOVEI screen0,$fd94
                SETRGB pal2
                END_IRQ

*****************

****************
* INCLUDES
                include <includes/draw_spr.inc>
                include <includes/irq.inc>
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/font2.hlp>
                include <includes/1000Hz.inc>
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

;>                lda Cursor
;>                tax
;>                and LastCursor
;>                sta Cursor
;>                txa
;>                eor #$ff
;>                sta LastCursor
                plx
                lda Cursor
                ora Button
                rts
****************

; add32 : op1 = op1+op2
; x = op1
; y = op1
;
add32::         clc
                lda 0,x
                adc 0,y
                sta 0,x
                lda 1,x
                adc 1,y
                sta 1,x
                lda 2,x
                adc 2,y
                sta 2,x
                lda 3,x
                adc 3,y
                sta 3,x
                rts
; sub32 : op1 = op1-op2
; x = op1
; y = op2
sub32::         sec
                lda 0,x
                sbc 0,y
                sta 0,x
                lda 1,x
                sbc 0,y
                sta 1,x
                lda 2,x
                sbc 2,y
                sta 2,x
                lda 3,x
                sbc 3,y
                sta 3,x
                rts
; neg32
; op1 = -op1
; x = op1
neg32::
                ldy #0
                sec
                tya
                sbc 0,x
                sta 0,x
                tya
                sbc 1,x
                sta 1,x
                tya
                sbc 2,x
                sta 2,x
                tya
                sbc 3,x
                sta 3,x
                rts

; fmul32 : op1 = op1*op2
; x = op1
; y = op2
;
; precision : 24 bit
;
fmul32::
                lda 3,y
                eor 3,x
                pha
                lda 3,x
                _IFMI
                  fneg ,{x}
                _ENDIF
                lda 3,y
                _IFMI
                  fneg ,{y}
                _ENDIF

                MOVE {0,y},$fc52
                MOVE {0,x},$fc54
                WAITSUZY
                MOVE $fc60,ftemp
                MOVE $fc62,$fc6c                ; lx*ly

                stz $fc6e
                MOVE {2,x},$fc54
                WAITSUZY                        ; hx*ly
                MOVE {2,y},$fc52
                MOVE {0,x},$fc54
                WAITSUZY                        ; hy*lx
                MOVE $fc6c,ftemp+2
                MOVE $fc6e,$fc6c
                stz $fc6e

                MOVE {2,x},$fc54
                WAITSUZY                        ; hx*hy

                MOVE $fc6c,ftemp+4
                MOVE $fc6e,ftemp+6

                MOVE ftemp+3,{0,x}
                MOVE ftemp+5,{2,x}
                pla
                _IFMI
                  fneg ,{x}
                _ENDIF
                rts

; mul32 : op1 = op1*op2
; x = op1
; y = op2
;
;
mul32::
                lda 3,y
                eor 3,x
                pha
                lda 3,x
                _IFMI
                  fneg ,{x}
                _ENDIF
                lda 3,y
                _IFMI
                  fneg ,{y}
                _ENDIF

                MOVE {0,y},$fc52
                MOVE {0,x},$fc54
                WAITSUZY
                MOVE $fc60,ftemp
                MOVE $fc62,$fc6c                ; lx*ly

                stz $fc6e
                MOVE {2,x},$fc54
                WAITSUZY                        ; hx*ly
                MOVE {2,y},$fc52
                MOVE {0,x},$fc54
                WAITSUZY                        ; hy*lx
                MOVE $fc6c,ftemp+2

;>                MOVE $fc6e,$fc6c
;>                stz $fc6e
;>
;>                MOVE {2,x},$fc54
;>                WAITSUZY                        ; hx*hy
;>
;>                MOVE $fc6c,ftemp+4
;>                MOVE $fc6e,ftemp+6
;>
;>                MOVE ftemp+3,{0,x}
;>                MOVE ftemp+5,{2,x}
                MOVE ftemp,{0,x}
                MOVE ftemp+2,{2,x}
                pla
                _IFMI
                  fneg ,{x}
                _ENDIF
                rts

                path


cls             dc.b $c0,$90,0
                dc.w 0,cls_data
                dc.w 0,0,160*$100,102*$100
                dc.b 0
cls_data        dc.b 2,0
                dc.b 0


pal2           DP 000,020,040,060,080,0A0,0C0,0f0,fff,002,004,006,008,00a,00c,00f
pal            DP 000,020,040,060,080,0A0,0C0,0f0,fff,002,004,006,008,00a,00c,00f
;>pal            DP 000,040,080,0c0,0f0,004,008,00c,00F,400,800,c00,f00,444,888,ddd

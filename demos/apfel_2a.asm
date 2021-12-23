; Manderbrot
; created : autumn '92
; changes for the new DevKit : 11.04.94/May 2020
;
; last modified
; 25.04.96      BS              included NEWKEY
;                               still buggy (right/left)
; 04.05.96      BS              NEWKEY works,some MACROs included
;

Baudrate        set 62500
_1000HZ_TIMER   equ 7
DEBUG		set 1

                include <includes/hardware.inc>
* macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/window.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/newkey.mac>
                include <macros/debug.mac>
* variables
                include <vardefs/debug.var>
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/window.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/newkey.var>
                include <vardefs/serial.var>
                include <vardefs/1000Hz.var>



FIX_BITS        EQU 11
R_MAX           EQU -4240       ; = -2.07
I_MAX           EQU -3257       ; = -1.59
DELTA0          EQU 67          ; =  0.0327
ABBRUCH         EQU $20;00      ; =  4.0

 BEGIN_ZP

TempPtr         equ temp1

R0              DS 2
I0              DS 2
R               DS 2
I               DS 2
R2              ds 2
I2              ds 2
BETRAG          DS 2

RMAX            DS 2
IMAX            DS 2
DELTA           DS 2
ZOOM            ds 2

MAX_ITER        DS 1

PlotMODE        DS 1
PlotMode2       ds 1
LOX             ds 1
LOY             ds 1
Width           ds 1
COUNTER         ds 2
DUMMY           ds 4
 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
MandelData      ds 53*102+4     ; sprite data
irq_vectors     ds 16
 END_MEM

                run LOMEM

                CLEAR_MEM
                CLEAR_ZP
                INITMIKEY
                INITSUZY
                lda _SPRSYS
                ora #USE_AKKU|SIGNED_MATH
                sta _SPRSYS
                sta SPRSYS
                INITIRQ irq_vectors
                INITKEY ,0
                INITFONT LITTLEFNT,ROT,WEISS
                SETIRQ 2,VBL
                jsr Init1000Hz
Start::         jsr InitComLynx
                cli
                SCRBASE screen0
                CLS #SCHWARZ
                SET_MINMAX 0,0,160,102
.clr            jsr RecComLynxByte
                bcs .clr
***********************************************
                jsr InitSCB
.loop           jsr APFEL
                bra .loop

VBL::           jsr Keyboard
                END_IRQ

box             DEFLCB 102,0,58,160,1
;*******************************
APFEL::         LDA #100
                STA MAX_ITER

                MOVEI R_MAX,RMAX
                MOVEI I_MAX,IMAX
                MOVEI DELTA0,DELTA

                stz PlotMODE
                stz PlotMode2

                LDA #$FF        ; set color to grey
                LDX #$F
                SEC
LOOP0           STA $FDA0,X
                STA $FDB0,X
                SBC #$11
                DEX
                BPL LOOP0
                STZ $FDB1
                lda #$11
                sta $fdb0

                lda #1
                STA BG_Color    ; BG color for PRINT
                LDA #$F
                STA FG_Color
                CLS #1          ; clear screen to BG-Color
APFEL2          LDAY box
                jsr DrawBox
                lda #52*2
                sta MinX
                sta CurrX
                stz CurrY
                PRINT {"MANDELBROT",13,"by B.Schick",13},1,0
                PRINT {"(C) 1992/93",13},1,0
                PRINT {"DIGI-SOFT",13},1,0
                PRINT {"SIZE = 5KB",13,"ITER = 100",13},1,0
                PRINT {"FIXP = 11 bits",13,"TIME = ",13},1,0
                PRINT "X,Y  =",1,0

                SET_XY 52*2+8*4,49
                stz seconds
                stz minutes
                JSR APFEL_MAIN  ; do it
                lda minutes
                jsr PrintHex
                lda #":"
                jsr PrintChar
                lda seconds
                jsr PrintHex

                stz PlotMode2
                STZ PlotMODE
                LDX #51         ; Cursor
                LDY #51
                LDA #$FF        ; set Flag
                STA LOX
WAIT_IT0        lda #$d
                sta $fd92

                JSR DRAW_CROSS
                phx
WAIT_IT         jsr ReadKey
                BEQ WAIT_IT
                plx
                JSR DRAW_CROSS
* show X,Y
                SET_XY 52*2+7*4,56
                txa
                jsr PrintDezA
                lda #","
                jsr PrintChar
                tya
                jsr PrintDezA

                lda CurrentButton
                BIT #_OPT2      ; Option 2 ?
                BEQ NO_2        ; no =>
                JSR ROL_COLOR   ; RO-RO
                BRA WAIT_IT0    ; and wait again
NO_2            BIT #_FIREA
                BEQ NO_A
                JSR SET_LO
                BRA WAIT_IT0

NO_A            BIT #_FIREB
                BEQ NO_B
                JSR COMPUTE
                beq .exit
                bpl WAIT_IT0
                lda CurrentButton
                bit #_OPT1
                beq .ok
                stz $fd92
.ok             jmp APFEL2
.exit           rts

NO_B            lda CurrentCursor
                BIT LOX
                BMI MOVE_CROSS

                BIT #_LEFT|_UP
                BEQ *+5
                JSR SMALL_CROSS
                BIT #_RIGHT|_DOWN
                BEQ WAIT_IT0
                JSR WIDE_CROSS
                BRA WAIT_IT0

WIDE_CROSS::    CPX #101
                BEQ .exit
                CPY #101
                BEQ .exit
                INX
                INY
.exit           RTS

SMALL_CROSS::   cpx #0
                BEQ .exit
                cpy #0
                BEQ .exit
                DEX
                DEY
.exit           RTS
****************
MOVE_CROSS      BIT #_UP
                BEQ NO_UP
                CPY #0
                BEQ NO_DOWN
                DEY
                BRA NO_DOWN

NO_UP           BIT #_DOWN
                BEQ NO_DOWN
                CPY #101
                BEQ *+3
                INY
NO_DOWN         BIT #_LEFT
                BEQ NO_LEFT
                CPX #0
                BEQ .1
                DEX
.1              JMP WAIT_IT0

NO_LEFT         BIT #_RIGHT
                BEQ NO_RIGHT    ; ??
                CPX #101
                BEQ NO_RIGHT
                INX
NO_RIGHT        JMP WAIT_IT0
****************
SET_LO          LDA LOX         ; first point set ?
                inc
                beq SET_LO2     ; EQ => no
                PHX
                PHY             ; save current x,y
                LDX LOX
                LDY LOY
                JSR DRAW_CROSS  ; clear old cross
                PLY
                PLX             ; restore x,y
                LDA #$FF
                STA LOX         ; clear flag
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
                RTS
****************
COMPUTE::       LDA LOX
                inc
                Beq SET_LO2
                TXA
                SEC
                SBC LOX         ; check for square
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
.ok             sta Width       ; save width/height
                TXA             ; compute lower-left
                SEC
                SBC #101
                EOR #$FF
                INC
                STA MATHE_C
                LDA DELTA
                STA MATHE_E
                LDA DELTA+1
                STA MATHE_E+1
                WAITSUZY

                CLC
                LDA RMAX
                ADC MATHE_A
                STA RMAX
                LDA RMAX+1
                ADC MATHE_A+1
                STA RMAX+1
                TYA             ; compute lower-left
                SEC
                SBC #101
                EOR #$FF
                INC
                STA MATHE_C
                LDA DELTA
                STA MATHE_E
                LDA DELTA+1
                STA MATHE_E+1
                WAITSUZY
                CLC
                LDA IMAX
                ADC MATHE_A
                STA IMAX
                LDA IMAX+1
                ADC MATHE_A+1
                STA IMAX+1

                lda Width
                STA MATHE_C     ; new Delta
                LDA DELTA
                STA MATHE_E
                LDA DELTA+1
                STA MATHE_E+1   ; width*Delta
                WAITSUZY
                LDA #102
                STA MATHE_B
                LDA MATHE_A+3
                STA MATHE_A+3
                WAITSUZY

                LDA MATHE_D
                STA DELTA
                ORA MATHE_D+1
                BNE *+3
                RTS
                LDA MATHE_D+1
                STA DELTA+1

                stz MATHE_A
                lda #102
                sta MATHE_A+1
                stz MATHE_A+2
                lda Width
                sta MATHE_B
                stz MATHE_A+3
                WAITSUZY
                lda MATHE_D
                sta MandelSCBSizeX
                sta MandelSCBSizeY
                lda MATHE_D+1
                sta MandelSCBSizeX+1
                sta MandelSCBSizeY+1
                lda LOX
                sta MATHE_E
                stz MATHE_E+1
                WAITSUZY
                lda MATHE_A+1
                sta $FC04
                lda MATHE_A+2
                sta $fc05
                lda LOY
                sta MATHE_E
                stz MATHE_E+1
                WAITSUZY
                lda MATHE_A+1
                sta $fc06
                lda MATHE_A+2
                sta $fc07
                lda #<MandelSCB
                ldy #>MandelSCB
                jsr DrawSprite
                stz $fc04
                stz $fc06
                stz MandelSCBSizeX
                stz MandelSCBSizeY
                lda #1
                sta MandelSCBSizeX+1
                sta MandelSCBSizeY+1
                LDA #$FF
                RTS
****************
APFEL_MAIN::    dec PlotMODE    ; REPLACE-Mode
                dec PlotMode2
                MOVE RMAX,R0
                LDX #101
LOOPX             MOVE IMAX,I0
                  LDY #101
LOOPY               PHY
                    PHX
                    JSR ITER
                    PLX
                    PLY
                    JSR Plot    ; plot on screen
                    stz PlotMode2
                    jsr Plot    ; plot in sprite
                    dec PlotMode2
                    CLC
                    LDA I0
                    ADC DELTA
                    STA I0
                    LDA I0+1
                    ADC DELTA+1
                    STA I0+1
                    DEY
                  BPL LOOPY
                  CLC
                  LDA R0
                  ADC DELTA
                  STA R0
                  LDA R0+1
                  ADC DELTA+1
                  STA R0+1
                  DEX
                bpl LOOPX
                LDAY MandelSCB
                jmp DrawSprite

ITER            LDA MAX_ITER
                STA COUNTER

                MOVE I0,I       ; I = I0
                MOVE R0,R       ; R = R0

LOOP_ITER       LDA R
                STA MATHE_C
                STA MATHE_E
                LDA R+1
                STA MATHE_C+1
                STA MATHE_E+1   ; R2 =R^2
                WAITSUZY
                LDA MATHE_A+3   ; normalize
                STA DUMMY+3
                LDA MATHE_A+2
                STA DUMMY+2
                LDA MATHE_A+1
                LDY #FIX_BITS-8
LOOP1           LSR DUMMY+3
                ROR DUMMY+2
                ROR
                DEY
                BNE LOOP1
                STA R2
                STA BETRAG
                LDA DUMMY+2
                STA R2+1
                STA BETRAG+1

                LDA I
                STA MATHE_C
                STA MATHE_E
                LDA I+1
                STA MATHE_C+1
                STA MATHE_E+1   ; I2 =I^2
                WAITSUZY
                LDA MATHE_A+3   ; normalize
                STA DUMMY+3
                LDA MATHE_A+2
                STA DUMMY+2
                LDA MATHE_A+1
                LDY #FIX_BITS-8
LOOP2           LSR DUMMY+3
                ROR DUMMY+2
                ROR
                DEY
                BNE LOOP2
                CLC
                STA I2
                ADC BETRAG
                LDA DUMMY+2
                STA I2+1
                ADC BETRAG+1
                CMP #ABBRUCH    ; R^2+I^2 >=4
                BCC CONT_ITER

                LDA COUNTER
                sta MATHE_A
                stz MATHE_A+2
                lda #12
                sta MATHE_B
                stz MATHE_A+3
                WAITSUZY
                lda MATHE_R
                inc
                RTS

CONT_ITER       LDA R
                STA MATHE_C
                LDA R+1
                STA MATHE_C+1
                LDA I
                STA MATHE_E
                LDA I+1
                STA MATHE_E+1   ;start R*I
;*
                SEC
                LDA R2
                SBC I2
                TAY
                LDA R2+1
                SBC I2+1
                TAX

                CLC
                TYA
                ADC R0
                STA R
                TXA
                ADC R0+1
                STA R+1         ; R=R2-I2+R0
;*
                LDA MATHE_A+3   ; get R*I
                STA DUMMY+3
                lda MATHE_A+2
                STA DUMMY+2
                LDA MATHE_A+1

                LDY #FIX_BITS-8-1               ; normalize
LOOP3           LSR DUMMY+3
                ROR DUMMY+2
                ROR
                DEY
                BNE LOOP3
                CLC
                ADC I0
                STA I
                LDA DUMMY+2
                ADC I0+1
                STA I+1         ; I=2*R*I+I0

                DEC COUNTER
                BEQ END_ITER
                JMP LOOP_ITER
END_ITER        LDA #0
                RTS
*****************************
* draw cross at x,y
*****************************
DRAW_CROSS      PHA
                PHX
                PHY
                LDY #101
                LDA #$E
LOOPY_DC        JSR Plot
                DEY
                BPL LOOPY_DC
                PLY
                LDX #101
LOOPX_DC        JSR Plot
                DEX
                BPL LOOPX_DC
                PLX
                PLA
                RTS
*******************
* Plot X,Y,A      *
*******************
Plot::          PHA
                PHX
                PHY             ; save parameters

                PHA             ; save color
                phx             ; X

                STY $FC52
                stz $fc53
                lda ScreenBase
                ldx ScreenBase+1
                ldy #80
                bit PlotMode2
                bpl .ok
                lda #<(MandelData+1)
                ldx #>(MandelData+1)
                ldy #53
.ok             sta $fc6c
                STX $FC6D
                STZ $FC6E       ; init Accu

                STY $FC54
                STZ $FC55       ; start it
                WAITSUZY
                MOVE MATHE_AKKU,TempPtr

                pla             ; X
                lsr
                tay
                plx             ; color
                txa
                bit PlotMode2
                bmi .ok1
                lda Colors,x
.ok1            ldx #$F0
                BCS SET_IT
                LDX #$F
                ASL
                ASL
                ASL
                ASL
SET_IT          BIT PlotMODE
                BPL XOR_IT
                PHA
                TXA             ;get mask
                AND (TempPtr),y
                sta temp
                PLA
                ora temp
                STA (TempPtr),y
                PLY
                PLX
                PLA
                RTS
XOR_IT          EOR (TempPtr),y
                STA (TempPtr),y
                PLY
                PLX
                PLA
                RTS
*************
* ROL_COLOR *
*************
ROL_COLOR       PHX
                PHY
LOOP_RC0        LDY #60
LOOP_RC1        LDA $FD0A
                BNE LOOP_RC1
                DEY
                BPL LOOP_RC1
                ldy $fdbe
                LDX #11
LOOP_RC2        LDA $FDB2,X
                STA $FDB3,X
                DEX
                BPL LOOP_RC2
                lda $fdb0
                sta $fdb2
                sty $fdb0
                jsr ReadKey
                BEQ LOOP_RC0
LOOP_RC3        jsr ReadKey
                BNE LOOP_RC3
                PLY
                PLX
                RTS
****************
MandelSCB::     db $C1,$90,$00
                dw 0,MandelData
                dw 0,0
MandelSCBSizeX  dw $100
MandelSCBSizeY  dw $100
                db $10,$23,$45,$67,$89,$AB,$CD,$EF
Colors          db 1,0,2,3,4,5,6,7,8,9,10,11,12,13,14,15

InitSCB::       MOVEI MandelData,TempPtr
                ldx #101        ; 102 lines
                ldy #53
.loopx          tya
                sta (TempPtr)
                clc
                adc TempPtr
                sta TempPtr
                bcc .ok
                 inc TempPtr+1
.ok             dex
                bpl .loopx
                lda #0
                sta (TempPtr)
                rts
****************
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
* IN : A
PrintDezA::
****************
                phx
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
* Plot X,Y,A
***************
plot::          phx
                phy
                pha
                MOVE ScreenBase,MATHE_AKKU
                stz MATHE_AKKU+2
                lda #80
                sta MATHE_C
                sty MATHE_E
                stz MATHE_E+1
                WAITSUZY
                MOVE MATHE_AKKU,TempPtr
                txa
                plx             ; get color
                phx
                lsr
                tay
                bcc .ok1        ;  Pel in upper Nibble
                lda #$F0
                and (TempPtr),y
                sta temp
                txa
                ora temp
                sta (TempPtr),y
                pla
                ply
                plx
                rts
.ok1            lda #$0F
                and (TempPtr),y
                sta temp
                txa
                asl
                asl
                asl
                asl
                ora temp
                sta (TempPtr),y
                pla
                ply
                plx
                rts

* INCLUDES
                include <includes/1000Hz.inc>
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/window2.inc>
                include <includes/irq.inc>
                include <includes/font2.hlp>
                include <includes/newkey.inc>

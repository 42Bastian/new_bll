***************
* FEUER.ASM
* simple body of a Lynx-program
*
* created : 06.12.97
* change  :
****************

BRKuser         set 1
Baudrate        set 62500

_1000HZ_TIMER   set 7

                
	include <macros/hardware.asm>
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
x               ds 2
y               ds 2
route_ptr       ds 1
 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0::         ds SCREEN.LEN
screen1         ds SCREEN.LEN
irq_vektoren    ds 16
                ALIGN 256
image           ds 80
                ds 3

tab1            ds 256
tab2            ds 256

 END_MEM

        global nexttab
        global line0,line1,line2,image
        global ptr0,ptr1,ptr2

                run LOMEM       ; code directly after variables

restart
Start::         START_UP             ; Start-Label needed for reStart
                CLEAR_MEM
                CLEAR_ZP

                INITMIKEY
                INITSUZY
                INITIRQ irq_vektoren
                INITBRK
                INITFONT BIGFNT,0,15
                SET_MINMAX 0,0,160,102
                jsr InitComLynx
                SETIRQ 2,VBL
                SETIRQ 0,HBL


                cli
                SCRBASE screen0 ,screen1

                stz $fc04
                stz $fc06

                SETRGB pal

                MOVEI 80,x
                MOVEI 51,y


.00
                stz route_ptr
.0

                ldx route_ptr
                lda route_x,x
                sta temp
                sta x
                lda route_y,x
                _IFMI
                  stz route_ptr
                  bra .0
                _ENDIF
                sta temp+1
                sta y
.01
                inx
                lda route_x,x
                sta temp1
                lda route_y,x
                _IFMI
                  ldx #0
                  bra .01
                _ENDIF
                sta temp1+1
                stx route_ptr

                sec
                lda temp1
                sbc temp
                sta temp        ; delta x

                sec
                lda temp1+1
                sbc temp+1
                sta temp+1      ; delta y
.1
                VSYNC
                jsr create

                jsr Getkey
;>                beq .1
                bne .2

                lda temp
                _IFNE
                  _IFMI
                    dec x
                    inc temp
                  _ELSE
                    inc x
                    dec temp
                  _ENDIF
                _ENDIF
                lda temp+1
                _IFNE
                  _IFMI
                    dec y
                    inc temp+1
                  _ELSE
                    inc y
                    dec temp+1
                  _ENDIF
                _ENDIF

                lda temp+1
                ora temp
                bne .1
                jmp .0



.2              lda Cursor
                bit #$c0
                _IFNE
                  tax
                  _IFMI
                    dec y
                    _IFMI
                      stz y
                    _ENDIF
                  _ELSE
                    ldx #101
                    cpx y
                    _IFNE
                      inc y
                    _ENDIF
                  _ENDIF
                _ENDIF
                bit #$30
                _IFNE
                  bit #$20
                  _IFNE
                    ldx x
                    _IFNE
                      dec x
                    _ENDIF
                  _ELSE
                    ldx #159
                    cpx x
                    _IFNE
                      inc x
                    _ENDIF
                  _ENDIF
                _ENDIF

                lbra .1

route
route_x
dc.b 51,53,56,58,61,64,66,69,72,74,77,80,82,85,88,90
dc.b 95,98,101,103,106,108,111,113,116,119,121,124,126,127,128,129
dc.b 129,129,128,126,124,122,119,117,114,111,109,106,103,101,98,95
dc.b 90,87,84,82,79,77,74,71,69,66,63,61,58,55,53,50
dc.b 45,42,40,37,35,32,29,27,24,22,20,19,18,18,18,18
dc.b 22,24,27,30,32,35,37,40,43,45,48,50,53,56,59,61
dc.b 67,70,72,75,78,81,84,87,90,92,95,98,101,104,106,109
dc.b 114,117,120,122,125,128,130,133,135,138,141,143,146,148,150,151
dc.b 149,146,144,141,139,136,133,131,128,126,123,120,118,115,113,110
dc.b 105,102,99,96,94,91,88,85,83,80,77,74,72,69,66,64
dc.b 58,55,52,50,47,44,42,39,36,34,31,28,26,23,20,18
dc.b 15,14,13,13,13,14,15,18,20,23,25,28,30,33,35,38
dc.b 43,45
route_y
dc.b 8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
dc.b 7,7,7,7,7,7,7,7,8,8,8,9,12,15,17,20
dc.b 25,28,30,33,35,37,39,40,41,42,43,43,44,44,45,45
dc.b 46,46,47,47,47,47,48,48,48,48,48,48,48,48,48,48
dc.b 48,48,48,49,49,50,50,52,53,55,58,60,63,66,68,71
dc.b 76,77,79,80,81,82,83,84,84,85,86,86,87,87,88,88
dc.b 89,89,89,89,89,90,90,90,90,90,90,91,91,91,91,91
dc.b 91,91,91,91,91,91,91,91,90,90,89,87,86,83,81,78
dc.b 73,72,71,70,69,69,69,68,68,68,68,68,68,68,68,68
dc.b 68,68,67,67,67,67,67,67,67,67,67,66,66,65,65,64
dc.b 63,62,61,60,59,58,57,56,55,53,51,49,47,45,43,40
dc.b 35,32,30,27,25,22,20,17,16,15,14,13,13,12,12,11
dc.b 9,8
dc.b -1,-1

create::
;>                stz $fc04
;>                stz $fc06
                LDAY cls
                jsr DrawSprite

                LDAY titelSCB
                jsr DrawSprite

                MOVE x,maske_x
                MOVE y,maske_y
                LDAY maske_SCB
                jsr DrawSprite
                SWITCHBUF
                rts

cls             dc.b $c0,$90,$00
                dc.w $0,cls_data
                dc.w 0,0,160*$100,102*$100
                dc.b $00

cls_data        dc.b 2,1,0

maske_SCB       dc.b $46,$10,$00
                dc.w 0,maske_data
maske_x         dc.w 80
maske_y         dc.w 51
                dc.w $100,$100
                dc.b $08,$80




maske_data      ibytes "maske.spr"



titelSCB        dc.b $b0,$10,$20
                dc.w invadersSCB,titeldata
                dc.w 159,101,$100,$100
                dc.b $01,$23,$45,$67

titeldata       ibytes "spr/backgnd1.spr"

invadersSCB::   dc.b $c4,$10,$20
                dc.w 0,invaders
                dc.w 9,8
                dc.w $100,$100
                dc.b $03,$33,$33,$33,$33,$33

invaders::      ibytes "spr/invaders.spr"





****************
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
                  VSYNC
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
;>                eor #$ff
                sta LastCursor
                plx
                lda Cursor
                ora Button
                rts
****************


VBL:: stz $fda0
                END_IRQ
                
HBL::          inc $fda0
                END_IRQ
****************
* INCLUDES
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/irq.inc>
                include <includes/font2.hlp>
                include <includes/hexdez.inc>
                include <includes/random2.inc>
                include <includes/draw_spr.inc>

pal     ;   0  1   2   3   4   5   6  7    8   9   10  11 12  13  14  15
      DP 000,000,000,000,000,001,002,003, 003,001,003,005,007,009,00B,00D,


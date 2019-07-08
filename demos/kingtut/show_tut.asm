
Baudrate        set 62500       ; define baudrate for serial.inc

BRKuser         set 1           ; if defined BRK #x support is enabled


                path "e:\bll\"                  ; global path
                
                path "macros"
                isyms "hardware.sym"            ; get hardware-names
* macros
                include "help.mac"              ; helping macros
                include "if_while.mac"          ; well, guess ..
                include "mikey.mac"             ; Mikey-stuff
                include "suzy.mac"              ; Suzy-stuff

                include "font.mac"
                include "irq.mac"
                include "newkey.mac"
                include "debug.mac"
* variables
                path "..\vardefs\"
                include "debug.var"             ; NOTE ! Must be the very first !!!!
                include "help.var"              ; temp. registers
                include "mikey.var"             ; shadow-vars of Mikey
                include "suzy.var"              ; and Suzy-registers
                include "serial.var"
                include "font.var"
                include "irq.var"
                include "newkey.var"
*
* local MACROs
*
                MACRO CLS
                lda \0
                jsr cls
                ENDM

*
* vars only for this program
*

BEGIN_ZP

END_ZP

BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
irq_vektoren    ds 16
END_MEM
                run  LOMEM                      ; code directly after variables

Start::                                         ; Start-Label needed for reStart
                START_UP                        ; set's system to a known state
                CLEAR_MEM                       ; clear used memory (definded with BEGIN/END_MEM)
                CLEAR_ZP                        ; clear zero-page

                INITMIKEY
                INITSUZY

                INITIRQ irq_vektoren            ; set up interrupt-handler
                INITKEY ,_FIREA|_FIREB          ; repeat for A & B
                INITFONT SMALLFNT,RED,WHITE
                jsr InitComLynx
                INITBRK                         ; if we're using BRK #X, init handler

                SETIRQ 2,VBL                    ; set irq-vector and enable IRQ
;>                SETIRQ 0,HBL

                MOVEI StartPause,PausePtr       ; load ptrs, MOVEI is in HELP.MAC
                MOVEI EndPause,PausePtr+2
                dec PauseEnable                 ; enable Pause

                cli                             ; allow interrupts
                SCRBASE screen0                 ; set screen, single buffering
                CLS #0                          ; clear screen with color #0
                SETRGB pal                      ; set palette

                LDAY kingtutSCB
                jsr DrawSprite
.loop
                bra .loop
****************

VBL::           jsr Keyboard                    ; read buttons
                stz $fda0
                END_IRQ
                
HBL::           inc $fda0
                END_IRQ
****************
StartPause::    SET_XY 40,40
                PRINT "PAUSE",,1
                rts

EndPause::      CLS #0
                rts
****************
cls::           sta cls_color
                LDAY clsSCB
                jmp DrawSprite

clsSCB          dc.b $c0,$90,$00
                dc.w 0,cls_data
                dc.w 0,0                        ; X,Y
                dc.w 160*$100,102*$100          ; size_x,size_y
cls_color       dc.b $00

cls_data        dc.b 2,$10,0


****************
* INCLUDES
                path "..\includes\"
                include "debug.inc"
                include "serial.inc"
                include "font.inc"
                include "irq.inc"
                include "font2.hlp"
                include "newkey.inc"
                include "hexdez.inc"
                include "draw_spr.inc"

kingtutSCB      db $c1,$10,0
                dw 0
                dw kingtut
                dw 35,5
                dw $100,$100
                db $01,$23,$45,$67
                db $89,$ab,$cd,$ef

                path
pal             ibytes "kingtut.pal"
kingtut         ibytes "kingtut.pic"



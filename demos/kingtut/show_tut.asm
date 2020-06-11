Baudrate        set 62500       ; define baudrate for serial.inc
DEBUG		set 1		; if defined BLL loader is included
BRKuser         set 1           ; if defined BRK #x support is enabled

                include <includes\hardware.inc>     ; get hardware-names
* Macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/window.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/debug.mac>
                include <macros/newkey.mac>
* Variablen
                include <vardefs/debug.var>
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/window.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/serial.var>
                include <vardefs/newkey.var>

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

                include <includes\debug.inc>
                include <includes\serial.inc>
                include <includes\font.inc>
                include <includes\irq.inc>
                include <includes\font2.hlp>
                include <includes\newkey.inc>
                include <includes\hexdez.inc>
                include <includes\draw_spr.inc>

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

DOUBLEBUFFER    set 1          ; 1 = double-buffering
DEBUG	set 1			; if defined BLL loader is included
;>BRKuser         set 1         ; define if you want to use debugger

Baudrate        set 62500

		include <includes/hardware.inc>
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/font.mac>

                include <macros/debug.mac>
                include <macros/irq.mac>
;
; essential variables
;
                include <vardefs/debug.var>
                include <vardefs/irq.var>
                include <vardefs/serial.var>

                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/font.var>

;
; local MACROs
;
                MACRO CLS
                lda #\0
                jsr cls
                ENDM
;
; zero-page
;
 BEGIN_ZP
x               ds 1
y               ds 1
 END_ZP
;
; main-memory variables
;
 BEGIN_MEM
                align 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
irq_vectors     ds 16

 END_MEM
;
; code
;

                run LOMEM

Start::         START_UP
                CLEAR_MEM
                CLEAR_ZP +STACK

                INITMIKEY
                INITSUZY

                INITIRQ irq_vectors
                jsr InitComLynx

                INITFONT SMALLFNT,2,15
                SET_MINMAX 0,0,160,102

                SETIRQ 0,HBL
                SETIRQ 2,VBL

                cli             ; don`t forget this !!!!

IF DOUBLEBUFFER
                SCRBASE screen0,screen1
ELSE
                SCRBASE screen0
ENDIF

                CLS 0
IF DOUBLEBUFFER
                SWITCHBUF
                CLS 0
ENDIF

                SETRGB pal      ; set color
                lda #40
                sta x
                sta y

;
; main-loop
;
.loop
                lda x
                sta sprite_x
                lda y
                sta sprite_y

                CLS 0
                LDAY spriteSCB
                jsr DrawSprite

                SET_XY 10,10
                PRINT posTxt
                lda x
                jsr PrintHex
                lda y
                jsr PrintHex
IF DOUBLEBUFFER
                SWITCHBUF
ENDIF

.0              READKEY         ; see MIKEY.MAC
                lda Cursor
                beq .0

                bit #$c0        ; up | down
                _IFNE
                  bit #$80
                  _IFNE
                    ldx y
                    _IFNE
                      dex
                    _ENDIF
                    stx y
                  _ELSE
                    ldx y
                    cpx #101
                    _IFNE
                      inx
                    _ENDIF
                    stx y
                  _ENDIF
                _ELSE
                  bit #$20
                  _IFNE
                    ldx x
                    _IFNE
                      dex
                    _ENDIF
                    stx x
                  _ELSE
                    ldx x
                    cpx #159
                    _IFNE
                      inx
                    _ENDIF
                    stx x
                  _ENDIF
                _ENDIF

                jmp .loop

posTxt          dc.b "Position :",0


spriteSCB       dc.b $c0,$10,$00
                dc.w 0          ; no linking
                dc.w sprite_data
sprite_x        dc.w 0
sprite_y        dc.w 0
                dc.w $100
                dc.w $100
                dc.b $0F,$AC    ; we use only 3 colors !!

HBL::           dec $fdb0
                END_IRQ

VBL::           stz $fdb0
                END_IRQ

;
; clear screen
;
cls::           sta cls_color
                LDAY clsSCB
                jmp DrawSprite

clsSCB          dc.b $c0,$90,$00
                dc.w 0,cls_data
                dc.w 0,0
                dc.w 160*$100,102*$100
cls_color       dc.b 00

cls_data        dc.b 2,$10,0


                include <includes/irq.inc>
                include <includes/debug.inc>
                include <includes/serial.inc>

                include <includes/hexdez.inc>
                include <includes/font.inc>
                include <includes/draw_spr.inc>
                include <includes/font2.hlp>

pal             STANDARD_PAL

;
; 4-quadrant-sprite => action-point is in the middle
;
sprite_data     ibytes "sprite.spr"

DOUBLEBUFFER    set 1          ; 1 = double-buffering
DEBUG	set 1			; if defined BLL loader is included
Baudrate        set 62500

                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
;
; essential variables
;
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>

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

 END_MEM
;
; code
;

                run LOMEM

Start::
		START_UP
                CLEAR_MEM
                CLEAR_ZP +STACK

                INITMIKEY
                INITSUZY


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


spriteSCB       dc.b $c0,$10,$00
                dc.w 0          ; no linking
                dc.w sprite_data
sprite_x        dc.w 0
sprite_y        dc.w 0
                dc.w $100
                dc.w $100
                dc.b $0F,$AC    ; we use only 3 colors !!

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

                include <includes/draw_spr.inc>

pal             STANDARD_PAL

;
; 4-quadrant-sprite => action-point is in the middle
;

sprite_data     ibytes "sprite.spr"

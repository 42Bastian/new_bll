;>BRKuser         set 1         ; define if you want to use debugger
DEBUG	set 1			; if defined BLL loader is included

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

red_y_init      ds 1
red_inc         ds 1
red_y           ds 1
red_height      ds 1

green_y_init      ds 1
green_inc         ds 1
green_y           ds 1
green_height      ds 1

blue_y_init      ds 1
blue_inc         ds 1
blue_y           ds 1
blue_height      ds 1

red_sinus       ds 13
green_sinus     ds 13
blue_sinus      ds 13


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
;
; system-init
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

;
; set up double-buffering and clear screens
;
                SCRBASE screen0,screen1

                CLS 0
                SWITCHBUF
                CLS 0
;
; copy color-tables into zero-page
; to speed-up the HBL-routine a bit
;
                ldx #12
.0                lda _red_sinus,x
                  sta red_sinus,x
                  lda _blue_sinus,x
                  sta blue_sinus,x
                  lda _green_sinus,x
                  sta green_sinus,x
                  dex
                bpl .0
;
; init color-bar vars
;
                lda #1
                sta red_inc
                lda #10
                sta red_y_init

                lda #1
                sta green_inc
                lda #60
                sta green_y_init

                lda #$ff
                sta blue_inc
                lda #80
                sta blue_y_init
;
; more inits
;
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

                SWITCHBUF

.1
                READKEY         ; see MIKEY.MAC
                lda Cursor
                beq .1

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
;
; HBL-routine
;
; shows three color-bars
;
HBL::
                lda #0

                dec red_y
                _IFMI
                  ldx red_height
                  ora red_sinus,x
                  dec red_height
                  _IFMI
                    ldx #127
                    stx red_y
                  _ENDIF
                _ENDIF

                dec blue_y
                _IFMI
                  ldx blue_height
                  ora blue_sinus,x
                  dec blue_height
                  _IFMI
                    ldx #127
                    stx blue_y
                  _ENDIF
                _ENDIF

                sta $fdb0

                lda #0
                dec green_y
                _IFMI
                  ldx green_height
                  lda green_sinus,x
                  dec green_height
                  _IFMI
                    ldx #127
                    stx green_y
                  _ENDIF
                _ENDIF
                sta $fda0

                END_IRQ

_red_sinus::     dc.b 2,5,7,9,11,13,15,13,11,9,7,5,2
_green_sinus::   dc.b 2,5,7,9,11,13,15,13,11,9,7,5,2
_blue_sinus::    dc.b $20,$50,$70,$90,$c0,$d0,$f0,$d0,$c0,$90,$70,$50,$20

;
; VBL - routine
;
; re-inits vars for the HBL-routine
;

VBL::
                lda red_y_init
                sta red_y
                clc
                adc red_inc
                sta red_y_init
                beq .0
                cmp #102-12
                bne .1
.0                lda red_inc   ; red_inc = -red_inc
                  eor #$fe
                  sta red_inc
.1

                lda blue_y_init
                sta blue_y
                clc
                adc blue_inc
                sta blue_y_init
                beq .2
                cmp #102-12
                bne .3
.2                lda blue_inc   ; blue_inc = -blue_inc
                  eor #$fe
                  sta blue_inc
.3

                lda green_y_init
                sta green_y
                clc
                adc green_inc
                sta green_y_init
                beq .4
                cmp #102-12
                bne .5
.4                lda green_inc   ; green_inc = -green_inc
                  eor #$fe
                  sta green_inc
.5
                lda #12
                sta red_height
                sta green_height
                sta blue_height

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

;

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

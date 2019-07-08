***************
* simple body of a Lynx-program
*
* created : 24.04.96
*
****************

                
BRKuser         set 1
Baudrate        set 62500
_1000HZ_TIMER   set 7

                include <macros/hardware.asm>
*
* macros
*
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/window.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/newkey.mac>
                include <macros/debug.mac>

                MACRO SHOW
                LDAY \0
                jsr DrawSprite
                ENDM
*
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
*
* Zeropage vars
*
 BEGIN_ZP
counter         ds 1
Save1000Hz      ds 2
s               ds 1
MouseX          ds 1
MouseY          ds 1
MouseButton     ds 1
XYadder         ds 1
MouseX_alt      ds 1
MouseY_alt      ds 1

CurrentColor    ds 2
CurrentRed      ds 1
CurrentGreen    ds 1
CurrentBlue     ds 1

HBLcount     ds 1
 END_ZP
*
* main-mem vars
*
 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
irq_vektoren    ds 16
 END_MEM
*
* sprite-coordinates
ColorBarX       equ 0
ColorBarY       equ 51
RedX            equ 4
RedY            equ 90
GreenX          equ 4
GreenY          equ 94
BlueX           equ 4
BlueY           equ 98

BigSpriteX      equ 80-16
BigSpriteY      equ 52-16
BigFrameX       equ 80-16-2
BigFrameY       equ 52-16-2

SpriteX         equ 80+16+4
SpriteY         equ 52-16-1
FrameX          equ 80+16+3
FrameY          equ 52-16-2
*
* menu-coordinates
*
MenuX           equ 8
MenuY           equ 0
ClearX          equ 9
ClearY          equ 1
InvX            equ 39
InvY            equ 1
SendX           equ 57
SendY           equ 1
GetX            equ 80
GetY            equ 1

*
                ALIGN 2
                run LOMEM       ; code directly after variables
*
* System-Init
*
Start::         START_UP
                CLEAR_MEM
                CLEAR_ZP +STACK ; clear stack ($100) too

                INITMIKEY
                FRAMERATE 60
                INITSUZY
                SETRGB pal
                INITIRQ irq_vektoren
                INITBRK                         ; if we're using BRK #X, init handler
                INITKEY ,$F6          ; repeat for cursor and buttons
                INITFONT LITTLEFNT,RED,WHITE
                jsr Init1000Hz
                jsr InitComLynx
                SETIRQ 2,VBL
                lda #127
                sta $fd04
                lda #%00011110
                sta $fd05
                SETIRQ 1,KeyboardTimer
                SETIRQ 0,HBL

                cli
                SCRBASE screen0,screen1
                CLS #0
                SET_MINMAX 0,0,160,102
                lda #4
                jsr SelectColor2

                lda #80
                sta MouseX_alt
                sta MouseX
                sta pointer_x
                lda #ColorBarY+5
                sta MouseY_alt
                lda #52
                sta MouseY
                sta pointer_y
                SHOW Frame
                SHOW ColorBar
                SHOW ColorSlider
                SHOW Menu
                SHOW Pointer
                SWITCHBUF
*
* main-loop
*
.loop           jsr DoCursor
                php
                jsr GetMouseXY
                pla
                bcs .ok
                lsr
                bcc .loop

.ok             CLS #0
                jsr CheckXY
                SHOW Frame
                SHOW ColorBar
                SHOW ColorSlider
                SHOW Menu
                SHOW Pointer

                SET_XY 0,10
                lda MouseX
                jsr PrintHex
                lda MouseY
                jsr PrintHex
                lda CurrentColor
                and #$f
                tax
                lda $fda0,x
                jsr PrintHex
                lda $fdb0,x
                jsr PrintHex

                SWITCHBUF
                jmp .loop
*
* DoCursor
*
DoCursor::      stz MouseButton
                jsr ReadKey
* C = 0 => no key
                clc
                bne .00
.99             lda #1
                sta XYadder
                rts

* test fire-buttons
.00             lda CurrentButton
                beq .1
                bit #_OPT1
                beq .0

                ldx MouseX
                ldy MouseX_alt
                stx MouseX_alt
                sty MouseX
                sty pointer_x

                ldx MouseY
                ldy MouseY_alt
                stx MouseY_alt
                sty MouseY
                sty pointer_y
                sec

.0              bit #_FIREA|_FIREB
                beq .1
* save button, set C
                lsr
                sta MouseButton
                sec
* test cursor-keys
.1              lda CurrentCursor
                beq .9
* get pos. into X,Y
                ldx MouseY
                tay
* up/down ?
                bit #$C0
                beq .3          ; not u/d =>
                bit #$80
                bne .2          ;  => up
                clc
                txa
                adc XYadder
                cmp #101
                bcc .29
                lda #101
                bra .29

.2              sec
                txa
                sbc XYadder
                bpl .29          ; still >= 0 =>
                lda #0
.29             sta MouseY
                sta pointer_y
                tya
* left/right ?
.3              ldx MouseX
                bit #$30
                beq .6         ; not l/r =>
                bit #$10        ; right ?
                beq .4          ; no
                clc
                txa
                adc XYadder
                cmp #159
                bcc .5
                lda #159
                bra .5

.4              sec
                txa
                sbc XYadder
                bcs .5
                lda #0
.5              sta MouseX
                sta pointer_x
.6
* set C => something happened
.7              sec
.9              rts


*
* GetMouseXY
*
GetMouseXY::    jsr RecComLynxByte
                bcc .9
                cmp #$AA
                bne .91
.1              jsr RecComLynxByte
                bcc .1
                tax
.2              jsr RecComLynxByte
                bcc .2
                tay
.3              jsr RecComLynxByte
                bcc .3
                sta MouseButton
                stx pointer_x
                stx MouseX
                sty pointer_y
                sty MouseY
                sec
                rts
.9              clc
                rts

.91             jsr RecComLynxByte
                bcc .9
                bra .91
*
* CheckXY
*
CheckXY::       ldx #9
                ldy MouseY
.0                lda MouseX
                  cmp hi_x,x
                  bcs .1
                  cmp lo_x,x
                  bcc .1
                  tya
                  cmp hi_y,x
                  bcs .1
                  cmp lo_y,x
                  bcs do_it
.1                dex
                bpl .0
                rts

hi_y            dc.b ColorBarY+32,BigSpriteY+32,RedY+8  ,GreenY+8,BlueY+8
                dc.b ClearY+7    ,InvY+7       ,SendY+7 ,GetY+7

lo_y            dc.b ColorBarY,   BigSpriteY,   RedY    ,GreenY  ,BlueY
                dc.b ClearY      ,InvY         ,SendY   ,GetY

hi_x            dc.b ColorBarX+32,BigSpriteX+32,64      ,64      ,64
                dc.b ClearX+29   ,InvX+17      ,SendX+22,GetX+17

lo_x            dc.b ColorBarX   ,BigSpriteX   ,0       ,0       ,0
                dc.b ClearX      ,InvX         ,SendX   ,GetX


do_it::         SET_XY 0,0
                clc
                txa
                asl
                tax
                lsr
                adc #"0"
                jsr PrintChar
                lda MouseButton
                beq .9
                jmp (jmp_tab,x)
.9              rts

jmp_tab         dc.w SelectColor
                dc.w SetPixel
                dc.w ChangeRed,ChangeGreen,ChangeBlue
                dc.w Clear,Invert,SendSprite,GetSprite


*
* SelectColor
*
SelectColor::
                lda CurrentColor
                sta CurrentColor+1
                sec
                lda MouseX
                sbc #ColorBarX
                lsr
                lsr
                lsr
                sta temp
                sec
                lda MouseY
                sbc #ColorBarY
                lsr
                and #$C
                ora temp
SelectColor2    sta CurrentColor
                tax
                asl
                asl
                asl
                asl
                ora CurrentColor
                sta CurrentColor
                lda $FDA0,x
                sta CurrentGreen
                sta green_size+1
                lda $FDB0,x
                tay
                lsr
                lsr
                lsr
                lsr
                sta CurrentBlue
                sta blue_size+1
                tya
                and #$F
                sta CurrentRed
                sta red_size+1

                SET_XY 80,0
                lda CurrentColor
                jsr PrintHex
                lda CurrentRed
                jsr PrintHex
                lda CurrentGreen
                jsr PrintHex
                lda CurrentBlue
                jsr PrintHex
                rts

*
* ChangeRed/Green/Blue
*
ChangeRed::     lda MouseX
                lsr
                lsr
                sta CurrentRed
                sta red_size+1
                bra .0
ChangeGreen     lda MouseX
                lsr
                lsr
                sta CurrentGreen
                sta green_size+1
                bra .0
ChangeBlue      lda MouseX
                lsr
                lsr
                sta CurrentBlue
                sta blue_size+1

.0              lda CurrentColor
                and #$f
                tax
                lda CurrentGreen
                sta pal,x
                sta $fda0,x
                lda CurrentBlue
                asl
                asl
                asl
                asl
                ora CurrentRed
                sta pal+$10,x
                sta $fdb0,x
                rts
*
* Print A hex
*
PrintHex::      phx
                pha
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
                pla
                plx
                rts
digits          db "0123456789ABCDEF"
*
* VBL
*
VBL::           ldx #4
.1                lda pal,x
                  sta $fda0,x
                  lda pal+16,x
                  sta $fdb0,x
                  dex
                bne .1
                lda #RedY+1
                sta HBLcount
                END_IRQ
                
*
* Keyboard-Timer
*
KeyboardTimer:: cli
                jsr Keyboard
                END_IRQ
*
* HBL
*
HBL::           dec HBLcount
                bne .2
                lda #$33
                sta $fda4
                sta $fdb4
                stz $fda1
                lda #$f
                sta $fdb1

                sta $fda2
                stz $fdb2
                stz $fda3
                lda #$f0
                sta $fdb3
.2              END_IRQ
*
* INCLUDES
		include <includes/irq.inc>
		include <includes/1000Hz.inc>
		include <includes/serial.inc>
		include <includes/font.inc>
		include <includes/font2.hlp>
                include <includes/newkey.inc>
                include <includes/debug.inc>
                include <includes/window2.inc>
                align 2

*
* SetPixel
*
SetPixel::      lda MouseX
                sec
                sbc #BigSpriteX
                lsr
                tax
                lsr
                inc
                tay

                lda MouseY
                sec
                sbc #BigSpriteY
                lsr

                sta temp
                asl
                asl
                clc
                adc temp
                asl
                sta temp

                lda #>sprite
                sta temp+1

                txa
                and #1
                tax
                lda .99,x
                and (temp),y
                sta (temp),y
                lda MouseButton
                bit #2
                bne .9
                lda .99+2,x
                and CurrentColor
                ora (temp),y
                sta (temp),y
.9              rts

.99             dc.b $0F,$F0,$F0,$0F

*
* Clear
*
Clear::         ldy #15
                ldx #1
.0              lda #8
.1              stz sprite,x
                inx
                dec
                bne .1
                inx
                inx
                dey
                bpl .0
                rts
*
* Invert
*
Invert::        lda #15
                sta temp
                ldx #1
.0              ldy #8
.1              lda sprite,x
                eor #$FF
                sta sprite,x
                inx
                dey
                bne .1
                inx
                inx
                dec temp
                bpl .0
                rts
*
* GetSprite
*
GetSprite::     lda #$AB
                jsr SndComLynxByte
                bcc GetSprite
.00             jsr RecComLynxByte
                cmp #$AB
                bne .00
                lda #15
                sta temp
                ldx #1
.0              ldy #8
.1              jsr RecComLynxByte
                bcc .1
                sta sprite,x
                inx
                dey
                bne .1
                inx
                inx
                dec temp
                bpl .0
                rts

*
* SendSprite
*
SendSprite::    lda #$AC
                jsr SndComLynxByte
                bcc SendSprite

                lda #15
                sta temp
                ldx #1
.0              ldy #8
.1              lda sprite,x
                jsr SndComLynxByte
                bcc .1
                inx
                dey
                bne .1
                inx
                inx
                dec temp
                bpl .0
.2              jsr RecComLynxByte
                bcs .2
                rts


* Frame
*
Frame::         dc.b $01,$90,0
;>                dc.w frame2_scb,frame
                dc.w sprite_scb,frame
                dc.w BigFrameX,BigFrameY
                dc.w $200,$200
                dc.b $0F

frame2_scb      dc.b $01,$90,0
                dc.w sprite_scb,frame
                dc.w FrameX,FrameY
                dc.w $100,$100
                dc.b $0F

frame           dc.b  4,%11111111,%11111111,%11000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%10000000,%00000000,%01000000
                dc.b  4,%11111111,%11111111,%11000000
                dc.b 0
*
* Sprite
*
sprite_scb      dc.b $C6,$90,0
                dc.w sprite2_scb,sprite
                dc.w BigSpriteX,BigSpriteY
                dc.w $200,$200
                dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF

sprite2_scb     dc.b $C6,$90,0
                dc.w sprite3_scb,sprite
                dc.w SpriteX,SpriteY
                dc.w $100,$100
                dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF

sprite3_scb     dc.b $C6,$88,0
                dc.w sprite4_scb,sprite
                dc.w SpriteX+16,SpriteY

sprite4_scb     dc.b $C6,$88,0
                dc.w 0,sprite
                dc.w SpriteX+32,SpriteY


                ALIGN 256
sprite          dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 10,$00,$00,$00,$00,$00,$00,$00,$00,0
                dc.b 0

*
* Mouse-Pointer
*
Pointer         dc.b $04|$40,$10,$00
                dc.w 0,pointer
pointer_x       dc.w 0
pointer_y       dc.w 0
                dc.w $100,$100
                dc.b $0E,$ff

pointer         ibytes "pointer.spr"


                dc.b 2,%10000000
                dc.b 2,%11000000
                dc.b 2,%11100000
                dc.b 2,%11110000
                dc.b 3,%11111000,%00000000
                dc.b 3,%11111100,%00000000
                dc.b 3,%11111110,%00000000
                dc.b 2,%11100000
                dc.b 2,%11000000
                dc.b 2,%10000000
                dc.b 2,%00000000
                dc.b 0

*
* Color-Bar
*
ColorBar        dc.b $C0,$90,$00
                dc.w 0,color
                dc.w ColorBarX,ColorBarY
                dc.w $800,$800
                dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF

color           dc.b 4,$01,$23,0
                dc.b 4,$45,$67,0
                dc.b 4,$89,$AB,0
                dc.b 4,$CD,$EF,0
                dc.b 0

ColorSlider::   dc.b $04,$90,$00
                dc.w red_scb,color2
                dc.w 0,RedY
                dc.w $1000,$C00
                dc.b $04

red_scb         dc.b $04,$90,$00
                dc.w green_scb,color2
                dc.w RedX,RedY
red_size        dc.w $100
                dc.w $400
                dc.b $01

green_scb       dc.b $04,$90,$00
                dc.w blue_scb,color2
                dc.w GreenX,GreenY
green_size      dc.w $100
                dc.w $400
                dc.b $02

blue_scb        dc.b $04,$90,$00
                dc.w 0,color2
                dc.w BlueX,BlueY
blue_size       dc.w $100
                dc.w $400
                dc.b $03

color2          dc.b 2,%11110000
                dc.b 0






*
* Menu
*
Menu            dc.b $40,$10,0
                dc.w 0,menu
                dc.w MenuX,MenuY
                dc.w $100,$100
                dc.b $01,$F0
menu            ibytes "spriteed.spr"

*
pal             STANDARD_PAL


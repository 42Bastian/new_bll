
Baudrate        set 62500


USE_CIRCLE      equ 1

IRQ_SWITCHBUF_USR  set 1


	include <macros/hardware.asm>
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
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/window.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/newkey.var>
                include <vardefs/draw.var>
                include <vardefs/fpolygon.var>

                include <vardefs/debug.var>
                include <vardefs/serial.var>
                include <vardefs/1000Hz.var>


_1000HZ_TIMER   equ 7

max_circles     equ 14

 BEGIN_ZP
counter         ds 1
winkel          ds 1
temp3           ds 2
last_x          ds 2
last_y          ds 2
last_r          ds 2
mytemp          ds 2
mytemp1         ds 2
mytemp2         ds 2
color           ds 1
start_circle    ds 1
ax              ds 2
ay              ds 2
bx              ds 2
by              ds 2
cx              ds 2
cy              ds 2
dx              ds 2
dy              ds 2

 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
irq_vektoren    ds 16
circle_x        ds max_circles
circle_y        ds max_circles
circle_r        ds max_circles
circle_radd     ds 1
circle_color    ds max_circles
 END_MEM
;---------------
; MACROs
;---------------
                MACRO DoSWITCH
                dec SWITCHFlag
.\wait_vbl      bit SWITCHFlag
                bmi .\wait_vbl
                ENDM

                MACRO SINUS
                ldx \0
                lda SinTab.Lo,x
                sta \1
                lda SinTab.Hi,x
                sta \1+1
                ENDM

                MACRO COSINUS
                clc
                lda \0
                adc #64
                tax
                lda SinTab.Lo,x
                sta \1
                lda SinTab.Hi,x
                sta \1+1
                ENDM

                MACRO SHOW_IT
                IFVAR \1
                lda \0+2
                jsr PrintHex
                ENDIF
                lda \0+1
                jsr PrintHex
                lda \0
                jsr PrintHex
                inc CurrX
                inc CurrX
                ENDM
;---------------

                run LOMEM

Start::         sei
                CLEAR_MEM
                CLEAR_ZP
                INITMIKEY
                INITSUZY
                lda _SPRSYS
                ora #USE_AKKU|SIGNED_MATH
                sta _SPRSYS
                sta SPRSYS      ; AKKU benutzen

                ldx #$ff
                txs 

                SETRGB pal
                FRAMERATE 60
                INITIRQ irq_vektoren
                INITKEY
                INITFONT LITTLEFNT,ROT,WEISS
                jsr Init1000Hz
                SETIRQ 2,MyVBL
;               SETIRQ 0,MyHBL
                jsr InitComLynx
                cli
                SCRBASE screen0,screen1
                CLS #0
                DoSWITCH
                CLS #0
                SET_MINMAX 0,0,160,102
****************
if 0
                ldx #7
                lda #$f
.loop_color       stz $fda0,x
                  sta $fdb0,x
                  sec
                  sbc #$2
                  dex
                bpl .loop_color
                ldx #7
                lda #$f0
.loop_color1      stz $fda8,x
                  sta $fdb8,x
                  sec
                  sbc #$20
                  dex
                bpl .loop_color1

endif

                stz winkel
                ldx #max_circles-1
.init             txa
                  asl
                  sta temp
                  asl
                  adc temp
                  jsr NewCircle
                  MOVEB #1,{circle_radd,x}
                  dex
                bpl .init

                stz start_circle
                stz _1000Hz
main::          ldx #max_circles-1
.loop0            clc
                  lda circle_r,x
                  adc circle_radd
                  sta circle_r,x
                  _IFGE ,#max_circles*6+1
                    lda #0
                    jsr NewCircle
                  _ENDIF
                  dex
                bpl .loop0
                CLS #0

                ldx start_circle
                stz last_x+1
                stz last_y+1
                stz last_r+1
                MOVEB {circle_x,x},last_x
                MOVEB {circle_y,x},last_y
                MOVEB {circle_r,x},last_r

.loop1          cpx #max_circles
                bge .end1
                  phx
                  lda circle_color,x
;                 jsr box3
                  jsr kreis
                  plx
                  inx
                bra .loop1
.end1           ldx #0
.loop2          cpx start_circle
                bge .end2
                  phx
                  lda circle_color,x
;                 jsr box3
                  jsr kreis
                  plx
                  inx
                bra .loop2
.end2           LDAY cir_maske
                jsr DrawSprite
                stz CurrX
                stz CurrY
                lda _1000Hz
                jsr PrintHex
                DoSWITCH
                stz _1000Hz
;               READBUTTON
                jsr ReadKey
                beq .cont
                lda CurrentButton
                bit #_OPT1|_OPT2
                beq .cont
                bit #_OPT1
                beq .faster
                inc circle_radd
                bra .cont
.faster         bit #_OPT2
                beq .cont
                lda circle_radd
                dec
                bmi .cont
                sta circle_radd
.cont           jmp main



NewCircle::     sta circle_r,x
;               MOVEB #2,{circle_radd,x}
                phx
                SINUS winkel,MATHE_C
                MOVEI 30,MATHE_E
                WAITSUZY
                plx
                clc
                lda #80
;               adc MATHE_A+1
                sta circle_x,x
                phx
                COSINUS winkel,MATHE_C
                MOVEI 30,MATHE_E
                WAITSUZY
                plx
                clc
                lda MATHE_A+1
                adc #50
                sta circle_y,x
                lda color
                eor #$A
                sta color
                sta circle_color,x
                clc
                lda winkel
                adc #14
                sta winkel
                stx start_circle
                rts

cir_maske::     dc.b $c0,$90,$00
                dc.w maske1,maske_data
                dc.w 0,0,160*$100,11*$100
                dc.b $f
maske1          dc.b $c0,$88,$00
                dc.w maske2,maske_data
                dc.w 0,91
maske2          dc.b $c0,$98,$00
                dc.w maske3,maske_data
                dc.w 0,11,40*$100,80*$100
maske3          dc.b $c0,$88,$00
                dc.w 0,maske_data
                dc.w 120,11
maske_data      dc.b 2,$10,0

kreis::         tay
                stz x1+1
                stz y1+1
                MOVEB {circle_x,x},x1
                MOVEB {circle_y,x},y1
                lda circle_r,x
                tax
                tya 
                jmp circle


box::
;>  MOVEB color,poly_color
                stz temp+1
                stz temp1+1
                MOVEB {circle_x,x},temp
                MOVEB {circle_y,x},temp1
                stz temp2+1
                MOVEB {circle_r,x},temp2

                SUBWABC temp2,temp,x1           ; x-r
                SUBWABC temp2,temp1,y1          ; y-r
                MOVE x1,x2                      ; x-r
                ADDWABC temp2,temp1,y2          ; y+r
                jsr DrawLine
                SUBWABC temp2,temp,x1           ; x-r
                ADDWABC temp2,temp1,y1          ; y+r
                ADDWABC temp2,temp,x2           ; x+r
                MOVE y1,y2                      ; y+r
                lda color
                jsr DrawLine
                ADDWABC temp2,temp,x1           ; x+r
                ADDWABC temp2,temp1,y1          ; y+r
                MOVE x1,x2                      ; x+r
                SUBWABC temp2,temp1,y2          ; y-r
                jsr DrawLine
                ADDWABC temp2,temp,x1
                SUBWABC temp2,temp1,y1
                SUBWABC temp2,temp,x2
                MOVE y1,y2
                jmp DrawLine

box2::          lda circle_color,x
                pha

                stz mytemp+1
                stz mytemp1+1
                MOVEB {circle_x,x},mytemp
                MOVEB {circle_y,x},mytemp1
                stz mytemp2+1
                MOVEB {circle_r,x},mytemp2
                phx

                SUBWABC mytemp2,mytemp,ax       ; x-r
                ADDWABC mytemp2,mytemp1,ay      ; y+r
                SUBWABC last_r,last_x,bx
                ADDWABC last_r,last_y,by
                ADDWABC mytemp2,mytemp,cx       ; x+r
                ADDWABC mytemp2,mytemp1,cy      ; y+r
                ADDWABC last_r,last_x,dx
                ADDWABC last_r,last_y,dy
                MOVE ax,x1
                MOVE ay,y1
                MOVE bx,x2
                MOVE by,y2
                MOVE cx,x3
                MOVE cy,y3
                pla
                pha
                jsr triangle
                MOVE bx,x1
                MOVE by,y1
                MOVE cx,x2
                MOVE cy,y2
                MOVE dx,x3
                MOVE dy,y3
                pla
                jsr triangle                     ; Boden
                plx
                lda circle_color,x
                eor #2
                pha             ; save color
                ldx #7
.loop1            lda ax,x
                  sta x1,x
                  dex
                bpl .loop1                      ; x-r,y+r
                sec
                lda mytemp
                sbc mytemp2
                sta x3
                sta ax
                lda mytemp+1
                sbc mytemp2+1
                sta x3+1
                sta ax+1
                sec
                lda mytemp1
                sbc mytemp2
                sta y3
                sta ay
                lda mytemp1+1
                sbc mytemp2+1
                sta y3+1
                sta ay+1
                pla             ; color
                pha
                jsr triangle
                ldx #7
.loop2            lda ax,x
                  sta x1,x
                  dex
                bpl .loop2
                SUBWABC last_r,last_x,x3
                SUBWABC last_r,last_y,y3
                pla
                pha
                jsr triangle
                ldx #7
.loop3            lda cx,x
                  sta x1,x
                  dex
                bpl .loop3                      ; x-r,y+r
                clc
                lda mytemp
                adc mytemp2
                sta x3
                sta cx
                lda mytemp+1
                adc mytemp2+1
                sta x3+1
                sta cx+1
                sec
                lda mytemp1
                sbc mytemp2
                sta y3
                sta cy
                lda mytemp1+1
                sbc mytemp2+1
                sta y3+1
                sta cy+1
                pla
                pha
                jsr triangle
                ldx #7
.loop4            lda cx,x
                  sta x1,x
                  dex
                bpl .loop4
                ADDWABC last_r,last_x,x3
                SUBWABC last_r,last_y,y3
                pla
                jsr triangle
                
                MOVE mytemp,last_x
                MOVE mytemp1,last_y
                MOVE mytemp2,last_r
                rts

box3::          lda circle_color,x
                pha

                stz temp+1
                stz temp1+1
                MOVEB {circle_x,x},temp
                MOVEB {circle_y,x},temp1
                stz temp2+1
                MOVEB {circle_r,x},temp2

                SUBWABC temp2,temp,x1           ; x-r
                SUBWABC temp2,temp1,y1          ; y-r
                SUBWABC last_r,last_x,x2
                SUBWABC last_r,last_y,y2
                pla
                pha
                jsr DrawLine

                SUBWABC temp2,temp,x1           ; x-r
                ADDWABC temp2,temp1,y1          ; y+r
                SUBWABC last_r,last_x,x2
                ADDWABC last_r,last_y,y2
                ldx #7
.loop1            lda x1,x
                  sta ax,x
                  dex
                bpl .loop1
                pla
                pha
                jsr DrawLine
                ADDWABC temp2,temp,x1           ; x+r
                ADDWABC temp2,temp1,y1          ; y+r
                ADDWABC last_r,last_x,x2
                ADDWABC last_r,last_y,y2
                ldx #7
.loop2            lda x1,x
                  sta cx,x
                  dex
                bpl .loop2
                pla
                pha
                jsr DrawLine
                ADDWABC temp2,temp,x1           ; x+r
                SUBWABC temp2,temp1,y1          ; y-r
                ADDWABC last_r,last_x,x2
                SUBWABC last_r,last_y,y2
                pla
                pha
                jsr DrawLine
                MOVE temp,last_x
                MOVE temp1,last_y
                MOVE temp2,last_r

                MOVE ax,x1
                MOVE ay,y1
                MOVE bx,x2
                MOVE by,y2
                MOVE cx,x3
                MOVE cy,y3
                pla
                pha
                jsr triangle
                MOVE bx,x1
                MOVE by,y1
                MOVE cx,x2
                MOVE cy,y2
                MOVE dx,x3
                MOVE dy,y3
                pla
                jsr triangle
                MOVE ax,x1
                MOVE ay,y1
                MOVE bx,x2
                MOVE by,y2
                rts


****************
rotate::        SINUS winkel,temp1              ; temp1 = sin
                COSINUS winkel,temp2            ; temp2 = cos
                sec
                lda #0
                sbc temp2
                sta temp3
                lda #0
                sbc temp2+1
                sta temp3+1                     ; temp3 = -cos
                ldx #0
                ldy #3
.loop             stz MATHE_AKKU
                  stz MATHE_AKKU+2
                  MOVE {ax,x},MATHE_C
                  MOVE temp1,MATHE_E
                  WAITSUZY
                  MOVE {ay,x},MATHE_C
                  MOVE temp2,MATHE_E
                  WAITSUZY
                  MOVE MATHE_AKKU+1,temp        ; temp = x*sin+y*cos
bit MATHE_AKKU
bpl .cont
inc temp
bne .cont
inc temp+1
.cont             stz MATHE_AKKU
                  stz MATHE_AKKU+2
                  MOVE {ax,x},MATHE_C
                  MOVE temp3,MATHE_E
                  WAITSUZY
                  MOVE {ay,x},MATHE_C
                  MOVE temp1,MATHE_E
                  WAITSUZY
                  MOVE temp,{ax,x}
                  MOVE MATHE_AKKU+1,temp
bit MATHE_AKKU
bpl .cont1
inc temp
bne .cont1
inc temp+1
.cont1            MOVE temp,{ay,x}              ; ay = -x*cos+y*sin

                  REPT 4
                    inx
                  ENDR
                  dey
                  bmi .exit
                jmp .loop
.exit           rts

************************************
MyVBL::         jsr Keyboard
                IRQ_SWITCHBUF
                END_IRQ
                

MyHBL           inc $fda0
                END_IRQ
****************
* Sinus-Tabelle
* 8Bit Nachkomma
****************
                align 2
SinTab.Lo       ibytes <bin/sintab_8.o>
SinTab.Hi       equ SinTab.Lo+256
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
* INCLUDES
                include <includes/1000Hz.inc>
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/window2.inc>
                include <includes/irq.inc>
                include <includes/draw.inc>
                include <includes/fpolygon.inc>
                include <includes/newkey.inc>
                include <includes/font2.hlp>

pal             STANDARD_PAL

proj_x          dc.w 50,75,50,30
proj_y          dc.w 30,50,70,50
faces           dc.b 0,1,2,3,-1
                dc.b -1

end

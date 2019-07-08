



		include <macros/hardware.asm>

                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font2.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>

                include <vardefs/font2.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
 END_MEM
                run LOMEM
                INITMIKEY
                INITSUZY
                SETRGB pal
                cli
                SCRBASE screen0
                lda #0
                jsr cls
                PRINT test
                INC_CURRY 4*13
                PRINT test2
.l              inc $fdaf
                bra .l

cls::           pha
                phx
                phy
                stz $fc04
                stz $fc06
                sta .CLScolor
                lda #<.CLSscb
                ldy #>.CLSscb
                jsr DrawSprite
                SET_XY 0,0      ; set cursor
                ply
                plx
                pla
                rts

.CLSscb         db $00,$10,00
                dw 0
                dw .CLSdata
                dw 0,0
                dw 10*$100,102*$100
.CLScolor       db $0F
.CLSdata        db 2,%01111100,0



test DEFTEXT text,textpuff,SMALLFNT2,NO_FLIP,NORMAL_SIZE,NORMAL_SIZE,15
text            db "ABCDEFGHIJKLMNOPQRSTUVWXYZéôö",255
                db "abcdefghijklmnopqrstuvwxyzÑîÅ",255
                db "1234567890!",34,"$%&/()=",255
                db "?'`#^[]{}~|_-:.;,<>",255
                db "Bastian Schick",255
                db "Brunnengasse 7 6*4+(19-4/2)=4x",0
                

test2 DEFTEXT text2,textpuff,SMALLFNT2,NO_FLIP,NORMAL_SIZE,NORMAL_SIZE,14
text2           db "Chaneil an t-adhar os cion",13
                db "Lunnainn a nochd soilleir no dorch",13
                db "(c) Runrig / The Big Wheel",0

;win1 DEFWCB 2,2,157,99,0,9,2

                include <includes/font2.inc>
                include <includes/font2.hlp>
                include <includes/draw_spr.inc>

pal             STANDARD_PAL    
textpuff        equ *

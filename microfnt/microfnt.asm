
; micro-font
;
; width is only _one_ byte = 2 pixel = 2 triads = 6 color-pixels
;

useSuzy         set 0

                include <macros/help.mac>

ptr             equ $fc
ptr1            equ $fe

                run $f880-32

;                      GBR
;                  000 100 010 110 001 101 011 111
fontPAL::       DP 000,00F,F00,F0F,0F0,0FF,FF0,FFF,000,000,000,000,000,000,000,000

MFNT_screenbase:: dc.w 0
MFNT_char_x::   dc.b 0
MFNT_char_y::   dc.b 0

_000            equ 0
_100            equ 1
_010            equ 2
_110            equ 3
_001            equ 4
_101            equ 5
_011            equ 6
_111            equ 7

                MACRO char
_\0             dc.b (\1<<4)|(\2)
                dc.b (\3<<4)|(\4)
                dc.b (\5<<4)|(\6)
                dc.b (\7<<4)|(\8)
                dc.b (\9<<4)|(\10)
                ENDM

                MACRO LO
                dc.b <(_\0)
                dc.b <(_\1)
                dc.b <(_\2)
                dc.b <(_\3)
                ENDM
                MACRO HI
                dc.b >(_\0)
                dc.b >(_\1)
                dc.b >(_\2)
                dc.b >(_\3)
                ENDM

                char A,_011,_000, _100,_100, _111,_100, _100,_100, _100,_100
                char B,_111,_000, _100,_100, _111,_000, _100,_100, _111,_000
                char C,_011,_000, _100,_100, _100,_000, _100,_100, _011,_000
                char D,_111,_000, _100,_100, _100,_100, _100,_100, _111,_000
                char E,_111,_100, _100,_000, _111,_000, _100,_000, _111,_100
                char F,_111,_100, _100,_000, _111,_000, _100,_000, _100,_000
                char G,_011,_000, _100,_100, _100,_000, _100,_100, _011,_100
                char H,_100,_100, _100,_100, _111,_100, _100,_100, _100,_100
                char I,_111,_000, _010,_000, _010,_000, _010,_000, _111,_000
                char J,_111,_100, _000,_100, _000,_100, _100,_100, _011,_000
                char K,_100,_100, _101,_000, _110,_000, _101,_000, _100,_100
                char L,_100,_000, _100,_000, _100,_000, _100,_000, _111,_100
                char M,_100,_100, _111,_100, _100,_100, _100,_100, _100,_100
                char N,_100,_100, _111,_100, _111,_100, _100,_100, _100,_100
                char O,_011,_000, _100,_100, _100,_100, _100,_100, _011,_000
                char P,_111,_000, _100,_100, _111,_000, _100,_000, _100,_000
                char Q,_011,_000, _100,_100, _100,_100, _101,_100, _010,_100
                char R,_111,_000, _100,_100, _111,_000, _100,_100, _100,_100
                char S,_011,_100, _100,_000, _011,_000, _000,_100, _111,_000
                char T,_111,_100, _010,_000, _010,_000, _010,_000, _010,_000
                char U,_100,_100, _100,_100, _100,_100, _100,_100, _011,_000
                char V,_100,_100, _100,_100, _100,_100, _101,_000, _110,_000
                char W,_100,_100, _100,_100, _100,_100, _111,_100, _100,_100
                char X,_100,_100, _100,_100, _011,_000, _100,_100, _100,_100
                char Y,_100,_100, _100,_100, _100,_100, _011,_000, _011,_000
                char Z,_111,_100, _001,_000, _010,_000, _100,_000, _111,_100

                char 0,_011,_000, _100,_100, _100,_100, _100,_100, _011,_000
                char 1,_010,_000, _110,_000, _010,_000, _010,_000, _010,_000
                char 2,_111,_000, _100,_100, _001,_000, _010,_000, _111,_100
                char 3,_111,_000, _000,_100, _011,_000, _000,_100, _111,_000
                char 4,_100,_000, _101,_000, _111,_100, _010,_000, _010,_000
                char 5,_111,_100, _100,_000, _111,_000, _000,_100, _111,_000
                char 6,_011,_000, _100,_000, _111,_000, _100,_100, _011,_000
                char 7,_111,_100, _000,_100, _001,_000, _010,_000, _010,_000
                char 8,_011,_000, _100,_100, _011,_000, _100,_100, _011,_000
                char 9,_011,_000, _100,_100, _011,_000, _000,_100, _011,_000

                char space,_000,_000, _000,_000, _000,_000, _000,_000, _000,_000
                char excl ,_010,_000, _010,_000, _010,_000, _000,_000, _010,_000
                char plus ,_000,_000, _010,_000, _111,_100, _010,_000, _000,_000
                char minus,_000,_000, _000,_000, _111,_100, _000,_000, _000,_000 
                char quote,_100,_100, _100,_100, _000,_000, _000,_000, _000,_000 

                char equal,_000,_000, _111,_100, _000,_000, _111,_100, _000,_000
 

charDatalo::
                LO A,B,C,D
                LO E,F,G,H
                LO I,J,K,L
                LO M,N,O,P
                LO Q,R,S,T
                LO U,V,W,X
                LO Y,Z,0,1
                LO 2,3,4,5
                LO 6,7,8,9

                LO space,excl,quote,plus
                LO minus,equal,0,0

charDatahi::
                HI A,B,C,D
                HI E,F,G,H
                HI I,J,K,L
                HI M,N,O,P
                HI Q,R,S,T
                HI U,V,W,X
                HI Y,Z,0,1
                HI 2,3,4,5
                HI 6,7,8,9
                HI space,excl,quote,plus
                HI minus,equal,0,0

;---------------
;- PrintStringXY
;- IN : X      - x-pos
;       Y      - y-pos
;       A      - string-address LSB
;       (sp-3) - string address MSB

MFNT_PrintStringXY::
                stx MFNT_char_x
                sty MFNT_char_y
;---------------
;- PrintString
;- IN : A      - string-address LSB
;       (sp-3) - string address MSB
;

MFNT_PrintString:: 
                plx
                ply             ; get return-address
                sta .off+1
                pla             ; get text-adress-MSB
                sta .off+2
                phy             ; restore return-address
                phx

                lda MFNT_char_x
                pha

                ldx #0
.off            lda $1111,x
                bmi .exit
                cmp #13
                bne .1
                clc
                lda MFNT_char_y
                adc #6
                sta MFNT_char_y
                pla
                pha
                sta MFNT_char_x
                bra .2
.1              jsr MFNT_PrintChar
.2              inx
                bne .off
.exit           pla
                rts
;--------------
; PrintHexXY
; IN : A - value
;      X - x-pos
;      Y - y-pos

MFNT_PrintHexXY::    stx MFNT_char_x
                sty MFNT_char_y

;---------------
; PrintHex
; IN : A - value

MFNT_PrintHex::
                pha
                lsr
                lsr
                lsr
                lsr
                tay
                lda convert,y
                jsr MFNT_PrintChar
                pla
                and #$f
                tay
                lda convert,y
                bra MFNT_PrintChar

convert:        dc.b "0123456789ABCDEF"
;--------------
; PrintCharXY
; IN : A - char
;      X - x-pos
;      Y - y-pos

MFNT_PrintCharXY::
                stx MFNT_char_x
                sty MFNT_char_y
;--------------
; PrintCharXY
; IN : A - char

IF useSuzy

MFNT_PrintChar::
                tay
                lda MFNT_char_x
                asl
                sta charSCB_x
                lda MFNT_char_y
                sta charSCB_y

                lda translate,y
                beq .99
                tay


                lda charDatalo-1,y
                sta ptr
                lda charDatahi-1,y
                sta ptr+1

                lda (ptr)
                sta charSCBdata+1
                ldy #1
                lda (ptr),y
                sta charSCBdata+1+3
                iny
                lda (ptr),y
                sta charSCBdata+1+6
                iny
                lda (ptr),y
                sta charSCBdata+1+9
                iny
                lda (ptr),y
                sta charSCBdata+1+12

                lda #<charSCB
                sta $fc10
                lda #>charSCB
                sta $fc11
                lda #1
                STA $FC91
                STZ $FD90
.WAIT           STZ $FD91
                lda $fc92
                lsr
                bcs .WAIT
                STZ $FD90

.99             inc MFNT_char_x
                rts

charSCB:        dc.b $C0,$90,00
                dc.w 0
                dc.w charSCBdata
charSCB_x       dc.w 0
charSCB_y       dc.w 0
                dc.w $100,$100
                dc.b $01,$23,$45,$67

charSCBdata     dc.b 3,0,0
                dc.b 3,0,0
                dc.b 3,0,0
                dc.b 3,0,0
                dc.b 3,0,0
                dc.b 0
ELSE

MFNT_PrintChar::
                tay
                lda translate,y
                beq .99
                tay

                lda charDatalo-1,y
                sta ptr
                lda charDatahi-1,y
                sta ptr+1

                clc
                lda MFNT_char_x
                ldy MFNT_char_y
                adc screenoff_lo,y
                pha
                lda screenoff_hi,y
                adc #0
                tay

                clc
                pla
                adc MFNT_screenbase     ; $fd94/95 is read-only !
                sta ptr1 
                tya
                adc MFNT_screenbase+1
                sta ptr1+1

                ldy #0

.0              lda (ptr),y
                sta (ptr1)
                clc
                lda ptr1
                adc #80
                sta ptr1
                bcc .1
                inc ptr1+1
.1              iny
                cpy #5
                bne .0

.99             inc MFNT_char_x
                rts

ENDIF
;---------------
; translate-table
; ASCII -> own numbers

translate:      ds 32
                dc.b 37,38,39   ; ` `,`!`, `"`
                ds 8            ; "#" .. "*"
                dc.b 40         ; "+"
                dc.b 0          ; ","
                dc.b 41         ; "-"
                ds 2            ; ".", "/"
                dc.b 27,28,29,30,31,32,33,34,35,36
                ds 3            ; ":" .. "<"
                dc.b 42
                ds 3
                dc.b 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
                dc.b 17,18,19,20,21,22,23,24,25,26
                ds 6            ; "[" .. "'"
                dc.b 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
                dc.b 17,18,19,20,21,22,23,24,25,26
                ds 5
;---------------
; y-offset-table
;
screenoff_lo:

s               set 0
                REPT 102
                dc.b <s
s               set s+80
                ENDR

screenoff_hi:

s               set 0
                REPT 102
                dc.b >s
s               set s+80
                ENDR

ende:
                echo "END : %Hende"

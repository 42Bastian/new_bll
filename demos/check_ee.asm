***************
* CHECK_EE.ASM
* Lynx-program to test a EEPROM-check-sub-routine
*
* created : 25.04.96
*
****************

Baudrate        equ 62500
DEBUG		equ 1

_1000HZ_TIMER   equ 7


	include <includes/hardware.inc>
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
                include <vardefs/debug.var>
                include <vardefs/serial.var>
                include <vardefs/1000Hz.var>
                include <vardefs/eeprom.var>

 BEGIN_ZP
counter         ds 1
Save1000Hz      ds 2
 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
irq_vektoren    ds 16
EEPROMbuffer    ds 128
 END_MEM
                run LOMEM       ; code directly after variables

                sei
                cld
                CLEAR_MEM
                CLEAR_ZP

                INITMIKEY
                INITSUZY
                SETRGB pal
                INITIRQ irq_vektoren
                INITKEY ,_FIREA|_FIREB          ; repeat for A & B
                INITFONT LITTLEFNT,RED,WHITE
                jsr Init1000Hz
                jsr InitComLynx
                SETIRQ 2,VBL
                SETIRQ 0,HBL
                MOVEI StartPause,PausePtr
                MOVEI EndPause,PausePtr+2
                dec PauseEnable

                cli
                SCRBASE screen0
                SET_MINMAX 0,0,160,102
Start::
* title
                CLS #0
                SET_XY 40,40
                PRINT "TITLE-SCREEN",,0
.wait
                jsr WaitKey
                lda CurrentButton
                bit #_FIREA|_FIREB
                beq .wait
	       jsr EEPROMcheat
	bra	.wait
* game-play
;;->                CLS #0
;;->.loop           jsr ReadKey
;;->                SET_XY 40,40
;;->                lda _1000Hz+1
;;->                jsr PrintHex
;;->                lda _1000Hz
;;->                jsr PrintHex
;;->                bra .loop
****************
* check EEPROM if up+A+up is pressed
****************
EEPROMcheat::
;;->		ldy #0
;;->.1              lda $fcb0
;;->                bit #$80        ; 1st state : up
;;->                bne .2
;;->                dey
;;->                bne .1
;;->.98             rts
;;->
;;->.2              ldy #0
;;->.3              lda $fcb0
;;->                bit #$1         ; 2nd state : A
;;->                bne .4
;;->                dey
;;->                bne .3
;;->                rts
;;->
;;->.4              ldy #0
;;->.5              lda $fcb0
;;->                bit #$80        ; 3rd state : up
;;->                bne .6
;;->                dey
;;->                bne .5
;;->                rts

.6              jsr CheckEEPROM
                pha
                SET_XY 0,0
                pla
                cmp #noEEPROM
                beq .8
                cmp #koEEPROM
                beq .7
                PRINT "EEPROM ok",,0
                bra .99
.7              PRINT "EEPROM damaged",,0
                bra .99
.8              PRINT "no EEPROM",,0
.99 rts
	bra .99         ; !!! stop !!!

EEPROMchecked   dc.b 0
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
****************

VBL::           jsr Keyboard                    ; read buttons
                stz $fda0
                END_IRQ

HBL::           inc $fda0
                END_IRQ
****************
StartPause::    MOVE _1000Hz,Save1000Hz
                SET_XY 40,40
                PRINT "PAUSE",,1
                rts
EndPause::      MOVE Save1000Hz,_1000Hz
                CLS #0
                rts
****************
* INCLUDES
                include <includes/1000Hz.inc>
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/window2.inc>
                include <includes/irq.inc>
                include <includes/font2.hlp>
                include <includes/newkey.inc>
                include <includes/check_ee.inc>
                include <includes/eeprom.inc>
                include <includes/savegame.inc>
pal             STANDARD_PAL

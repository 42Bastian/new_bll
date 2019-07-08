***************
* SOUND.ASM
* simple body of a Lynx-program
*
* created : 5.3.97
*
****************

DEBUG		set 1
BRKuser         set 1
Baudrate        set 9600

SND_TIMER       set 7

                include <macros/hardware.asm>            ; get hardware-names
****************
* macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/newkey.mac>
                include <macros/debug.mac>

****************
* variables
                include <vardefs/debug.var>
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/newkey.var>
                include <vardefs/serial.var>
                include <vardefs/sound.var>
****************
 BEGIN_ZP
VBLsema         ds 1

 END_ZP


 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
irq_vektoren    ds 16
 END_MEM
                run LOMEM       ; code directly after variables
*
* system init
Start::         START_UP             ; Start-Label needed for reStart
                CLEAR_MEM
                CLEAR_ZP +STACK ; clear stack ($100) too

                INITMIKEY
                INITSUZY
                FRAMERATE 60
                SETRGB pal
                INITIRQ irq_vektoren
                INITBRK                         ; if we're using BRK #X, init handler
                INITKEY ,_FIREA|_FIREB          ; repeat for A & B
                INITFONT LITTLEFNT,RED,WHITE
                jsr InitComLynx
                SETIRQ 2,VBL
                SETIRQ 0,HBL

                cli
                SCRBASE screen0
                SET_MINMAX 0,0,160,102
                jsr SndInit
*
Main::
                LDAY DefineENVs
                ldx #0
                jsr SndStartSound

	
.loop           stz CurrX
                stz CurrY
	
                stz CurrX
                lda #20
                sta CurrY
                lda t2
                jsr PrintHex
                lda t1
                jsr PrintHex

                stz CurrX
                lda #30
                sta CurrY
                ldx #1
.1
                lda SndVolume,x
                jsr PrintHex

                lda SndEnvFrq,x
                jsr PrintHex

                lda SndEnvFrqCnt,x
                jsr PrintHex

                lda SndEnvFrqOff,x
                jsr PrintHex

                lda SndEnvFrqLoop,x
                jsr PrintHex
;-->                lda SndMaxFrq,x
;-->                jsr PrintHex
                inc CurrX
                inc CurrX
                dex
                bpl .1

                jsr ReadKey
                beq .loop
                stz t1
                stz t2
                lda CurrentButton
                bit #_FIREA
                _IFNE
                  pha
;-->                  LDAY UfoSnd
;-->                  ldx #0
;-->                  jsr SndStartSound
                  LDAY AlienMoveSnd
                  ldx #2
                  jsr SndStartSound
                  pla
                _ENDIF
                bit #_FIREB
                _IFNE
                  pha
                  LDAY ShipExplSnd
                  ldx #1
                  jsr SndStartSound
                _ENDIF
                jmp .loop
*
****************
VBL::           lda #$ff
                tsb VBLsema
                _IFEQ
                  cli
                  jsr Keyboard                    ; read buttons
                  stz VBLsema
                _ENDIF
                stz $fdb0
                END_IRQ
                
HBL::
                dec $fdb0
                END_IRQ
****************
* INCLUDES

                include <includes/draw_spr.inc>
                include <includes/hexdez.inc>
                include <includes/serial.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/irq.inc>
                include <includes/font2.hlp>
                include <includes/newkey.inc>
		include <includes/sound.inc>

****************
pal             STANDARD_PAL

                include <macros/sound.mac>
DefineENVs:
        DEFVOL 15,explenv1
        DEFFRQ 15,explenv2
        DEFVOL 14,explenv1
        DEFFRQ 14,explenv2
        DEFVOL 13,shotenv1
        DEFFRQ 13,shotenv2
        DEFVOL 12,Sexplenv1
        DEFFRQ 12,Sexplenv2
        DEFVOL 11,gnurbsh1
        DEFFRQ 11,gnurbsh2
        DEFFRQ 10,ufoenv1
        dc.b 0

explenv1:       dc.b 0,1,60,-2
explenv2        dc.b 1,1,1,-4
Sexplenv1:       dc.b 0,1,60,-1
Sexplenv2        dc.b 1,1,1,-2
shotenv1:       dc.b 2,2,2,-10,1,-8
shotenv2        dc.b 1,1,4,-15
ufoenv1            dc.b 1,2,20,-2,20,2
gnurbsh1:       dc.b 0,1,20,-10
gnurbsh2        dc.b 1,1,1,-20
	
ShotSnd:
;-->        DEFVOL 15,explenv1
;-->        DEFFRQ 15,explenv2
        SETFRQ 15
        SETVOL 15
        INSTR 3,120,120
        PLAY 100,40
        STOP
        dc.b 0


AlienExplSnd
;>        DEFVOL 14,explenv1
;>        DEFFRQ 14,explenv2
        SETVOL 14
        SETFRQ 14
        INSTR $ff,120,120
        PLAY 60,60
        STOP
        dc.b 0

AlienMoveSnd
;>        DEFVOL 11,gnurbsh1
;>        DEFFRQ 11,gnurbsh2
        SETFRQ 11
        SETVOL 11
        INSTR $31,20,20
        PLAY 70,10
        INSTR $30,20,20
        PLAY 70,10
        STOP
        dc.b 0

NotHitExplSnd
;>        DEFVOL 13,shotenv1
;>        DEFFRQ 13,shotenv2
        SETFRQ 13
        SETVOL 13
        INSTR $5,120,120
        PLAY 70,40
        STOP
        dc.b 0


ShipExplSnd
;>        DEFVOL 12,Sexplenv1
;>        DEFFRQ 12,Sexplenv2
        SETVOL 12
        SETFRQ 12
        INSTR $ff,120,120
        PLAY 60,60
        STOP
        dc.b 0

UfoSnd
;-->                DEFFRQ 10,ufoenv1
                SETFRQ 10

                INSTR $3,50,50
                PLAY 50,1000
                STOP
                dc.b 0


***************

* simple body of a Lynx-program
*
* created : 24.04.96
*
****************


;>BRKuser         set 1

Baudrate        set 62500

MAX_PLAYERS     equ 2
LOGON_TIMER     equ 1
SERIAL_TIMER    equ 5
_1000HZ_TIMER   equ 7

IRQ_SWITCHBUF_USR set 1



		include <macros/hardware.asm>

*
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
                include <vardefs/msg.var>
                include <vardefs/1000Hz.var>
*
 BEGIN_ZP
MsgError        ds 1
Reboot          ds 1
Save1000Hz      ds 2
VBLcount        ds 2
VBLsema         ds 2

MyID            ds 1
Master          ds 1
Players         ds 1
XButton         ds MAX_PLAYERS
XCursor         ds MAX_PLAYERS
PlayerOK        ds 1
 END_ZP

 BEGIN_MEM
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
irq_vektoren    ds 16
PlayersTab      ds MAX_PLAYERS
 END_MEM
                run LOMEM       ; code directly after variables
*
* init
*
                START_UP             ; Start-Label needed for reStart
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
                jsr Init1000Hz

Start::         VSYNC
                sei
                jsr InitComLynx
                SETIRQ 2,VBL
                MOVEI StartPause,PausePtr
                MOVEI EndPause,PausePtr+2
;>                dec PauseEnable


                cli
                SCRBASE screen0,screen1
                CLS #15
                SETIRQ 0,HBL
                CLS #0
                SET_MINMAX 0,0,160,102


*
;>.do             jsr ReadKey
;>                beq .do

Main::          jsr InitLogon

                jsr Logon
New::           jsr ReInitLogon
                inc Reboot
                CLS #0
                lda Players
                jsr PrintDezA
                PRINT pl_text
                lda Reboot
                jsr PrintHex
                SWITCHBUF

                CLS #0
                lda Players
                jsr PrintDezA
                PRINT pl_text
                lda Reboot
                jsr PrintHex

.loop           lda LogonFlag
                bne New

                jsr ReadKey
                _IFNE
                  lda CurrentButton
                  bit #_FIREA
                  _IFNE
                    jsr ReqToStopLogon
                  _ENDIF
                  bit #_FIREB
                  _IFNE
                    stz Reboot
                    bra New
                  _ENDIF
                  bit #_OPT2
                  _IFNE
                    sei
                    WAITNOKEY
                    WAITKEY
                    cli
                  _ENDIF
                _ENDIF
                SET_XY 0,60
                lda _1000Hz+1
                jsr PrintDezA

                SET_XY 100,0
                lda MyID
                jsr PrintDezA

                lda LogonActivePlrs
                jsr PrintHex

                SET_XY 0,10
                ldx #MAX_PLAYERS-1
.0              lda PlayersTab,x
                jsr PrintHex
                inc CurrX
                dex
                bpl .0

                SET_XY 0,20
                lda RxPtrIn
                jsr PrintHex
                inc CurrX
                lda RxBuffer
                jsr PrintHex


                SWITCHBUF
                lda LogonFail
                bmi .exit
                lda LogonCount
                lbne .loop

.exit
                jsr ExitLogon
                jsr InitComLynx
.5              CLS #0
                lda Players
                jsr PrintDezA
                PRINT pl_text
                lda Master
                jsr PrintHex
                lda LogonFail
                jsr PrintHex
                SET_XY 0,20
                ldx #MAX_PLAYERS-1
.6                lda XButton,x
                  jsr PrintHex
                  lda XCursor,X
                  jsr PrintHex
                  inc CurrX
                  inc CurrX
                  dex
                bpl .6

                SET_XY 50,50
                lda VBLcount
                jsr PrintHex
                SET_XY 0,60
                ldx #MAX_PLAYERS-1
.7              lda pl1,x
                jsr PrintHex
                dex
                bpl .7
                jsr GetKey

                SWITCHBUF
                ldx #MAX_PLAYERS-1
.8              lda XCursor,x
                bit #$C0
                _IFNE
                  asl
                  _IFCS
                    inc pl1,x
                  _ELSE
                    dec pl1,x
                  _ENDIF
                _ENDIF
                lda XButton,x
                and #_RESTART
                cmp #_RESTART
                _IFEQ
                  stz VBLcount
                  lda #4
.9                cmp VBLcount
                  bne .9
                  jmp Start
                _ENDIF
                dex
                bpl .8


                jmp .5

pl_text         dc.b " PLAYERS",0

pl1             ds MAX_PLAYERS
************************************************************
* Logon
*

* MAX_PLAYERS     equ 4
* LOGON_TIMER     equ 1

LOGON_MSG_SIZE  EQU 4

PLAYER_INIT     equ 16 ;MAX_PLAYERS*4

                MACRO LogonEND_IRQ
                ply
                stz LogonSema
                END_IRQ
                ENDM

*
* InitLogon
InitLogon::     jsr Random
                and #MAX_PLAYERS-1
                sta MyID
                lda #255
                sta $fd00+LOGON_TIMER*4
                lda #%00011100
                sta $fd01+LOGON_TIMER*4
                SETIRQVEC LOGON_TIMER,do_logon
                rts

ExitLogon::     php
                sei
                stz MsgReceivedHook
                jsr CheckMaster
                lda #$80
                trb $fd01+LOGON_TIMER*4
                dec LogonComplete
                plp
                rts
* LogonVars
LogonDelay      dc.b 0
LogonNext       dc.b 0
LogonSema       dc.b 0
LogonFail       dc.b 0
LogonCount      dc.b 0
LogonReqFinish  dc.b 0
LogonFlag       dc.b 0
LogonActivePlrs dc.b 0
LogonListenCount dc.b 0
LogonComplete   dc.b 0

power_of_two    dc.b 1,2,4,8,16,32,64,128

* CheckMaster
CheckMaster::   stz Master
                ldx MyID
.0              dex
                bmi .9
                lda PlayersTab,x
                beq .0
                rts

.9              dec Master
                rts
* Logon
*
; clear player-table and enable Logon interrupt

Logon::         ldx #MAX_PLAYERS-1
.0                stz PlayersTab,x
                  dex
                bpl .0
                stz LogonFail
                stz LogonComplete

                lda #LOGON_MSG_SIZE
                sta TxBuffer
                lda MyID
                tax
                sta TxBuffer+1
                clc
                adc #$42
                sta TxBuffer+2
                stz TxBuffer+3

                lda #PLAYER_INIT
                sta PlayersTab,x
                lda power_of_two,x
                sta LogonActivePlrs
                lda #1
                sta Players

                lda #MAX_PLAYERS*10
                sta LogonListenCount
                lda #6
                sta LogonNext

                stz LogonReqFinish
                stz LogonSema

                lda #MAX_PLAYERS*4
                sta LogonCount
                stz LogonFlag

                lda #$80
                tsb $fd01+LOGON_TIMER*4
                rts
ReInitLogon::
                lda LogonSema
                bne ReInitLogon
                stz LogonReqFinish
                lda #MAX_PLAYERS*4
                sta LogonCount

                stz LogonFlag
                stz LogonFail
                stz RxDone
                stz RxPtrIn
                rts
ReqToStopLogon::
;>                lda LogonSema
;>                bne ReqToStopLogon
                lda #$80
                sta LogonReqFinish
                ora MyID
                sta TxBuffer+1
                clc
                adc #$42
                sta TxBuffer+2
                rts
do_logon::
                lda #$ff
                tsb LogonSema
                bne .99
                cli
                phy

                ldx LogonNext
                jsr .9
                LogonEND_IRQ
.9              jmp (logon_tab,x)

.99             END_IRQ

logon_tab       dc.w LogonHello,LogonDown,LogonWait,LogonListen


LogonMsg::
                stz RxDone
                lda RxBuffer
                cmp #LOGON_MSG_SIZE
                _IFNE
                  lda #2
                  sta LogonNext
                _ELSE
                  phy
                  jsr LogonCheckIn
                  ply
                _ENDIF
                rts

LogonHello::
                ldx MyID
                lda #PLAYER_INIT
                sta PlayersTab,x
                lda power_of_two,x
                tsb LogonActivePlrs

                ldy Players
                stz Players
                stz LogonActivePlrs

                ldx #MAX_PLAYERS-1
.01               _IFNE {PlayersTab,x}
                    dec PlayersTab,x
                    _IFNE
                      inc Players
                      lda power_of_two,x
                      tsb LogonActivePlrs
                    _ENDIF
                  _ENDIF
                  dex
                bpl .01

                cpy Players
                _IFNE
                  dec LogonFlag
                _ENDIF

                lda LogonActivePlrs
                sta TxBuffer+3
.1              jsr MsgSendMessage
                bcc .1

                lda #MAX_PLAYERS+1
                sta LogonDelay
                lda #4
                sta LogonNext
                _IFNE LogonReqFinish
                  dec LogonCount
                _ENDIF
                rts
LogonDown::
*
                ldx #MAX_PLAYERS-1
.0                _IFNE {PlayersTab,x}
                    dec PlayersTab,x
                  _ENDIF
                  dex
                bpl .0
                stz LogonNext
                rts

LogonWait::
                dec LogonDelay
                bne .99
                stz LogonNext
.99             rts
LogonListen::
                dec LogonListenCount
                _IFEQ
                  php
                  sei
                  MOVEI LogonMsg,MsgReceivedHook
                  stz LogonNext
                  plp
                  rts
                _ENDIF
.0              lda RxDone
                _IFEQ
                  rts
                _ENDIF
                stz RxDone

                lda RxBuffer+1
                tax
                and #$7f
                cmp #MAX_PLAYERS
                _IFCS
                  inc LogonListenCount
                  rts
                _ENDIF
                txa
                _IFMI
                  lda #$80
                  trb $fd01+LOGON_TIMER*4
                  dec LogonFail
                  rts
                _ENDIF
                cpx MyID
                _IFNE
                  lda #PLAYER_INIT
                  sta PlayersTab,x
                  bra .0
                _ELSE
                dec $fda0
                  ldy #-1
.1                  txa
                    inc
                    and #MAX_PLAYERS-1
                    tax
                    cpx MyID
                    _IFEQ
                      dec LogonFail
                      lda #$80
                      trb $fd01+LOGON_TIMER*4
                      rts
                    _ENDIF
                    iny
                    lda PlayersTab,x
                  bne .1
                  stx MyID
                  stx TxBuffer+1
                  lda #PLAYER_INIT
                  sta PlayersTab,x
                  txa
                  clc
                  adc #$42
                  sta TxBuffer+2
                  bra .0
                _ENDIF
                rts
LogonCheckIn::
*
                lda RxBuffer+1
                tay
                and #$7f
                tax
                cmp #MAX_PLAYERS
                _IFCS
                  lda #2
                  sta LogonNext
                  rts
                _ENDIF
                tya
                _IFMI
                  lda #$80
                  sta LogonReqFinish
                  ora MyID
                  sta TxBuffer+1
                  clc
                  adc #$42
                  sta TxBuffer+2
                _ENDIF
                cpx MyID
                _IFNE
                  lda #PLAYER_INIT
                  sta PlayersTab,x

                  ldy #-1
.0                  inx
                    txa
                    and #MAX_PLAYERS-1
                    tax
                    cpx MyID
                    _IFEQ
                      tya
                      _IFEQ
                        stz LogonNext
                      _ENDIF
                      rts
                    _ENDIF
                    iny
                    cpy #MAX_PLAYERS
                    _IFNE
                       lda PlayersTab,x
                       beq .0
                    _ENDIF
                    rts
                _ELSE
                  ldy #-1
.1                  txa
                    inc
                    and #MAX_PLAYERS-1
                    tax
                    cpx MyID
                    _IFEQ
                      dec LogonFail
                      _IFMI
                        lda #$80
                        trb $fd01+LOGON_TIMER*4
                      _ELSE
                        lda #2
                        sta LogonNext
                      _ENDIF
                      rts
                    _ENDIF
                    iny
                    lda PlayersTab,x
                  bne .1
                  stx MyID
                  stx TxBuffer+1
                  txa
                  clc
                  adc #$42
                  sta TxBuffer+2
                  tya
                  _IFNE
                    jsr Random
                    and #MAX_PLAYERS-1
                    inc
                    sta LogonDelay
;>                    sty LogonDelay
                    lda #4
                    sta LogonNext
                  _ELSE
                    stz LogonNext
                  _ENDIF
                _ENDIF
                rts

*
************************************************************
*
DoComLynx::
                phy
                ldx #MAX_PLAYERS-1
.000              stz XCursor,x
                  stz XButton,x
                  dex
                bpl .000

                lda #4
                sta TxBuffer
                lda #$A0
                ora MyID
                ldx MyID
                sta TxBuffer+1
                lda CurrentButton
                sta TxBuffer+2
                sta XButton,x
                lda CurrentCursor
                sta TxBuffer+3
                sta XCursor,X
                ldx MyID
                lda power_of_two,x
                sta PlayerOK
                _IFNE Master
                  jsr MsgSendMessage
                  ldx #0
.0                dex
                  beq .9
                  lda RxDone
                  beq .0
                  stz RxDone
                  lda RxBuffer+1
                  tax
                  and #$a0
                  cmp #$a0
                  bne .0
                  txa
                  and #MAX_PLAYERS-1
                  tax
                  lda RxBuffer+2
                  sta XButton,x
                  lda RxBuffer+3
                  sta XCursor,x
                _ELSE
                  ldx #0
.1                dex
                  beq .9
                  lda RxDone
                  beq .1
                  stz RxDone
                  lda RxBuffer+1
                  tax
                  and #$a0
                  cmp #$a0
                  bne .1
                  txa
                  and #MAX_PLAYERS-1
                  tax
                  lda RxBuffer+2
                  sta XButton,x
                  lda RxBuffer+3
                  sta XCursor,x
                  jsr MsgSendMessage
                _ENDIF
                ply
                rts
.9              dec MsgError
                ply
                rts
*
* mulAX
mulAX::         sta $fc52
                stx $fc54
                stz $fc55
.wait           bit $fc92
                bmi .wait
                lda $fc60
                rts
*
* Random
last_random     db 35

Random
InitRandom::    phx
.1              lda $fd0a       ; $fd0a
                ldx $fd02
.2              adc $fd0a
                dex
                bne .2
                lsr             
                adc last_random
                sta last_random
                beq .1
                plx
                rts
*
* IRQs
*
VBL::           IRQ_SWITCHBUF
                inc VBLcount
                _IFEQ
                  inc VBLcount+1
                _ENDIF

                lda #$ff
                tsb VBLsema
                bne .99
                cli
                jsr Keyboard                    ; read buttons

                _IFNE LogonComplete
                  jsr DoComLynx
                _ENDIF
                stz VBLsema
.99              stz $fdb0
                END_IRQ
                
HBL::           inc $fdb0
                END_IRQ

*
* Pause
StartPause::    MOVE _1000Hz,Save1000Hz
                SET_XY 40,40
                PRINT "PAUSE",,1
                brk #$ff
                rts
EndPause::      MOVE Save1000Hz,_1000Hz
                CLS #0
                rts
*
* INCLUDES

                include <includes/hexdez.inc>
                include <includes/1000Hz.inc>
                include <includes/msg.inc>
                include <includes/debug.inc>
                include <includes/font.inc>
                include <includes/window2.inc>
                include <includes/irq.inc>
                include <includes/font2.hlp>
                include <includes/newkey.inc>

*
pal             STANDARD_PAL

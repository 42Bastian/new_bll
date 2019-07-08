                db "TALKTALK"
* SERIAL modified => TALKTALK
* Version 1.0 of 28.3.94
* (c) 1993 Bastian Schick
*
* works with 300/1200/2400/4800/9600 Baud
*
*
* last modified:
*
* 20.03.96      check-sum not computed in TxIRQ
*               TxIRQ leaner
*               Baudrate set by label Baudrate
*               SerialReload (wake up of RxIRQ) now connected to
*               baudrate

TALKTALK        set 1

SerialControl   equ %00011101   ; even par


IFND Baudrate
Baudrate        set 9615
ENDIF
SerClkDiv       set 125000/Baudrate-1

ifd vorteiler
 fail "Old source using 'vorteiler'"
endif

                echo "Baudrate : %DBaudrate"

IFND TimeOut
TimeOut         equ 20          ; ~5s
ENDIF


RxParityErr     equ %00010000
RxOverrun       equ %00001000
RxFrameErr      equ %00000100
RxBreak         equ %00000010


*********************************
* Schnittstelle initialisieren
*********************************
InitComLynx::   php
                sei
IFD DEBUG
                jsr InstallLoader
ENDIF
                lda #SerClkDiv
                sta $fd10

                lda #%00011000
                sta $fd11
                
                lda #SerialControl|$48
;>                sta SerialContrl
;>                ora #$48
                sta $fd8c
                stz MessageDone
                stz MessageReceived
                stz TimeOutFlag
                stz FirstByteIn
                stz MessagePtrIn
                stz MessagePtrOut
                lda #TimeOut
                sta SerialTimeOut               ; 2,6 s
.loop1          lda $fd8d
                bit $fd8c
                bvs .loop1
                
.exit           SETIRQVEC 4,SerialIRQ
                plp
                rts
****************************
* IRQ-Einsprung von TxIRQ und RxIRQ
****************************
SerialIRQ::     bit MessageDone
                bpl .rx
*************** 
.tx_irq         ldx MessagePtrOut
                cpx MessageLenOut
                beq .cont1
                lda MessageBufferOut,x
                sta $fd8d
                inc MessagePtrOut

.exit2          lda #$10
                sta $fd80
                END_IRQ

.cont1
* 97/01/31
                lda $fd8c
                bit #$20        ; tx totally done ?
                beq .exit2
                bvs .exit2
*
                lda #SerialControl|$48
                sta $fd8c       ; disable tx-irq/enable rx-irq

                stz MessageDone
                stz CheckOutFlag

                lda #$10
                sta $fd80
                END_IRQ
****************
.rx             ldx $fd8d       ; Byte holen
                lda $fd8c
                and #RxParityErr|RxOverrun|RxFrameErr|RxBreak
                beq .rx_irq
                tsb SerialStat  ; ev. Fehler merken
                bit #RxBreak
                beq .noBreak
                stz TimeOutFlag ; bei BREAK alles reset
                stz MessagePtrIn
                stz MessagePtrOut
                stz FirstByteIn
.noBreak        lda #SerialControl|$48        ; RxIRQ setzen und Fehler l”schen
                sta $fd8c
                lda #$10
                sta $fd80
                END_IRQ
                

.rx_irq         lda #SerialControl|$48        ; RxIRQ setzen und Fehler l”schen
                sta $fd8c
                lda #$10
                sta $fd80
                txa
IFD DEBUG
                jsr do_debug    ; ev. DEBUGGER-Befehl
                bcc .exit0
ENDIF
                ldx FirstByteIn
                bne .ok_rx
                cmp #MessageBufferLen-1
                bge .error
                stz MessagePtrIn
                sta CheckIn
                stz CheckInFlag
                sta MessageLenIn
                dec FirstByteIn
.exit0          END_IRQ

.error
                lda #SerialControl|$48        ; rx_irq/Fehler l”schen
                sta $fd8c
                lda #$10
                sta $fd80
                END_IRQ
                
.ok_rx          ldx MessagePtrIn
                sta MessageBufferIn,x
                clc
                adc CheckIn
                sta CheckIn
                inx
                cpx MessageLenIn
                blt .exit1
                lda #$ff
                tsb CheckInFlag
                beq .exit1
                lda MessageReceived
                bne .overrun
                lda #$ff
                sta MessageReceived
                stz FirstByteIn
.exit1          stx MessagePtrIn
                END_IRQ

.overrun        lda #$80
                tsb SerialStat
                END_IRQ
***************
* Meldung abschicken
***************
SendMessage::   bit MessageDone
                bmi .exit
                phx
                php
                sei
                sec
                lda #0
                tax
                sbc MessageLenOut
.0                sec
                  sbc MessageBufferOut,x
                  inx
                  cpx MessageLenOut
                bne .0
                sta MessageBufferOut,x          ; put checksum at end of data
                inc MessageLenOut
                stz MessagePtrOut
                stz CheckOutFlag
                lda #$88|SerialControl
                sta $fd8c       ; enable TX-IRQ, disable RX-IRQ

                stx $fd8d                       ; first send message length

                sta MessageDone
                plp
                plx
.exit           sec
                rts
****************
* Testet auf Message
****************
TestMessage::   clc
                bit MessageReceived
                bpl .exit
                sec
.exit           rts

* -*-asm-*-
	db "SERIAL"
* SERIAL
* (c) 1993 Bastian Schick
*
* runs ok with 300/1200/2400/4800/9600/31250/62500 Baud
*
* 15.08.96      42BS            removed 'nonsense'-code
* 31.08.96      42BS            error in WaitComLynxByte
* 07.02.96      42BS            removed old stuff
* 18.11.97      42BS            move Loader init. to debug.inc

SERIAL          equ 1           ; set flag for DEBUG.INC
***************
* TIMER4 = UART-Timer
* initialisieren
***************
contrl          equ %00011101   ; even par

IFND Baudrate
Baudrate        set 9615
ENDIF

prescale        set 125000/Baudrate-1

                echo "Baudrate : %DBaudrate"

****************
InitComLynx::
****************
                php
                sei
IFD DEBUG
                jsr InstallLoader
ENDIF

patch0          IF prescale<256
                lda #prescale
                sta $fd10
                lda #%00011000
                ELSE
                lda #prescale/2
                sta $fd10
                lda #%00011001
                ENDIF
                sta $fd11

                lda #contrl
                sta SerialContrl
                ora #$48
                sta $fd8c
                stz TxDone
                stz TxPtrIn
                stz TxPtrOut
                stz RxPtrIn
                stz RxPtrOut

.exit           SETIRQVEC 4,SerialIRQ
                plp
                rts
***************
SerialIRQ::
***************
                bit TxDone
                bmi .tx_irq
                ldx $fd8d
                lda $fd8c
                and #RxParityErr|RxOverrun|RxFrameErr|RxBreak
                beq .rx_irq
                tsb SerialStat  ; ev. Fehler merken
                bit #RxBreak
                beq .noBreak
                stz TxPtrIn
                stz TxPtrOut
                stz RxPtrIn
                stz RxPtrOut
.noBreak        lda #$48|contrl        ; RxIRQ setzen und Fehler loeschen
                sta $fd8c
                lda #$10
                sta $fd80
                END_IRQ

.rx_irq         lda #$48|contrl        ; RxIRQ setzen und Fehler loeschen
                sta $fd8c
                txa
IFD DEBUG
                jsr do_debug
                bcc .exit0
ENDIF
                ldx RxPtrIn
                sta RxBuffer,x
                txa
                inx

IF RxBufferSize<>256
                cpx #RxBufferSize
                bne .cont0
                ldx #0
ENDIF

.cont0          cpx RxPtrOut
                beq .1
                stx RxPtrIn
                lda #$10
                sta $fd80
                END_IRQ

.1              sta RxPtrIn
                lda #$80
                tsb SerialStat

.exit0
                lda #$10
                sta $fd80
                END_IRQ
***************
.tx_irq         ldx TxPtrOut
                cpx TxPtrIn
                beq .cont1

                lda TxBuffer,x
                sta $fd8d

IF TxBufferSize<>256
                inx
                cpx #TxBufferSize
                bne .cont2
                ldx #0
.cont2          stx TxPtrOut
ELSE
                inc TxPtrOut
ENDIF

.exit1          lda #$88|contrl
                sta $fd8c
                lda #$10
                sta $fd80
                END_IRQ

.cont1          lda $fd8c
                bit #$20
                beq .exit1
                bvs .exit1
                stz TxDone
                lda #$48|contrl
                sta $fd8c

                lda #$10
                sta $fd80
                END_IRQ
***************
RecComLynxByte::
***************
                phx
                ldx RxPtrOut
                cpx RxPtrIn
                beq .99
                lda RxBuffer,x
IF RxBufferSize<>256
                inx
                cpx #RxBufferSize
                bne .1
                ldx #0
.1              stx RxPtrOut
ELSE
                inc RxPtrOut
ENDIF
                plx
                sec
                rts
.99             plx
                clc
                rts
***************
SndComLynxByte::
***************
                phx
                ldx TxPtrIn
                sta TxBuffer,x
                inx
IF TxBufferSize<>256
                cpx #TxBufferSize
                bne .ok
                ldx #0
.ok
ENDIF
                cpx TxPtrOut
                beq .error
                stx TxPtrIn
                bit TxDone
                _IFPL
                  php
                  sei
                  lda #$88|contrl
                  sta $fd8c       ; TX-IRQ erlauben RX-IRQ sperren
                  sta TxDone
                  plp
                _ENDIF
                plx
                sec
                rts

.error          plx
                clc
                rts
***************
WaitComLynxByte::
***************
                stz SerialStat
.loop           jsr RecComLynxByte
                bcs .exit
                lda SerialStat
                beq .loop

.exit0          lda #0
                clc
.exit           rts

***************
TxStat::
* C = 0 => send buffer full
***************
                lda TxPtrIn
                cmp TxPtrOut
                beq .exit
                sec
.exit           rts

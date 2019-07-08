                db "SERIAL"
* SERIAL
* (c) 1993 Bastian Schick
*
* runs ok with 300/1200/2400/4800/9600/31250/62500 Baud
*
* 15.08.96      42BS            removed 'nonsense'-code
* 31.08.96      42BS            error in WaitComLynxByte
* 07.02.96      42BS            removed old stuff

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
                lda $fff9
                pha
                lda #$C
                sta $fff9                       ; enable RAM under the ROM

                ldx #LoaderLen-1                ; put Loader in the right place
.loop             lda _Loader,x
                  sta Loader,x
                  dex
                bpl .loop
                pla
                eor #$80
                sta $fff9
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

RxDone          ds 1

SerialIRQ::
***************
                bit TxDone
                bmi .tx_irq

                ldx $fd8d
                lda $fd8c
                and #RxParityErr|RxOverrun|RxFrameErr|RxBreak
                _IFNE
                  tsb SerialStat  ; ev. Fehler merken
                  bit #RxBreak
                  _IFNE
                    stz TxPtrIn
                    stz TxPtrOut
                    stz RxPtrIn
                    stz RxPtrOut
                  _ENDIF
                  lda #$48|contrl        ; RxIRQ setzen und Fehler l”schen
                  sta $fd8c
                  lda #$10
                  sta $fd80
                  END_IRQ
                _ENDIF

                txa
IFD DEBUG
                jsr do_debug
                bcc .exit0
ENDIF
                ldx RxDone
                bne .exit0

                ldx RxPtrIn
                _IFEQ
                  cmp #4
                  bne .exit0
                _ENDIF

                sta RxBuffer,x
                inx
                cpx RxBuffer
                _IFNE
                  stx RxPtrIn
                _ELSE
                  dec RxDone
                  stz RxPtrIn
                _ENDIF

.exit0          lda #$48|contrl        ; RxIRQ setzen und Fehler l”schen
                sta $fd8c
                lda #$10
                sta $fd80
                END_IRQ
*************** 
.tx_irq         ldx TxPtrOut
                inx
                cpx TxBuffer
                _IFNE
                  lda TxBuffer,x
                  sta $fd8d
                  stx TxPtrOut

.exit1            lda #$88|contrl
                  sta $fd8c
                  lda #$10
                  sta $fd80
                  END_IRQ
                _ELSE
                 lda $fd8c
                  bit #$20
                  beq .exit1
                  bvs .exit1
                  stz TxDone
                  lda #$48|contrl
                  sta $fd8c

                  lda #$10
                  sta $fd80
                  END_IRQ
                _ENDIF
****************
MsgSendMessage::
****************
                lda TxDone
                _IFEQ
                  stz TxPtrOut
                  lda TxBuffer
                  sta $fd8d
                  php
                  sei
                  lda #$88|contrl
                  sta $fd8c
                  sta TxDone
                  lda $fd8d
                  plp
                  sec
                _ELSE
                  clc
                _ENDIF
                rts


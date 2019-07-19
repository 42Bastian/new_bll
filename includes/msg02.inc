* -*-asm-*-
* MSG
* (c) 1997 Bastian Schick
*

MSG          equ 1           ; set flag for DEBUG.INC


UART_CONTROL          equ %00011101   ; even par

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

                lda #UART_CONTROL|$48
                sta $fd8c

                stz TxDone
                stz TxPtrOut

                stz RxDone
                stz RxPtrIn

                stz SerialStat

.exit           SETIRQVEC 4,SerialIRQ
                plp
                rts


***************
SerialIRQ::
***************
                ldx $fd8d
                lda $fd8c
                and #RxParityErr|RxOverrun|RxFrameErr|RxBreak
                _IFNE
                  tsb SerialStat  ; ev. Fehler merken
                  bit #RxBreak
                  _IFNE
                    stz TxPtrOut
                    stz RxPtrIn
                    stz TxDone
                    stz RxDone
                  _ENDIF
                  lda #$48|UART_CONTROL        ; RxIRQ setzen und Fehler l”schen
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
                  cmp #MSG_SIZE
                  bcs .exit0
                _ENDIF

                sta RxBuffer,x
                inx
                cpx RxBuffer
                _IFNE
                  stx RxPtrIn
                  cpx #MSG_SIZE+2
                  _IFEQ
                    stz RxDone
                    stz RxPtrIn
                    bra .exit0
                  _ENDIF
                _ELSE
                  dec RxDone
                  stz RxPtrIn
                  lda MsgReceivedHook
                  _IFNE
                    jsr .99
                  _ENDIF
                _ENDIF

.exit0          lda #$48|UART_CONTROL        ; RxIRQ setzen und Fehler l”schen
                sta $fd8c
                lda #$10
                sta $fd80
                END_IRQ


MsgReceivedHook dc.w 0
.99             jmp (MsgReceivedHook)
****************
MsgSendMessage::
****************
                _IFNE RxPtrIn
                  clc
                  rts
                _ENDIF

                lda #$8|UART_CONTROL
                sta $fd8c

                ldx #0
.0                lda $fd8c
                  bpl .0
                  lda TxBuffer,x
                  sta $fd8d
                  inx
                  cpx TxBuffer
                bne .0

                lda #$20
.1              bit $fd8c
                beq .1
.2              bit $fd8c
                bvc .3
                lda $fd8d
                bra .2
.3              stz RxPtrIn
                sec
                lda #$48|UART_CONTROL
                sta $fd8c
                rts

;>                lda TxDone
;>                _IFEQ
;>                  stz TxPtrOut
;>                  lda TxBuffer
;>                  sta $fd8d
;>                  php
;>                  sei
;>                  lda #$88|UART_CONTROL
;>                  sta $fd8c
;>                  sta TxDone
;>                  lda $fd8d
;>                  plp
;>                  sec
;>                _ELSE
;>                  clc
;>                _ENDIF
;>                rts

* -*-asm-*-
* MSG
* (c) 1997 Bastian Schick
*
* 97/08/13      42BS            commented-out all tx-irq stuff

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
;>    lda #prescale*20
;>    sta $fd00+SERIAL_TIMER*4
                lda #%00011000
                ELSE
                lda #prescale/2
                sta $fd10
                lda #%00011001
                ENDIF
                sta $fd11
;>    sta $fd01+SERIAL_TIMER*4

                lda #UART_CONTROL|$48
                sta $fd8c

;>                stz TxDone
;>                stz TxPtrOut

                stz RxDone
                stz RxPtrIn

                stz SerialStat

.exit           SETIRQVEC 4,SerialIRQ
;>                SETIRQVEC SERIAL_TIMER,Tx2RxIRQ
                plp
                rts


;>Tx2RxIRQ::      lda #$20
;>                bit $fd8c
;>                beq .99
;>                bvc .99
;>                lda $fd8d
;>                lda #$80
;>                trb $fd01+SERIAL_TIMER*4
;>                lda #$48|UART_CONTROL
;>                sta $fd8c
;>                stz TxDone
;>.99             END_IRQ
***************
SerialIRQ::
***************
;>                bit TxDone
;>                bmi .tx_irq

                ldx $fd8d       ; get byte
                lda $fd8c       ; get status
                and #RxParityErr|RxOverrun|RxFrameErr|RxBreak
                _IFNE
                  tsb SerialStat  ; save errors
                  bit #RxBreak
                  _IFNE
;>                    stz TxPtrOut
                    stz RxPtrIn
;>                    stz TxDone
                    stz RxDone
                  _ENDIF
                  lda #$48|UART_CONTROL
                  sta $fd8c
                  lda #$10
                  sta $fd80
                  END_IRQ
                _ENDIF

                txa             ; new byte in A
IFD DEBUG
                jsr do_debug
                bcc .exit0
ENDIF
                ldx RxDone      ; already received a message ?
                bne .exit0      ; oops, overrun

                ldx RxPtrIn     ; currently receiving a message ?
                _IFEQ           ; == 0 => no
                  cmp #MSG_SIZE+1; first byte is message-length
                  bge .exit0    ; too big => discard it
                _ENDIF

                sta RxBuffer,x  ; save current byte
                inx             ; prepare ptr
                cpx RxBuffer    ; was it the last one ?
                _IFNE
                  stx RxPtrIn   ; save ptr
                  cpx #MSG_SIZE+2
                  _IFEQ
                    stz RxDone
                    stz RxPtrIn
                    bra .exit0
                  _ENDIF
                _ELSE
                  dec RxDone    ; set flag
                  stz RxPtrIn   ; prepare for next message
                  lda MsgReceivedHook
                  _IFNE
                    jsr .99     ; eat the meal real hot
                  _ENDIF
                _ENDIF

.exit0          lda #$48|UART_CONTROL        ; RxIRQ setzen und Fehler l”schen
                sta $fd8c
                lda #$10
                sta $fd80
                END_IRQ


MsgReceivedHook dc.w 0
.99             jmp (MsgReceivedHook)
***************
;>.tx_irq         ldx TxPtrOut
;>                inx
;>                cpx TxBuffer
;>                _IFNE
;>                  lda TxBuffer,x
;>                  sta $fd8d
;>                  stx TxPtrOut
;>
;>.exit1            lda #$88|UART_CONTROL
;>                  sta $fd8c
;>                  lda #$10
;>                  sta $fd80
;>                  END_IRQ
;>                _ELSE
;>                  lda #prescale*25
;>                  sta $fd00+SERIAL_TIMER*4
;>                  lda #$80
;>                  tsb $fd01+SERIAL_TIMER*4
;>                  lda #$8|UART_CONTROL
;>                  sta $fd8c
;>
;>                  lda #$10
;>                  sta $fd80
;>                  END_IRQ
;>                _ENDIF
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
.0                lda TxBuffer,x
                  inx
.01               bit $fd8c
                  bpl .01
                  sta $fd8d
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

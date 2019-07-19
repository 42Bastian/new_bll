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

prescale_to     set prescale*11*MSG_SIZE        ; time-out

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
                  ldx #%00011000
                ELSE
                  lda #prescale/2
                  ldx #%00011001
                ENDIF
                sta $fd10
                stx $fd11

                IF prescale_to<256
                  lda #prescale_to
                  ldx #%10001100
                ELSE
                  lda #prescale_to/2
                  ldx #%10001101
                ENDIF
                sta $fd00+SERIAL_TIMER*4
                stx $fd01+SERIAL_TIMER*4

                lda #UART_CONTROL|$48
                sta $fd8c

                stz RxDone
                stz RxPtrIn

                stz SerialStat

.exit           SETIRQVEC 4,SerialIRQ
                SETIRQVEC SERIAL_TIMER,TimeOutIRQ
                plp
                rts

TimeOutIRQ::    _IFNE RxPtrIn
                  stz RxPtrIn
                  dec $fda0
                _ENDIF
                END_IRQ
***************
SerialIRQ::
***************
                ldx $fd8d       ; get byte
                lda $fd8c       ; get status
                and #RxParityErr|RxOverrun|RxFrameErr|RxBreak
                _IFNE
                  tsb SerialStat  ; save errors
                  stz RxPtrIn
                  stz RxDone

                  lda #$48|UART_CONTROL
                  sta $fd8c
                  lda #$10
                  sta $fd80
                  END_IRQ
                _ENDIF

                txa             ; new byte in A

                ldx RxDone      ; already received a message ?
                bne .exit0      ; oops, overrun

                ldx RxPtrIn     ; currently receiving a message ?
                _IFEQ           ; == 0 => no

IFD DEBUG
                  jsr do_debug
                  bcc .exit0
ENDIF

                  tax
                  beq .exit0    ; 0 => not valid
                  dex
                  beq .exit0    ; 1 => not valid
                  cmp #MSG_SIZE+1; first byte is message-length
                   le .exit0    ; too big => discard it

                  sta RxBuffer
                  inc RxPtrIn
                  lda #prescale_to
                  sta $fd02+4*SERIAL_TIMER
                  stz $fd03+4*SERIAL_TIMER
                  bra .exit0
                _ENDIF

                sta RxBuffer,x  ; save current byte
                inx             ; prepare ptr
                cpx RxBuffer    ; was it the last one ?
                _IFNE
                  stx RxPtrIn   ; save ptr
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
MsgSendMessage::
****************
                _IFNE RxPtrIn
                  clc
                  rts
                _ENDIF


                phy

                lda #$8|UART_CONTROL
                sta $fd8c

                ldx #0
                ldy TxBuffer
.0                lda TxBuffer,x
                  inx
.01               bit $fd8c
                  bpl .01
                  sta $fd8d
                  dey
                bne .0

                ply

                lda #$20
.1              bit $fd8c
                beq .1

.2              bit $fd8c
                bvc .3
                lda $fd8d
                bra .2

.3              lda #$48|UART_CONTROL
                sta $fd8c
                sec
                rts

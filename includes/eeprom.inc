* -*-asm-*-
****************
* EEPROM-routs
* for 93C46 (1024bit => 64 16-bit words)
*
* created : 11.05.95
* last modified :
*
* 16.02.96      leaner (thanks to Harry)
* 12.03.96      test for busy after write and erase (well, Harry ;)) )
* 11.01.99      new EEPROMs need DO to be set to 0 command write!
*
*
*
*
* (c) 1995 Bastian Schick
* CS    = A7 (18)
* CLK   = A1 (11)
* DI/DO = AUDIN (32)
*
*And now how to contact the EEPROM :
*
*CARD
*PORT               ----\/----      93C46(SMD too)
*(18)  A7   --------| CS     |- +5V
*(11)  A1   --------| CLK    |- NC
*               +---| DI     |- NC
*(32) AUDIN ----+---| DO     |- GND
*                   ----------
*
****************

* -------------------
* EEPROM command list
* -------------------
EE_C_WRITE      EQU    $40
EE_C_READ       EQU    $80
EE_C_ERASE      EQU    $C0
EE_C_EWEN       EQU    $30
EE_C_EWDS       EQU    $00


                MACRO EE_TOGGLE_CLK
                stz $fcb2
                stz $fcb2
                ENDM

                MACRO EE_SET_CS_HIGH            ; CS = 1
                ldx #63
.\ee1             stz $fcb2
                  stz $fcb2
                  dex
                bpl .\ee1
                ENDM

                MACRO EE_SET_CS_LOW             ; CS = 0 and CLK = 0
                ldx #3
                stx $fd87
                dex
                stx $fd87
                ENDM

****************
* read 16bit Wort from address A
****************
EE_Read::       and #$3f
                ora #EE_C_READ
                jsr EE_Send9Bit
;               jmp EE_Read16Bit                ; fall into
****************
* reads EEPROM-word to I2Cword
* A,Y destroyed
****************
EE_Read16Bit::
;               lda _IOdir
;               tax
;               eor #$10
                lda #$a
                sta $fd8A       ; set AUDIN to Input

                clc
                stz I2Cword
                stz I2Cword+1
                ldy #15
.loop           EE_TOGGLE_CLK   ; CLK = 1
                EE_TOGGLE_CLK   ; CLK = 0
                lda $fd8b
                and #$10        ; mask bit
                adc #$f0        ; C=1 if A=$10
                rol I2Cword
                rol I2Cword+1   ; shifts 0 to Carry
                dey
                bpl .loop

                ldx #$1a
                stx $fd8a       ; set AUDIN for output

                EE_SET_CS_LOW

                rts
****************
* clear word at address A
****************
EE_Erase::      pha
                lda #EE_C_EWEN  ; EWEN
                jsr EE_Send9Bit
                pla
                and #$3f
                ora #EE_C_ERASE ; clear cell A
                jsr EE_Send9Bit
                bra EE_wait
****************
* write word at address A
****************
EE_Write::      pha             ; save adress
                lda #EE_C_EWEN  ; EWEN
                jsr EE_Send9Bit
                pla
                and #$3f
                ora #EE_C_WRITE ; WRITE
                jsr EE_Send9Bit
                jsr EE_Send16Bit

EE_wait         EE_SET_CS_HIGH
                lda #$0A
                sta $fd8a       ; AUDIN to input
                lda #$10
.wait           bit $fd8b       ; 'til ready :D0-read is /D0-written
                beq .wait
                lda #$1a        ; AUDIN to output
                sta $fd8a

                lda #EE_C_EWDS  ; EWDS
;>                bra  EE_Send9Bit ; fall into
****************
* send A via I2C
* A,Y destroyed
****************
EE_Send9Bit::   EE_SET_CS_LOW   ; CLK = 0 / CS = 0
                EE_SET_CS_HIGH

                ldy #8
                sec             ; start bit
                ror
                ror
                ror
                ror             ; bit 8 at pos. 4
.loop            tax
                 and #$10
                 ora #$b
                 sta $fd8b
                 EE_TOGGLE_CLK  ; CLK = 1
                 EE_TOGGLE_CLK  ; CLK = 0
                 txa
                 rol
                 dey
                bpl .loop

                lda #$b
                sta $fd8b

                rts

****************
* send I2Cword to EEPROM
* A,Y detroyed
****************
EE_Send16Bit::  lda I2Cword
                pha
                lda I2Cword+1

                REPT 3
                ror
                ror I2Cword
                ENDR

                ldy #15
.loop            tax
                 and #$10
                 ora #$b
                 sta $fd8b
                 EE_TOGGLE_CLK  ; CLK = 1
                 EE_TOGGLE_CLK  ; CLK = 0
                 txa
                 rol I2Cword
                 rol
                 dey
                bpl .loop
                pla
                sta I2Cword

                EE_SET_CS_LOW

                lda #$b
                sta $fd8b

                rts

* -*-asm-*-
* FONT2.INC
*
* print a text as a sprite (proportional !)
*
* created : in some darker times , means (long) before Jaguar ;-)
*
* date          changes
* 26.07.96      comments to English
*               made something more elegant

***************
* InitFont
* init a Font
* IN : X font-number
*
* all registers saved
**************
InitFont::      pha
                phx
                phy
                stx CurrFntNr                   ; save font #
                lda FntAdrLo,x
                sta TextPtr
                lda FntAdrHi,x
                sta TextPtr+1                   ; ptr to font
                lda (TextPtr)                   ; line-offest (width of font-line)
                sta CurrLineOff
                ldy #1
                lda (TextPtr),y                 ; height of font
                sta CurrHeight
                iny
                lda (TextPtr),y                 ; first
                sta CurrFirst
                iny
                lda (TextPtr),y                 ; and last char. in this font
                sta CurrLast
                sec
                inc
                sbc CurrFirst
                tax                             ; => number of char.s

                clc
                lda #4
                adc TextPtr
                sta CurrLen
                lda TextPtr+1
                adc #0
                sta CurrLen+1                   ; ptr to length-table

                clc
                txa
                adc CurrLen
                sta CurrByteOff
                lda #0
                adc CurrLen+1
                sta CurrByteOff+1                ; ptr to byte-offset-table

                clc
                txa
                adc CurrByteOff
                sta CurrBitOff
                lda #0
                adc CurrByteOff+1
                sta CurrBitOff+1                 ; ptr to bit-offset-table

                clc
                txa
                adc CurrBitOff
                sta CurrFnt
                lda #0
                adc CurrBitOff+1
                sta CurrFnt+1                   ; ptr to packed font-data

                sec
                lda CurrLast
                sbc CurrFirst
                inc
                tay
                lda #0
.loop           cmp (CurrLen),Y
                bcs .cont
                lda (CurrLen),y
.cont           dey
                bpl .loop
                sta CurrBiggest                 ; find the widest char.
                ply
                plx
                pla
                rts
FntAdrLo        db <BigFnt,<SmallFnt,<LittleFnt,<SmallFnt2,<LittleFnt2
FntAdrHi        db >BigFnt,>SmallFnt,>LittleFnt,>SmallFnt2,>LittleFnt2
****************
* print
* convert a string into a sprite
* IN : X:Y points to a PCB
*
* all registers saved
****************
SpritePtr       equ TextPtr2
FontPtr         equ TextPtr3

print::         pha
                phx
                phy
                stx TextPtr2
                sty TextPtr2+1
                ldy #TextFont
                lda (TextPtr2),y
                cmp CurrFntNr                   ; font already initialised ?
                beq .ok                         ; yes =>
                tax
                jsr InitFont                    ; no, init. it
.ok             lda (TextPtr2)
                sta TextPtr
                ldy #TextData+1
                lda (TextPtr2),y
                sta TextPtr+1                   ; get the StringPtr
                ldy #TextBuffer
                lda (TextPtr2),y
                tax
                iny
                lda (TextPtr2),y
                stx SpritePtr
                sta SpritePtr+1                 ; get the SpriteDataPtr
.loopY0           lda CurrFnt
                  sta FontPtr
                  lda CurrFnt+1
                  sta FontPtr+1                 ; get ptr to pattern
                  lda CurrHeight                ; # of lines
                  sta Ycount
.loopY1             stz ByteCount
                    lda #8
                    sta _Bit                    ; which bit
                    ldy #0
.loopY2               lda (TextPtr),y           ; get character
                      beq .ok1                  ; zero => next line
                      cmp #13                   ; /n
                      beq .ok1                  ; yes => next line
                      cmp #$FF                  ; delemiter ?
                      beq .ok1                  ; yes => next line
                      jsr GetCharLineBytes      ; insert pattern
                      iny                       ; next char
                    bra .loopY2
.ok1                phy                         ; save char-ptr
                     ldy ByteCount              ; save the last bits
                     ldx _Bit                   ; how many bits (8-x)
                     lda Byte                   ; current byte
.loopShift             asl
                       dex
                     bne .loopShift             ; shift it to the top
                     iny                        ; at the end of the line
                     sta (SpritePtr),y
                     tya
                     inc
                     sta (SpritePtr)            ; insert data-length into sprite-data
                    ply                         ; get char-ptr back

                    clc                         ; advance sprite-ptr by A
                    adc SpritePtr
                    sta SpritePtr
                    bcc .1
                    inc SpritePtr+1
.1
                    clc                         ; advance font-ptr to the next font-line
                    lda CurrLineOff
                    adc FontPtr
                    sta FontPtr
                    bcc .2
                    inc FontPtr+1
.2
                    dec Ycount                  ; all lines ???
                  bne .loopY1                   ; no =>
                  lda (TextPtr),y               ; no more char.s in the string ?? EOL ??
                  beq .ok2                      ; zero => finish

                  tya                           ; set TextPtr to next line
                  sec
                  adc TextPtr                   ; TextPtr += Y+1
                  sta TextPtr
                  bcc .loopY0
                  inc TextPtr+1
                bra .loopY0                     ; and back

.ok2            lda #0
                sta (SpritePtr)                 ; set end of sprite
                ply                             ; restore the TextPtr
                plx
                stx TextPtr
                sty TextPtr+1
                phx
                phy
; FLIP-flags
                ldy #TextFlip
                lda (TextPtr),y
                iny
                ora #5
                sta (TextPtr),y                 ; SPRCTL0
; X-Y-coordinates
                ldy #TextXpos
                lda CurrX
                sta (TextPtr),y
                iny
                IF SCR_MAX_X>255
                  lda CurrX+1
                ELSE
                  lda #0
                ENDIF
                sta (TextPtr),y
                iny
                lda CurrY
                sta (TextPtr),y
                iny
                IF SCR_MAX_Y>255
                  lda CurrY+1
                ELSE
                  lda #0
                ENDIF
                sta (TextPtr),y
                ply
                plx
                pla
                rts                             ; ready
****************
* GetCharLineBytes
* insert pattern of the current char into the buffer
* IN : A character
*
* X,Y are saved
****************
GetCharLineBytes::
                phx
                phy
                sec
                sbc CurrFirst
                bcc .exit
                cmp CurrLast
                beq .ok
                bcs .exit
.ok             tay                             ; get char-offset
                lda (CurrLen),y                 ; get length
                cmp #2
                blt .exit                       ; <2 => ooops
                sta BitCount                    ; = # of bits
                lda (CurrBitOff),y
                tax                             ; start at bit X
                lda (CurrByteOff),y
                tay                             ; in byte Y
                lda (FontPtr),y                 ; get this byte
                sta FontBitBuffer
                iny
                lda (FontPtr),y                 ; and the next one
                sta FontBitBuffer+1
                iny
                lda (FontPtr),y
                bra ._11                        ; into loop
._01              asl
                  rol FontBitBuffer+1
                  rol FontBitBuffer
._11              dex
                bpl ._01                        ; shift the MSB to the top
                sta FontBitBuffer+2

                ldx BitCount                    ; how many bits ?
                lda _Bit                        ; # of bits inserted in the current byte (uff)
                ldy ByteCount                   ; ptr to the current sprite-data-pos
._02              asl FontBitBuffer+2
                  rol FontBitBuffer+1
                  rol FontBitBuffer             ; MSB => C
                  rol Byte                      ; C => current byte
                  dec                           ; 8 bits inserted ?
                  bne ._03                      ; no =>
                    lda Byte                    ; get the byte
                    iny
                    sta (SpritePtr),y           ; and put it into the sprite-data
                    lda #8                      ; again 8 bits
._03              dex                           ; next bit of the current pattern
                bne ._02
                sta _Bit                        ; save the current bit-pos
                sty ByteCount                   ; and byte pos
.exit           ply
                plx
                rts                             ; done ;-)

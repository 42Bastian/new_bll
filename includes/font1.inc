* FONT.INC
* created: ??.??.??
*
* date          change
* 25.07.96      comments in English
*               bug in BuildChar (better : bad programming ;-) )
*               also in CharOut
* 31.08.96      change in PrintChar (NewLine)
* 06.02.97      corrected ajust to adjust !
* 11.08.97      added global label CharSCB, to allow modification of the
*               Character SCB

***************
* init font 
* IN : X - font number
**************
InitFont::      pha
                phx
                phy
                lda FntAdrLo,x
                sta TextPtr
                lda FntAdrHi,x
                sta TextPtr+1
                lda (TextPtr)   ; line-offset
                sta CurrLineOff
                ldy #1
                lda (TextPtr),y ; char-height
                sta CurrHeight
                iny
                lda (TextPtr),y ; first
                sta CurrFirst
                iny
                lda (TextPtr),y ; and last char
                sta CurrLast
                sec
                inc
                sbc CurrFirst
                tax             ; # of chars
                clc
                lda #4
                adc TextPtr
                sta CurrLen
                lda TextPtr+1
                adc #0
                sta CurrLen+1   ; ptr to length-tabel
                clc
                txa
                adc CurrLen
                sta CurrByteOff
                lda #0
                adc CurrLen+1
                sta CurrByteOff+1 ; ptr to byte-offset-table
                clc
                txa
                adc CurrByteOff
                sta CurrBitOff
                lda #0
                adc CurrByteOff+1
                sta CurrBitOff+1 ; ptr to bit-offset-table
                clc
                txa
                adc CurrBitOff
                sta CurrFnt
                lda #0
                adc CurrBitOff+1
                sta CurrFnt+1   ; ptr to font-pattern
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
                sta CurrBiggest
                lda #1
                sta CurrSize
                ply
                plx
                pla
                rts
                
; see FONT.HLP
FntAdrLo        db <BigFnt,<SmallFnt,<LittleFnt,<SmallFnt2,<LittleFnt2
FntAdrHi        db >BigFnt,>SmallFnt,>LittleFnt,>SmallFnt2,>LittleFnt2
***************
* BuildChar
* draw a character as literal sprite
* IN : A   char
*      X,Y ptr where to save sprite-data
* A,X,Y are saved
***************
BuildChar::     pha
                phx
                phy
                stx TextPtr2
                sty TextPtr2+1
                cmp CurrLast
                bcc .cont
                beq .cont
.err_exit       lda #0          ; char not in font
                sta (TextPtr2)
                ply
                plx
                pla
                rts
                
.cont           sec
                sbc CurrFirst
                bcc .err_exit
                tay
                lda (CurrLen),y
                sta BitCounter
                lda CurrHeight
                sta LineCounter
                lda (CurrBitOff),y
                sta BitCounter2

                clc
                lda (CurrByteOff),Y
                adc CurrFnt
                sta TextPtr
                lda #0
                adc CurrFnt+1
                sta TextPtr+1   ; ptr to the first byte of the pattern
.loop0          lda (TextPtr)
                sta BitBuff
                ldy #1
                lda (TextPtr),y
                sta BitBuff+1
                iny
                lda (TextPtr),y

                ldx BitCounter2 ; ptr to the first bit in this byte
                beq .cont0
.loop2          ;clc
                ;rol             ; why didn't I use asl ??? ;-)
                asl             ; it works :-)
                rol BitBuff+1
                rol BitBuff
                dex
                bne .loop2      ; shift first bit to the top

.cont0          sta BitBuff+2
                lda BitCounter  ; width in bits
                
                clc
                adc #7
                lsr
                lsr
                lsr             ; width in bytes
                pha             ; save it

                inc             ; +1 to make Suzy happy
                sta (TextPtr2)
                ldy #1
                lda BitBuff
                sta (TextPtr2),y 
                iny
                lda BitBuff+1
                sta (TextPtr2),y
                iny
                lda BitBuff+2
                sta (TextPtr2),y
                ply             ; get back width in bytes
                lda BitCounter  ; get width in bits
                and #$7
                tax
                lda .maske,x    ; mask for the last byte
                and (TextPtr2),y
                sta (TextPtr2),y
                and #1
                _IFNE
                  lda (TextPtr2)
                  inc
                  sta (TextPtr2)
                  iny
                  lda #0
                  sta (TextPtr2),y
                _ENDIF
                tya             ; compute new ptr
                sec
                adc TextPtr2
                sta TextPtr2
                bcc .cont2
                inc TextPtr2+1
.cont2          clc             ; compute next pattern-line
                lda TextPtr
                adc CurrLineOff
                sta TextPtr
                bcc .cont23
                inc TextPtr+1
.cont23         dec LineCounter ; everything done ??
                bne .loop0
                lda #0
                sta (TextPtr2) ; EOS = EndOfSprite
                ply
                plx
                pla             ; restore registers
                rts
                
.maske          db $FF,$80,$C0,$E0,$F0,$F8,$FC,$FE
***************
* CharOut
* draw character (A) at X,Y (in pels)
***************
CharOut::       pha
                phx
                phy             ; save registers
                stx .CharX      ; position into SCB
                sty .CharY
                tay             ; save character
                bit Invers
                _IFPL
                  lda BG_Color
                  asl
                  asl
                  asl
                  asl
                  ora FG_Color    ; make color-index
                _ELSE
                  lda FG_Color
                  asl
                  asl
                  asl
                  asl
                  ora BG_Color
                _ENDIF

.cont           sta .CharCol    ; into SCB
                lda CurrSize    ; size
                sta .CharCurrSizeX+1 ; both x and y same size
                sta .CharCurrSizeY+1
                tya             ; restore character
                ldx #<.CharData
                ldy #>.CharData
                jsr BuildChar   ; create sprite-data

                lda #<.Char
                ldy #>.Char
                jsr DrawSprite  ; and draw it
                ply
                plx
                pla             ; restore all registers
                rts
CharSCB
.Char           db $05,$90,$00
                dw 0
                dw .CharData
.CharX          db 0,0
.CharY          db 0,0
.CharCurrSizeX  dw $100
.CharCurrSizeY  dw $100
.CharCol        db $00
.CharData       ds 60
***************
* print
* draw string at A:Y
* /0-terminated
***************
print::         pha
                phx
                phy
                sta TextPtr3
                sty TextPtr3+1  ; set ptr to string
                _SWITCH CurrAdjust
                _CASE #CENTER_ADJUST
                  jsr GetLen    ; compute total length
                  sta CurrX
                  sec
                  lda MaxX      ; upper X of the current window
                  inc
                  sbc MinX      ; - lower X of the current window => width
                  sec
                  sbc CurrX     ; - text-width
                  lsr           ; /2
                  clc
                  adc MinX
                  sta CurrX     ; start pos
                _CASE #RIGHT_ADJUST
                  jsr GetLen    ; length of text
                  sec
                  sbc MaxX      ; - rightest x
                  eor #$ff
                  inc           ; neg
                  sta CurrX     ; => start-pos
                _ENDS           ; uups, LEFT_ADJUST needs no computing ;-)
.loop1          lda (TextPtr3)  ; get character
                beq .cont2      ; =0 => EOString
                tay
                inc TextPtr3
                _IFEQ
                  inc TextPtr3+1
                _ENDIF
                tya
                jsr PrintChar   ; print it
                bra .loop1

.cont2          ply
                plx
                pla             ; restore all registers
                rts
**************
* PrintChar
* print character A at CurrX,CurrY 
* or do some action
**************
PrintChar::     _IFLO ,#" "     ; < " " ?
                  cmp #13
                  beq NewLine
;>                  _IFEQ ,#13    ; newline ?
;>                    lda MaxX
;>                    sta CurrX   ; set cursor at the very end of the window
;>                    rts
;>                  _ENDIF
                _ELSE
.cont             phy
                  phx
                  pha           ; save all
                  sec
                  sbc CurrFirst
                  tay           ; y = normalized character-number
                  lda CurrX
                  ldx CurrSize
.loop             clc
                  adc (CurrLen),y
                  dex
                  bne .loop     ; compute width of the char.
                  cmp MaxX      ; outside the window ?
                  bcc .cont2
                  beq .cont2    ; no =>
                  jsr NewLine   ; next line
                  
                  lda CurrX     ; compute pos. of the _next_ char
                  ldx CurrSize
.loop1            clc
                  adc (CurrLen),y
                  dex
                  bne .loop1
.cont2            ldx CurrX     ; get current cursor-x
                  sta CurrX     ; save next x
                  pla           ; get char
                  ldy CurrY     ; get y
                  jsr CharOut   ; draw it
                  plx
                  ply
                _ENDIF
                rts
**************
* NewLine
**************
NewLine::       pha
                phx
                ldx CurrSize
                inx
                lda CurrY
.loop           clc
                adc CurrHeight
                dex
                bne .loop       ; CurrY += CurrSize*CurrHeight
                cmp MaxY        ; out of Rosenheim ??
                blt .cont0      ; no =>
                lda MinY        ; ok, get on top
                clc
                adc CurrHeight
.cont0          sec
                sbc CurrHeight
                sta CurrY
                _SWITCH CurrAdjust ; see, if it's ok ?
                _CASE #CENTER_ADJUST
                  jsr GetLen
                  sta CurrX
                  sec
                  lda MaxX
                  inc
                  sbc MinX       
                  sec
                  sbc CurrX
                  lsr            
                  adc MinX
                _CASE #RIGHT_ADJUST
                  jsr GetLen
                  sec
                  sbc MaxX
                  eor #$FF
                  inc
                _ELSES
                  lda MinX
                _ENDS
                sta CurrX       ; new X pos
                plx
                pla
                rts
***************
* GetLen
* compute length of a string
* stops at zero or 13
*
* IN : TextPtr3
* OUT: A (length)
****************
GetLen::        phx
                phy
                ldy #0
                stz Laenge
                stz Laenge+1    ; clear length ( = Laenge ;-)
.loop           lda (TextPtr3),y ; get char.
                beq .exit       ; =0 => ready
                cmp #13
                beq .exit       ; /n => ready
                phy             ; save pos.
                sec
                sbc CurrFirst
                tay             ; offset
                ldx CurrSize    
.loop1          clc
                lda Laenge
                adc (CurrLen),y
                sta Laenge
                lda #0
                adc Laenge+1
                sta Laenge+1
                dex
                bne .loop1      ; Laenge = CurrLen[char]*CurrSize
                ply
                iny
                bra .loop       ; next one
                
.exit           sec
                lda MaxX
                sbc MinX
                inc
                ldx Laenge+1
                bne .cont       ; hell, more than 256 pixels =>
                cmp Laenge      ; width <= Laenge
                bcc .cont
                lda Laenge      ; return Laenge
.cont           ply
                plx
                rts
***************
                END


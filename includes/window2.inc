* letzte Žnderung : 20.6.95
* 20.6.95       Fehler in DrawSprite (SUZY-Busy)

IFD CLSuser
IFND cls
;***************
;* Bildschirm l”schen
;***************
cls::           pha
                phx
                phy
                stz $fc04
                stz $fc06
                sta .CLScolor
                lda #<.CLSscb
                ldy #>.CLSscb
                jsr DrawSprite
                SET_XY 0,0
                ply
                plx
                pla
                rts
.CLSscb         db $00,$10,00
                dw 0
                dw .CLSdata
                dw 0,0
                dw 10*$100,102*$100
.CLScolor       db $0F
.CLSdata        db 2,%01111100,0
ENDIF
ENDIF
;****************
;* Fenster ”ffnen
;****************
OpenWindow::    phx
                pha
                phy
                sta ptr
                sty ptr+1
                ldy #LCB.LEN
.loopOW         lda (ptr),y     ; x
                sta TempLCB,y
                dey
                bpl .loopOW
                ldy #WCBBorder
                lda (ptr),y
                sta TempLCB+LineColor ; Rahmenfarbe
                iny
                lda (ptr),y
                sta TempLCB+LineWidth
                jsr Rectangle0
                bra contCLW
;***************
;* Fenterinhalt l”schen
;***************
ClearWindow::   phx
                pha
                phy
                sta ptr
                sty ptr+1
contCLW         ldy #WCBCol
                lda (ptr),y
                sta TempLCB+LineColor
                sta BG_Color
                iny             ; WCBBorder
                iny             ; WSBW
                lda (ptr),y     ; Rahmen-Dicke in Pixels
                tax             ; merken
                clc
                adc (ptr)       ; WCBX
                sta TempLCB
                ldy #1
                IF SCR_MAX_X>255
                  lda #0
                  adc (ptr),y
                  sta TempLCB,y
                  iny
                ENDIF
                clc
                txa
                adc (ptr),y     ; WCBY
                sta TempLCB,y
                iny
                IF SCR_MAX_Y>255
                  lda #0
                  adc (ptr),y
                  sta TempLCB,y
                  iny
                ENDIF
                txa
                asl             ; * 2
                eor #$ff
                inc
                tax
                IF SCR_MAX_X>255
                  clc
                  adc (ptr),y
                  sta TempLCB,y
                  iny
                  lda #$ff
                  adc (ptr),y
                  sta TempLCB,y
                  iny
                else
                  clc
                  adc (ptr),y   ; - WCBW
                  sta TempLCB,y
                  iny
                ENDIF
                txa
                IF SCR_MAX_Y>255
                  clc
                  adc (ptr),y
                  sta TempLCB,y
                  iny
                  lda #$ff
                  adc (ptr),y
                  sta TempLCB,y
                ELSE
                  clc
                  adc (ptr),y
                  sta TempLCB,y
                ENDIF
                lda #<TempLCB
                ldy #>TempLCB
                jsr DrawBox
                lda TempLCB+LineX
                sta MinX
                sta CurrX
                IF SCR_MAX_X>255
                  clc
                  adc TempLCB+LineW
                  sta MaxX
                  lda TempLCB+LineX+1
                  sta MinX+1
                  sta CurrX+1
                  adc TempLCB+LineW+1
                  sta MaxX+1
                ELSE
                  clc
                  adc TempLCB+LineW
                  dec
                  sta MaxX
                ENDIF
                lda TempLCB+LineY
                sta MinY
                sta CurrY
                IF SCR_MAX_Y>255
                  clc
                  adc TempLCB+LineH
                  sta MaxY
                  lda TempLCB+LineY+1
                  sta MinY+1
                  sta CurrY+1
                  adc TempLCB+LineH+1
                  sta MaxY+1
                ELSE
                  clc
                  adc TempLCB+LineH
                  dec
                  sta MaxY
                ENDIF
                ply
                pla
                plx
                rts
;***************
;* zeichnet Rechteck
;* A:Y : Zeiger auf LCB
;***************
Rectangle0::    pha
                phy
                bra .rect_cont
Rectangle       pha
                phy
                sta ptr2
                sty ptr2+1
                ldy #LCB.LEN-1
.loopR          lda (ptr2),y
                sta TempLCB,y
                dey
                bpl .loopR
.rect_cont      lda #TempLCB
                sta ptr2
                stz ptr2+1
                lda TempLCB+LineH
                sta TempVal
                lda TempLCB+LineWidth
                sta TempLCB+LineH
                IF SCR_MAX_Y>255
                  lda TempLCB+LineH+1
                  sta TempVal+1
                  stz TempLCB+LineH+1
                ENDIF
                jsr DrawBox0
                clc
                lda TempLCB+LineY
                sta TempVal2    ; alte Y-Koordinate merken
                adc TempVal
                sta TempLCB+LineY
                IF SCR_MAX_Y>255
                  lda TempLCB+LineY+1
                  sta TempVal2+1
                  adc TempVal+1
                  sta TempLCB+LineY+1
                  sec
                  lda TempLCB+LineY
                  sbc TempLCB+LineWidth
                  sta TempLCB+LineY
                  lda TempLCB+LineY+1
                  sbc #0
                  sta TempLCB+LineY+1
                ELSE
                  sec
                  lda TempLCB+LineY
                  sbc TempLCB+LineWidth
                  sta TempLCB+LineY
                ENDIF
                jsr DrawBox0    ; unten
                lda TempVal
                sta TempLCB+LineH
                lda TempVal2
                sta TempLCB+LineY
                if SCR_MAX_Y>255
                  lda TempVal+1
                  sta TempLCB+LineH+1
                  lda TempVal2+1
                  sta TempLCB+LineY+1
                ENDIF
;******
                lda TempLCB+LineW
                sta TempVal
                lda TempLCB+LineWidth
                sta TempLCB+LineW
                IF SCR_MAX_X>255
                  lda TempLCB+LineW+1
                  sta TempVal+1
                  stz TempLCB+LineW+1
                ENDIF
                jsr DrawBox0
                clc
                lda TempLCB+LineX
                sta TempVal2    ; alte X-Koordinate merken
                adc TempVal
                sta TempLCB+LineX
                IF SCR_MAX_X>255
                  lda TempLCB+LineX+1
                  sta TempVal2+1
                  adc TempVal+1
                  sta TempLCB+LineX+1
                  sec
                  lda TempLCB+LineX
                  sbc TempLCB+LineWidth
                  sta TempLCB+LineX
                  lda TempLCB+LineX+1
                  sbc #0
                  sta TempLCB+LineX+1
                ELSE
                  sec
                  lda TempLCB+LineX
                  sbc TempLCB+LineWidth
                  sta TempLCB+LineX
                ENDIF
                jsr DrawBox0    ; unten
                ply
                pla
                rts
;**************
;* zeichnet horizontale Linie
;* A:Y : Zeiger auf LCB
;***************
LineHo::        pha
                phy
                sta ptr2
                sty ptr2+1
                ldy #LineWidth
                lda (ptr2),y
                ldy #LineH
                sta (ptr2),y
                IF SCR_MAX_Y>255
                  iny
                  lda #0
                  sta (ptr2),y
                ENDIF
                bra DrawBoxCont ; Box mit H”he 1
;**************
;* zeichnet vertikale Linie
;* A:Y : Zeiger auf LCB
;***************
LineVe::        pha
                phy
                sta ptr2
                sty ptr2+1
                ldy #LineWidth
                lda (ptr2),y
                ldy #LineW
                sta (ptr2),y
                IF SCR_MAX_X>255
                  iny
                  lda #0
                  sta (ptr2),y
                ENDIF
                bra DrawBoxCont ; Box mit H”he 1
IFD PlotUser
;**************
;* zeichnet einzelne Punkt
;* A:Y : Zeiger auf LCB
;***************
Plot::          pha
                phy
                sta ptr2
                sty ptr2+1
                ldy #LineW
                lda #1
                sta (ptr2),y
                ldy #LineH
                sta (ptr2),y
                bra DrawBoxCont ; Box mit H”he 1
ENDIF
;***************
;* DrawBox
;* Zeichnet ausgeflltes Rechteck
;* A:Y => LCB
;***************
DrawBox0::      pha
                phy
                bra DrawBoxCont
DrawBox::       pha
                phy
                sta ptr2
                sty ptr2+1
DrawBoxCont     lda (ptr2)
                sta BSX
                ldy #1
                IF SCR_MAX_X>255
                  lda (ptr2),y
                  sta BSX+1
                  iny
                ENDIF
                lda (ptr2),y
                sta BSY
                iny
                if SCR_MAX_Y>255
                  lda (ptr2),y
                  sta BSY+1
                  iny
                ENDIF
                lda (ptr2),y    ; Breite
                iny
                IF SCR_MAX_X>255
                  sta BSXsize
                  lda (ptr2),y  ; lo-Byte
                  iny
                  STA BSXsize+1
                  lda #0
                  lsr BSXsize+1
                  ror BSXsize
                  ror
                  tax
                  lda BSXsize
                  sta BSXsize+1
                  stx BSXsize
                ELSE
                  lsr
                  sta BSXsize+1
                  lda #0
                  ror
                  sta BSXsize
                ENDIF
                lda (ptr2),y    ; H”he
                iny
                IF SCR_MAX_Y>255
                  sta BSYsize
                  lda (ptr2),y  ; lo-Byte
                  iny
                  STA BSYsize+1
                  lda #0
                  lsr BSYsize+1
                  ror BSYsize
                  ror
                  tax
                  lda BSYsize
                  sta BSYsize+1
                  stx BSYsize
                ELSE
                  lsr
                  sta BSYsize+1
                  lda #0
                  ror
                  sta BSYsize
                ENDIF
                lda (ptr2),y
                and #$0f
                sta BScol
                lda #<BS
                ldy #>BS
                jsr DrawSprite
                ply
                pla
                rts
                db 00
BS              db $c5,$90,01
                dw 0
                dw BSpixel
BSX             dw 0
BSY             dw 0
BSXsize         dw 0
BSYsize         dw 0
BScol           db 0
BSpixel         db 3,$11,$00,3,$11,$00,0
IFND DrawSprite
***************
* draw a single Sprite
***************
DrawSprite::    pha
                sta $fc10
                sty $fc11
                MOVE ScreenBase,$fc08
                lda #1
                STA $FC91
                STZ $FD90
.WAIT           STZ $FD91
                lda $fc92
                lsr
                bcs .WAIT
                STZ $FD90
                pla
                rts
endif

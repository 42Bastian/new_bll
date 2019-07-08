****************
SndInit::
                php
                sei
                lda #%10011000|_31250Hz
                sta $fd01+SND_TIMER*4
                lda #129
                sta $fd00+SND_TIMER*4           ; set up a 240Hz IRQ
                SETIRQVEC SND_TIMER,SndIRQ

                stz $fd20
                stz $fd28
                stz $fd30
                stz $fd38       ; all volumes zero

                stz $fd44       ; all channels full volume
                lda #$ff
                stz $fd50       ; channels on

                lda #%01011000
                sta $fd20+5
                sta $fd28+5
                sta $fd30+5
                sta $fd38+5

                ldx #3
                lda #0
.0                stz SndActive,x
                  stz SndReqStop,x
                  stz SndEnvVol,x
                  stz SndEnvFrq,x
;>                  stz SndEnvPly,x
                  ldy SndOffsets,x
                  sta SndChannel+2,y
                  dex
                bpl .0
                stz SndSema
                plp
                rts

SndOffsets      dc.b $00,$08,$10,$18

****************
SndIRQ::
 inc t1
 lda t1
 cmp #250
 _IFEQ
 inc t2
 stz t1
 _ENDIF

                lda #$ff
                tsb SndSema
                _IFNE
                  dec $fda0
                  END_IRQ
                _ENDIF
                phy
                jsr SndSetValues
                cli
                ldx #3
.0                phx
                  lda SndActive,x
                  _IFNE
                    _IFNE {SndEnvVol,x}
                      phx
                      jsr SndChangeVol
                      plx
                    _ENDIF
                    _IFNE {SndEnvFrq,x}
                      phx
                      jsr SndChangeFrq
                      plx
                    _ENDIF
                    jsr SndGetCmd
                  _ENDIF
                  plx
                  dex
                bpl .0
                sei
                ply
                stz SndSema
                END_IRQ


****************
* SndGetCmd
SndGetCmd::
                dec SndDelay,x
                bne .99

                lda SndReqStop,x
                bne SndStop

;>                _IFNE {SndReqStop,x}
;>                  stz SndActive,x
;>                  rts
;>                _ENDIF

                lda SndPtrLo,x
                sta SndPtrTmp
                lda SndPtrHi,x
                sta SndPtrTmp+1

.0              lda (SndPtrTmp)
                beq SndStop
                _IFMI
                  and #$7f
                  tay
                  jsr SndCallCmd
                _ELSE
                  jsr SndNewNote
                _ENDIF

                clc
                tya
                and #$7f
                adc SndPtrTmp
                sta SndPtrLo,x
                sta SndPtrTmp
                lda #0
                adc SndPtrTmp+1
                sta SndPtrHi,x
                sta SndPtrTmp+1

                tya
                bmi .0
.99             rts

SndCallCmd::    lda SndCmdsHi,y
                pha
                lda SndCmdsLo,y
                pha
                ldy #1
                rts
*
SndStop::
                stz SndReqStop,x
                stz SndActive,x
                ldy SndOffsets,x
                lda #0
                sta SndChannel,y
                lda #1
                sta SndChannel+2,y
                ldy #1
                rts
*
SndNewNote::
; Note,length,volume

                phx
                  sta SndNotePlaying,x
                  pha
                  ldy #1
                  lda (SndPtrTmp),y         ; laenge
                  sta SndDelay,x

                  ldy SndOffsets,x
;>                  _IFEQ {SndEnvVol,x}
                  lda SndVolume,x
;>                  _ELSE
;>                    lda #0
;>                  _ENDIF
                  sta SndChannel,y
                  plx
                  lda SndPrescaler,x
                  sta SndChannel+5,y
                  lda SndReload,x
                  sta SndChannel+4,y
                  lda #-1
                  sta SndChannel+2,y
                plx
                _IFNE {SndEnvVol,x}
                  jsr SndSetEnvVol1
                _ENDIF
                _IFNE {SndEnvFrq,x}
                  jsr SndSetEnvFrq1
                _ENDIF
                ldy #$2
;>                dec SndNotePlaying,x
;>                ldy #$81
                rts
*
SndLoop::
                lda (SndPtrTmp),y
                sta SndLoopCnt,x
                lda SndPtrTmp
                sta SndLoopPtrLo,x
                lda SndPtrTmp+1
                sta SndLoopPtrHi,x
                ldy #$82
                rts
*
SndDo::
                dec SndLoopCnt,x
                _IFNE
                  lda SndLoopPtrLo,x
                  sta SndPtrTmp
                  lda SndLoopPtrHi,x
                  sta SndPtrTmp+1
                  ldy #$82
                _ELSE
                  ldy #$81
                _ENDIF
                rts
*
SndDefEnvVol::
*
                phx
                lda (SndPtrTmp),y               ; env #
                tax

                iny
                lda (SndPtrTmp),y
                sta SndEnvVolPtrLo,x
                iny
                lda (SndPtrTmp),y
                sta SndEnvVolPtrHi,x            ; Ptr to [cnt,inc]

                ldy #$84
                plx
                rts
*
SndSetEnvVol::
                lda (SndPtrTmp),y               ; # env

SndSetEnvVol1   and #$7f
                sta SndEnvVol,x                 ; save
                _IFEQ
                  ldy #$82
                  rts
                _ENDIF

                tay

                lda SndEnvVolPtrLo,y
                sta SndEnvPtr
                lda SndEnvVolPtrHi,y
                sta SndEnvPtr+1

                lda (SndEnvPtr)
                sta SndTmp
                asl
                sta SndEnvVolLoop,x             ; here is the loop-start

                ldy #1
                lda (SndEnvPtr),y
                sta SndEnvVolParts,x
                sec
                sbc SndTmp
                sta SndEnvVolParts2,x

                stz SndEnvVolCnt,x
                lda #2
                sta SndEnvVolOff,x

                ldy #$82
                rts
*
SndDefEnvFrq::
*
                phx
                lda (SndPtrTmp),y               ; env #
                tax

                iny
                lda (SndPtrTmp),y
                sta SndEnvFrqPtrLo,x
                iny
                lda (SndPtrTmp),y
                sta SndEnvFrqPtrHi,x            ; Ptr to [inc,cnt]
                plx
                ldy #$84
                rts
*
SndSetEnvFrq::
                lda (SndPtrTmp),y               ; # env

SndSetEnvFrq1   and #$7f
                sta SndEnvFrq,x                 ; save
                _IFEQ
                  ldy #$82
                  rts
                _ENDIF

                tay

                lda SndEnvFrqPtrLo,y
                sta SndEnvPtr
                lda SndEnvFrqPtrHi,y
                sta SndEnvPtr+1

                lda (SndEnvPtr)
                sta SndTmp
                asl
                sta SndEnvFrqLoop,x

                ldy #1
                lda (SndEnvPtr),y
                sta SndEnvFrqParts,x
                sec
                sbc SndTmp
                sta SndEnvFrqParts2,x

                stz SndEnvFrqCnt,x
                lda #2
                sta SndEnvFrqOff,x

                ldy #$82
                rts

*
SndPause::
                lda (SndPtrTmp),y
                sta SndDelay,x
                iny
SndDummy        rts
*
SndNoteOff::
                ldy SndOffsets,x
                stz SndNotePlaying,x
                lda SndEnvVol,x
                ora #$80
                sta SndEnvVol,x
                lda SndEnvFrq,x
                ora #$80
                sta SndEnvFrq,x
                lda #0
                sta SndChannel,y
                sta SndChannel+4,y
                sta SndChannel+5,y
                dec
                sta SndChannel+2,y
                ldy #$81
                rts
*
SndSetInstr::
                phx
                lda SndOffsets,x
                tax
                lda (SndPtrTmp),y
                sta SndChannel+3,x
                iny
                lda (SndPtrTmp),y
                sta SndChannel+7,x
                iny
                lda (SndPtrTmp),y
                sta SndChannel+1,x
                plx
                iny
                lda (SndPtrTmp),y
                sta SndVolume,x
                iny
                lda (SndPtrTmp),y
                sta SndMaxVolume,x

                ldy #$86
                rts
*
SndCallPattern::
                clc
                lda SndPtrTmp
                adc #3
                sta SndRetAddr,x
                lda SndPtrTmp+1
                adc #0
                sta SndRetAddr+4,x
                ldy #1
                lda (SndPtrTmp),y
                pha
                iny
                lda (SndPtrTmp),y
                sta SndPtrTmp+1
                pla
                sta SndPtrTmp
                ldy #$80
                rts
*
SndRetToSong::
                lda SndRetAddr,x
                sta SndPtrTmp
                lda SndRetAddr+4,x
                sta SndPtrTmp+1
                ldy #$80
                rts
*
SndNewNote2::
; Note,length,volume

                phx
                  sta SndNotePlaying,x
                  ldy #1
                  lda (SndPtrTmp),y             ; reload
                  pha
                  iny
                  lda (SndPtrTmp),y             ; prescale
                  pha
                  iny
                  lda (SndPtrTmp),y         ; laenge
                  sta SndDelay,x

                  ldy SndOffsets,x
                  lda SndVolume,x
                  sta SndChannel,y
                  pla
                  sta SndChannel+5,y
                  pla
                  sta SndChannel+4,y
                  lda #-1
                  sta SndChannel+2,y
                plx
                _IFNE {SndEnvVol,x}
                  jsr SndSetEnvVol1
                _ENDIF
                _IFNE {SndEnvFrq,x}
                  jsr SndSetEnvFrq1
                _ENDIF
                ldy #4
                rts


****************
                MACRO LO
                dc.b <((\0)-1)
                ENDM

                MACRO HI
                dc.b >((\0)-1)
                ENDM

SndCmdsLo::     LO SndLoop              ; count
                LO SndDo
                LO SndPause             ; count
                LO SndNoteOff
                LO SndSetInstr          ; shiferinit1,shifterinit2,feedback
                LO SndNewNote2             ;
                LO SndCallPattern           ; SndCallSubr
                LO SndRetToSong             ; SndRetSubr

                LO SndDefEnvVol
                LO SndSetEnvVol
                LO SndDefEnvFrq
                LO SndSetEnvFrq
                LO SndDummy             ; SndDefEnvFbk
                LO SndDummy             ; SndSetEnvFbk


SndCmdsHi::
                HI SndLoop
                HI SndDo
                HI SndPause
                HI SndNoteOff
                HI SndSetInstr
                HI SndNewNote2
                HI SndCallPattern           ; SndCallSubr
                HI SndRetToSong             ; SndRetSubr

                HI SndDefEnvVol
                HI SndSetEnvVol
                HI SndDefEnvFrq
                HI SndSetEnvFrq
                HI SndDummy             ; SndDefEnvFbk

*
SndChangeVol::
                tay
                _IFMI
.99               rts
                _ENDIF
                lda SndNotePlaying,x
                beq .99

                lda SndEnvVolPtrLo,y
                sta SndEnvPtr
                lda SndEnvVolPtrHi,y
                sta SndEnvPtr+1

                dec SndEnvVolCnt,x
                _IFMI
                  dec SndEnvVolParts,x
                  _IFMI
                    _IFNE {SndEnvVolLoop,x}
                      tay
                      lda SndEnvVolParts2,x
                      sta SndEnvVolParts,x
                      bra .1
                    _ELSE
                      tya
                      ora #$80
                      sta SndEnvVol,x
                    _ENDIF
                  _ELSE
                    ldy SndEnvVolOff,x
.1                  lda (SndEnvPtr),y
                    sta SndEnvVolCnt,x
                    iny
                    lda (SndEnvPtr),y
                    sta SndEnvVolInc,x
                    iny
                    tya
                    sta SndEnvVolOff,x
                  _ENDIF
                _ELSE
                  ldy SndOffsets,x
                  clc
                  lda SndEnvVolInc,x
                  _IFEQ
                    rts
                  _ENDIF
                  _IFPL
                    adc SndChannel,y
                    cmp SndMaxVolume,x
                    _IFCS
                      lda SndMaxVolume,x
                      stz SndEnvVolInc,x
                    _ENDIF
                    cmp #$80
                    _IFGE
                      lda #$7f
                      stz SndEnvVolInc,x
                    _ENDIF
                 _ELSE
                   adc SndChannel,y
                   _IFCC
                     lda #0
                     stz SndEnvVolInc,x
                   _ENDIF
                   cmp #$80
                   _IFGE
                     lda #0
                     stz SndEnvVolInc,x
                   _ENDIF
                 _ENDIF
                  sta SndChannel,y
                  lda #1
                  sta SndChannel+2,y
                _ENDIF
                rts

*
SndChangeFrq::
                tay
                _IFMI
.99               rts
                _ENDIF
                lda SndNotePlaying,x
                beq .99

                lda SndEnvFrqPtrLo,y
                sta SndEnvPtr
                lda SndEnvFrqPtrHi,y
                sta SndEnvPtr+1

                dec SndEnvFrqCnt,x
                _IFMI
                  dec SndEnvFrqParts,x
                  _IFMI
                    _IFNE {SndEnvFrqLoop,x}
                      tay
                      lda SndEnvFrqParts2,x
                      sta SndEnvFrqParts,x
                      bra .1
                    _ELSE
                      tya
                      ora #$80
                      sta SndEnvFrq,x
                      rts
                    _ENDIF
                  _ELSE
                    ldy SndEnvFrqOff,x
.1                  lda (SndEnvPtr),y
                    sta SndEnvFrqCnt,x
                    iny
                    lda (SndEnvPtr),y
                    eor #$ff
                    inc
                    sta SndEnvFrqInc,x
                    iny
                    tya
                    sta SndEnvFrqOff,x
                  _ENDIF
                  rts
                _ENDIF

                  phy
                  ldy SndOffsets,x

                  lda SndEnvFrqInc,x
                  _IFEQ
                    ply
                    rts
                  _ENDIF

                  clc
                  _IFMI
                    adc SndChannel+4,y
                    _IFPL
                      pha
                      lda SndChannel+5,y
                      _IFNE
                        dec
                        sta SndChannel+5,y
                        pla
                        eor #128
                      _ELSE
                        pla
                        pha
                        clc
                        adc SndEnvFrqInc,x
                        _IFCC
                          lda #0
                          sta SndEnvFrqInc,x
                        _ENDIF
                        pla
                      _ENDIF
                    _ELSE
                      pha
                      lda SndChannel+5,y
                      _IFEQ
                        pla
                        lda #0
                        sta SndEnvFrqInc,x
                        lda SndChannel+4,y
                        ply
                        rts
                      _ENDIF
                      pla
                    _ENDIF
                  _ELSE
                    adc SndChannel+4,y
                    _IFPL
                      pha
                      lda SndChannel+5,y
                      cmp #6
                      _IFNE
                        inc
                        sta SndChannel+5,y
                        pla
                        eor #128
                      _ELSE
                        lda SndChannel+4,y
                        _IFMI
                          lda #0
                          sta SndEnvFrqInc,x
                          pla
                          ply
                          rts
                        _ENDIF
                        pla
                      _ENDIF
                    _ELSE
                      pha
                      lda SndChannel+5,y
                      cmp #6
                      _IFEQ
                        lda SndChannel+4,y
                        _IFPL
                          lda #0
                          sta SndEnvFrqInc,x
                          pla
                          ply
                          rts
                        _ENDIF
                      _ENDIF
                      pla
                    _ENDIF
                  _ENDIF
                  sta SndChannel+4,y

                  lda #1
                  sta SndChannel+2,y
                  ply
                rts

*
***************
* SndSetValues
* set new values for all channels

SndSetValues::
                ldx #4-1
.0                ldy SndOffsets,x
                  lda SndChannel+2,y
                  beq .1                        ; flag == 0 => don`t set
;>                    lda $fd25,y
;>                    and #$ef
;>                    sta $fd25,y

                    _IFMI                       ;
                      lda #0
                      sta $fd25,y                 ; stop sound timer
                      lda SndChannel+3,y
                      sta $fd23,y                 ; shifter 1
                      lda $fd27,y
                      and #$f
                      ora SndChannel+7,y          ; shifter 2
                      sta $fd27,y
                      lda SndChannel+1,y
                      sta $fd21,y                 ; feedback
                    _ENDIF
                    lda #0
                    sta SndChannel+2,y          ; clear flag

                    lda SndChannel+4,y
                    sta $fd24,y                 ; reload
                    lda SndChannel+5,y
                    ora #%01011000
                    sta $fd25,y                 ; re-enable timer
                    lda SndChannel,y
                    sta $fd20,y                 ; volume


.1                dex
                bpl .0
                rts
****************
SndStartSound::
*
                php
                pha
                _IFNE {SndActive,x}
                  dec SndReqStop,x
                  lda #1
                  sta SndDelay,x
.0                lda SndActive,x
                  bne .0
                _ENDIF
                bra .1
SndStartSoundx
                php
                pha

.1              sei
                pla
                sta SndPtrLo,x
                tya
                sta SndPtrHi,x
                lda #1
                sta SndDelay,x
                stz SndEnvVol,x
                stz SndEnvFrq,x
;>                stz SndEnvPly,x
                sta SndActive,x
                stz SndReqStop,x
                plp
                rts

****************
SndStartSound2::
* x - default channel
* search for a free channel, if found use it
* else use default
                pha

                lda SndActive,x         ; check default
                beq .0                  ; inactive => ok
                phx
                ldx #3                  ; search free channel
.1                lda SndActive,x
                  beq .2                ; found =>
                  dex
                bpl .1
                plx                     ; not found
                dec SndReqStop,x        ; stop default-channel
                lda #1
                sta SndDelay,x
.3                lda SndActive,x
                bne .3
                bra .0
.2              pla             ; clear stack

.0              pla
                phx
                jsr SndStartSoundx      ; launch new sound
                plx
                rts
****************
SndStopAll::
                ldx #3
                  _IFNE {SndActive,x}
.0                  dec SndReqStop,x
                    lda #1
                    sta SndDelay,x
.1                  lda SndActive,x
                    bne .1
                  _ENDIF
                  dex
                bpl .0
                rts
****************
SndStopChannel::
                _IFNE {SndActive,x}
                  dec SndReqStop,x
                  lda #1
                  sta SndDelay,x
.1                lda SndActive,x
                  bne .1
                _ENDIF
                rts
*****************
SndChannelsActive::
                ldx #3
                lda #0
.0                ldy SndActive,x
                  _IFNE
                    ora SndMask,x
                  _ENDIF
                  dex
                bpl .0
                rts

SndMask::       dc.b 1,2,4,8
*****************
SndPauseOn::    php
                sei
                lda $fd01+SND_TIMER*4
                sta SndPauseOff1+1
                stz $fd01+SND_TIMER*4
                lda $fd50
                sta SndPauseOff2+1
                lda #$ff
                sta $fd50
                lda #$18
                trb $fd25
                trb $fd25+8
                trb $fd25+16
                trb $fd25+24
                plp
                rts

SndPauseOff::   php
                sei
SndPauseOff1    lda #0
                sta $fd01+SND_TIMER*4
SndPauseOff2    lda #0
                sta $fd50

                lda #$18
                tsb $fd25
                tsb $fd25+8
                tsb $fd25+16
                tsb $fd25+24

                plp
                rts

SndPrescaler:
                DC.B $00,$06,$06,$06,$06,$05,$05,$05,$05,$05,$05,$05,$04,$04,$04,$04
                DC.B $04,$04,$04,$04,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02
                DC.B $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01
                DC.B $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00
                DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
SndReload:
                DC.B $00,$9A,$96,$8F,$86,$FA,$E5,$D1,$BE,$AC,$9C,$8D,$00,$E8,$D3,$C0
                DC.B $AF,$A0,$93,$87,$FA,$E7,$D6,$C6,$B8,$AC,$A1,$96,$8D,$84,$FA,$EB
                DC.B $DE,$D2,$C7,$BC,$B3,$AA,$A1,$9A,$93,$8C,$86,$00,$F5,$EB,$E1,$D8
                DC.B $CF,$C7,$C0,$B9,$B2,$AB,$A5,$A0,$9A,$95,$90,$8B,$87,$82,$FD,$F5
                DC.B $EE,$E7,$E0,$D9,$D3,$CD,$C8,$C2,$BD,$B8,$B3,$AE,$AA,$A5,$A1,$9D
                DC.B $99,$96,$92,$8F,$8B,$88,$85,$82,$7F,$7C,$79,$77,$74,$72,$6F,$6D
                DC.B $6B,$69,$67,$64,$63,$61,$5F,$5D,$5B,$59,$58,$56,$55,$53,$51,$50
                DC.B $4F,$4D,$4C,$4B,$49,$48,$47,$46,$44,$43,$42,$41,$40,$3F,$3E,$3D


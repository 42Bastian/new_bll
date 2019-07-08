* 1000Hz-Timer
*
* 26.03.97      removed VBL-stuff
*               select Timer by main (set _1000HZ_TIMER)

Init1000Hz::    php
                sei
                lda #249
                sta $fd00+_1000HZ_TIMER*4
                lda #%10011010  ; 250KHz
                sta $fd01+_1000HZ_TIMER*4
                lda #$ff-$e8
                sta milli
                lda #$ff-3
                sta milli+1
                stz _1000Hz
                stz _1000Hz+1
                stz _1000Hz+2
                SETIRQVEC _1000HZ_TIMER,_1000HzIRQ
                plp
                rts
;***************
;* Millisekunden-Timer
;***************
_1000HzIRQ::    inc _1000Hz
                bne .cont       
                inc _1000Hz+1
                bne .cont
                inc _1000Hz+2
                
.cont           inc milli
                bne .exit
                inc milli+1
                bne .exit
                lda #$ff-$e8
                sta milli
                lda #$ff-3
                sta milli+1
                sed
                clc             ; added 17.07.96
                lda seconds
                adc #1
                sta seconds
                cmp #$60
                bne .exit
                stz seconds
                clc
                lda minutes
                adc #1
                sta minutes
.exit           cld
IFD KeyCounter
                lda KeyCounter
                ora KeyCounter+1
                bne .cont0
                END_IRQ
.cont0          inc KeyCounter
                beq .cont1
                END_IRQ
.cont1          inc KeyCounter+1
ENDIF
                END_IRQ

                END

IFD FlipUser
;***************
;* Vertical Blank
;***************
VBL::           _IFNE FlipFlag
                  stz FlipFlag
                  lda ScreenBase
                  ldx ScreenBase2
                  sta ScreenBase2
                  stx ScreenBase
                  sta $fd94
                  lda ScreenBase+1
                  sta $fd95
                  ldx ScreenBase2+1
                  sta ScreenBase2+1
                  stx ScreenBase+1
                _ENDIF
                END_IRQ
ENDIF

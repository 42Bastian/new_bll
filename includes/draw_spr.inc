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
ENDIF

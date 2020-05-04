****************
* IRQ_TEST.ASM
* tiny example on IRQ-programming on the lynx
*
* created : somewhat in the nineties ;)
*
* modified :
* 06.05.96      BS              translation to English
* 22.06.98      BS              slight modifications



	include <includes/hardware.inc>
* macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/suzy.mac>
                include <macros/mikey.mac>
                include <macros/irq.mac>
* vardefs
                include <vardefs/help.var>
                include <vardefs/irq.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>

****************

 BEGIN_ZP
irq_vectors     ds 16
_10             ds 2
sema            ds 1
 END_ZP
 BEGIN_MEM
screem	DS SCREEN.LEN
 END_MEM
                run LOMEM
                START_UP
                CLEAR_ZP
                ldx #$ff
                txs
                cld
                sei
                INITSUZY
                INITMIKEY
                INITIRQ irq_vectors
                FRAMERATE 60
* set IRQ-vectors and enable IRQs
                SETIRQ 0,HBL
;>                SETIRQ 1,NHBL
                SETIRQ 2,VBL
                SETIRQ 3,_1000Hz
* init 1000Hz-Counter
                lda #249
                sta $fd0c
                lda #%11011010  ; divider 4
                sta $fd0d
*

                cli
                stz _10
                stz _10+1
.loop           lda $fd0a
                bne .loop
.wait
                READKEY
                lda Cursor
                beq .wait
                bit #$80
                beq .no_up
                sec
                lda _10
                sbc #1
                sta _10
                lda _10+1
                sbc #0
                sta _10+1
                bcs .loop
                stz _10
                stz _10+1
                bra .loop
.no_up          bit #$40
                beq .loop
                clc
                lda _10
                adc #1
                sta _10
                lda _10+1
                adc #0
                sta _10+1
                cmp #$10
                blt .loop
                lda #$ff
                sta _10
                lda #$f
                sta _10+1
                bra .loop
****************
* interrupt routines
****************
_1000Hz::       lda #$ff
                tsb sema
                bne .exit
                cli
                ldx #10
.l              nop
                nop
                nop
                nop
                nop
                dex
                bpl .l
                stz sema
.exit           END_IRQ

HBL:
                inc $fdbf
                inc $fdaf

selfHBL         lda #0
                beq .sub
                inc $fda0
                lda $fda0
                cmp #$f
                bne .ok
                stz selfHBL+1
.ok             END_IRQ

.sub            dec $fda0
                bne .ok
                dec selfHBL+1
                END_IRQ

VBL::           lda _10
                sta $fdb0
                stz $fda0

                stz $fdbf
                stz $fdaf
                END_IRQ

                include <includes\irq.inc>

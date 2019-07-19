* -*-asm-*-
; created : 17.8.92
; last changes : 170796/250296/131293/2406093

; 25.02.96      $FFF9 now %1100 instead of %1000
; 17.07.96      change IRQ-handle
; 28.01.97      special handling for Tx/Rx-IRQ

InitIRQ::       php
                sei
                lda #$c
                sta $fff9
                lda #<irq
                sta $fffe
                lda #>irq
                sta $ffff
                ldy #<dummy_irq
                ldx #15
.loop           lda #>dummy_irq
                sta irq_vecs,x
                dex
                tya
                sta irq_vecs,x
                dex
                bpl .loop
IFD BRKuser
                lda #>dummy_irq
                sta BRKvec+1
                sty BRKvec
ENDIF
                plp
                rts
;---------------
;- Interrupt-Handler
;---------------
irq::           cld
                phx
                pha
                IFD BRKuser
                  tsx
;>                  inx
;>                  inx
;>                  inx
                  lda $103,x    ; p-register
                  bit #$10      ; break ??
                  beq .no_break
                  and #$ef
                  sta $103,x
                  pla
                  plx
                  jmp (BRKvec)
.no_break
                ENDIF

                ldx #0
                lda $fd81
                bit #$10	; SERIAL IRQ?
                beq .1
                jmp (irq_vecs+8)


.loop           inx
                inx
.1              lsr
                bcc .loop

                lda mask,x
                sta $fd80
                jmp (irq_vecs,x)

mask            dc.w $01,$02,$04,$08,$10,$20,$40,$80

dummy_irq       END_IRQ
                END

****************
*old version

.no_break       lda #$1
                ldx #-2
.loop           inx
                inx
                bit $fd81
                bne .do_irq
                lsr
                bcc .loop
                pla
                plx
                rti

.do_irq         sta $fd80
                jmp (irq_vecs,x)

* -*-asm-*-
; created : 17.8.92
; 25.02.96	$FFF9 now %1100 instead of %1000
; 17.07.96	change IRQ-handle
; 28.01.97	special handling for Tx/Rx-IRQ
; 20.07.19	reworked code, remove CLD (not needed)

InitIRQ::
	php
	sei
	lda #$c
	sta $fff9
	lda #<irq
	sta $fffe
	lda #>irq
	sta $ffff
	ldy #<dummy_irq
	ldx #15
.loop
	lda #>dummy_irq
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
 IFD NEW_IRQ_HANDLER
;---------------
;- Interrupt-Handler
;---------------
;
; Timer 7 => 3+2+4+3+2+12        = 26
; Timer 6 => 3+2+4+2+3+12        = 28
; UART    => 3+2+4+3+6           = 18
; pre = 19
; Timer 5 => 19+4*(2+2)+12       = 47
; Timer 3 => 19+3*(2+2)+(2+3)+12 = 48
; Timer 2 => 19+2*(2+2)+(2+3)+12 = 44
; Timer 1 => 19+1*(2+2)+(2+3)+12 = 40
; Timer 0 => 19+(2+3)+12         = 36

; Timer 0 => HBL
; Timer 2 => VBL

irq::
	pha		; 3
	lda	#$10	; 2
	bit	$fd81	; 4
	bne	_4	; 2,3
	bmi	_7	; 2,3
	bvs	_6	; 2,3
	lda	$fd81	; 4
 IFD BRKuser
	beq	brk_handler
 ENDIF
	lsr		; 2
	bcs	_0	; 2,3
	lsr		; 2
	bcs	_1	; 2,3
	lsr		; 2
	bcs	_2	; 2,3
	lsr		; 2
	bcs	_3	; 2,3
_5:
	lda	#$20	; 2
	sta	$fd80	; 4
	jmp	(irq_vecs+5*2) ;6
_4:
	jmp	(irq_vecs+4*2) ; 6
_3:
	lda	#$08
	sta	$fd80
	jmp	(irq_vecs+3*2)
_2:
	lda	#$04
	sta	$fd80
	jmp	(irq_vecs+2*2)
_1:
	lda	#$2
	sta	$fd80
	jmp	(irq_vecs+1*2)
_0:
	lda	#$1
	sta	$fd80
	jmp	(irq_vecs+0*2)
_6:
	lda	#$40
	sta	$fd80
	jmp	(irq_vecs+6*2)
_7:
	lda	#$80
	sta	$fd80
	jmp	(irq_vecs+7*2)

dummy_irq
	END_IRQ

 IFD BRKuser
brk_handler:
	phx
	tsx
	lda $103,x    ; p-register
	bit #$10      ; break ??
	beq dummy_irq
;;->	and #$ef
;;->	sta $103,x
	plx
	pla
	jmp (BRKvec)
 ENDIF
	END
 ELSE
 ENDIF
;---------------
;- Interrupt-Handler
;---------------
; pre = 17 , post = 14
; Timer 0 => 17+4+2+2+14         = 39
; Timer 1 => 17+4+2+3+2+2+14     = 44
; Timer 2 => 17+4+2+2*(3+2)+2+14 = 49
; Timer 3 => 17+4+2+3*(3+2)+2+14 = 54
; UART    =>                       22
; Timer 5 => 17+4+2+5*(3+2)+2+14 = 64
; Timer 6 => 17+4+2+6*(3+2)+2+14 = 69
; Timer 7 => 17+4+2+7*(3+2)+2+14 = 74
irq::
        phx				; 3
        pha				; 3
        ldx #0				; 2
        lda $fd81			; 4
 IFD BRKuser
	beq .break
 ENDIF
        bit #$10	; SERIAL IRQ?	; 2
        beq .1				; 2,3
        jmp (irq_vecs+8)		; 6

.loop
        inx				; 2
        inx				; 2
.1
	lsr				; 2
        bcc .loop			; 2,3

        lda mask,x			; 4
        sta $fd80			; 4
        jmp (irq_vecs,x)		; 6
 IFD BRKuser
.break
	tsx
        lda $103,x    ; p-register
        bit #$10      ; break ??
        beq dummy_irq
;;->        and #$ef
;;->        sta $103,x
        pla
        plx
        jmp (BRKvec)
 ENDIF
mask
	dc.w $01,$02,$04,$08,$10,$20,$40,$80

dummy_irq
	END_IRQ
	 END

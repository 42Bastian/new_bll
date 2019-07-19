* -*-asm-*-
* 1000Hz-Timer
*
* 19.07.19	clean up
*		conditional use of RTC (define RTC before including)
* 26.03.97	removed VBL-stuff
*		select Timer by main (set _1000HZ_TIMER)

Init1000Hz::
	php
	sei
	lda #249
	sta $fd00+_1000HZ_TIMER*4
	lda #%10011010	; 250KHz
	sta $fd01+_1000HZ_TIMER*4
 IFD RTC
	lda #$ff-$e8
	sta milli
	lda #$ff-3
	sta milli+1
	stz seconds
	stz minutes
 ENDIF
	stz _1000Hz
	stz _1000Hz+1
	stz _1000Hz+2
	SETIRQVEC _1000HZ_TIMER,_1000HzIRQ
	plp
	rts
;***************
;* Millisecond-Timer
;***************
_1000HzIRQ::
	inc _1000Hz
	bne .cont
	inc _1000Hz+1
	bne .cont
	inc _1000Hz+2
.cont
 IFD RTC
	inc milli
	bne .cont1
	inc milli+1
	bne .cont1

	lda #$ff-$e8
	sta milli
	lda #$ff-3
	sta milli+1

	sed
	clc
	lda seconds
	adc #1
	sta seconds
	cmp #$60
	bne .exit
	stz seconds
	lda minutes
	adc #1
	sta minutes
.exit
	cld
.cont1
 ENDIF
 IFD KeyCounter
	lda KeyCounter
	ora KeyCounter+1
	bne .cont2
	END_IRQ
.cont2
	inc KeyCounter
	beq .cont3
	END_IRQ
.cont3
	inc KeyCounter+1
 ENDIF
	END_IRQ

	END

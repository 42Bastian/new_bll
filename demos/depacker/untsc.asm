;;
;; depacker for TSCrunch, based on Antonio Savona's 6502 version.
;;
;; IN: tsget - packed data
;;     tsput - destination
;;
SMALL	EQU 1

untsc::
	lda	(tsget)
	sta	optRun+1
	clc
	lda	#1
	bra	uptdate_getonly
entry2:
	iny			; Y = 1
	lda	(tsget)
	bmi	rleorlz
	cmp	#$20
	bcs	lz2
	tax
	tay
ts_delit_loop:
	lda	(tsget),y
	dey
	sta	(tsput),y
	bne	ts_delit_loop
	txa
	inx
updatezp_noclc:
	adc	tsput
	sta	tsput
 IFD SMALL
	bcc putnoof
	inc tsput+1
	clc
 ELSE
	bcs	updateput_hi
 ENDIF
putnoof:
	txa
uptdate_getonly:
	adc	tsget
	sta	tsget
	bcc	entry2
	inc	tsget+1
	bra	entry2
 IFND SMALL
updateput_hi:
	inc	tsput+1
	clc
	bra	putnoof
 ENDIF

rleorlz:
	ldx	#2
	and	#$7f
	lsr
	bcc	ts_delz
	// RLE
	beq	optRun
plain:
	sta	tstemp		; count
	lda	(tsget),y
	ldy	tstemp
runStart:
	sta	(tsput),y
ts_derle_loop:
	dey
	sta	(tsput),y
	bne	ts_derle_loop

	lda	tstemp
	bra	updatezp_noclc
lz2:
	beq	done		; == $20
	ora	#$80
	adc	tsput
 IFD SMALL
	ldx	#1
	stx	lzto+1
	bra	lz2_put
 ELSE
	sta	lzput
	lda	tsput+1
	sbc	#$0
	sta	lzput+1
	lda	(lzput)
	sta	(tsput)
	lda	(lzput),y
	sta	(tsput),y

	tya
	dey			; y = 0

	adc	tsput
	sta	tsput
	lda	#1
	bcc	uptdate_getonly
	dec
	inc	tsput+1
	bra	uptdate_getonly
 ENDIF
	// LZ
ts_delz:
	lsr
	sta	lzto+1
	lda	tsput
	bcc	long
	sbc	(tsget),y
lz2_put:
	sta	lzput
	lda	tsput+1
	sbc	#$0
lz_put:
	sta	lzput+1

 IFD SMALL
	ldy	#$ff
 ELSE
	lda	(lzput)
	sta	(tsput)
	ldy	#0
 ENDIF
ts_delz_loop:
	iny
	lda	(lzput),y
	sta	(tsput),y
lzto:
	cpy	#0
	bne	ts_delz_loop
	tya
	ldy	#0
	bra	updatezp_noclc
optRun:
	ldy	#255
	sty	tstemp
	ldx	#1
	bra	runStart

long:
	adc	(tsget),y
	sta	lzput
	iny
	lda	(tsget),y
	tax
	ora	#$80
	adc	tsput+1
	cpx	#$80
	rol	lzto+1
	ldx	#3
	bra	lz_put
done:
	rts

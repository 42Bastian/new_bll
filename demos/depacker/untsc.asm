;;
;; depacker for TSCrunch, based on Antonio Savona's 6502 version.
;;
;; IN: tsget - packed data
;;     tsput - destination
;;
//->SMALL	EQU 1

untsc::
	lda	(tsget)
 IFD SMALL
	pha
 ELSE
	sta	optRun+1
 ENDIF
	ldx	#1
	bra	putnoof
entry2:
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
	iny
updatezp_noclc2:
	adc	tsput
	sta	tsput
 IFD SMALL
	bcc putnoof
	inc tsput+1
 ELSE
	bcs	updateput_hi
 ENDIF
putnoof:
	clc
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
 IFD SMALL
	pha
	pha
	lda	(tsget),y
	ply
 ELSE
	sta	tstemp		; count
	lda	(tsget),y
	ldy	tstemp
 ENDIF
runStart:
	sta	(tsput),y
ts_derle_loop:
	dey
	sta	(tsput),y
	bne	ts_derle_loop
 IFD SMALL
	pla
 ELSE
	lda	tstemp
 ENDIF
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
	tax
	bra	updatezp_noclc2
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
 IFD SMALL
	ply
	phy
	phy
 ELSE
	ldy	#255
	sty	tstemp
 ENDIF
	dex
	bra	runStart

long:
	adc	(tsget),y
	sta	lzput
	iny
	lda	(tsget),y
	tay
	ora	#$80
	adc	tsput+1
	cpy	#$80
	rol	lzto+1
	inx
	bra	lz_put
done:
 IFD SMALL
	ply
 ENDIF
	rts

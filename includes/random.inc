* -*-asm-*-
**************************
* ZUFALL
* (c) 1994 Bastian Schick
* erstellt : 260694-
**************************

InitRandom::
	lda $fd0A
	sta seed_lo
	adc $fd02
	sta seed_lo+1
	adc $fd02
	sta seed_lo+2
	adc $fd02
	and #$3f
	sta seed_hi
	adc $fd02
	and #$3f
	sta seed_hi+1
	adc $fd02
	and #$3f
	sta seed_hi+2
Random::
	phx
	phy
	lda _SPRSYS
	ora #$C0	; mit Vorzeichen und Akku
	sta $fc92
	ldx #0
	jsr compute_seed
	inx
	jsr compute_seed
	inx
	jsr compute_seed
	sec
	lda seed_lo
	sbc seed_lo+1
	sta rnd_rest
	lda seed_hi
	sbc seed_hi+1
	sta rnd_rest+1	; z=seed1-seed2
	beq .ok
	cmp #>706
	blt .ok
	bne .ko
	lda rnd_rest
	cmp #<706
	blt .ok
.ko	sbc #<32362
	sta rnd_rest
	lda rnd_rest+1
	sbc #>32362
	sta rnd_rest+1
.ok	clc
	lda rnd_rest
	adc seed_lo+2
	sta rnd_rest
	lda rnd_rest+1
	adc seed_hi+2
	bmi .ko1
	bne .ok1
	lda rnd_rest
	dec
	bne .ok1
.ko1	clc
	lda rnd_rest
	adc #<32362
	sta rnd_rest
	lda rnd_rest+1
	adc #>32362
	sta rnd_rest+1
.ok1	lda _SPRSYS
	sta $fc92
	ply
	plx
	lda rnd_rest
	rts

compute_seed::
	lda rnd_divisor,x
	sta MATHE_B
	stz MATHE_B+1
	lda seed_lo,x
	sta MATHE_A
	lda seed_hi,x
	sta MATHE_A+1
	stz MATHE_A+2
	stz MATHE_A+3
.wait	bit $fc92
	bmi .wait
	clc
	lda MATHE_R+1
	lsr
	sta rnd_rest+1
	lda MATHE_R
	ror
	sta rnd_rest	; rnd_rest := A MOD B
	stz MATHE_AKKU
	stz MATHE_AKKU+2
	lda rnd_mult1,x
	sta MATHE_E
	lda #$FF
	sta MATHE_E+1
.wait1	bit $fc92
	bmi .wait1	; AKKU = -mult1*(A DIV B)
	lda rnd_rest
	sta MATHE_C
	lda rnd_rest+1
	sta MATHE_C+1
	lda rnd_mult2,x
	sta MATHE_E
	stz MATHE_E+1
.wait2	bit $fc92
	bmi .wait2
	ldy MATHE_AKKU+1
	tya
	sta seed_hi,x
	lda MATHE_AKKU
	sta seed_lo,x
	tya
	bpl .exit
	clc
	lda seed_lo,x
	adc rnd_add_lo,x
	sta seed_lo,x
	lda seed_hi,x
	adc rnd_add_hi,x
	sta seed_hi,x
.exit	rts

rnd_mult1	dc.b -21,-45,$7B
rnd_mult2	dc.b 157,146,142
rnd_divisor	dc.b 206,217,222
rnd_add_lo	dc.b <32363,<31727,<31657
rnd_add_hi	dc.b >32363,>31727,>31657

rnd_rest
seed_lo	dc.b 1,2,3
seed_hi	dc.b 4,5,6

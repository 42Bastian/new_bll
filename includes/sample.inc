* -*-asm-*-
* Sample
* Date	changes
* 28.11.94	InitSample stops  SampleTimer
* 17.07.96	added STZ $FD22 (mute) in StopSampleIRQ (rm glitch)

***************
* start Sample
* IN : A file-number
***************
StartSample::	nop
	stz $fd22
	stz $FD01+SmpTimer*4 ; stop curr. Sample
	jsr OpenFile
	SETIRQVEC SmpTimer,PlayMonoU
	jsr ReadByte
	tax
	beq .ok
	SETIRQVEC SmpTimer,PlayMono
	stz SmpTemp
	stz SmpSema
	stz SmpTemp2
.ok	jsr ReadByte
	eor #$ff
	sta DigiCount+2
	jsr ReadByte
	eor #$ff
	sta DigiCount+1
	jsr ReadByte
	eor #$ff
	sta DigiCount
	jsr ReadByte
	sta $fd00+SmpTimer*4

	lda $fd50
	and #$EE
	sta $fd50	; Kanal A an
	jsr ReadByte	; Stereo-Flag weg
	lda #%10011000
	sta $fd01+SmpTimer*4
	rts
StopSample	stz $fd01+SmpTimer*4
	rts
***************
* MONO-Sample
***************
PlayMonoU::	jsr ReadByte
	sta $fd22
.cont1	inc DigiCount
	beq .next0
	END_IRQ
.next0	inc DigiCount+1
	beq .next1
	END_IRQ
.next1	inc DigiCount+2
	beq StopSampleIRQ
	END_IRQ

StopSampleIRQ	stz $fd01+SmpTimer*4
	stz $fd22	; mute ( added 170796 )
	lda $fd50
	ora #$11
	sta $fd50	; channel A off
	END_IRQ
***************
* packed Mono-Sample
***************
PlayMono::	lda SmpSema
	bne .no_read
	dec SmpSema
	jsr ReadByte
	sta SmpTemp2
	REPT 4
	lsr
	ENDR
	tax
	clc
	lda tabelle,x
	adc SmpTemp
	sta SmpTemp
	sta $fd22

.cont1	inc DigiCount
	beq .next0
	END_IRQ
.next0	inc DigiCount+1
	beq .next1
	END_IRQ
.next1	inc DigiCount+2
	beq StopSampleIRQ
	END_IRQ

.no_read	stz SmpSema

	lda SmpTemp2
	and #$f
	tax
	clc
	lda tabelle,x
	adc SmpTemp
	sta SmpTemp
	sta $fd22
	END_IRQ

tabelle	DC.B 128,-64,-32,-16,-8,-4,-2,-1,0,1,2,4,8,16,32,64
 ***************
* prepare channel A
* prepare Timer
***************
InitSample::	stz $fd01+SmpTimer*4

	lda $fd44
	ora $11
	sta $fd44	; channel A - panning

	lda #$ff	; full volume right/left
	sta $fd40

;	lda #$77
;	sta $fd42	; channel C half volume right/left

	lda $fd50
	ora #$11
	sta $fd50	; channel A quite

	stz $fd22
	stz $fd25	; Audio-Contrl A
	stz $fd24
	rts

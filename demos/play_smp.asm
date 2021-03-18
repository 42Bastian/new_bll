BlockSize	set 1024
NEWHEAD	set 1

;* Macros
   include <includes/hardware.inc>
   include <macros/help.mac>
   include <macros/if_while.mac>
   include <macros/font.mac>
   include <macros/window.mac>
   include <macros/mikey.mac>
   include <macros/suzy.mac>
   include <macros/irq.mac>
   include <macros/file.mac>
;* Variablen
   include <vardefs/font.var>
   include <vardefs/window.var>
   include <vardefs/mikey.var>
   include <vardefs/suzy.var>
   include <vardefs/irq.var>
   include <vardefs/file.var>
   include <vardefs/sample.var>

 BEGIN_ZP
digi_count	ds 2
digi_ptr	ds 2
temp		ds 1
temp2		ds 1
temp3		ds 1
sema		ds 1
count2		ds 1
channel		ds 1
zp_tab		ds 16
volume		ds 1
 END_ZP

 BEGIN_MEM
screen0		ds SCREEN.LEN
puff		ds 500
irq_vektoren	ds 16
 END_MEM

v8195		equ 121
v9834		equ 101
v12292		equ 80
v12517		equ 79
v49170		equ 19
frequenz	equ v8195

	run LOMEM
	INITMIKEY
	INITSUZY
	SETRGB pal
	INITIRQ irq_vektoren
	SETIRQ 0,HBL
	SETIRQ 2,VBL
	jsr InitSample
	SCRBASE screen0

	stz volume
	clc
	lda volume
	adc #2
;	jsr StartSample
;	jsr init_sound
	cli
	CLS #0
	WINDOW win1
.loop	lda $fcb0
	beq .loop
.loop1	cmp $fcb0
	beq .loop1
	bit #1
	beq no_launch
	clc
	lda #2
	adc volume
	jsr StartSample
;	jsr init_sound
	bra .loop
no_launch
	bit #$80
	bne up
	bit #$40
	bne down
	bra .loop

down	dec volume
	bpl .loop
	lda #6
	sta volume
	bra .loop
up	inc volume
	lda volume
	cmp #7
	bne .loop
	stz volume
	bra .loop

win1  DEFWCB 20,20,120,62,1,15,2

HBL::	inc $fda0
	END_IRQ
VBL::	stz $fda0
	END_IRQ
if 0
;***************
;* MONO-Sample spielen
;***************
PlayMonoU:
	jsr ReadByte
  sta $fda1
	sta $fd22
.cont1	inc digi_count
	beq .next0
	END_IRQ
.next0	inc digi_count+1
	beq .next1
	END_IRQ
.next1	inc digi_count+2
	beq reinit_play
	END_IRQ
;***************
;* gepacktes Mono-Sample spielen
;***************
PlayMono::
	lda sema
	bne .no_read
	dec sema
	jsr ReadByte
	sta temp2
	lsr
	lsr
	lsr
	lsr
	tax
 stx $fda1
	clc
	lda zp_tab,x
	sta $fd22+8
	sta $fd22+24
	adc temp
	sta temp
	sta $fd22
	sta $fd22+16
.cont1	inc digi_count
	beq .next0
	END_IRQ
.next0	inc digi_count+1
	beq .next1
	END_IRQ
.next1	inc digi_count+2
	beq reinit_play
	END_IRQ

.no_read
	stz sema
	lda temp2
	and #$f
.cont	tax
	clc
	lda zp_tab,x
	sta $fd22+8
	sta $fd22+24
	adc temp
	sta temp
	sta $fd22
	sta $fd22+16
	END_IRQ

tabelle	DC.B 128,-64,-32,-16,-8,-4,-2,-1,0,1,2,4,8,16,32,64

reinit_play
	lda #$80
	trb $fd05

	END_IRQ
	phy
	lda #2
	jsr OpenFile
	jsr ReadByte
	jsr ReadByte
	eor #$ff
	sta digi_count+2
	jsr ReadByte
	eor #$ff
	sta digi_count+1
	jsr ReadByte
	eor #$ff
	sta digi_count
	jsr ReadByte
	SETIRQVEC 1,PlayMono
	jsr ReadByte
	tax
	beq .ok
	SETIRQVEC 1,PlayStereo
.ok	lda #128
	sta temp
	sta temp2
	stz sema
	ply
	END_IRQ

PlayStereo::	jsr ReadByte
	sta temp3
	lsr
	lsr
	lsr
	lsr
	tax

	clc
	lda zp_tab,x
	sta $fd22+8
	adc temp
	sta $fd22
	sta temp

	lda temp3
	and #$f
	tax
	clc
	lda zp_tab,x
	sta $fd22+24
	adc temp2
	sta $fd22+16
	sta temp2

	inc digi_count
	beq .next0
	END_IRQ
.next0	inc digi_count+1
	beq .next1
	END_IRQ
.next1	inc digi_count+2
	bne .exit
	jmp reinit_play
.exit	END_IRQ


;********************
init_sound::	php
	stz $fd05
	ldx #15
.loop	  lda tabelle,x
	  sta zp_tab,x
	  dex
	bpl .loop
	clc
	lda #2
	adc volume
	jsr OpenFile
	jsr ReadByte
	jsr ReadByte
	eor #$ff
	sta digi_count+2
	jsr ReadByte
	eor #$ff
	sta digi_count+1
	jsr ReadByte
	eor #$ff
	sta digi_count
	jsr ReadByte
	sta $fd04
	SETIRQVEC 1,PlayMonoU
	jsr ReadByte
	tax
	beq .ok
	SETIRQVEC 1,PlayStereo
.ok	stz temp
	stz temp2
	stz sema
	stz $fd25
	stz $fd25+8
	stz $fd25+16
	stz $fd25+24
	stz $fd50
	lda #$F0
	sta $fd40
	sta $fd42
	lda #$0F
	sta $fd41
	sta $fd43
	stz $fd50
	lda #$ee
	sta $fd44
	lda #%10011000
	sta $fd05
	plp
	rts
ENDIF
;* INCLUDES
	include <includes/font.inc>
	include <includes/window2.inc>
	include <includes/file.inc>
	include <includes/irq.inc>
	include <includes/sample.inc>
	include <includes/font2.hlp>
pal	STANDARD_PAL
end	equ *
echo "ENDE : %Hend"

*****************
* BRK.ASM
* short program, that installs the BRK-server
* and then stops
*
* created : 15.08.96 by Bastian Schick
* changed
* 23.12.96	Baudrate is taken from the loader !
****************

BRKuser	set 1
Baudrate	set 62500


	include <macros/help.mac>
	include <macros/debug.mac>
	include <macros/irq.mac>

	include <vardefs/debug.var>
	include <vardefs/help.var>

	BEGIN_ZP
BRKvec	ds 2
	END_ZP


	RUN $200
Start
	START_UP	; disable all IRQs, init S,cli,cld ...
	lda	#$c
	sta	$fff9
	INITBRK
	MOVEI EnterBRK,$FFFE ; set IRQ-vector on BRK-routine

	lda #%00011101	 ; even par/clear all errors
	sta $fd8c
	lda #%00011000	 ; enable count,enable reload
	sta $fd11
	lda $fd10
	sta _brk_baud+1 ; patch BRK-server
;	 lda #125000/Baudrate-1
	sta $fd10	; 31250Bd
	cli
	stz	$fda0
	lda	#$42
	ldx	#42
	ldy	#$24
; fall into brk
.1
	BREAKPOINT 0
	bra .1

	include "debug.inc"

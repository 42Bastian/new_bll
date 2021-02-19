***************
* Mini COMLynx Loader (not size optimized)
* First stage
****************

	include <includes/hardware.inc>

Baudrate EQU 62500

	run	$200
Start::
	ldy	RCART0
	ldx	#$ff
	txs
.read2nd:
	  inx
	  lda	RCART0
	  sta   $100,x
	  dey
	bne	.read2nd
	jmp	$100
End:

size	set End-Start
free	set 49-size

	IF free > 0
	REPT	free
	dc.b	$0
	ENDR
	ENDIF
	dc.b 0
	echo "Size:%dsize  Free:%dfree"

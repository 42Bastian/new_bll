; micro loader
;
; programm must start at $1ff, first byte must contain number of
; pages to load (see demo.s), so actual code at $200
;
; Note: Does not clear AUDIN, therefore not for use for bank-switching carts!
;      (lda #$1a; sta $FD8A, and FE00 sets AUDIN (B4) == 0)
;
; Currently 3 bytes spare ...

; Addresses
RCART_0		EQU $fcb2	; cart data register
BLOCKNR		EQU 0		; zeroed by ROM
PAGECNT		EQU $1ff

	RUN    $0200

	; Copy loader onto stack
	txs			; x = 0 after ROM
	ldx	#(b9+1)-b0
cpy:
	stz	$fda0,x		; clear colors
	lda	b0,x		; copy loader
	pha
	dex
	bpl	cpy

	ldy	#51+1		; already 51 bytes loaded from 1st block!
	bra	$200-(b9+1-b1)	; bra b1

	; From here copied onto stack
b0:
	dex
	bne	b2
	inc	BLOCKNR		; next block
	lda	BLOCKNR
	jsr	$fe00		; select block
b1:
	ldx	#4		; 4 pages per block
b2:
	lda	RCART_0
DST
	sta	$200-(51+2),y	; first byte goes to $1ff (PAGECNT)
	iny
	bne	b2

	inc	$200-(b9+1-DST)+2	; next dst page

	dec	PAGECNT
	bne	b0
	dc.b	$a2		; opcode "LDX"
	; PAGECNT will be here, zero after loading => LDX #0
b9:
	; program is here at $200!

endofbl:

size	set endofbl-$200
free	set 49-size

	echo "Free %Dfree"
	IF free < 0
	echo "Size must be <= 50!"
	ENDIF

	; fill remaining space
	IF free > 0
	REPT	free
	dc.b	$42		; unused space shall not be 0!
	ENDR
	ENDIF
	dc.b 	$00		; end mark!

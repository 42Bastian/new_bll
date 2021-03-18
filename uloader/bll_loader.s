; BLL file loader
;
; This is a second stage loader for files with BLL header.
; It must be combined with ml.enc and the resulting file then with
; a BLL file.

; Addresses
RCART_0		EQU $fcb2	; cart data register
BLOCKNR		EQU 0		; zeroed by ROM
PAGECNT		EQU $1ff
HEADER		EQU $e0
HEADER2		EQU $f0
LENGTH		EQU HEADER+6
DEST		EQU HEADER+4
RUN_ADDR	EQU HEADER2+4

	RUN    $01ff

	dc.b	1
	lda	HEADER_ORG+4
	eor	#$ff
	sta	LENGTH+1
	lda	HEADER_ORG+5
	eor	#$ff
	sta	LENGTH
	lda	HEADER_ORG+2
	sta	DEST+1
	sta	RUN_ADDR+1
	lda	HEADER_ORG+3
	sta	DEST
	sta	RUN_ADDR
	ldx	#$c0
	txs
	ldy	#b9-b0-1+2+1
copy_loader:
	lda	b0-1,y
	sta	$1C0,y
	dey
	bne	copy_loader
	ldx	#3		; already 1 page bytes loaded from 1st block!
	bra	$1C0+(b2-b0+1)	; bra b2

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
	sta	(DEST)		; first byte goes to $1ff (PAGECNT)
	inc	DEST
	bne	b3
	inc	DEST+1
b3
	inc	LENGTH
	bne	b4
	inc	LENGTH+1
	bne	b4
	jmp	(RUN_ADDR)
b4
	iny
	bne	b2
	bra	b0

b9:
	; program is here at $200!
endofbl:

size	set endofbl-$1ff
	ds	256-size-10-52
HEADER_ORG:
	echo "Size %Dsize"

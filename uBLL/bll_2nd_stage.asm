***************
* Mini COMLynx Loader (not size optimized)
* 2nd stage
****************

	include <includes/hardware.inc>

Baudrate EQU 62500

;;; ROM sets this address
screen0	 equ $2000

	run	$100-1
Start::
	dc.b size		; needed for 1st stage
	ldx	#12-1
.sloop
	  ldy	SUZY_addr,x
	  lda	SUZY_data,x
          sta	$fc00,y
          dex
        bpl .sloop

	ldx	#7-1
.mloop
	  ldy	MIKEY_addr,x
	  lda	MIKEY_data,x
	  sta   $fd00,y
	  dex
	bpl	.mloop
wait:
	jsr	read_byte
	cmp	#0x81
	bne	wait
	jsr	read_byte
	cmp	#'P'
	bne	wait

load_len	equ $0
load_ptr	equ $2
load_len2	equ $4
load_ptr2	equ $6

Loader::
	ldy #4
.loop0	  jsr read_byte
	  sta load_len-1,y
	  sta load_len2-1,y	; mirror for call
	  dey
	bne .loop0		; get destination and length
	tax			; lowbyte of length

.loop1	inx
	bne .1
	inc load_len+1
	bne .1
	jmp (load_ptr)

.1	jsr read_byte
	sta (load_ptr2),y
	sta $fdb0
	iny
	bne .loop1
	inc load_ptr2+1
	bra .loop1

read_byte
	bit $fd8c
	bvc read_byte
	lda $fd8d
	rts
;;;------------------------------
	;; Writing low-byte in SUZY space clears highbyte!
_SDONEACK EQU SDONEACK-$fd00
_CPUSLEEP EQU CPUSLEEP-$fd00
MIKEY_addr
	dc.b	$10,$11,$8c,_CPUSLEEP,_SDONEACK,$b3,$a0

MIKEY_data
	dc.b	125000/Baudrate-1,%11000,%11101,0,0,$0f,0

_SCBNEXT EQU SCBNEXT-$fc00
_SPRGO   EQU SPRGO-$fc00
SUZY_addr
	db _SPRGO,_SCBNEXT+1,_SCBNEXT,$09,$08,$04,$06,$28,$2a,$83,$92,$90
SUZY_data
	db 1,>plot_SCB,<plot_SCB,$20,$00,$00,$00,$7f,$7f,$f3,$00

plot_SCB:
next:
	db $01						;0
	dc.b SPRCTL1_LITERAL| SPRCTL1_DEPTH_SIZE_RELOAD ;1
	dc.b 0						;2
	dc.w 0						;3
	dc.w plot_data					;5
plot_x	dc.w 80-21					;7
plot_y	dc.w 51-3					;9
        dc.w $100					;11
        dc.w $200					;13
plot_color:						;15
	db	3

plot_data:
	;; "NEW_BLL"
	ibytes "new_bll.spr"
End:
size	set End-Start

	echo "Size:%dsize "

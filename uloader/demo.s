;;; Demo for CART_HEADER
;;;

BlockSize	equ 1024

	include <macros/lnx_header.mac>
	include <macros/cart_header.mac>

 IFD LNX
	CART_HEADER "RAYCAST","42Bastian",0,0
 ELSE
	run $200
 ENDIF

Start::
; code will be loaded at $200!
	jsr	subroutine
	sta 0
endless:
	jmp	endless
	REPT 19
	dc.b "Hjfvhfdsjhgjkfdhjkghfdkjghfdj sdafjdshgjkfhjkhghfjs"
	dc.b "000000000001111111111111111222222222222222222222222"
	dc.b "Hjfvhfdsjhgjkfdhjkghfdkjghfdj sdafjdshgjkfhjkhghfjs"
	dc.b "000000000001111111111111111222222222222222222222222"
	dc.b "Hjfvhfdsjhgjkfdhjkghfdkjghfdj sdafjdshgjkfhjkhghfjs"
	dc.b "000000000001111111111111111222222222222222222222222"
	dc.b "Hjfvhfdsjhgjkfdhjkghfdkjghfdj sdafjdshgjkfhjkhghfjs"
	dc.b "000000000001111111111111111222222222222222222222222"
	ENDR
subroutine:
	rts
End:

size	EQU *-$200	; Take encrypted loader into account!

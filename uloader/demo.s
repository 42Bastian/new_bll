;

	RUN $1ff	; do not change!!


	; number of pages to load (must by 1st byte!!!)
	dc.b 	(size+255)>>8	; round up to full pages

; code will be loaded at $200!
	jsr	ende
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
ende	rts

size	EQU *-$200	; Take encrypted loader into account!

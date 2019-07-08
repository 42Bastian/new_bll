; title-sprite loaded by LYNXER?.TTP or NEWLYNX.TTP
; if called without *.MAK
; assmeble if : lyxass -d insert

	include <macros\help.mac>
	include <macros\if_while.mac>
	include <macros\mikey.mac>
	
	
	RUN $2400

ATARI	EQU 1	; show Fuji

	STANDARD_PAL
	
	IF ATARI=0
SCB	db $01,$90,$00
	dw 0,insert
	dw 31,29
	dw $400,$400
	db $0F
insert	db 5,%11101001,%01110111,%01100111,0
	db 4,%01001101,%01000100,%01010010
	db 4,%01001111,%01110110,%01100010
	db 4,%01001011,%00010100,%01010010
	db 4,%11101001,%01110111,%01010010
	db 2,0
	db 4,%00010010,%11101000,%10111000
	db 4,%00011010,%10101101,%10100000
	db 4,%00011110,%11101111,%10110000
	db 4,%00010110,%10101010,%10100000
	db 4,%00010010,%10101000,%10111000
	db 0
	
ELSE

SCB	db $41,$10,$00
	dw 0,atari
	dw 39,8
	dw $100,$100
	db $0F,$A0
atari	ibytes "atari.o"

ENDIF
	END
	


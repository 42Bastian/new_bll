; -*-asm-*-
;****************
;* LYNX CART EEPROM driver
;* for 24AAXXX (up to 512Kbit => 64K 8-bit words)
;*
;* created : 30.12.2020
;*
;* CLK   = A1 (11)
;* DI/DO = AUDIN (32)
;*
;* How to contact the EEPROM :
;*
;*                -----\/-----     24AAXXX
;*   GND  --------| A0   VCC |- +5V
;*   GND  --------| A1   WP  |- GND
;*   GND  --------| A2   SCL |- A1    (11)
;*   GND  --------| VSS  SDA |- AUDIN (32)
;*                ------------
;*
;****************
;* Based on eeprom64k.s from Karri and Nop90
;****************

 IFND ee24aaxxx_tmp
	echo "Need ee24aaxxx_tmp ZP variable"
 ENDIF

 IFND pageBuffer
	echo "Need 'pageBuffer'"
 ENDIF

CLOCK_ON_A1	EQU 1		; undefine if clock is on A0

CHIP_IS_24AA512 EQU 1
; ------------------------------------------------------------------------
; EEPROM command list

EE24AAXXX_C_WRITE      EQU $a0
EE24AAXXX_C_READ       EQU $a1

; ------------------------------------------------------------------------
; LYNX CART IO acions macros -> use Y register

 MACRO IO_CHANGECLOCK
	stz	 RCART0
 IFD CLOCK_ON_A1
	stz	 RCART0
 ENDIF
 ENDM

 MACRO IO_INITCLOCK
;;; Strobing bit 0 of SYSCTL1 changes the high part of the cart address,
;;; and this resets the low part of the address controlled by the ripple counter
	ldy	#3
	sty	SYSCTL1
	dey
	sty	SYSCTL1
 ENDM

 MACRO IO_SETINPUT
	ldy	#$a
	sty	IODIR   ; set AUDIN to Input
 ENDM

 MACRO IO_SETOUTPUT
	ldy	#$1a
	sty	IODIR   ; set AUDIN for output
 ENDM

 MACRO IO_LINELOW
	ldy	#$0b
	sty	IODAT
 ENDM

 MACRO IO_LINEHIGH
	ldy	#$1b
	sty	IODAT
 ENDM

; ------------------------------------------------------------------------
; EEPROM Low level macros

 MACRO EE24AAXXX_CHECKACK
	IO_CHANGECLOCK  ;clock high
	lda	IODAT
	IO_CHANGECLOCK  ;clock low
	and	#$10
	adc	#$f0
 ENDM

 MACRO EE24AAXXX_STOP
;;  STOP signal is a LOW->HIGH transition during clock HIGH
	IO_SETOUTPUT	;drive the line low
	IO_LINELOW
	IO_CHANGECLOCK  ;clock high
	IO_LINEHIGH	;releasing channel drive the data line high.
	IO_CHANGECLOCK  ;clock low
	IO_SETINPUT
 ENDM

 MACRO EE24AAXXX_INIT	;this is the only command resetting the clock to low as first action
	IO_SETINPUT	;release channel -> data line pulled up
	IO_INITCLOCK
	IO_LINELOW	;needed?
 ENDM

 MACRO EE24AAXXX_START
	IO_SETOUTPUT
	IO_LINEHIGH
	IO_CHANGECLOCK  ;clock high
	IO_LINELOW	;START signal is a HIGH->LOW transition during clock HIGH
	IO_CHANGECLOCK  ;clock low
	IO_SETINPUT	;releasing channel after the clock -> data line pulled up
 ENDM

; ------------------------------------------------------------------------
; EEPROM IO functions

ee24aaxxx_setAddr_Exit1:
	pla
ee24aaxxx_setAddr_Exit:
	rts

ee24aaxxx_setAddr:
	pha
	phx
	lda	#EE24AAXXX_C_WRITE
	jsr	ee24aaxxx_put8
	pla
	bcs	ee24aaxxx_setAddr_Exit1

	jsr	ee24aaxxx_put8
	pla
	bcs	ee24aaxxx_setAddr_Exit
	;; fall thru

ee24aaxxx_put8::		;data in A
	IO_SETOUTPUT
	ldx	#8
.loop
	ldy	#$0b
	rol
	bcc	.zero
	ldy	#$1b
.zero
	sty	IODAT

	IO_CHANGECLOCK  ;clock high
	IO_CHANGECLOCK  ;clock low
	dex
	bne	.loop

	IO_SETINPUT	;release the channel
	EE24AAXXX_CHECKACK
	rts		; C == 1 => no ACK

ee24aaxxx_get8::
	IO_SETINPUT
	pha
	ldx	#8
.loop
	IO_CHANGECLOCK  ;clock high
	lda	IODAT
	IO_CHANGECLOCK  ;clock low
	and	#$10
	adc	#$f0
	rol	ee24aaxxx_tmp
	dex
	bne	.loop

	pla
	beq   .noack		; if A == 0 => no ACK
	IO_SETOUTPUT
	ldy   #$0b		; Low => ACK
	sty   IODAT
	IO_CHANGECLOCK
	IO_CHANGECLOCK
.noack
	lda	ee24aaxxx_tmp
	rts

 IFD CHIP_IS_24AA512
;;; ----------------------------------------------------------------------
;;; ee24aa512_page2Addr
;;; IN:  X:A - page [0..$1ff]
;;; OUT: X:A - address
;;; ----------------------------------------------------------------------
ee24aa512_page2Addr::
	phx
	ror
	tax
	pla
	ror
	rts
 ENDIF
;;; ----------------------------------------------------------------------
;;; ee24aaxxx_read
;;; IN:  X:A - Address
;;; OUT: A - data if C = 0
;;; ----------------------------------------------------------------------
ee24aaxxx_read::
	EE24AAXXX_INIT
	EE24AAXXX_START
	jsr	ee24aaxxx_setAddr
	bcs	.error
eeread_cont:
	EE24AAXXX_START
	lda	#EE24AAXXX_C_READ
	jsr	ee24aaxxx_put8
	bcs	.error
	lda	#0   ; Flag: No ACK after read
	jsr	ee24aaxxx_get8
.error
	EE24AAXXX_STOP
	rts
;;; ----------------------------------------------------------------------
;;; ee24aaxx_readNext
;;; OUT: A - data if C = 0
;;; ----------------------------------------------------------------------
ee24aaxxx_readNext::
	EE24AAXXX_INIT
	bra   eeread_cont

;;; ----------------------------------------------------------------------
;;; ee24aaxxx_write
;;; IN:  X:A - Address
;;;      Y   - Data
;;; OUT: C = 0 => error
;;; ----------------------------------------------------------------------
ee24aaxxx_write::
	phy
	EE24AAXXX_INIT
	EE24AAXXX_START
	jsr	ee24aaxxx_setAddr
	pla
	bcs	.error
	jsr	ee24aaxxx_put8
.error
	EE24AAXXX_STOP
	rts

 IFD CHIP_IS_24AA512
;;; ----------------------------------------------------------------------
;;; ee24aa512_readPage(unsigned int page)
;;; IN:  X:A - Page (0..$1ff)
;;; OUT: pageBuffer contains data
;;;      C = 0 => error
;;; ----------------------------------------------------------------------
ee24aa512_readPage::
	jsr	ee24aa512_page2Addr
	EE24AAXXX_INIT
	EE24AAXXX_START
	jsr	ee24aaxxx_setAddr
	bcs	.error

	EE24AAXXX_START
	lda	#EE24AAXXX_C_READ
	jsr	ee24aaxxx_put8
	bcs	.error
	ldy	#0
.1	phy
	tya
	eor	#$7f
	jsr	ee24aaxxx_get8
	ply
	sta	pageBuffer,y
	iny
	bpl	.1
	sec
.error
	EE24AAXXX_STOP
	rts

;;; ----------------------------------------------------------------------
;;; ee24aa512_writePage(unsigned int page)
;;; IN:  X:A - Page (0..$1ff)
;;;      pageBuffer
;;; OUT: C = 0 => error
;;; ----------------------------------------------------------------------
ee24aa512_writePage::
	jsr	ee24aa512_page2Addr
	EE24AAXXX_INIT
	EE24AAXXX_START
	jsr	ee24aaxxx_setAddr
	bcs	.error
	ldy	#0
.1
	phy
	lda	pageBuffer,y
	jsr	ee24aaxxx_put8
	bcs	.error
	ply
	iny
	bpl	.1
.error
	EE24AAXXX_STOP
	rts
 ENDIF

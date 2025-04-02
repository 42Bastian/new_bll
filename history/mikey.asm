* ===========================================================================
	include <includes/hardware.inc>

CART_POWER_OFF	equ 2
* ===========================================================================

SIZEKEY			EQU 51

BASE_ORG		EQU $0200
WORK_ORG		EQU $5000

SETCARTBLOCK		EQU $FE00
RSA_LOAD		EQU $FE4A

DISP			EQU $FEC1-WORK_ORG

* ===========================================================================
* ===                       =================================================
* ===  Zero-Page Variables  =================================================
* ===                       =================================================
* ===========================================================================

		ORG $0000

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* These are the variables as declared by the Mikey ROM code

* Note!  dest is presumed to be at memory location zero
dest		DS 2

checksum	DS 1		; checksum used during decryption

powerdowncount	DS 2

ptr		DS 2
num_blocks	DS 1

bitcount	DS 1		; temporary counter
bytecount	DS 1		; temporary counter
temp0		DS 1
acc0		DS 2		; accumulator pointers
acc1		DS 2
input1		DS 2		; pointer to multiplicand
scratch0	DS SIZEKEY	; scratch areas must be in zero page
scratch1	DS SIZEKEY
scratch2	DS SIZEKEY
inputcode	DS SIZEKEY

encrypted_area	EQU inputcode

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

* ===========================================================================
* ===========================================================================



* ===========================================================================
* ===========================================================================

		RUN $fe00

SetCartBlock
		; Fill shift register for cartridge (in X, in A)
		SEC
		BRA .0
.1		BCC .2
		STX IODAT		; Set cartridge output (bit to shift into register) to X
		CLC
.2		INX
		STX SYSCTL1
.0		LDX #$02
		STX SYSCTL1		; Power on and strobe
		ROL
		STZ IODAT		; Zero for bit to shift into register
		BNE .1
		RTS				; Back to decryption routine

		; Clear all memory from $0003 to $FFFF to 0x00
ClearMemory
		STZ dest+1
		LDA #$00
.3		STA (dest),y
		INY
		BNE .3
		INC dest+1
		BNE .3

		; Routine to initialize Mikey
InitMikey
		LDX #MIKEYVALS_COUNT
.4		LDA MikeyValues-1,x
		LDY MikeyOffsets-1,x
		STA $FD00,y
		DEX
		BNE .4

; Copy 256 bytes from $FEC1 to $5000
copy		LDA Decrypt,x
		STA WORK_ORG,x
		INX
		BNE copy

; Start decryption process for first frame
		STZ ptr			; Destination address of decrypted data (low)
		LDA #2
		STA ptr+1		; Destination address of decrypted data (high)
		STZ checksum		; Initialize transition byte
		LDA #0			; Prepare for first block
		JSR SetCartBlock

		LDA RCART0		; Read cart (using strobe CART0)
		CMP #$FB		; First byte has two's complement of number of blocks in first frame
		BCC retry		; If value is less than #$FB it is not a correct header
		STA num_blocks		; Save block count
		STZ GREENF		; GREENF = 0
		STZ BLUEREDF		; BLUEREDF = 0

; Read entire block of encrypted data (reversed)
ReadBlock
		LDX #SIZEKEY-1		; Each block in a frame is 50 + 1 byte long
.5		LDA RCART0		; Read cart (using strobe CART0)
		STA inputcode,x		; Store block data in ZP from $AA to $DC
		DEX
		BPL .5			; Next byte

; Decrypt current block
		ORA inputcode+1		; Accumulator contains last byte of encrypted data
		ORA inputcode+2
		BEQ retry		; First three bytes should contain at least one non-zero value, otherwise error
		LDX #$02		; Start at position 2
.8		LDA inputcode,x		; Read value
		SBC modulus,x		; Subtract with public part of encryption key
		DEX
		BPL .8			; Next value
		BCS retry		; If sanity check fails go to error
		JSR WORK_ORG		; Start decryption (plaintext = encrypted ^ public_exponent % modulus)
		LDA (acc0)		; Sanity check for contents of decrypted (and still obfuscated) data's first byte
		CMP #$15		; Must always be $15 as hardcoded marker byte of start of obfuscated block
		BNE retry		; On error

		LDA checksum		; Get transition byte between blocks
		LDY #SIZEKEY-1		; Start at end of decrypted data
.9		CLC
		ADC (acc0),y		; A += decrypted data
		STA (ptr)		; Store at destination address ($0200) and onwards
		INC ptr			; Update destination
		DEY			; Next byte
		BNE .9			; Until all data in block is done
		STA checksum		; Remember last byte
		INC num_blocks		; Next block
		BNE ReadBlock		; Continue reading next block of data from cart
		LDY #CART_POWER_OFF
		STY IODAT		; Set cart address data
		TAX
		BNE retry		; On error retry
		JMP BASE_ORG		; Run whatever is at $0200

; Retry lots of times
retry
		INC powerdowncount
		BNE InitSuzy
		INC powerdowncount+1
		BNE InitSuzy
		STZ SYSCTL1		; Reset cart address counter
.6		BRA .6			; Give up and loop forever

; Initialize Suzy
InitSuzy
		LDX #SUZYVALS_COUNT-1
.7		LDA SuzyValues,x
		LDY SuzyOffsets,x
		STA $FC00,y
		DEX
		BPL .7
		STZ CPUSLEEP	; Reset CPU bus request flip flop (draw INSERT GAME sprite)
		STZ SDONEACK	; Clear SDONEACK
		JMP InitMikey	; Call routine to initialize Mikey

Decrypt
	echo "RAM code: %HDecrypt"
		RUN $5000
		LDA #<scratch0
		STA acc0		; Pointer to start of zero page temporary data
		LDA #<scratch1		; End of working data zero page address
		STA _5070+1		; Self-modifying code (see FF32)
		LDA #<inputcode
		STA input1		; Pointer to start of encrypted data in zero page range
		JSR _5018		; Currently FED9: perform first multiplication of enc * enc * enc (encrypted^3)
		LDA acc0		; Transfer pointer to data with enc^2 ...
		STA input1		; ... to encryption data
		LDA #<scratch2		; Set pointer for work data right after squared encryption data
		STA acc0		; Perform second multiplication of enc * enc * enc (encrypted^3)

; Clear all 51 values of temporary work data
_5018
		LDY #SIZEKEY-1
		LDA #0
.10		STA (acc0),y
		DEY
		BPL .10

; Montgomery multiplication algorithm
		INY			; Y = 0
.19		LDA (input1),y		; Load value from encrypted data (or enc^2 on second pass)
		STA temp0		; Store in work variable
		DEC bitcount
.20		LDA acc0		; Change data address to work on
		STA $5037		; Self-modifying code (see FEF7)
		STA $5043		; Self-modifying code (see FF04)
		STA $5047		; Self-modifying code (see FF08)
		CLC
		LDX #SIZEKEY-1
_FEF7
		ROL $00,x		; Operand corresponds to $5037
		DEX
		BPL _FEF7
		ASL $0A
		BCC _FF11
		LDX #$32
		CLC
.21		LDA dest,x		; Operand corresponds to $5043
		ADC inputcode,x
		STA dest,x		; Operand corresponds to $5047
		DEX
		BPL .21
; TODO: Name routine X
 		JSR _505D		; Call routine X
		BCC .22
_FF11
		JSR _505D		; Call routine X
.22		LSR $08
		BNE .20
		INY
		CPY #SIZEKEY
		BCC .19
		RTS			; scratch0 + scratch1 contains enc^2 at first pass

; Routine X (unknown purpose: Step in montgomery multiplication process?)
_505D:
		LDA acc0
		STA .30+1
		LDA (acc0)
		CMP modulus		; Start of public part of encryption key
		BCC done
		LDX #SIZEKEY-1
.30		LDA dest,x
		SBC modulus,x		; Subtract from corresponding byte in public key
_5070		STA dest,x		; Operand corresponds to $5071 when copied
		DEX
		BPL .30
		BCC done
		LDA acc0
		LDX _5070+1
		STX acc0		; Update pointer to work data
		STA _5070+1		; Self-modify code
done
		RTS

		; SCB data for INSERT GAME sprite
		DB $05			; SPRCTLO (1 bit/pixel, no flipping, non-collideable sprite)
		DB $93			; SPRCTL1 (Totally literal, HSIZE and VSIZE specified, drawing starts at upper left quadrant)
		DB $00			; SPRCOLL
		DW $0000		; Address of next SCB
		DW INSERT_DATA		; Address of SPRDLINE (sprite data)
		DW $0080		; HPOSSTRT 128
		DW $0048		; VPOSSTRT 72
		DW $0400		; HSIZE (magnify by 4 horizontally)
		DW $0400		; VSIZE (magnify by 4 vertically)
		DB $F0			; Palette colors

; Sprite data (INSERT GAME upside down)
INSERT_DATA:
		DB $04, $E2, $EA, $87		; ...000.0...0.0.0.0000...
		DB $04, $FA, $AA, $B7 		; .....0.0.0.0.0.0.0..0...
		DB $04, $F2, $08, $97 		; ....00.00000.000.00.0...
		DB $04, $FA, $4A, $F7		; .....0.00.00.0.0....0...
		DB $04, $E2, $E8, $87		; ...000.0...0.000.0000...
		DB $02, $FF					; ........
		DB $05, $B5, $11, $68, $FF	; .0..0.0.000.000.0..0.000 .... ....
		DB $04, $B5, $D7, $2D		; .0..0.0...0.0...00.0..0.
		DB $04, $B9, $91, $0D		; .0...00..00.000.0000..0.
		DB $04, $B5, $DD, $4D		; .0..0.0...0...0.0.00..0.
		DB $05, $19, $11, $68, $FF	; 000..00.000.000.0..0.000........
		DB $00						;$ End of quadrant

; Start of boot sequence
		LDA SUZYHREV	; Load hardware version (always 1.0 for hardware)
		DB $f0,$7b	; BEQ $0000
		PLA
		PLA
		PLA
		PLA
		LDY #CART_POWER_OFF
		STY IODAT		; Set cartridge power off
		INY
		STY IODIR		; External power and cart address to output
		STY MAPCTL		; Memory map to 03 (Mikey and Suzy addresses are RAM)
		STZ $00			; Set $0000 to 0
		JMP ClearMemory

* ===========================================================================
* ===========================================================================

		RUN $FF9A

; Public key modulus for decryption
modulus
		DB $35, $B5, $A3, $94, $28, $06, $D8, $A2
		DB $26, $95, $D7, $71, $B2, $3C, $FD, $56
		DB $1C, $4A, $19, $B6, $A3, $B0, $26, $00
		DB $36, $5A, $30, $6E, $3C, $4D, $63, $38
		DB $1B, $D4, $1C, $13, $64, $89, $36, $4C
		DB $F2, $BA, $2A, $58, $F4, $FE, $E1, $FD
		DB $AC, $7E, $79


MikeyOffsets
; Mikey addresses to be initialized (add to Mikey range offset $FD00)
		DB $90	; SDONEACK
		DB $92	; DISPCTL
		DB $95	; DISPADRH
		DB $94	; DISPADRL
		DB $93	; PBCKUP
		DB $09	; TIM2CTLA
		DB $08	; TIM2BCKUP
		DB $BF	; BLUEREDF
		DB $AF	; GREENF
		DB $B0	; BLUERED0
		DB $A0	; GREEN0
		DB $01	; TIM0CTLA
;		DB $00	; TIM0BCKUP

; Initialization values for Mikey addresses
MikeyValues
		DB $00	; Render sprite command (and also address TIM0BCKUP)
		DB $0D	; 4 bit color with video DMA enabled
		DB $20	; Video address at $2000
		DB $00	; Video address at $2000
		DB $29	; Magic P value for screen frequency
		DB $1F	; Enable count and reload, linking
		DB $68	; 104 backup value for vertical scan timer (== 102 vertical lines plus 2)
		DB $3E	; Yellow
		DB $0E	; Yellow
		DB $00	; Black
		DB $00	; Black
		DB $18	; 2 microseconds timing for horizontal line
		DB $9E	; 158 backup value for horizontal line scan (160 pixel across)

MIKEYVALS_COUNT	EQU *-MikeyValues	; number of values to INIT in loop

; Suzy addresses to be initialized (add to Suzy range offset $FC00)
SuzyOffsets
		DB $91	; SPRGO
		DB $11	; SCBNEXTH
		DB $10	; SCBNEXTL
		DB $09	; VIDBASH
		DB $08	; VIDBASL
		DB $06	; VOFFL
		DB $04	; HOFFL
		DB $90	; SUZYBUSEN
		DB $92	; SPRSYS

; Initialization values for Suzy addresses (see also $FFE6)
SuzyValues
		DB $01	; Draw sprite (no everon detection)
		DB $50	; SCBNEXT = $5082
		DB $82	;
		DB $20	; VIDBAS = $2000
		DB $00	;
		DB $00	; VOFF = $0000
		DB $00	; HOFF = $0000
		DB $01	; Bus enabled
		DB $00	; Unsigned math, no accumulation, collission on, normal handed

SUZYVALS_COUNT	EQU *-SuzyValues	; number of values to INIT in loop

; Reserved registers
		DB $00		; Reserved
		DB $f0		; MAPCTL value
		DW $3000	; NMI vector
		DW $FF80	; Boot vector
		DW $FF80	; IRQ vector

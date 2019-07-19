* -*-asm-*-
; Lynx hard-ware addresse
; written 8.3.96
; 42Bastian Schick
; new (Atari's) label names !


CPU_IRQ	EQU $FFFE
CPU_RESET	EQU $FFFC
CPU_NMI	EQU $FFFA
MAPCTL	EQU $FFF9	; set to 0 at reset

; B7	sequential enable
; B6..B4	don't use
; a 1 means the area is RAM
; B3	vector space
; B2	ROM
; B1	MIKEY
; B0	SUZY

; Mikey/Suzy see all memory as RAM

FREE_RAM	EQU $FFF8 (alway RAM !)
; ROM
; $FE00-FFF7


;-----------------------
;- Mikey ($FD00-$FDFF) -
;-----------------------

; timer/counter
TIMER0	EQU $FD00
TIMER1	EQU $FD04
TIMER2	EQU $FD08
TIMER3	EQU $FD0C
TIMER4	EQU $FD10
TIMER5	EQU $FD14
TIMER6	EQU $FD18
TIMER7	EQU $FD1C


HCOUNTER	EQU TIMER0
VCOUNTER	EQU TIMER2
SERIALRATE	EQU TIMER4

; for every timer
TIM_BAKUP	EQU 0	; backup-value (count+1)
TIM_CNTRL1	EQU 1	; timer-control register
TIM_CNT	EQU 2	; current counter
TIM_CNTRL2	EQU 3	; dynamic control

; TIM_CNTRL1
TIM_IRQ	EQU %10000000	; enable interrupt (not TIMER4 !)
TIM_RESETDONE	EQU %01000000	; reset timer done
TIM_MAGMODE	EQU %00100000	; nonsense in Lynx !!
TIM_RELOAD	EQU %00010000	; enable reload
TIM_COUNT	EQU %00001000	; enable counter
TIM_LINK	EQU %00000111
; link timers (0->2->4 / 1->3->5->7->Aud0->Aud1->Aud2->Aud3->1
TIM_64us	EQU %00000110
TIM_32us	EQU %00000101
TIM_16us	EQU %00000100
TIM_8us	EQU %00000011
TIM_4us	EQU %00000010
TIM_2us	EQU %00000001
TIM_1us	EQU %00000000

;TIM_CNTRL2 (read-only)
; B7..B4 unused
TIM_DONE	EQU %00001000	; set if timer's done; reset with TIM_RESETDONE
TIM_LAST	EQU %00000100	; last clock (??)
TIM_BORROWIN	EQU %00000010
TIM_BORROWOUT	EQU %00000001

; Audio registers

AUDIO_A	EQU $FD20
AUDIO_B	EQU $FD28
AUDIO_C	EQU $FD30
AUDIO_D	EQU $FD38

VOLUME_CNTRL	EQU 0
FEEDBACK_ENABLE EQU 1	; enables 11/10/5..0
OUTPUT_VALUE	EQU 2
SHIFTER_L	EQU 3
AUD_BAKUP	EQU 4
AUD_CNTRL1	EQU 5
AUD_COUNT	EQU 6
AUD_CNTRL2	EQU 7

; AUD_CNTRL1
FEEDBACK_7	EQU %10000000
AUD_RESETDONE	EQU %01000000
AUD_INTEGRATE	EQU %00100000
AUD_RELOAD	EQU %00010000
AUD_CNTEN	EQU %00001000
AUD_LINK	EQU %00000111
; link timers (0->2->4 / 1->3->5->7->Aud0->Aud1->Aud2->Aud3->1
AUD_64us	EQU %00000110
AUD_32us	EQU %00000101
AUD_16us	EQU %00000100
AUD_8us	EQU %00000011
AUD_4us	EQU %00000010
AUD_2us	EQU %00000001
AUD_1us	EQU %00000000

; AUD_CNTRL2 (read only)
; B7..B4	; shifter bits 11..8
; B3	; who knows
; B2	; last clock state (0->1 causes count)
; B1	; borrow in (1 causes count)
; B0	; borrow out (count EQU 0 and borrow in)

ATTEN_A	EQU $FD40
ATTEN_B	EQU $FD41
ATTEN_C	EQU $FD42
ATTEN_D	EQU $FD43
; B7..B4 attenuation left ear (0 silent ..15/16 volume)
; B3..B0       "     right ear

MPAN	EQU $FD44
; B7..B4 left ear
; B3..B0 right ear
; B7/B3 EQU Audio D
; a 1 enables attenuation for channel and side


MSTEREO	EQU $FD50	; a 1 disables audio connection
AUD_D_LEFT	EQU %10000000
AUD_C_LEFT	EQU %01000000
AUD_B_LEFT	EQU %00100000
AUD_A_LEFT	EQU %00010000
AUD_D_RIGHT	EQU %00001000
AUD_C_RIGHT	EQU %00000100
AUD_B_RIGHT	EQU %00000010
AUD_A_RIGHT	EQU %00000001


AUDIN	EQU $FD86
; B7 EQU audio-in comparator

SYSCTL1	EQU $FD87
CART_STROBE	EQU %00000001
POWER_ON	EQU %00000010

IODIR	EQU $FD8A	; write only, copy in _IODIR
; 1 EQU output
; it's set $1A by INITMIKEY

IODAT	EQU $FD8B
; it's set to $1B by INITMIKEY

; B7..B5	unsused
AUDIN_BIT	EQU %00010000	; CartPort PIN 32
RESET	EQU %00001000	; reset cart address
NOEXP	EQU %00000100	; =1 => no ComLynx-connector
CARTPOWERON	EQU %00000010	; 0 turns power on
EXTPOWER	EQU %00000001	; (in Lynx II alway 1 !!)


SERCTL	EQU $FD8C	; serial control
; write
TXINTEN	EQU %10000000	; enable TX interrupt
RXINTEN	EQU %01000000	; enable RX interrupt
PAREN	EQU %00010000	; disable parity  !!!!
RESETERR	EQU %00001000	; reset ALL errors
TXOPEN	EQU %00000100	; open collector driver
TXBRK	EQU %00000010	; send BRK
PAREVEN	EQU %00000001	; use EVEN parity
; read
TXRDY	EQU %10000000	; TX buffer empty
RXRDY	EQU %01000000	; received character ready
TXEMPTY	EQU %00100000	; transmitter totally done
PARERR	EQU %00010000	; parity error
OVERRUN	EQU %00001000	; receiver overrun
FRAMERR	EQU %00000100	; framing error (wrong baud-rate !)
RXBRK	EQU %00000010	; BRK received
PARBIT	EQU %00000001	; parity or 9th bit

SERDAT	EQU $FD8D

SDONACK	EQU $FD90	; Suzy done acknoledge
CPUSLEEP	EQU $FD91
DISPCTL	EQU $FD92	; set to $D by INITMIKEY

; B7..B4	0
; B3	1 EQU color
; B2	1 EQU 4 bit mode
; B1	1 EQU flip screen
; B0	1 EQU video DMA enabled

PBKUP	EQU $FD93	; INT((((line time-0.5us)/15)*4)-1)
; set by FRAMERATE, don't mess around
DISPADR	EQU $FD94	; low/high bits 0/1 must be 0 (write-only !!)

GREEN0	EQU $FDA0	; bit 3..0 EQU green
GREEN1	EQU $FDA1
GREEN2	EQU $FDA2
GREEN3	EQU $FDA3
GREEN4	EQU $FDA4
GREEN5	EQU $FDA5
GREEN6	EQU $FDA6
GREEN7	EQU $FDA7
GREEN8	EQU $FDA8
GREEN9	EQU $FDA9
GREENA	EQU $FDAA
GREENB	EQU $FDAB
GREENC	EQU $FDAC
GREEND	EQU $FDAD
GREENE	EQU $FDAE
GREENF	EQU $FDAF

BLUERED0	EQU $FDB0	; bit 7..4 EQU blue
BLUERED1	EQU $FDB1	; bit 3..0 EQU red
BLUERED2	EQU $FDB2
BLUERED3	EQU $FDB3
BLUERED4	EQU $FDB4
BLUERED5	EQU $FDB5
BLUERED6	EQU $FDB6
BLUERED7	EQU $FDB7
BLUERED8	EQU $FDB8
BLUERED9	EQU $FDB9
BLUEREDA	EQU $FDBA
BLUEREDB	EQU $FDBB
BLUEREDC	EQU $FDBC
BLUEREDD	EQU $FDBD
BLUEREDE	EQU $FDBE
BLUEREDF	EQU $FDBF


;----------------------
;- Suzy ($FC00-$FCFF) -
;----------------------
;-----------------
;- sprite engine -
;-----------------
;                $FC00   (ENG)  Temporary address
;                $FC02   (ENG)  accumulator for tilt
HOFF            EQU $FC04 ;(CPU)   Offset to H-edge of screen
VOFF            EQU $FC06 ;(CPU)   Offset to V-edge of screen
VIDBAS          EQU $FC08 ;(CPU)   Video build-buffer (8K)
COLLBAS         EQU $FC0A ;(CPU)   Collision buffer (8K)
;                $FC0C  (ENG)   current video build address
;                $FC0E  (ENG)   current collision build address
SCBNEXT         EQU $FC10 ;(SCB)   address of next SCB
SPRDLINE        EQU $FC12 ;(SCB)   start of sprite-data line address
HPOSSTRT        EQU $FC14 ;(SCB)   start X
VPOSSTRT        EQU $FC16 ;(SCB)   start Y
SPRHSIZ         EQU $FC18 ;(SCB)   H size
SPRVSIZ         EQU $FC1A ;(SCB)   V size
;                $FC1C  (ENG)   H size adder
;                $FC1E  (ENG)   H pos. adder (tilt)
;                $FC20  (ENG)   offset to next data line
;                $FC22  (ENG)   current Y
COLLOFF EQU        $FC24 ;(CPU)   offset to collision depository
;                $FC26  (ENG)   Vsize accumulator
HSIZOFF         EQU $FC28 ;(CPU)   H size offset
VSIZOFF         EQU $FC2A ;(CPU)   V size offset
;                $FC2C  (ENG)   current SCB address
;                $FC2E  (ENG)   current sprite data address
; $FC30..4F             (---)   not used
;                $FC50  (ENG)   do not use (why ???)
MATHD           EQU $FC52
MATHC           EQU $FC53
MATHB           EQU $FC54
MATHA           EQU $FC55
MATHP           EQU $FC56
MATHN           EQU $FC57
; $FC58..5F                     do not use
MATHH           EQU $FC60
MATHG           EQU $FC61
MATHF           EQU $FC62
MATHE           EQU $FC63
; $FC64..6B                     do not use
MATHM           EQU $FC6C
MATHL           EQU $FC6D
MATHK           EQU $FC6E
MATHJ           EQU $FC6F
; $FC70..7F                     do not use
;                $FC80  (ENG)   sprite control bits (SCB[0])
; B7/6	bits per pixel -1
; B5	=1 => h flip
; B4	=1 => v flip
; B3	reserved
; B2..B0	sprite type
ONE_PER_PIXEL	equ %00000000
TWO_PER_PIXEL	equ %01000000
THREE_PER_PIXEL	equ %10000000
FOUR_PER_PIXEL	equ %11000000
HFLIP	equ %00100000
VFLIP	equ %00010000

SCB_BCKSHADOW	equ %00000000
SCB_BCKNOCOLL	equ %00000001
SCB_BNDSHADOW	equ %00000010
SCB_BOUNDARY	equ %00000011
SCB_NORMAL	equ %00000100
SCB_NOCOLL	equ %00000101
SCB_XORSHADOW	equ %00000110
SCB_SHADOW	equ %00000111

;	 $FC81	Sprite control bits 1 SCB[1]
LITERAL	equ %10000000
;SHIFTER	equ %01000000	; don't use, broken
RELOAD_HV	equ %00010000	; reload Hsize and Vsize
RELOAD_HVS	equ %00100000	; reload Hsize,Vsize and stretch
RELOAD_HVST	equ %00110000	; reload Hsize,Vsize,stretch and tilt
REUSE_PALETTE	equ %00001000	; use existing palette
SKIP_SPRITE	equ %00000100	; skip this sprite
DRAW_UP	equ %00000010
DRAW_LEFT	equ %00000001

;	$FC82	Sprite Collision Number  SCB[2]
SCB_DONTCOLL	equ %00100000
;		lower nibble is coll. number

SPRINIT	EQU $FC83	; set to $F3 before any sprite-op
SUZYBUSEN	EQU $FC90	; bit 0 EQU 1 Suzy bus enabled
SPRGO	EQU $FC91	; Sprite Process Start Bit
SCB_START	equ %00000001
; write starts sprite-engine, is reset after completion
SCB_EVERON	equ %00000100	; enable everon detector

SPRSYS	EQU $FC92	; system control bits
; will be initialised in INITSUZY
; with DONT_COLLIDE+CLR_UNSAFE
; copy in _SPRSYS
* WRITE
SIGNED_MATH	EQU %10000000
USE_AKKU	EQU %01000000
DONT_COLLIDE	EQU %00100000	;*
VERT_STRETCH	EQU %00010000
FLIP_JOYPAD	EQU %00001000
CLR_UNSAFE	EQU %00000100	;*
STOP_SPRITE	EQU %00000010
RESERVED	EQU %00000001
;READ
COMPUTING	EQU %10000000	; =1 => still doing math
AKKU_OVERFLOW	EQU %01000000
LAST_CARRY	EQU %00100000
;VERT_STRETCH	EQU %00010000
;FLIP_JOYPAD	EQU %00001000
UNSAFE_ACCESS	EQU %00000100
RESERVED2	EQU %00000010
SUZY_DONE	EQU %00000001	; =1 => sprite enging is running

JOYPAD	EQU $FCB0
JOY_UP	EQU %10000000
JOY_DOWN	EQU %01000000
JOY_LEFT	EQU %00100000
JOY_RIGHT	EQU %00010000
JOY_OPT1	EQU %00001000
JOY_OPT2	EQU %00000100
JOY_B	EQU %00000010
JOY_A	EQU %00000001

SUZY_IO	EQU $FCB1
JOY_PAUSE	EQU %00000001
SW_CON	EQU %00000100

CART0	EQU $FCB2
CART1	EQU $FCB3

; $FCB4..$FCFF	not allocated or Howard-board specific

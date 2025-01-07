* -*-asm-*-
* DEBUG.INC
*
* modified:
*
* 21.6.95       DebugEnable-Flag
*  3.2.96       Loader included
* 24.2.96       Debugging improved : $82 - continue
*                    $83 - set registers
*                    $84 - write : 0 - byte
*                          1 - word (hi first!)
*                          2 - bytes
*                    $85 - read  : 0/1/2
*
* 11.8.96       $81,"M" : This cmd. sends the complete RAM to host
*                       modified Loader : not self-mod. anymore, shorter
* 16.8.96       removed $81,"M"
*                       changed BRK-remote commands :
*                       $84,addr,n
*                       $85,addr,n
* 19.8.96       bug found: BRKserver now has a own SendByte-routine
*
* 28.8.96       included special-BRK : BRK #$FF only sends data and continues
*  2.8.96       TxDone is cleared after BRK
* 23.12.96      Test for the Profiling BRK changed
*                       wait until Xmitter done after host-command
* 26.03.97      BRK-server waits for echo on ComLynx
* 18.11.97      moved Loader installation from serial/talktalk..
*                       added :      $86 - get registers
*                       if BRK comes up while not in monlynx, this helps to get
*                       the current status
* 7.1.25        added $8f - breakpoint to distinguish breakpoint from $86
*

***************
* ComLynx-loader
***************
InstallLoader::
	ldy $fff9
	lda #$C
	sta $fff9		; enable RAM under the ROM

	ldx #LoaderLen-1	; put Loader in the right place
.loop
	  lda _Loader,x
	  sta Loader,x
	  dex
	bpl .loop
	sty $fff9
	stz DebugFlag
	rts

_Loader	set *	; save current PC

	RUN $fe00	; place Loader under ROM

load_len	equ $0
load_ptr	equ $2
load_ptr2	equ $4

	MACRO READ_BYTE
.\w
	bit $fd8c
	bvc .\w
	lda $fd8d
	ENDM

Loader::
	ldy #4
.loop0
	  READ_BYTE
	  sta load_len-1,y
	  dey
	bne .loop0	; get destination and length
	tax	; lowbyte of length

	lda load_ptr
	sta load_ptr2
	lda load_ptr+1
	sta load_ptr2+1

.loop1
	inx
	bne .1
	inc load_len+1
	bne .1
	jmp (load_ptr)

.1	READ_BYTE
	sta (load_ptr2),y
	sta $fda0
	iny
	bne .loop1
	inc load_ptr2+1
	bra .loop1

LoaderE	equ *

LoaderLen	equ LoaderE-Loader

	echo "Loader size:%DLoaderLen"
	RUN _Loader+LoaderLen
***************
* Debug-Handler
* used _ONLY_ by SerialIRQ
***************
do_debug::
	bit DebugEnable
	bmi .no_debug
	cmp #$81
	bne .no_head	; no DEBUG-command =>
	sta DebugFlag	; set flag
	clc		; C=0 => SERIAL ,don't use this byte
	rts
.no_debug
	sec		; C=1 => use this one
	rts

.no_head
	bit DebugFlag	; flag set ?
	bpl .no_debug	; >0 => no => ready
	cmp #"P"	; (P)rogram down-load ?
	bne .cont
	sei
	lda #$C
	sta $fff9	; enable RAM under the ROM/vectors
	jmp Loader	; get it
.cont
	cmp #"R"	; (R)eset ?
	bne .cont1
	jmp Start	; yes => reset program
.cont1
	IFD ScreenBase
	cmp #"S"
	beq screen_to_comlynx
	ENDIF
* Headerbyte $81 + undefinded command
* => 'resend' the header-byte

.exit
	pha
	lda #$81

 IFD TALKTALK	 ; which IRQ-service-routine ?
	ldx MessagePtrIn
.ok_rx
	sta MessageBufferIn,x
	inx
	cpx MessageLenIn
	bne .exit0
	lda MessageReceived
	bne .overrun
	lda #$FF
	sta MessageReceived
	stz FirstByteIn
.exit0	stx MessagePtrIn
 ENDIF
****************
 IFD SERIAL
	ldx RxPtrIn
	sta RxBuffer,x
	txa
	inx
IF RxBufferSize<>256
	cpx #RxBufferSize
	bne .cont0
	ldx #0
.cont0
ENDIF
	cpx RxPtrOut
	bne .exit0
	tax
.exit0
	stx RxPtrIn
 ENDIF
****************
 IFD MSG
	ldx RxPtrIn
	sta RxBuffer,x
	inc RxPtrIn
 ENDIF

	pla
.exit1
	stz DebugFlag
	sec
	rts

 IFD TALKTALK
.overrun
	lda #$80
	tsb SerialStat
	pla
	sec
	rts
 ENDIF
****************
* send the current screen
* via comlynx
****************
 IFD ScreenBase
screen_to_comlynx::
	phy
	ldx #31
.loopc
	  lda $fda0,x
	  jsr SendByte
	  dex
	bpl .loopc	; colors first
	ldy #102
;-- send screen with Y lines
IF DBUFuser=1		; send current screen !!
	MOVE ScreenBase2,DebugPtr
ELSE
	MOVE ScreenBase,DebugPtr
ENDIF
.loopy
	    ldx #79
.loopx
	    lda (DebugPtr)
	    inc DebugPtr
	    bne .cont
	    inc DebugPtr+1
.cont	    jsr SendByte
	    dex
	  bpl .loopx
	  dey
	bne .loopy
	jmp Start	; reset
 ENDIF
****************
* send one byte
****************
SendByte
	bit $fd8c
	bpl SendByte
	sta $fd8d
	rts
****************

 IFD BRKuser
****************
* Init BRK-server
InitBRK::
	ldy $fff9
	lda #$C
	sta $fff9		; enable RAM under the ROM

	ldx #BRKlen
.1
	  lda _BRKserver-1,x
	  sta BRKserver-1,x
	  dex
	bne .1
	MOVEI EnterBRK,BRKvec
	ldx #_EnterBRKe-_EnterBRK-1
.2
	  lda _EnterBRK,x
	  sta EnterBRK,x
	  dex
	bpl .2
	sty $fff9
	rts
_EnterBRK
	pha
	lda #$C	; vectors + ROM = RAM
	sta $fff9
	jmp BRKserver
_EnterBRKe
****************
_BRKserver	set *
	RUN $FF00
****************
* BRKserver handles BRK #xx
* and host-commands
****************
BRKserver::
	cld	; we do it binary ;-)
	pla
	sta SaveA
	stx SaveX
	sty SaveY
	pla
	sta SaveP
	ply
	sty SavePC
	plx
	stx SavePC+1	; brk pushes next address !!!
	dey
	sty DebugPtr
	iny
	bne .cont
	dex
.cont
	stx DebugPtr+1
	lda (DebugPtr)	; get BRK-number
	sta SaveBRKNum
	tsx
	stx SaveS
*
* re-init serial port
*
	lda #%11101
	sta $fd8c
	lda #%00011000	 ; enable count,enable reload
	sta $fd11
_brk_baud
	lda #125000/Baudrate-1
	sta $fd10
*
* send current registers
*
	jsr BRKSendBreakpoint
*
* wait until the comlynx-port is silent
*
.wait0
	bit $fd8c
	bvc .wait1
	lda $fd8d
	bra .wait0
.wait1
*
* check for profiling-BRK
*
	lda SaveBRKNum
	inc
	beq .99		; on BRK #$FF => continue
*
* wait for a command-byte
*
	jsr BRK_RecByte ; get host command
	sec
	sbc #$82
	bcc .wait0	; illegal => enjoy the silence
	beq .99
	cmp #MAX_BRK_FN-$82+1
	bge .wait0	; too big => silence
*
* compute the offset
*
	asl
	tax
	jsr call_BRK_fn ; and make Master happy
*
* wait, until Tx totally done
*
	lda #$20
.wait2
	bit $fd8c
	beq .wait2

	bra .wait0
*
* continue from BRK and restore registers
*
Continue
.99
 IFD SERIAL
	lda #%01011101
	sta $fd8c	; reset ComLynx-errors and enable RX-irq
	stz TxDone
 ENDIF
	ldx SaveS	; leave BRK-irq
	txs
	lda SavePC+1
	pha
	lda SavePC
	pha
	lda SaveP
	pha
	lda SaveA
	ldx SaveX
	ldy SaveY
	rti
*
* jump via X to the BRK-command
*
call_BRK_fn::
	jmp (BRK_routs_host,x)
*
* remote-routines
*
BRK_routs_host::
	dc.w Continue		; $82
	dc.w BRKSetRegisters	; $83,A,X,Y,S,P,PC
	dc.w BRKWriteMem	; $84,addr,n,...
	dc.w BRKReadMem		; $85,addr,n
	dc.w BRKSendRegisters	; $86

MAX_BRK_FN	equ $86
****************
* Send breakpoint number and fall into sending registers
BRKSendBreakpoint::
	ldx #8
	SKIP2			; skip next instruction
* send current registers
BRKSendRegisters::
	ldx #7
loop
	  lda SaveA,x
	  jsr BRKSendByte
	  dex
	bpl loop
	rts
****************
* set processor registers
* bytes are send : PC-high,PC-low,S,P,Y,X,A
****************
BRKSetRegisters::
	ldx #6
.loop1
	  jsr BRK_RecByte
	  sta SaveA,x
	  dex
	bpl .loop1
	rts
****************
* modify Lynx memory
* $84,addr,n
****************
BRKWriteMem::
	jsr GetAddrCnt
.loop
	  jsr BRK_RecByte	; what
	  sta (DebugPtr),y
	  iny
	  dex
	bne .loop
	rts
****************
* read Lynx memory
* $85,addr,n
****************
BRKReadMem::
	jsr GetAddrCnt
.loop
	  lda (DebugPtr),y
	  jsr BRKSendByte
	  iny
	  dex
	bne .loop
	rts
****************
* read Address and count
GetAddrCnt::
	jsr BRK_RecByte
	sta DebugPtr+1
	jsr BRK_RecByte
	sta DebugPtr
	jsr BRK_RecByte
	tax
	ldy #0
	rts
****************
* send/reveice a byte
****************
*
* send serial-data
*
BRKSendByte::
	bit $fd8c
	bpl BRKSendByte
	sta $fd8d
;>	  rts
*
* wait for serial-data
*
BRK_RecByte::
	bit $fd8c
	bvc BRK_RecByte
	lda $fd8d
	rts
****************
* saved registers
****************
SaveA::	ds 1
SaveX	ds 1
SaveY	ds 1
SaveP	ds 1
SaveS	ds 1
SavePC	ds 2
SaveBRKNum
	ds 1
	dc.b $8f		; Header
****************
BRKend	set *

 IF BRKend > $fff8
    FAIL "Change start of BRKserver ! Current end: %HBRKend "
 ENDIF

BRKlen	set BRKend-BRKserver
BRKstart set $FFF8-BRKlen

	echo "length of BRK-server :%DBRKlen"
	echo "End of BRK-server:%HBRKend"
 IF BRKstart <> BRKserver
	echo "Possible start: %HBRKstart"
 ENDIF
	RUN _BRKserver+BRKlen
ENDIF ; BRKuser

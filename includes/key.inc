* -*-asm-*-
IFD KBD_DELAY
LongDelay	equ KBD_DELAY
ELSE
LongDelay	equ 400 ; ms
ENDIF

IFD KBD_RATE
ShortDelay	equ KBD_RATE
ELSE
ShortDelay	equ 200  ; ms
ENDIF
;**************
InitKey::
	stz LastButton
	stz LastCursor
	stz KeyCounter
	stz KeyCounter+1
	lda #<.dummy
	sta PausePtr
	sta PausePtr+2
	lda #>.dummy
	sta PausePtr+1
	sta PausePtr+3
	sei

.dummy	rts
;***************
;* Tastendruck mit
;* Delay/Repeat holen
;***************
GetKey::
	READKEY
	lda Button
	ora Cursor
	bne .cont
	stz LastButton
	stz LastCursor
	lda #0
	rts
.cont	lda Button
	cmp LastButton
	bne .cont1
	lda Cursor
	cmp LastCursor
	beq .cont2
;-- same button or combination
.cont1	lda Button
	sta LastButton
	lda Cursor
	sta LastCursor
	SET_KEYCOUNTER LongDelay
	lda #$ff
	rts
;-- same button or combination
.cont2	lda KeyCounter
	ora KeyCounter+1
	bne .cont3
	SET_KEYCOUNTER ShortDelay
	lda #$ff
	rts
.cont3	lda #0
	stz Button
	stz Cursor
	rts
;***************
;* Read button and do actions
;***************
ReadKey::
	jsr GetKey
	beq .exit1
ReadKey2
	lda Button
	beq .exit0
	and #_RESTART	; Pause+Opt 1 => Restart
	cmp #_RESTART
	bne .cont0
	jmp Start
.cont0	lda Button
	and #_FLIP	; Pause+Opt2 => Flip
	cmp #_FLIP
	beq Flip
.cont1	lda Button
	bit #_PAUSE	; Pause ?
	bne Pause
.exit0	lda #$ff
.exit1	rts
;***************
;* auf Button warten
;***************
WaitKey::
WaitButton::
	jsr ReadKey
	bne WaitButton
.wait	jsr ReadKey
	beq .wait
	rts
;***************
Flip::	VSYNC
	FLIP
	lda #0
	rts
;***************
Pause::	lda PauseEnable	; Pause allowed ?
	bne .cont	; <> 0 => PAUSE
	lda #0
	rts

.cont	lda #$80
	tsb PauseFlag	; already paused ?
	bne ExitPause
.cont1	lda minutes	; save time
	pha
	lda seconds
	pha
	tsx
	stx LastSP+1	; and current SP
	lda PausePtr+1
	beq .wait0
	jsr DrawPause
.wait0	  READKEY
	  lda Button		; wait until
	  bit #1		; pause-button is release
	bne .wait0
.wait1	jsr ReadKey		; and wait ...
	bra .wait1

ExitPause::
	stz PauseFlag		; clear pause-flag
LastSP	ldx #0
	txs			; restore stack
	lda PausePtr+3
	beq .ok
	jsr ReDrawPause
.ok	pla
	sta seconds
	pla
	sta minutes
	lda #0		; keine Taste gedrÅckt
	rts
DrawPause	jmp (PausePtr)
ReDrawPause	jmp (PausePtr+2)

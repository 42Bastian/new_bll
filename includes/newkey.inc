* -*-asm-*-
* NewKey
* created : 28.03.96
*
* (c) Bastian Schick
*
* last modified :
* DD MM YY
* 31.03.96      GetKey included
*               Buffer (8 button/cursor) included
* 04.05.96      If Pause was disabled, ReadKey killed any PAUSE-press !
* 06.03.97      Added KBD_REPEAT/KB_DELAY constants
* 22.06.98      changed FLIP/Pause-handling
*
*
*
* routines:
* Initkey       set up keyboar-routine and clear local vars
* Keyboard      read keyboard with delay/repeat best to be done in VBL
*                buffered
* GetKey        get a key out of the buffer => Current*
*               Z = 1 => no key
* ReadKey       get a key and do things like PAUSE/RESTART/FLIP


IFND KBD_REPEAT
KBD_DELAY       equ 20
KBD_REPEAT      equ 1
ENDIF

;**************
InitKey::
                stz LastButton
                stz LastCursor

                lda #<.dummy
                sta PausePtr
                sta PausePtr+2
                lda #>.dummy
                sta PausePtr+1
                sta PausePtr+3
.dummy          rts
*
* Keyboard
*
Keyboard::
                READKEY         ; get buttons AND cursor
                bne .1          ; = 0 => no button

                stz LastButton
                bra .50         ; check cursor

.1              lda Button
                cmp LastButton
                beq .10

                stz DelayButton
                ldx #KBD_DELAY
                stx RepeatButton

.10             sta LastButton
                dec DelayButton
                bmi .2
                stz Button
                bra .50


.2              lda RepeatButton
                sta DelayButton
                ldx #KBD_REPEAT
                stx RepeatButton
                dec
                bne .50
                lda EnableButtonRepeat
                and Button
                sta Button

.50             lda Cursor
                bne .51
                stz LastCursor
                bra .59

.51             cmp LastCursor
                beq .510
                stz DelayCursor
                ldx #KBD_DELAY
                stx RepeatCursor

.510            sta LastCursor
                dec DelayCursor
                bmi .52
                stz Cursor
                bra .59


.52             lda RepeatCursor
                sta DelayCursor
                ldx #KBD_REPEAT
                stx RepeatCursor
                dec
                bne .59
                lda EnableCursorRepeat
                and Cursor
                sta Cursor

.59             lda Button
                ora Cursor
                _IFNE
                  ldx KeyPtrIn
                  lda Button
                  sta KeyBuffer,x
                  lda Cursor
                  sta KeyBuffer+8,x
                  txa
                  inc
                  and #7
                  sta KeyPtrIn
                  cmp KeyPtrOut
                  _IFEQ
                    lda KeyPtrOut
                    inc
                    and #7
                    sta KeyPtrOut
                  _ENDIF
                _ENDIF
                rts
*
* GetKey
*
GetKey::        stz CurrentButton
                stz CurrentCursor
                ldx KeyPtrOut
                cpx KeyPtrIn
                beq .99
                lda KeyBuffer,x
                sta CurrentButton
                lda KeyBuffer+8,x
                sta CurrentCursor
                txa
                inc
                and #7
                sta KeyPtrOut
                lda #$ff
.99             rts
*
* ReadKey
*
ReadKey::       jsr GetKey
                beq .exit1
                lda CurrentButton
                beq .exit0
                and #_RESTART   ; Pause+Opt 1 => Restart
                cmp #_RESTART
                bne .cont0
Restart         jmp Start
.cont0          lda CurrentButton
                and #_FLIP      ; Pause+Opt2 => Flip
                cmp #_FLIP
                beq Flip
.cont1          lda CurrentButton
                bit #_PAUSE     ; Pause ?
                bne Pause
.exit0          lda #$ff
.exit1          rts
*
* WaitKey/WaitButton
*
WaitKey::
WaitButton::    jsr ReadKey
                bne WaitButton
.wait           jsr ReadKey
                beq .wait
                rts
*
* Flip
*
Flip::
                VSYNC
                FLIP

.1              READKEY
                lda Button
                cmp #_PAUSE
                beq .1

                lda PauseEnable
                beq .9
                lda PauseFlag
                beq Pause
.9              rts



*
* Pause
*
Pause::         lda PauseEnable ; Pause enable ?
                bne .cont       ; <> 0 => PAUSE
;               lda #0          ; FLAG : no key
lda #$ff
                rts

.cont           lda #$80
                tsb PauseFlag   ; already paused ?
                bne ExitPause
.cont1
                tsx
                stx LastSP+1    ; and SP
                lda PausePtr+1
                _IFNE
                  jsr DrawPause
                _ENDIF
Pause2

.1              READKEY
                lda Button
                cmp #_PAUSE
                beq .1

.wait1          jsr ReadKey     ; wait, wait
                bra .wait1      ; wait ...

ExitPause::     stz PauseFlag   ; clear semaphore
LastSP          ldx #0          ; !! self-modifying !!
                txs             ; get SP
                lda PausePtr+3
                _IFNE
                  jsr ReDrawPause
                _ENDIF

                lda #0          ; FLAG : no key pressed
                rts

DrawPause       jmp (PausePtr)
ReDrawPause     jmp (PausePtr+2)
*

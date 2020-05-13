; da65 V2.13.0 - (C) Copyright 2000-2009,  Ullrich von Bassewitz
; Created:    2009-12-07 11:34:49
; Input file: LYNX.ROM
; Page:       1


        .setcpu "65SC02"

L0000           := $0000
ptr             := $0005
blockCount      := $0007
L0200           := $0200
xx              := $5000
L5018           := $5018
sub_ram         := $505D
InsertDate_ram  := $5092
SUZY            := $FC00
SUZYHREV        := $FC88
RCARD           := $FCB2
MIKEY           := $FD00
SYSCTL1         := $FD87
IODIR           := $FD8A
IODAT           := $FD8B
SDONEACK        := $FD90
CPUSLEEP        := $FD91
GREEN_F         := $FDAF
BLUERED_F       := $FDBF
selSector:
        sec
        bra     LFE0D
LFE03:  bcc     LFE09
        stx     IODAT
        clc
LFE09:  inx
        stx     SYSCTL1
LFE0D:  ldx     #$02
        stx     SYSCTL1
        rol     a
        stz     IODAT
        bne     LFE03
        rts
ClearRAM:
        stz     $01
        lda     #$00
LFE1D:  sta     (L0000),y
        iny
        bne     LFE1D
        inc     $01
        bne     LFE1D
setupMikey:
        ldx     #$0D
LFE28:  lda     MikeyInitData,x
        ldy     MikeyInitOffset,x
        sta     MIKEY,y
        dex
        bne     LFE28
LFE34:  lda     ramCode,x
        sta     xx,x
        inx
        bne     LFE34
        stz     ptr
        lda     #$02
        sta     ptr+1
        stz     $02
        lda     #$00
        jsr     selSector
        lda     RCARD
        cmp     #$FB
        bcc     LFE9D
        sta     blockCount
        stz     GREEN_F
        stz     BLUERED_F
LFE59:  ldx     #$32
LFE5B:  lda     RCARD
        sta     $AA,x
        dex
        bpl     LFE5B
        ora     $AB
        ora     $AC
        beq     LFE9D
        ldx     #$02
LFE6B:  lda     $AA,x
        sbc     RSAKey,x
        dex
        bpl     LFE6B
        bcs     LFE9D
        jsr     xx
        lda     ($0B)
        cmp     #$15
        bne     LFE9D
        lda     $02
        ldy     #$32
LFE82:  clc
        adc     ($0B),y
        sta     (ptr)
        inc     ptr
        dey
        bne     LFE82
        sta     $02
        inc     blockCount
        bne     LFE59
        ldy     #$02
        sty     IODAT
        tax
        bne     LFE9D
        jmp     L0200
LFE9D:  inc     $03
        bne     setupSuzy
        inc     $04
        bne     setupSuzy
        stz     SYSCTL1
LFEA8:  bra     LFEA8
setupSuzy:
        ldx     #$08
LFEAC:  lda     SuzyInitData,x
        ldy     SuzyInitOffset,x
        sta     SUZY,y
        dex
        bpl     LFEAC
        stz     CPUSLEEP
        stz     SDONEACK
        jmp     setupMikey
ramCode:lda     #$11
        sta     $0B
        lda     #$44
        sta     $5071
        lda     #$AA
        sta     $0F
        jsr     L5018
        lda     $0B
        sta     $0F
        lda     #$77
        sta     $0B
        ldy     #$32
        lda     #$00
LFEDD:  sta     ($0B),y
        dey
        bpl     LFEDD
        iny
LFEE3:  lda     ($0F),y
        sta     $0A
        dec     $08
LFEE9:  lda     $0B
        sta     $5037
        sta     $5043
        sta     $5047
        clc
        ldx     #$32
LFEF7:  rol     L0000,x
        dex
        bpl     LFEF7
        asl     $0A
        bcc     LFF11
        ldx     #$32
        clc
LFF03:  lda     L0000,x
        adc     $AA,x
        sta     L0000,x
        dex
        bpl     LFF03
        jsr     sub_ram
        bcc     LFF14
LFF11:  jsr     sub_ram
LFF14:  lsr     $08
        bne     LFEE9
        iny
        cpy     #$33
        bcc     LFEE3
        rts
sub:    lda     $0B
        sta     $506C
        lda     ($0B)
        cmp     RSAKey
        bcc     LFF42
        ldx     #$32
LFF2C:  lda     L0000,x
        sbc     RSAKey,x
        sta     L0000,x
        dex
        bpl     LFF2C
        bcc     LFF42
        lda     $0B
        ldx     $5071
        stx     $0B
        sta     $5071
LFF42:  rts
InsertSCB:
        .byte   $05,$93,$00,$00,$00
InsertSpritePtr:
        .word   $5092
InsertSCB2:
        .byte   $80,$00,$48,$00,$00,$04,$00,$04
        .byte   $F0
InsertData:
        .byte   $04,$E2,$EA,$87,$04,$FA,$AA,$B7
        .byte   $04,$F2,$08,$97,$04,$FA,$4A,$F7
        .byte   $04,$E2,$E8,$87,$02,$FF,$05,$B5
        .byte   $11,$68,$FF,$04,$B5,$D7,$2D,$04
        .byte   $B9,$91,$0D,$04,$B5,$DD,$4D,$05
        .byte   $19,$11,$68,$FF,$00
boot:   lda     SUZYHREV
        beq     L0000
        pla
        pla
        pla
        pla
        ldy     #$02
        sty     IODAT
        iny
        sty     IODIR
        sty     MEMMAP
        stz     L0000
        jmp     ClearRAM

RSAKey: .byte   $35,$B5,$A3,$94,$28,$06,$D8,$A2
        .byte   $26,$95,$D7,$71,$B2,$3C,$FD,$56
        .byte   $1C,$4A,$19,$B6,$A3,$B0,$26,$00
        .byte   $36,$5A,$30,$6E,$3C,$4D,$63,$38
        .byte   $1B,$D4,$1C,$13,$64,$89,$36,$4C
        .byte   $F2,$BA,$2A,$58,$F4,$FE,$E1,$FD
        .byte   $AC,$7E
MikeyInitOffset:	// $FFCC
        .byte   $79,$90,$92,$95,$94,$93,$09,$08
        .byte   $BF,$AF,$B0,$A0
MikeyInitData:		// $ffd8
        .byte   $01,$00,$0D,$20,$00,$29,$1F,$68
        .byte   $3E,$0E,$00,$00,$18,$9E

SuzyInitOffset:		// $FEE6
        .byte   $91,$11,$10,$09,$08,$06,$04,$90,$92
SuzyInitData:		// $FEEF
        .byte   $01,$50,$82,$20,$00,$00,$00,$01,00

        .byte 	$00

MEMMAP: .byte   $F0
LFFFA:  .word   $3000,$FF80,$FF80

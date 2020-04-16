****************
*
* DEMO 6
* created : 29.05.95
*
* date          changes
* 04.05.96      NEWKEY included
*

DEBUG		set 1
Baudrate        set 62500

_1000HZ_TIMER   set 7

IRQ_SWITCHBUF_USR set 1

CUBE            equ 1

DIAMANT         equ 1
PRISMA          equ 2
BALL            equ 3
WUERFEL          equ 4
ZYLINDER        equ 5
WUERFEL2         equ 6
GLEITER         equ 7
OBJEKT          equ WUERFEL

dist            equ 100

* some switches
HIDEFACE        equ 1
GRID            equ 0
NEWPOLYGON      equ 1


max_punkte      equ 62


		include <includes/hardware.inc>
****************
                MACRO DoSWITCH
                dec SWITCHFlag
.\wait_vbl      bit SWITCHFlag
                bmi .\wait_vbl
                ENDM

                MACRO NEG
                sec
                tya
                sbc \0
                sta \0
                tya
                sbc 1+\0
                sta 1+\0
                ENDM

                MACRO SINUS
                ldx \0
                lda SinTab.Lo,x
                sta \1
                lda SinTab.Hi,x
                sta \1+1
                ENDM

                MACRO COSINUS
                clc
                lda \0
                adc #64
                tax
                lda SinTab.Lo,x
                sta \1
                lda SinTab.Hi,x
                sta \1+1
                ENDM

****************
* macros
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/font.mac>
                include <macros/window.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
                include <macros/irq.mac>
                include <macros/newkey.mac>
                include <macros/debug.mac>
****************
* variables
                include <vardefs/debug.var>
                include <vardefs/help.var>
                include <vardefs/font.var>
                include <vardefs/window.var>
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
                include <vardefs/irq.var>
                include <vardefs/newkey.var>
                include <vardefs/serial.var>
                include <vardefs/1000Hz.var>
                IF GRID
                  include <vardefs/polygon.var>
                ELSE
                  include <vardefs/fpolygon.var>
                ENDIF
                include <vardefs/draw.var>
****************************************************

 BEGIN_ZP
poly_color      ds 1
ptr1            ds 2
counter         ds 1
flag            ds 1
winkel          ds 1
winkel_nk       ds 1  ; Nachkomma
winkel_add1     ds 1
amplitude       ds 1
Y               ds 1
frame_counter   ds 1

IF CUBE
*********************
* Variables for Draw
color           ds 1
if 0
delta_x         ds 2
delta_y         ds 2
delta           ds 2
x1              ds 2
y1              ds 2
x2              ds 2
y2              ds 2
*********************
ENDIF
*********************
* variables for projection
hilfe           ds 2
hilfex          ds 2
hilfez          ds 2
hilfe_sign      ds 1
sign            ds 1
*********************
pos_x           ds 2
pos_y           ds 2
pos_z           ds 2
winkel_x        ds 1
winkel_y        ds 1
winkel_z        ds 1
*********************
* variabls for rotation in _one_ dir.
sinus           ds 2
min_sinus       ds 2
cosinus         ds 2
*********************
* variables for rotation (matrix)
a               ds 2
b               ds 2
c               ds 2
d               ds 2
e               ds 2
f               ds 2
af              ds 2
bf              ds 2
ae              ds 2
be              ds 2

a1              ds 2
b1              ds 2
c1              ds 2
d1              ds 2
e1              ds 2
f1              ds 2
h1              ds 2
i1              ds 2
*********************
points          ds 1  ; # of points
points_mal_2    ds 1
winkel_add      ds 1
farbe           ds 1
face_count      ds 1
ENDIF
Xoffset         ds 2
radius          ds 2
radius_sub      ds 1
radius_flag     ds 1
*********************
 END_ZP

 BEGIN_MEM
irq_vektoren    ds 16
                ALIGN 4
screen0         ds SCREEN.LEN
screen1         ds SCREEN.LEN
scbdata         ds SCREEN.LEN+256
scbtab          ds 160
                ds 160
IF CUBE
*******************
* Speicher fÅr WÅrfel
proj_x          ds max_punkte*2 ; projected X
proj_y          ds max_punkte*2 ; projected Y
rot_x           ds max_punkte*2 ; rotated X,Y,Z-coordinates
rot_y           ds max_punkte*2
rot_z           ds max_punkte*2
sichtbar        ds 100
ENDIF

HBLTable        ds 102
 END_MEM
                run LOMEM
ECHO "START :%HLOMEM ZP : %HNEXT_ZP"
Start::         sei
                cld
                CLEAR_MEM
                CLEAR_ZP
                ldx #0
                txs
                INITMIKEY
                INITSUZY
                SETRGB pal
                INITIRQ irq_vektoren
                INITKEY
                INITFONT LITTLEFNT,RED,WHITE
                jsr Init1000Hz
                FRAMERATE 60
                jsr InitComLynx
                jsr MakeHBLTable
                SETIRQ 2,VBL
                SETIRQ 0,HBL
                SCRBASE screen0,screen1
                SET_MINMAX 0,0,160,102
                jsr MakeSCBs

                lda #$c0
                ora _SPRSYS
                sta SPRSYS
                sta _SPRSYS

                stz _1000Hz
                stz _1000Hz+1
                stz _1000Hz+2
                cli
                jsr InitCube
                lda #20
                sta amplitude
                stz counter
                stz winkel
                lda #$E0
                sta winkel_add1
                stz _1000Hz
                stz _1000Hz+1
                lda #101
                sta Y
                lda #1
                sta frame_counter
                pha
.loop             jsr _cls
                  jsr DrawSCBs4
                  jsr DoCube
                  pla
                  jsr PrintTime
                  DoSWITCH
                  lda _1000Hz
                  pha
                  stz _1000Hz
.ok0              dec Y
                  bpl .ok
                  stz Y
.ok               inc winkel
                  inc counter
                bne .loop
                dec frame_counter
                bne .loop

.loop1            jsr _cls
                  jsr DrawSCBs4
                  jsr DoCube
                  pla
                  jsr PrintTime
                  DoSWITCH
                  lda _1000Hz
                  pha
                  stz _1000Hz
                  inc winkel
                  inc counter
                  clc
                  lda pos_y
                  adc #8
                  sta pos_y
                  lda pos_y+1
                  adc #0
                  sta pos_y+1
                  inc Xoffset
                  lda Xoffset
                  cmp #160
                bne .loop1
                lda #$ff
                ldx #$f
.loop_col         sta $fda0,x
                  stz $fdb0,x
                  sec
                  sbc #11
                  dex
                bpl .loop_col
                stz $fda0
                stz $fdb0

                stz counter
.loop2            MOVEI 40,MATHE_D
                  SINUS counter,MATHE_E
                  WAITSUZY
                  MOVE MATHE_A+1,pos_x
                  COSINUS counter,MATHE_E
                  WAITSUZY
                  MOVE MATHE_A+1,pos_z
                  jsr _cls
                  jsr DoCube
                  pla
                  jsr PrintTime
                  DoSWITCH
                  lda _1000Hz
                  pha
                  stz _1000Hz
                  inc counter
                  sec
                  lda pos_y
                  sbc #8
                  sta pos_y
                  lda pos_y+1
                  sbc #0
                  sta pos_y+1
                bcs .loop2
                stz radius_flag
                lda #$ff
                sta radius_sub
                MOVEI 40,radius
.loop3            MOVE radius,MATHE_D
                  SINUS counter,MATHE_E
                  WAITSUZY
                  MOVE MATHE_A+1,pos_x
                  COSINUS counter,MATHE_E
                  WAITSUZY
                  MOVE MATHE_A+1,pos_z
                  jsr _cls
                  jsr DoCube
                  pla
                  jsr PrintTime
                  lda radius
                  jsr PrintHex
                  DoSWITCH
                  lda _1000Hz
                  pha
                  stz _1000Hz
                  inc counter
                bra .loop3

PrintTime       sta MATHE_B
                MOVEI 1000,MATHE_A
                stz MATHE_A+2
                stz MATHE_A+3
                WAITSUZY
                lda MATHE_D
                stz CurrX
                jmp PrintHex


IF CUBE
*******************
* WÅrfel
InitCube::      lda punkte
                dec
                sta points
                asl
                sta points_mal_2

                stz pos_y
                lda #5
                sta pos_y+1

                stz pos_y
                stz pos_y+1
                stz winkel_x
                stz winkel_y
                stz winkel_z
                stz pos_x
                stz pos_x+1
                stz pos_z
                stz pos_z+1
                lda #1
                sta winkel_add
                rts
******************
** DoCube
DoCube::        jsr ReadKey
                beq .ok
                  lda CurrentButton
                  bit #_FIREA|_FIREB
                  beq .cont1
                  bit #_FIREB
                  beq .cont
                    dec winkel_add
                    bra .cont1
.cont               inc winkel_add
.cont1            lda CurrentButton
                  bit #_OPT1|_OPT2
                  beq .cont3
                  bit #_OPT2
                  beq .cont2
                  clc
                  lda #5
                  adc pos_y
                  sta pos_y
                  bcc .cont3
                    inc pos_y+1
                    bra .cont3
.cont2            sec
                  lda pos_y
                  sbc #5
                  sta pos_y
                  bcs .cont3
                  dec pos_y+1
.cont3          lda CurrentButton
                and #_PAUSE
                cmp #_PAUSE
                bne .ok
                lda radius_sub
                eor #$ff
                inc
                sta radius_sub
                lda #$ff
                sta radius_flag
.ok             jsr RotateXYZ
                jsr Projektion
                jsr ZeichneFlaechen
                lda radius_flag
                beq .cont5
                sec
                lda radius
                sbc radius_sub
                sta radius
                bne .cont4
                  stz radius_flag
                bra .cont5
.cont4          cmp #40
                bne .cont5
                  stz radius_flag
.cont5
if 0
                ldx winkel_add
                clc
                txa
                adc winkel_x
                sta winkel_x
                clc
                txa
                adc winkel_y
                sta winkel_y
                clc
                txa
                adc winkel_z
                sta winkel_z
endif
                rts
ENDIF
****************
VBL::
if 1
                ldx winkel_add
                clc
                txa
                adc winkel_x
                sta winkel_x
                clc
                txa
                adc winkel_y
                sta winkel_y
                clc
                txa
                adc winkel_z
                sta winkel_z
endif
                jsr Keyboard
                IRQ_SWITCHBUF
                END_IRQ

HBL::           ldx $fd0a
                lda HBLTable,x
                sta $fdb0
                END_IRQ


MakeHBLTable::  ldx #15
                ldy #101
.loop             lda SinTab.Lo,x
                  dec
                  and #$0f
                  eor #$0f
                  sta HBLTable,y
                  inx
                  dey
                bpl .loop
                rts
****************
mulAX::         sta $fc52
                stz $fc53
                stx $fc54
                stz $fd55
.wait           lda $fc92
                bmi .wait
                lda $fc60
                rts
****************
DrawSCBs4::     ldy #101
                ldx winkel
                stz flag
                lda Y
                sta SCBy
                stz SCBy+1
                beq .cont0
                stz winkel
                ldx #0
.cont0          lda winkel
                pha
                lda winkel_nk
                pha
.loop             lda scbtab,y
                  sta SCBDATA+2
                  lda scbtab+160,y
                  sta SCBDATA+3
                  lda amplitude
;clc
;adc SCBy
                  sta $fc52
                  stz $fc53

                  lda SinTab.Lo,x
                  sta $fc54
                  lda SinTab.Hi,x
                  sta $fc55
.wait             bit SPRSYS
                  bmi .wait
                  clc
                  lda $fc61
                  adc Xoffset
                  sta SCBx
                  lda Xoffset+1
                  adc $fc62
                  sta SCBx+1
                  clc
                  lda winkel_nk
                  adc winkel_add1
                  sta winkel_nk
                  lda winkel
                  adc #0
                  sta winkel
                  tax
.cont
                  phy
                  lda #<SCB
                  ldy #>SCB
                  jsr DrawSprite
                  ply
                  inc SCBy
                  lda SCBy
                  cmp #102
                  beq .exit
                  dey
                bpl .loop
.exit           pla
                sta winkel_nk
                pla
                sta winkel
                rts
IF 0
DrawSCBs3::     ldy #101
                ldx winkel
                stz flag
                lda Y
                sta SCBy
                stz SCBy+1
                beq .loop
                stz winkel
                ldx #0
.loop             lda scbtab,y
                  sta SCBDATA+2
                  lda scbtab+160,y
                  sta SCBDATA+3
                  lda amplitude
                  clc
                  adc SCBy
                  sta $fc52
                  stz $fc53

                  lda SinTab.Lo,x
                  sta $fc54
                  lda SinTab.Hi,x
                  sta $fc55
.wait             bit SPRSYS
                  bmi .wait
                  lda $fc61
                  sta SCBx
                  lda $fc62
                  sta SCBx+1
                  txa
                  clc
                  adc winkel_add1
                  tax
.cont
stz SCBsizex
lda SCBy
inc
lsr
ror SCBsizex
lsr
ror SCBsizex
sta SCBsizex+1

                  phy
                  lda #<SCB
                  ldy #>SCB
                  jsr DrawSprite
                  ply
                  inc SCBy
                  lda SCBy
                  cmp #102
                  beq .exit
                  dey
                bpl .loop
.exit           rts

DrawSCBs::      ldx #102
                stz SCBy
.loop             lda scbtab,x
                  sta SCBDATA+2
                  lda scbtab+160,x
                  sta SCBDATA+3
                  lda #<SCB
                  ldy #>SCB
                  jsr DrawSprite
                  inc SCBy
                  dex
                bne .loop
                rts


DrawSCBs2::     ldx #102
                stx SCBy
.loop             lda scbtab,x
                  sta SCBDATA+2
                  lda scbtab+160,x
                  sta SCBDATA+3
                  dec SCBy
                  lda #<SCB
                  ldy #>SCB
                  jsr DrawSprite
                  dex
                bne .loop
                rts
ENDIF
****************
_cls::          lda #<clsSCB
                ldy #>clsSCB
                jmp DrawSprite

clsSCB          dc.b $0,$10,0
                dc.w 0,clsDATA
                dc.w 0,0
                dc.w $100*10,$100*102
clsCOLOR        dc.b 0
clsDATA         dc.b 2,%01111100
                dc.b 0

clsSCB2         dc.b $0,$10,0
                dc.w 0,clsDATA
                dc.w 8,8
                dc.w $100*9,$100*86
                dc.b 0
****************
MakeSCBs::      MOVEI piggy-1,ptr               ; Adresse des Bildes
                MOVEI scbdata,ptr1              ; aubereitetes Bild
                ldx #101
.loop             lda ptr1
                  sta scbtab,x
                  sta SCBDATA+2
                  lda ptr1+1
                  sta scbtab+160,x
                  sta SCBDATA+3
                  lda #82
                  sta (ptr1)
                  ldy #1
.loop1              lda (ptr),y
                    sta (ptr1),y
                    iny
                    cpy #81
                  bne .loop1
                  lda #0
                  sta (ptr1),y
                  iny
                  sta (ptr1),y
                  clc
                  lda ptr1
                  adc #83
                  sta ptr1
                  bcc .cont0
                    inc ptr1+1
.cont0            clc
                  lda ptr
                  adc #80
                  sta ptr
                  bcc .cont1
                    inc ptr+1
.cont1            dex
                bne .loop
                rts

SCB             dc.b $c0,$90,$00
SCBDATA         dc.w 0,0
SCBx            dc.w 0
SCBy            dc.w 0
SCBsizex        dc.w $100,$100
                dc.b $01,$23,$45,$67,$89,$AB,$CD,$EF
****************
PrintHex::      phx
                pha
                lsr
                lsr
                lsr
                lsr
                tax
                lda digits,x
                jsr PrintChar
                pla
                and #$f
                tax
                lda digits,x
                jsr PrintChar
                plx
                rts

digits          db "0123456789ABCDEF"
****************
* Sinus-Tabelle
* 8Bit Nachkomma
****************
SinTab.Lo       ibytes <bin/sintab_8.o>
SinTab.Hi       equ SinTab.Lo+256
***************************************************

****************
RotateXYZ::
****************
                COSINUS winkel_z,a
                SINUS winkel_z,b
                COSINUS winkel_y,c
                SINUS winkel_y,d

                COSINUS winkel_x,e
                SINUS winkel_x,f
                ldy #0

                MOVE a,MATHE_C
                MOVE f,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,af
                MOVE b,MATHE_C
                MOVE f,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,bf
                MOVE a,MATHE_C
                MOVE e,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,ae
                MOVE b,MATHE_C
                MOVE e,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,be

                MOVE a,MATHE_C
                MOVE c,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,a1
                sec
                tya
                sbc be
                stz MATHE_AKKU
                sta MATHE_AKKU+1
                tya
                sbc be+1
                sta MATHE_AKKU+2
                tya
                sbc #0
                sta MATHE_AKKU+3
                MOVE af,MATHE_C
                MOVE d,MATHE_E
                WAITSUZY
                MOVE MATHE_AKKU+1,b1
                stz MATHE_AKKU
                MOVE bf,MATHE_AKKU+1
                MOVE ae,MATHE_C
                MOVE d,MATHE_E
                WAITSUZY
                MOVE MATHE_AKKU+1,c1
                MOVE b,MATHE_C
                MOVE c,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,d1
                stz MATHE_AKKU
                MOVE ae,MATHE_AKKU+1
                MOVE bf,MATHE_C
                MOVE d,MATHE_E
                WAITSUZY
                MOVE MATHE_AKKU+1,e1
                stz MATHE_AKKU
                sec
                tya
                sbc af
                sta MATHE_AKKU+1
                tya
                sbc af+1
                sta MATHE_AKKU+2
                tya
                sbc #0
                sta MATHE_AKKU+3
                MOVE be,MATHE_C
                MOVE d,MATHE_E
                WAITSUZY
                MOVE MATHE_AKKU+1,f1
                NEG d
                MOVE c,MATHE_C
                MOVE f,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,h1
                MOVE c,MATHE_C
                MOVE e,MATHE_E
                WAITSUZY
                MOVE MATHE_A+1,i1
                ldx points_mal_2
                ldy punkte
.loop             stz MATHE_AKKU
                  stz MATHE_AKKU+2
                  MOVE a1,MATHE_C
                  MOVE {punkte_x,x},MATHE_E
;               WAITSUZY
                  MOVE b1,MATHE_C
                WAITSUZY
                  MOVE {punkte_y,x},MATHE_E
;               WAITSUZY
                  MOVE c1,MATHE_C
                WAITSUZY
                  MOVE {punkte_z,x},MATHE_E
                  WAITSUZY
                  MOVE MATHE_AKKU+1,{rot_x,x}

                  stz MATHE_AKKU
                  stz MATHE_AKKU+2
                  MOVE d1,MATHE_C
                  MOVE {punkte_x,x},MATHE_E
;               WAITSUZY
                  MOVE e1,MATHE_C
                WAITSUZY
                  MOVE {punkte_y,x},MATHE_E
;               WAITSUZY
                  MOVE f1,MATHE_C
                WAITSUZY
                  MOVE {punkte_z,x},MATHE_E
                  WAITSUZY
                  MOVE MATHE_AKKU+1,{rot_y,x}

                  stz MATHE_AKKU
                  stz MATHE_AKKU+2
                  MOVE d,MATHE_C
                  MOVE {punkte_x,x},MATHE_E
;               WAITSUZY
                  MOVE h1,MATHE_C
                WAITSUZY
                  MOVE {punkte_y,x},MATHE_E
;               WAITSUZY
                  MOVE i1,MATHE_C
                WAITSUZY
                  MOVE {punkte_z,x},MATHE_E
                  WAITSUZY
                  MOVE MATHE_AKKU+1,{rot_z,x}

                  dex
                  dex
                  dey
                  beq .exit
                jmp .loop
.exit           rts

NoRot::         ldx points_mal_2
                inx
.loop             lda punkte_x,x
                  sta rot_x,x
                  lda punkte_y,x
                  sta rot_y,x
                  lda punkte_z,x
                  sta rot_z,x
                  dex
                cpx #$ff
                bne .loop
                rts
****************
* projeziert 3d -> 2d
****************
Projektion::    ldx points_mal_2
                ldy points_mal_2
.loop           phy
                ldy #0
                  clc
                  lda rot_y,x
                  adc pos_y
                  sta hilfe
                  lda rot_y+1,x
                  adc pos_y+1
                  inc
                  sta hilfe+1                   ; hilfe = rot_y[x]+pos_y
                  sta hilfe_sign
                  bpl .ok0
                    NEG hilfe
.ok0              clc                           ; hilfe = |hilfe+256|
                  lda rot_x,x
                  adc pos_x
                  sta hilfex
                  lda rot_x+1,x
                  adc pos_x+1
                  sta hilfex+1                  ; hilfex = rot_x[x]+pos_x
                  clc
                  lda rot_z,x
                  adc pos_z
                  sta hilfez
                  lda rot_z+1,x
                  adc pos_z+1
                  sta hilfez+1                  ; hilfez = rot_z[x]+pos_z
                  lda hilfe
                  ora hilfe+1
                  bne .cont2a
                  jmp .cont2                    ; hilfe = 0 =>
.cont2a             lda hilfe_sign
                    eor hilfex+1
                    sta sign
                    lda hilfex+1
                    bpl .ok1
                      NEG hilfex
.ok1                MOVE hilfe,MATHE_B
                    stz MATHE_A
                    MOVE hilfex,MATHE_A+1       ; |rot_x+pos_x|*256
                    stz MATHE_A+3
                    WAITSUZY
                    MOVE MATHE_D,hilfex         ; hilfex = |rot_x+pos_x|*256/hilfe
                    bit sign
                    bpl .cont1
                      NEG hilfex
.cont1              lda hilfe_sign
                    eor hilfez+1
                    sta sign
                    lda hilfez+1
                    bpl .ok2
                      NEG hilfez
.ok2                MOVE hilfe,MATHE_B
                    stz MATHE_A
                    MOVE hilfez,MATHE_A+1
                    stz MATHE_A+3
                    WAITSUZY
                    MOVE MATHE_D,hilfez
                    bit sign
                    bpl .cont2
                      NEG hilfez
.cont2            ply
                  clc
                  lda hilfex
                  adc #80
                  sta proj_x,y
                  lda hilfex+1
                  adc #0
                  sta proj_x+1,y
                  clc
                  lda hilfez
                  adc #51
                  sta proj_y,y
                  lda hilfez+1
                  adc #0
                  sta proj_y+1,y
                  dex
                  dex
                  dey
                  dey
                  cpy #$fe
                  beq .exit
                jmp .loop
.exit           rts
****************
* draw all faces
****************
ZeichneFlaechen::lda #10
                sta poly_color
                stz face_count
                ldx #5
.loop0            stz sichtbar,x                ; all faces invisible
                  dex
                bpl .loop0
                ldy #0
                bra .loop
.exit           rts
.loop             ldx faces,y
                  inx
                  beq .exit
                  dex
IF HIDEFACE
                stz MATHE_AKKU
                stz MATHE_AKKU+2
                sec
                ldx faces+1,y
                MOVE {proj_x,x},hilfe           ; xp(f1)
                ldx faces,y
                sec
                lda hilfe
                sbc proj_x,x
                sta MATHE_C
                lda hilfe+1
                sbc proj_x+1,x
                sta MATHE_C+1                   ; -xp(f0)
                sec
                ldx faces+2,y
                MOVE {proj_y,x},hilfe
                ldx faces+1,y
                sec
                lda hilfe
                sbc proj_y,x
                sta MATHE_E
                lda hilfe+1
                sbc proj_y+1,x
                sta MATHE_E+1
                WAITSUZY
                ldx faces+1,y
                MOVE {proj_x,x},hilfe
                ldx faces+2,y
                sec
                lda hilfe
                sbc proj_x,x
                sta MATHE_C
                lda hilfe+1
                sbc proj_x+1,x
                sta MATHE_C+1   ; -(xp(f2)-xp(f1))=(xp(f1)-xp(f2)
                ldx faces+1,y
                MOVE {proj_y,x},hilfe
                ldx faces,y
                sec
                lda hilfe
                sbc proj_y,x
                sta MATHE_E
                lda hilfe+1
                sbc proj_y+1,x
                sta MATHE_E+1
                WAITSUZY
                lda MATHE_AKKU+3 ; >0 ?? => viewable
                bmi .cont
                ora MATHE_AKKU+2
                ora MATHE_AKKU+1
                ora MATHE_AKKU
                beq .cont
ENDIF ;(* HIDEFACE *)
if GRID
                lda poly_color
                jsr Polygon
else
                ldx face_count
                dec sichtbar,x
                txa
                and #$f
                tax
                lda farbtab,x
                sta poly_color
                jsr FPolygon
endif
                inc face_count
                jmp .loop

.cont           iny
                lda faces,y
                inc
                bne .cont
                iny
                inc face_count
                jmp .loop


IFD TEST
show_point::    ldx #0
.loop           lda ax+1,x
                jsr PrintHex
                lda ax,x
                jsr PrintHex
                inc CurrX
                inc CurrX
                inx
                inx
                cpx #16
                bne .loop
                rts
ENDIF
****************
* datas
****************
                SWITCH OBJEKT
                CASE ZYLINDER
punkte          DC.B 16
punkte_x:       DC.W $0023,$0018,$0000,$FFE8,$FFDD,$FFE8,$0000
                DC.W $0018,$0023,$0018,$0000,$FFE8,$FFDD,$FFE8,$0000
                DC.W $0018
punkte_y:       DC.W $0000,$0018,$0023,$0018,$0000,$FFE8,$FFDD
                DC.W $FFE8,$0000,$0018,$0023,$0018,$0000,$FFE8,$FFDD
                DC.W $FFE8
punkte_z:       DC.W $FFEC,$FFEC,$FFEC,$FFEC,$FFEC,$FFEC,$FFEC
                DC.W $FFEC,$0014,$0014,$0014,$0014,$0014,$0014,$0014
                DC.W $0014
farbtab         dc.b WEISS,HELLROT,13,HELLROT,13,HELLROT,PINK,HELLROT,13,HELLGRUEN

faces:        dc.b 10,8,6,4,2,0,14,12,-1
                DC.B 0,2,18,16,-1
                DC.B 2,4,20,18,-1
                DC.B 4,6,22,20,-1
                DC.B 6,8,24,22,-1
                DC.B 8,10,26,24,-1
                DC.B 10,12,28,26,-1
                DC.B 12,14,30,28,-1
                DC.B 14,0,16,30,-1
                dc.b 18,20,22,24,26,28,30,16,-1
                DC.B -1

                CASE DIAMANT
punkte          DC.B 12
punkte_x:       DC.W $0000,$0028,$0020,$000C,$FFF4,$FFE0,$FFD8,$FFE0
                DC.W $FFF4,$000C,$0020,$0000
punkte_y:       DC.W $0000,$0000,$0018,$0026,$0026,$0018,$0000,$FFE8
                DC.W $FFDA,$FFDA,$FFE8,$0000
punkte_z:       DC.W $FFD8,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                DC.W $0000,$0000,$0000,$0028
farbtab         dc.b 1,2,3,4,5,6,7,8,9,11,12,13,14,15,1,2
faces:          DC.B 0,4,2,-1
                DC.B 0,6,4,-1
                DC.B 0,8,6,-1
                DC.B 0,10,8,-1

                DC.B 0,12,10,-1
                DC.B 0,14,12,-1
                DC.B 0,16,14,-1
                DC.B 0,18,16,-1

                DC.B 0,20,18,-1
                DC.B 0,2,20,-1
                DC.B 2,4,22,-1
                DC.B 4,6,22,-1

                DC.B 6,8,22,-1
                DC.B 8,10,22,-1
                DC.B 10,12,22,-1
                DC.B 12,14,22,-1

                DC.B 14,16,22,-1
                DC.B 16,18,22,-1
                DC.B 18,20,22,-1
                DC.B 20,2,22,-1
                DC.B -1

                CASE PRISMA
punkte          DC.B 5
punkte_x:       DC.W $0000,$0028,$FFEC,$FFEC,$0000
punkte_y:       DC.W $0000,$0000,$0023,$FFDD,$0000
punkte_z:       DC.W $FFD8,$0000,$0000,$0000,$0028
faces:          DC.B 0,4,2,-1
                DC.B 0,6,4,-1
                DC.B 0,2,6,-1
                DC.B 2,4,8,-1
                DC.B 4,6,8,-1
                DC.B 6,2,8,-1
                DC.B -1
farbtab         dc.b 8,9,10,12,14,15

                CASE BALL
farbtab         dc.b 1,2,3,4,5,6,7,8,9,11,12,13,14,15,1,2
punkte          DC.B 34
punkte_x:       DC.W $0000,$0018,$0011,$0000,$FFEF,$FFE8,$FFEF,$0000
                DC.W $0011,$0026,$001B,$0000,$FFE5,$FFDA,$FFE5,$0000
                DC.W $001B,$0026,$001B,$0000,$FFE5,$FFDA,$FFE5,$0000
                DC.W $001B,$0018,$0011,$0000,$FFEF,$FFE8,$FFEF,$0000
                DC.W $0011,$0000
punkte_y:       DC.W $0000,$0000,$0011,$0018,$0011,$0000,$FFEF,$FFE8
                DC.W $FFEF,$0000,$001B,$0026,$001B,$0000,$FFE5,$FFDA
                DC.W $FFE5,$0000,$001B,$0026,$001B,$0000,$FFE5,$FFDA
                DC.W $FFE5,$0000,$0011,$0018,$0011,$0000,$FFEF,$FFE8
                DC.W $FFEF,$0000
punkte_z:       DC.W $FFD8,$FFE0,$FFE0,$FFE0,$FFE0,$FFE0,$FFE0,$FFE0
                DC.W $FFE0,$FFF4,$FFF4,$FFF4,$FFF4,$FFF4,$FFF4,$FFF4
                DC.W $FFF4,$000C,$000C,$000C,$000C,$000C,$000C,$000C
                DC.W $000C,$0020,$0020,$0020,$0020,$0020,$0020,$0020
                DC.W $0020,$0028
faces:        DC.B 0,4,2,-1
                DC.B 0,6,4,-1
                DC.B 0,8,6,-1
                DC.B 0,10,8,-1
                DC.B 0,12,10,-1
                DC.B 0,14,12,-1
                DC.B 0,16,14,-1
                DC.B 0,2,16,-1
                DC.B 2,4,20,18,-1
                DC.B 4,6,22,20,-1
                DC.B 6,8,24,22,-1
                DC.B 8,10,26,24,-1
                DC.B 10,12,28,26,-1
                DC.B 12,14,30,28,-1
                DC.B 14,16,32,30,-1
                DC.B 16,2,18,32,-1
                DC.B 18,20,36,34,-1
                DC.B 20,22,38,36,-1
                DC.B 22,24,40,38,-1
                DC.B 24,26,42,40,-1
                DC.B 26,28,44,42,-1
                DC.B 28,30,46,44,-1
                DC.B 30,32,48,46,-1
                DC.B 32,18,34,48,-1
                DC.B 34,36,52,50,-1
                DC.B 36,38,54,52,-1
                DC.B 38,40,56,54,-1
                DC.B 40,42,58,56,-1
                DC.B 42,44,60,58,-1
                DC.B 44,46,62,60,-1
                DC.B 46,48,64,62,-1
                DC.B 48,34,50,64,-1
                DC.B 50,52,66,-1
                DC.B 52,54,66,-1
                DC.B 54,56,66,-1
                DC.B 56,58,66,-1
                DC.B 58,60,66,-1
                DC.B 60,62,66,-1
                DC.B 62,64,66,-1
                DC.B 64,50,66,-1
                DC.B 66,66,66,-1
                DC.B -1

                CASE WUERFEL
punkte          dc.b 8 ;32
punkte_x        dc.w -25, 25, 25,-25,-25, 25, 25,-25
                dc.w -10, 10,  0,  0            ; Tx
                dc.w   0,  0                    ; Ix
                dc.w  -5, -5, -5,  5,  5,  5    ; Rx
                dc.w   5,  5,  5, -5, -5, -5    ; Sx
                dc.w  25, 25                    ; -x
                dc.w -25,-25,-25,-25            ; T2x
punkte_y        dc.w -25,-25, 25, 25,-25,-25, 25, 25
                dc.w -25,-25,-25,-25            ; Ty
                dc.w -10, 10                    ; Iy
                dc.w  10,  0,-10, 10,  0,-10    ; Ry
                dc.w  25, 25, 25, 25, 25, 25    ; Sy
                dc.w   5, -5                    ; -y
                dc.w   0,  0,-10, 10            ; T2y
punkte_z        dc.w -25,-25,-25,-25, 25, 25, 25, 25
                dc.w -10,-10,-10, 10            ; Tz
                dc.w -25,-25                    ; Iz
                dc.w  25, 25, 25, 25, 25, 25    ; Rz
                dc.w  10,  0,-10, 10,  0,-10    ; Sz
                dc.w   0,  0                    ; -z
                dc.w -10, 10,-10,-10            ; T2z

farbtab         dc.b 15,9,11,12,13,14
faces         dc.b 3*2,2*2,1*2,0*2,-1
                dc.b 4*2,5*2,6*2,7*2,-1
                dc.b 0*2,1*2,5*2,4*2,-1
                dc.b 1*2,2*2,6*2,5*2,-1
                dc.b 2*2,3*2,7*2,6*2,-1
                dc.b 3*2,0*2,4*2,7*2,-1
                dc.b -1

                CASE WUERFEL2
punkte          dc.b 8
punkte_x        dc.w -25, 25, 25,-25,-25, 25, 25,-25
punkte_y        dc.w -25,-25,-25,-25, 25, 25, 25, 25
punkte_z        dc.w -25,-25, 25, 25,-25,-25, 25, 25

farbtab         dc.b 15,15,9,9,11,11,12,12,13,13,14,14
faces         dc.b  0, 2, 4,-1, 0, 4, 6,-1
                dc.b  2,10,12,-1, 2,12, 4,-1
                dc.b 10, 8,14,-1,10,14,12,-1
                dc.b  8, 0, 6,-1, 8, 6,14,-1
                dc.b  8,10, 2,-1, 8, 2, 0,-1
                dc.b  6, 4,14,-1, 4,12,14,-1
                dc.b -1
                CASE GLEITER
punkte          dc.b 13
punkte_x        dc.w 20, 0, 0,  0,  0,-50,-50,-50,-50,-50,-50,-50,-50
punkte_y        dc.w  0,10, 0,-20,  0, 10,  0,-20,  0,  5,  5, -5, -5
punkte_z        dc.w  0, 0,30,  0,-30,  0, 30,  0,-30, -5,  5,  5, -5

farbtab         dc.b 15,14,13,12,11,10,9,8,7,6,5

faces
                dc.b 2*0,2*1,2*2,-1             ; Spitze
                dc.b 2*0,2*2,2*3,-1
                dc.b 2*0,2*3,2*4,-1
                dc.b 2*4,2*1,2*0,-1
                dc.b 2*6,2*7,2*3,2*2,-1         ; Seiten
                dc.b 2*2,2*1,2*5,2*6,-1
                dc.b 2*7,2*8,2*4,2*3,-1
                dc.b 2*1,2*4,2*8,2*5,-1
                dc.b 2*5,2*8,2*7,2*6,-1         ; RÅckseite
                dc.b 2*9,2*12,2*11,2*10,-1
                dc.b -1
                ENDS

linien          dc.b 0                                          ; I
                dc.b 12*2,13*2
                dc.b -1
                dc.b 1                                          ; R
                dc.b 14*2,16*2, 16*2,19*2, 19*2,18*2, 18*2,15*2, 15*2,17*2
                dc.b -1
                dc.b 2                                          ; T
                dc.b 8*2,9*2,10*2,11*2
                dc.b -1
                dc.b 3                                          ; -
                dc.b 26*2,27*2
                dc.b -1
                dc.b 4                                          ; S
                dc.b 20*2,23*2, 23*2,24*2, 24*2,21*2, 21*2,22*2, 22*2,25*2
                dc.b -1
                dc.b 5
                dc.b 28*2,29*2, 30*2, 31*2
                dc.b -1
                dc.b -1                         ; Ende der Liste


****************
* INCLUDES
                include <includes/draw_spr.inc>
		include <includes/irq.inc>
		include <includes/1000Hz.inc>
		include <includes/serial.inc>
		include <includes/font.inc>
		include <includes/font2.hlp>
		IF GRID
	          include <includes/draw.inc>
                  include <includes/polygon.inc>
                ELSE
                  include <includes/fpolygon.inc>
                ENDIF
                include <includes/newkey.inc>
                include <includes/debug.inc>
                align 2
piggy           ibytes <etc/phobyx1.o>

pal  DP 000,574,434,555,656,799,A9A,BCC,DCD,EFF,FAF,695,9B7,7A6,AAB,AC9

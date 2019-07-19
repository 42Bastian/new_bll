* -*-asm-*-
* Mathe-Register
* A = C * E
* A : B = D + R/2
*
MATHE_A         EQU $FC60
MATHE_B         EQU $FC56
MATHE_C         EQU $FC52
MATHE_D         EQU $FC52
MATHE_E         EQU $FC54
MATHE_AKKU      EQU $FC6C
MATHE_R         EQU $FC6C

* Atari-definitions for co-pro registers
MATHD           equ $fc52
MATHC           equ $fc53
MATHB           equ $fc54
MATHA           equ $fc55
MATHP           equ $fc56
MATHN           equ $fc57
MATHH           equ $fc60
MATHG           equ $fc61
MATHF           equ $fc62
MATHE           equ $fc63
MATHM           equ $fc6c
MATHL           equ $fc6d
MATHK           equ $fc6e
MATHJ           equ $fc6f


SUZY_BUS_ENABLE EQU $FC90       ; 0 disables Suzy
SPRSYS          EQU $FC92

* Initialised to %00100100
* Copy is in _SPRSYS in der ZP

* WRITE
SIGNED_MATH     EQU %10000000
USE_AKKU        EQU %01000000
DONT_COLLIDE    EQU %00100000   ;*
VERT_STRETCH    EQU %00010000
FLIP_JOYPAD     EQU %00001000
CLR_UNSAFE      EQU %00000100   ;*
STOP_SPRITE     EQU %00000010
RESERVED        EQU %00000001
;READ
COMPUTING       EQU %10000000
AKKU_OVERFLOW   EQU %01000000
LAST_CARRY      EQU %00100000
;VERT_STRETCH   EQU %00010000
;FLIP_JOYPAD    EQU %00001000
UNSAFE_ACCESS   EQU %00000100
RESERVED2       EQU %00000010
SUZY_DONE       EQU %00000001

SPRCTL0_2_COL             EQU $00
SPRCTL0_4_COL             EQU $40
SPRCTL0_8_COL             EQU $80
SPRCTL0_16_COL            EQU $c0
SPRCTL0_HFLIP             EQU $20
SPRCTL0_VFLIP             EQU $10
SPRCTL0_SHADOW            EQU $07
SPRCTL0_XOR_SHADOW        EQU $06
SPRCTL0_NON_COLLIDABLE    EQU $05
SPRCTL0_NORMAL            EQU $04
SPRCTL0_BOUNDARY          EQU $03
SPRCTL0_BOUNDARY_SHADOW   EQU $02
SPRCTL0_BACKGROUND_NON_COLLIDABLE EQU $01
SPRCTL0_BACKGROUND_SHADOW EQU $00

SPRCTL1_LITERAL           EQU $80
SPRCTL1_DEPTH_NO_RELOAD   EQU $00
SPRCTL1_DEPTH_SIZE_RELOAD EQU $10
SPRCTL1_DEPTH_SIZE_STRECH_RELOAD EQU $20
SPRCTL1_DEPTH_ALL_RELOAD  EQU $30
SPRCTL1_PALETTE_NO_RELOAD EQU $08
SPRCTL1_SKIP              EQU $04
SPRCTL1_DRAW_UP           EQU $02
SPRCTL1_DRAW_LEFT         EQU $01

SPRCOLL_DONT_COLLIDE      EQU $20

JOYPAD          EQU $FCB0
JOY_UP          EQU %10000000
JOY_DOWN        EQU %01000000
JOY_LEFT        EQU %00100000
JOY_RIGHT       EQU %00010000
JOY_OPT1        EQU %00001000
JOY_OPT2        EQU %00000100
JOY_B           EQU %00000010
JOY_A           EQU %00000001

SUZY_IO         EQU $FCB1
JOY_PAUSE       EQU %00000001
SW_CON          EQU %00000100

CART0           EQU $FCB2
CART1           EQU $FCB3
***************
* Mikey
***************
VOLUME_A        equ $fd20
FEEDBACK_A      equ $fd21
OUTPUTVAL_A     equ $fd22
SHIFT_A         equ $fd23
FREQ_A          equ $fd24
CONTRL_A        equ $fd25
COUNTER_A       equ $fd26
OTHER_A         equ $fd27

VOLUME_B        equ $fd28
FEEDBACK_B      equ $fd29
OUTPUTVAL_B     equ $fd2a
SHIFT_B         equ $fd2b
FREQ_B          equ $fd2c
CONTRL_B        equ $fd2d
COUNTER_B       equ $fd2e
OTHER_B         equ $fd2f

VOLUME_C        equ $fd30
FEEDBACK_C      equ $fd31
OUTPUTVAL_C     equ $fd32
SHIFT_C         equ $fd33
FREQ_C          equ $fd34
CONTRL_C        equ $fd35
COUNTER_C       equ $fd36
OTHER_C         equ $fd37

VOLUME_D        equ $fd38
FEEDBACK_D      equ $fd39
OUTPUTVAL_D     equ $fd3a
SHIFT_D         equ $fd3b
FREQ_D          equ $fd3c
CONTRL_D        equ $fd3d
COUNTER_D       equ $fd3e
OTHER_D         equ $fd3f


BALANCE_A       equ $fd40
BALANCE_B       equ $fd41
BALANCE_C       equ $fd42
BALANCE_D       equ $fd43

PANING          equ $fd44

STEREO_CNTRL    equ $fd50

VIDEODMA        equ $fd92
***************

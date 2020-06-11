
	Run $2400

	ibytes "kingtut.pal"
CLS	db $01,$90,$00
	dw KINGTUT0,cls
cls_x	dw 0
cls_y	dw 0
	dw 160*256,102*256
	db $00
cls	db 2,00,0
kingtut	ibytes "kingtut.pic"

KINGTUT0	db $C1,$10,$00
	dw KINGTUT1,kingtut
	dw 80,52,0,0
	db $01,$23,$45,$67,$89,$ab,$cd,$ef

size	set 1
x	set 79
y	set 51
count	set 5
KINGTUT1
	REPT 511
	db $c1,$18,$00
	dw *+12,kingtut
	dw x,y,size,size
size	set size+1
count	set count-1
IF count=0
x	set x-1
y	set y-1
count	set 5
ENDIF
	ENDR

	REPT 511
	db $c1,$18,$00
	dw *+12,kingtut
	dw x,y,size,size
size	set size-1
count	set count-1
IF count=0
x	set x+1
y	set y+1
count	set 5
ENDIF
	ENDR


KINGTUT1024	db $C1,$18,$00
	dw KINGTUT1,kingtut
	dw 80,52,0,0

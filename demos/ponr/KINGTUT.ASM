	Run $2400
	ibytes "kingtut.pal"
	db $c1,$10,0
	dw 0
	dw kingtut
	dw 35,5
	dw $100,$100
	db $01,$23,$45,$67
	db $89,$ab,$cd,$ef
kingtut	ibytes "kingtut.pic"

* -*-asm-*-
*
* fpolygon8.inc
*
* re-created : 20/09/06
*
* Same as fpolygon.inc, but only 8bit coordinates.


***************
* Filled Polygon
* actually only a tri or tetragon
* IN : A - color
*      Y - ptr
*
* XXX: Not tested!
****************
*
FPolygon8::	sta .fpcolor
		phy				; save ptr
		ldx faces,y
		MOVEB {proj_x,x},x1
		MOVEB {proj_y,x},y1
		iny
		ldx faces,y
		MOVEB {proj_x,x},x2
		MOVEB {proj_y,x},y2
		iny
		ldx faces,y
		MOVEB {proj_x,x},x3
		MOVEB {proj_y,x},y3
		iny
		pla				; fetch ptr
		ldx faces,y			; last vertex
		inx
		beq .exit			; yes =>
		pha				; save ptr
		lda .fpcolor			; get color
		jsr triangle8			; draw triangle
		ply
		ldx faces,y
		MOVEB {proj_x,x},x1
		MOVEB {proj_y,x},y1
		iny
		iny
		ldx faces,y
		MOVEB {proj_x,x},x2
		MOVEB {proj_y,x},y2
		iny
		ldx faces,y
		MOVEB {proj_x,x},x3
		MOVEB {proj_y,x},y3
		iny
.exit		iny
		phy
		lda .fpcolor
		jsr triangle8
		ply
		rts
.fpcolor	ds 1
****************
* Triangle
* (x1,y1),(x2,y2),(x3,y3)
* draw
*        A
*       /\
*      /  \
*     /    \
*  B /      \ B'
*    \       \
*     \_      \
*       \_     \
*         \_    \
*           \_   \
*             \_  \
*               \_ \
*                 \_\
*                     C
*
* two triangles/sprites : 1) ABB' 2) BB'C
*
* Same as triangle, but only 8bit coordinates
****************
triangle8::
	sta .tri_scb_color
	sta .tri_scb2_color
*
* sort points
*
	lda	y1
	cmp	y2
	_IFCS			; y1 > y2 ?
	  ldx	y2
	  sta	y2
	  stx	y1
	  lda	x1
	  ldy	x2
	  sta	x2
	  sty	x1
	  txa			; x = y1
	_ENDIF
	cmp	y3
	_IFCS			; y1 > y3
	  ldx	y3
	  sta	y3
	  stx	y1
	  lda	x1
	  ldx	x3
	  sta	x3
	  stx	x1
	_ENDIF
	lda	y2
	cmp	y3
	_IFCS			; y2 > y3
	  ldx	y3
	  sta	y3
	  stx	y2
	  lda	x2
	  ldx	x3
	  sta	x3
	  stx	x2
	_ENDIF
*
*
	stz MATHE_A		; clear MATHE_A
	stz MATHE_A+2

	ldy #-1
	sec
	lda y2
	sbc y1

	sta MATHE_B
//->	stz MATHE_B+1	; high-byte cleared by HW

	_IFNE
	  inc
	_ENDIF
	sta .tri_scb_ysize+1

	sec
	lda x2
	sbc x1
	bcs .1
	  iny
	  eor #$ff
	  inc
.1
	sta MATHE_A+3
	WAITSUZY
	tya
	_IFEQ
	  sec
	  sbc MATHE_D+2
	  tax
	  tya
	  sbc MATHE_D+3
	  dey
	_ELSE
	  ldx MATHE_D+2
	  lda MATHE_D+3
	_ENDIF
	stx tiltAB
	sta tiltAB+1
****************
	sec
	lda y3
	sbc y1
	sta MATHE_B
//->	stz MATHE_B+1	; high-byte cleared by HW

	sec
	lda x3
	sbc x1
	bpl .2
	  iny
	  eor #$ff
	  inc
.2
	sta MATHE_A+3
	WAITSUZY
	tya
	_IFEQ
	  sec
	  sbc MATHE_D+2
	  tax
	  tya
	  sbc MATHE_D+3
	  dey
	_ELSE
	  ldx MATHE_D+2
	  lda MATHE_D+3
	_ENDIF
	stx tiltAC
	stx temp
	sta tiltAC+1
	sta temp+1
****************
	sec
	lda y3
	sbc y2
	sta MATHE_B
//->	stz MATHE_B+1	; high-byte cleared by HW
	sta .tri_scb2_ysize+1

	sec
	lda x3
	sbc x2
	bpl .3
	  iny
	  eor #$ff
	  inc
.3
	sta MATHE_A+3
	WAITSUZY
	tya
	_IFEQ
	  sec
	  sbc MATHE_D+2
	  tax
	  tya
	  sbc MATHE_D+3
	_ELSE
	  ldx MATHE_D+2
	  lda MATHE_D+3
	_ENDIF
	stx tiltBC
	sta tiltBC+1
****************
	MOVEB x1,.tri_scb_x
	MOVEB y1,.tri_scb_y
	MOVEB x3,.tri_scb2_x
	MOVEB y3,.tri_scb2_y
****************
	CMPWS tiltAC,tiltAB
	_IFLT
	  SWAP tiltAB,tiltAC
	_ENDIF
	SUBW tiltAC,tiltAB,.tri_scb_stretch
	MOVE tiltAC,.tri_scb_tilt
****************
	CMPWS temp,tiltBC	; original tiltAC
	_IFLT
	  SWAP temp,tiltBC
	_ENDIF
	SUBW temp,tiltBC,.tri_scb2_stretch

	sec
	lda #0
	sbc tiltBC
	sta .tri_scb2_tilt
	lda #0
	sbc tiltBC+1
	sta .tri_scb2_tilt+1
****************
	lda .tri_scb_ysize+1
	_IFNE
	  MOVEI .tri_scb, $fc10

	  lda #1
	  STA $FC91
	  lda #1
	  stz $fd90
.wait	  STZ $FD91
	  bit $fc92
	  bne .wait
	  STZ $FD90
	_ELSE
	  lda .tri_scb2_ysize+1
	  _IFNE
	    inc .tri_scb2_ysize+1
	  _ENDIF
	_ENDIF
//-> dec .tri_scb2_color
	lda .tri_scb2_ysize+1
	_IFNE
	  MOVEI .tri_scb2, $fc10

	  lda #1
	  STA $FC91
	  lda #1
	  stz $fd90
.wait1	  STZ $FD91
	  bit $fc92
	  bne .wait1
	  STZ $FD90
	_ENDIF
	rts

**************************************************
.trieveron1	dc.b 0
.tri_scb	dc.b $c0,$80|$30,0
		dc.w 0,.triimage
.tri_scb_x	dc.w 0
.tri_scb_y	dc.w 0
.tri_scb_xsize	dc.w $180
.tri_scb_ysize	dc.w $180
.tri_scb_stretch dc.w 0
.tri_scb_tilt	dc.w 0
.tri_scb_color	dc.b $03

.trieveron2	dc.b 0
.tri_scb2	dc.b $d0,$80|$30,0
		dc.w 0,.triimage
.tri_scb2_x	dc.w 0
.tri_scb2_y	dc.w 0
.tri_scb2_xsize dc.w $180
.tri_scb2_ysize dc.w $180
.tri_scb2_stretch dc.w 0
.tri_scb2_tilt	dc.w 0
.tri_scb2_color dc.b $e
.triimage	dc.b 2,$10,0

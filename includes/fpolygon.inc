* -*-asm-*-
*
* polygon.inc
*
* re-created : 98/01/17
*

***************
* Filled Polygon
* actually only a tri or tetragon
* IN : A - color
*      Y - ptr
****************
*
FPolygon::	sta .fpcolor
		phy				; save ptr
		ldx faces,y
		MOVE {proj_x,x},x1
		MOVE {proj_y,x},y1
		iny
		ldx faces,y
		MOVE {proj_x,x},x2
		MOVE {proj_y,x},y2
		iny
		ldx faces,y
		MOVE {proj_x,x},x3
		MOVE {proj_y,x},y3
		iny
		pla				; fetch ptr
		ldx faces,y			; last vertex
		inx
		beq .exit			; yes =>
		pha				; save ptr
		lda .fpcolor			; get color
		jsr triangle			; draw triangle
		ply
		ldx faces,y
		MOVE {proj_x,x},x1
		MOVE {proj_y,x},y1
		iny
		iny
		ldx faces,y
		MOVE {proj_x,x},x2
		MOVE {proj_y,x},y2
		iny
		ldx faces,y
		MOVE {proj_x,x},x3
		MOVE {proj_y,x},y3
		iny
.exit		iny
		phy
		lda .fpcolor
		jsr triangle
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
****************
triangle::
		sta .tri_scb_color
		sta .tri_scb2_color
*
* sort points
*
		CMPWS y1,y2
		_IFLT				; y1>y2 ?
		  SWAP x1,x2
		  SWAP y1,y2
		_ENDIF
		CMPWS y1,y3
		_IFLT
		  SWAP x1,x3
		  SWAP y1,y3
		_ENDIF
		CMPWS y2,y3
		_IFLT
		  SWAP x2,x3
		  SWAP y2,y3
		_ENDIF
*
*
		ldy #-1
		sec
		lda y2
		sbc y1

		sta MATHE_B
//->		stz MATHE_B+1		; high-byte cleared by HW

		_IFNE
		  inc
		_ENDIF
		sta .tri_scb_ysize+1
		stz MATHE_A
//->		stz MATHE_A+1		; high-byte cleared by HW
		sec
		lda x2
		sbc x1
		tax
		lda x2+1
		sbc x1+1
		bpl .1
		  iny
		  pha
		  txa
		  eor #$ff
		  tax
		  pla
		  eor #$ff
		  inx
		  bne .1
		  inc
.1
		stx MATHE_A+2
		sta MATHE_A+3
		WAITSUZY
		tya
		_IFEQ
		  sec
		  sbc MATHE_D+1
		  tax
		  tya
		  sbc MATHE_D+2
		  dey
		_ELSE
		  ldx MATHE_D+1
		  lda MATHE_D+2
		_ENDIF
		stx tiltAB
		sta tiltAB+1
****************
		sec
		lda y3
		sbc y1
		sta MATHE_B
//->		stz MATHE_B+1		; high-byte cleared by HW
		stz MATHE_A
//->		stz MATHE_A+1		; high-byte cleared by HW
		sec
		lda x3
		sbc x1
		tax
		lda x3+1
		sbc x1+1
		bpl .2
		  iny
		  pha
		  txa
		  eor #$ff
		  tax
		  pla
		  eor #$ff
		  inx
		  bne .2
		  inc
.2
		stx MATHE_A+2
		sta MATHE_A+3
		WAITSUZY
		tya
		_IFEQ
		  sec
		  sbc MATHE_D+1
		  tax
		  tya
		  sbc MATHE_D+2
		  dey
		_ELSE
		  ldx MATHE_D+1
		  lda MATHE_D+2
		_ENDIF
		stx tiltAC
		sta tiltAC+1
****************
		sec
		lda y3
		sbc y2
		sta MATHE_B
//->		stz MATHE_B+1		; high-byte cleared by HW

		sta .tri_scb2_ysize+1
		stz MATHE_A
//->		stz MATHE_A+1		; high-byte cleared by HW
		sec
		lda x3
		sbc x2
		tax
		lda x3+1
		sbc x2+1
		bpl .3
		  iny
		  pha
		  txa
		  eor #$ff
		  tax
		  pla
		  eor #$ff
		  inx
		  bne .3
		  inc
.3
		stx MATHE_A+2
		sta MATHE_A+3
		WAITSUZY
		tya
		_IFEQ
		  sec
		  sbc MATHE_D+1
		  tax
		  tya
		  sbc MATHE_D+2
		_ELSE
		  ldx MATHE_D+1
		  lda MATHE_D+2
		_ENDIF
		stx tiltBC
		sta tiltBC+1
****************
		MOVE x1,.tri_scb_x
		MOVE y1,.tri_scb_y
		MOVE x3,.tri_scb2_x
		MOVE y3,.tri_scb2_y
		lda #$80
		sta .tri_scb_xsize
		sta .tri_scb2_xsize
		lda #1
		sta .tri_scb_xsize+1
		sta .tri_scb2_xsize+1
****************
		MOVE tiltAC,temp
		CMPWS tiltAC,tiltAB
		_IFLT
		  SWAP tiltAB,tiltAC
		_ENDIF
		SUBW tiltAC,tiltAB,.tri_scb_stretch
		MOVE tiltAC,.tri_scb_tilt
****************
		CMPWS temp,tiltBC
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
		cmp #1
		_IFNE
		  MOVEI .tri_scb, $fc10

		  lda #1
		  STA $FC91
		  lda #1
		  stz $fd90
.wait		  STZ $FD91
		  bit $fc92
		  bne .wait
		  STZ $FD90
		_ELSE
		  lda .tri_scb2_ysize+1
		  _IFNE
		    inc .tri_scb2_ysize+1
		  _ENDIF
		_ENDIF

		lda .tri_scb2_ysize+1
		_IFNE
		  MOVEI .tri_scb2, $fc10

		  lda #1
		  STA $FC91
		  lda #1
		  stz $fd90
.wait1		  STZ $FD91
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
.tri_scb_xsize	dc.w $100
.tri_scb_ysize	dc.w $100
.tri_scb_stretch dc.w 0
.tri_scb_tilt	dc.w 0
.tri_scb_color	dc.b $03

.trieveron2	dc.b 0
.tri_scb2	dc.b $d0,$80|$30,0
		dc.w 0,.triimage
.tri_scb2_x	dc.w 0
.tri_scb2_y	dc.w 0
.tri_scb2_xsize dc.w $100
.tri_scb2_ysize dc.w $100
.tri_scb2_stretch dc.w 0
.tri_scb2_tilt	dc.w 0
.tri_scb2_color dc.b $e
.triimage	dc.b 2,$10,0
****************

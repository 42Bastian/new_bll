* -*-asm-*-
****************
* wire-frame polygon

Polygon::       sta .pcolor
                ldx faces,y
                MOVE {proj_x,x},x1
                MOVE {proj_y,x},y1
                MOVE x1,ax
                MOVE y1,ay      ; save first point
.loop             iny
                  ldx faces,y
                  inx
                  beq .exit
                  MOVE {proj_x-1,x},x2
                  MOVE {proj_y-1,x},y2
                  MOVE x2,bx
                  MOVE y2,by
                  lda .pcolor
                  jsr DrawLine
                  MOVE bx,x1
                  MOVE by,y1
                bra .loop
.exit           MOVE ax,x2
                MOVE ay,y2
                iny
                lda .pcolor
                jmp DrawLine
.pcolor         ds 1
****************

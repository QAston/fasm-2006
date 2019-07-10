.386
.model flat,STDCALL
.data
INCLUDE 'OGL.INC'
;----------------------------------------------------------------------------------------------
CGLW_height	equ	300
CGLW_width	equ	400
CGLW_bits	equ	16
;----------------------------------------------------------------------------------------------
.code
START:

;----------------------------------------------------------------------------------------------

DrawGLScene:
  call	glLoadIdentity
  push	GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT
  call	glClear

call glBegin,GL_TRIANGLES

  Color3f 0.0 0.0 1.0
  Vertex3f -1.0 0.0  -10.0
  Vertex3f 1.0	0.0  -10.0
  Vertex3f 0.0	1.0  -10.0

call glEnd
;----------------------------------------------------------------------------------------------
keyboard:
  cmp byte ptr KEY[VK_ESCAPE],TRUE
  jne nie_esc
   call theend
  nie_esc:
ret

theend:
  mov done,TRUE
ret
;----------------------------------------------------------------------------------------------
END START
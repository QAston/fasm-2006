				   ;
;
;                              -  f l a m e  -
;                           quality 122 byte fire
;                      copyright 1997 Gaffer/prometheus
;                             gaffer@zip.com.au
;
;                         optimization contribution:        
;                  goblin,icepick,mf,patrik sundberg,pgeist
;                                 mark andreas



;# You may wish to insert code to keep Buffer aligned on an
;# even address, regardless of the size of the program.

Format binary
ORG 100h




; INITIALIZATION: setup video mode & palette
; ------------------------------------------


; SETUP VGA SEG
	push	0A000h
	pop	es


; INIT VGA MODE 13h
	mov	al,13h		;# doesn't look nice if using mode 93h
	int	10h


; GENERATE PALETTE
	dec	di
PaletteGen:			; alternate palette generation
	xor	ax,ax		; (Patrick Sundberg)
	mov	cl,63
@@L1:
	stosb
	inc	ax
	cmpsw			; small way to advance si,di!
				;# why are we advancing SI too
				;# scasw works just as well (same size)
	loop	@@L1
	push	di
	mov	cl,192
@@L2:
	stosw
	inc	di
	loop	@@L2
	pop	di
	inc	di
	jns	PaletteGen	; cheesy! :)


; SET PALETTE
	mov	ax,1012h
	cwd			; equivalent to 'xor dx,dx'
	mov	cl,255
	int	10h




; MAIN LOOP: Cycle through flame animation until keypress
; -------------------------------------------------------
MainLoop:

	push	es
	push	ds
	pop	es		; set es=ds to use stosw


; FLAME ANIMATION
	inc	cx
	mov	di,Buffer
	mov	bl,99
@@L3:
	mov	ax,[di+639]		      
	add	al,ah			      
	setc	ah
	mov	dl,[di+641]
	add	ax,dx
	mov	dl,[di+1280]
	add	ax,dx
	shr	ax,2
	jz	@@ZERO		; cool a bit...
	dec	ax
@@ZERO:
	stosb
	add	ax,dx		; double the height
	shr	ax,1			      
	mov	[di+319],al		      
	loop	@@L3			     
	mov	cx,320
	add	di,cx
	dec	bx
	jnz	@@L3


; FLAME GENERATOR BAR
; assumes cx=320
; assumes di=generator bar offset (bottom of flame buffer)
@@L4:

;#        in      ax,40h          ; read from timer
;# don't need to thump the clock 320 times per frame.  That just
;# kills the display on slower video cards, even on Pentiums
;# In fact, the display looks just as nice without this instruction.
;# If you decide it's needed, try moving it to be just before the
;# loop, so you're only reading the port once per frame.


;#      xadd    [ds:100h],ax      ; "seed" is first two bytes of code
;# Instead, use the BP register as a seed.
;        xadd    bp,ax           ;#

;# another option for allowing the program to run on a 386 is to
;# replace XADD, since that's the only 486 instruction used.
;# an alternate of the same size is:
	add	ax,[di]
	inc	ax

	mov	ah,al
;# removing this instruction doesn't seem to affect the display.

	stosw
	stosw
	loop	@@L4

	pop	es		      ; restore es=A000h


; OUTPUT FLAME TO SCREEN
	xor	di,di
	lea	si,[Buffer+320]
	mov	ch,60		      ; assumes cl=0
	rep	movsd		      ; change to "mov ch,120" "rep movsw"
				      ; saves one byte but is slower
				      ; (patrik sundberg)
				      
; CHECK FOR KEYPRESS
	mov	ah,1
	int	16h
	jz	MainLoop	      ; alternative keypress check
				      ; "in al,60h" "das" "jc MainLoop"
				      ; saves one byte but is not as reliable
				      ; (icepick)


; DOS EXIT CODE: Switch to textmode, return to DOS
; ------------------------------------------------

	mov	ax,03h
	int	10h
	ret				  

;data:

Buffer:   times  320*203 db  ?
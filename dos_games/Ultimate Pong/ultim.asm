format mz
;program do wyswietlania plikow gpf z rozjasnieniem i wyciemnieniem
;wersja niekozystajaca z instrukcji movsd
heap   1000h
stack  1000h
include 'loader.inc'
;fs= 0-based segment ;ds=es-data segnt cs=code segment gs=wolny
segment _code  use32
macro GETVIDEO szer,dlu,transp,name
	{mov	 edx,dlu
	mov	ecx,szer
	name:
	mov	al,[ds:esi]
	cmp	al,transp
	je	@f
	mov	[es:edi],al
	@@:
	inc	esi
	inc	edi
	dec	ecx
	jnz	name
	mov	ecx,szer
	add	edi,640-szer
	add	esi,640-szer
	dec	edx
	jnz	name}


code32:
alloc_dos:
	push	 ds
	pop	 [timer]
	mov	 [AErrorMsg],TMemoryErrorMsg
	mov	 eax,100h			       ;alokuj pamiec dosa
	mov	 ebx,40h			       ;400h bajtow 40h paragrafow 1024 bajty
	int	 31h				       ;do dx=selektor segmentu[PM] do ax=segment [RM]
	jc	 error				       ;jc to blad

	push	 dx
	mov	 [RMes],ax
	pop	 gs				       ;do edx ofset bufora sel:fs

	mov	eax,0204h		     ; zmien int 09
	mov	ebx,08
	int	31h
	mov	[OfsOldTimeInt],edx
	mov	[SelOldTimeInt],cx

	mov	ax,0205h		    ; zmien int 09
	mov	edx,timer_int
	push	cs
	pop	cx
	mov	ebx,08
	int	31h

get_vesa:
	lea	edi,[RMRegs]			       ;edi=indeks do struktury z rejestrami RM
	mov	ebx,0010h			       ;ebx=przerwanie 10h
	mov	ecx,0				       ;cx=liczba slow do skopiowanie do stosu RM
	mov	[RMeax],4f00h			       ;funkcja pobierz informacje SVGA
	mov	eax,0300h			       ;funkcja symuluj przerwanie 16-bit
	int	31h

	mov	[AErrorMsg],TDPMIErrorMsg
	jc	error
	mov	[AErrorMsg],TVESAErrorMsg
	cmp	[RMeax],004fh
	jne	error				       ;gs:0 bufor na informacje SVGA
	cmp	dword[gs:0],'VESA'		       ;sprawdz, czy VESA obslugiwana
	jne	error
	movzx	eax,word[gs:10h]			    ;DWORD w gs:0eh=adres
	shl	eax,4
	movzx	edx,word[gs:0eh]			    ;eax=adres struktury z obslugiwanymi modulami
	add	eax,edx
detect_mode:					       ;petla sprawdzania obslugi mode 101h
	mov	dx,[fs:eax]
	cmp	dx,0ffffh
	je	error				       ;je to nie obsluguje
	add	eax,2
	cmp	dx,101h 			       ;sprawdz czy obsluguje 101h
	jne	detect_mode
get_101:
	mov	[RMeax],4f01h			       ;emuluj funkcje 4f01h int 10h
	mov	[RMecx],edx
	mov	eax,0300h
	int	31h
	cmp	[RMeax],004fh
	jne	error

	mov	eax,4f03h
	int	10h
	mov	[OldVideoMode],bx		       ;pobierz stary tryb
	mov	eax,4f02h
	mov	ebx,101h			       ;zmien tryb na 101h
	int	10h
	cmp	eax,004fh
	jne	error

;przygotowania- rezultat:
;ds_=code es=_code fs=0-based gs= selektor zaalokowanej pamieci DOS
;RMeax=004fh RMecx=101h RMes=segment zaalokowanej pamieci DOS
;OldVideoMode= stary tryb wideo
;eax=004fh ebx=101h ecx=0 edx=101h edi=RMRegs esi?=431 ebp?=447
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;wyswietlanie
	mov	edx,LogoName
	call	open_file
	call	get_file_size

	call	aloc_extended
	call	create_selector

	push	si
	pop	ds
	mov	ecx,4
	mov	esi,1024
	xor	edx,edx 		     ;ebx uchwyt pliku
	mov	ebx,[es:FileHandle]

prepare_palettes:		      ;dzialanie: tworzy z 1 6 palet ,kazda nastepna jest ciemniejsza
				      ;wymaga: ebx=uchwyt pliku ecx=4 edx=bufor na palete ds=aloc esi=1024
				      ;niszczy: eax,ebx,esi,edx,bp,edi
				      ;zwraca: esi=0 bp=0 edx=1024
	mov	eax,3f00h

	int	21h

	call	copy_palette
	inc	edx
	call	copy_palette
	inc	edx
	call	copy_palette
	inc	edx
	call	copy_palette
	inc	edx
	sub	esi,ecx

	jnz	prepare_palettes
	push	ebx
	mov	esi,1024*6
	call	move_palette
	call	set_palette_p

	pop	ebx				;przywroc uchwyt pliku
	call	get_picture_p

	mov	eax,3e00h
	int	21h

	mov	esi,1024*7
	call	get_video

	call	show_video_p

	mov	ecx,200
	call	make_delay


	mov	ecx,6
	mov	esi,1024*5		;wymagane przez move_palette

@@:
	push	esi ecx
	call	move_palette
	mov	ecx,8
	call	make_delay
	call	set_palette
	pop	ecx esi
	sub	esi,1024
	loop	@r

	mov	ecx,80
	call	make_delay

	mov	esi,1024	       ;wymagane przez move_palette
	mov	ecx,6
@@:
	push	esi ecx
	call	move_palette
	mov	ecx,8
	call	make_delay
	call	set_palette
	pop	ecx esi
	add	esi,1024
	loop	@r

	mov	ecx,20
	call	make_delay
	mov	[es:Key],0

	push	es
	pop	ds

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&logo wyswietlone&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;       detect   mouse
;        xor      ax,ax
;        int      33h
;        test     ax,ax
;        jnz      mouse_detected


;config:
;config create or read
	mov	edx,FConfigName
	mov	ax,4300h
	int	21h
	jnc	config_exists
	mov	ax,3c00h	   ;02 to write
	xor	ecx,ecx
	int	21h
	mov	ebx,eax
	mov	edx,DefaultKeys
	mov	ecx,18
	mov	eax,4000h
	int	21h		   ;gdy plik nie istnieje utworz go i zaladuj standardowe ustawienia
	shr	ecx,2
	mov	edi,UsersKeys
	mov	esi,DefaultKeys
	rep	movsd
	jmp	config_created
config_exists:
	call	open_file
	mov	eax,3f00h
	mov	ecx,18
	mov	edx,UsersKeys	 ;odczytaj ustawienia klawiszy, gdy plik istnieje
	int	21h
config_created:
	mov	eax,3e00h    ;zamknij plik
	int	21h

	mov	edx,FMenuName
	call	open_file
	call	get_file_size

	call	resize_aloc
	call	create_selector

	push	si
	pop	ds
	mov	ecx,1024
	xor	edx,edx 		     ;ebx uchwyt pliku
	mov	ebx,[es:FileHandle]
	mov	eax,3f00h
	int	21h
	push	ebx


	mov	esi,0
	call	move_palette
	call	set_palette
	pop	ebx

	mov	ecx,[es:FileSize]
	mov	edx,1024
	sub	ecx,edx
	call	get_picture

	mov	eax,3e00h
	int	21h
set_mouse:
	mov	ax,007h
	mov	cx,0
	mov	dx,636
	int	33h
	mov	ax,8h
	mov	dx,476
	int	33h
	mov	ax,04h
	mov	cx,0
	mov	dx,0
	int	33h
	jmp	start_menu

menu_main:
	mov	ecx,10
	call	wait_time
start_menu:
	xor	ebp,ebp
main_loop:
	call	main_draw
	mov	ah,1
	int	16h
	jz	.no_key_pressed
	mov	ah,0
	int	16h
	mov	dl,[es:UsersKeys]
	cmp	dl,ah
	je	ending
	mov	dl,[es:UsersKeys+5]
	cmp	dl,ah
	jnz	 @f
	dec	ebp
	cmp	ebp,-1
	jg	@f
	mov	ebp,3
	@@:
	mov	dl,[es:UsersKeys+6]
	cmp	dl,ah
	jnz	@f
	inc	ebp
	cmp	ebp,4
	jb	@f
	xor	ebp,ebp
	@@:
	mov	edi,MenuJmp
	mov	dl,[es:UsersKeys+1]
	cmp	dl,ah
	je	menu_button_pressed
.no_key_pressed:
	mov	esi,MenuButt
	mov	edi,3
	call	get_mouse
.button_l_check:
	mov	edi,MenuJmp
	test	bx,1
	jnz	menu_button_pressed
.button_r_check:
	test	bx,2
	jnz	ending
	jmp	main_loop

main_draw:
	mov	esi,1024
	call	get_video
	push	ebp
	shl	ebp,4
	add	ebp,MenuButt
	call	get_button
	pop	ebp
	call	get_cursor
	call	show_video_p0
	ret

menu_button_pressed:
	mov	ecx,ebp
	shl	ecx,2
	jmp	dword[es:edi+ecx]

menu_options:
	mov	ecx,10
	call	wait_time
	xor	ebp,ebp
options_loop:
	call	options_draw
	mov	ah,1
	int	16h
	jz	.no_key_pressed
	mov	ah,0
	int	16h
	mov	dl,[es:UsersKeys]
	cmp	dl,ah
	je	menu_main
	mov	dl,[es:UsersKeys+5]
	cmp	dl,ah
	jnz	 @f
	dec	ebp
	cmp	ebp,-1
	jne	 @f
	mov	ebp,18
	@@:
	mov	dl,[es:UsersKeys+6]
	cmp	dl,ah
	jnz	@f
	inc	ebp
	cmp	ebp,19
	jb	@f
	xor	ebp,ebp
	@@:
	mov	edi,OptionsJmp
	mov	dl,[es:UsersKeys+1]
	cmp	dl,ah
	je	menu_button_pressed
.no_key_pressed:
	mov	esi,OptionsButt
	mov	edi,18
	call	get_mouse
.button_l_check:
	mov	edi,OptionsJmp
	test	bx,1
	jnz	menu_button_pressed
.button_r_check:
	test	bx,2
	jnz	menu_main
	jmp	options_loop

options_draw:
	mov	esi,1024+640*580
	call	get_video
	cmp	ebp,2
	ja	draw_keys
	push	ebp
	shl	ebp,4
	add	ebp,OptionsButt
	call	get_button
	pop	ebp
	keys_drawn:
	call	get_cursor
	call	show_video_p0
	ret

draw_keys:
	push	ebp
	shl	ebp,4
	add	ebp,OptionsButt

	mov	al,[640*1060+1024+639]
	mov	edi,[es:ebp+4]
	movzx	ecx,word[es:ebp+8]
	movzx	edx,word[es:ebp+10]
	@@:
	cmp	byte[es:edi],09h
	je	.transp
	mov	[es:edi],al
	.transp:
	inc	edi
	loop	@r
	add	edi,640
	movzx	ecx,word[es:ebp+8]
	sub	edi,ecx
	dec	edx
	jnz	@r
	pop	ebp
	jmp	keys_drawn


ending: 			       ;dzialanie: konczy program
	push	es
	pop	ds
	call	free_aloc
	mov	ecx,20
	call	wait_time
	mov	bx,[OldVideoMode]
	mov	eax,4f02h				;przywroc tryb
	int	10h

Ending:
	mov	eax,4c00h				;wyjdz
	int	21h

get_cursor:
	mov	eax,03h
	xor	ecx,ecx
	int	33h
	mov	ax,640
	mul	dx
	shl	edx,16
	mov	dx,ax
	mov	edi,Video
	add	edx,ecx
	add	edi,edx
	mov	esi,640*480+220+1024+220
	GETVIDEO 4,4,0ffh,video1
	ret

get_button:
	mov	esi,[es:ebp]
	mov	edi,[es:ebp+1*4]
	movzx	  ecx,word[es:ebp+2*4]
	movzx	  edx,word[es:ebp+2*4+2]
.move_button:
	mov	al,[ds:esi]
	mov	[es:edi],al
	inc	esi
	inc	edi
	dec	ecx
	jnz	.move_button
	movzx	ecx,word[es:ebp+2*4]
	add	edi,640
	sub	edi,ecx
	add	esi,640
	sub	esi,ecx
	dec	edx
	jnz	.move_button
	ret

get_mouse:
	mov	eax,03h
	int	33h
	push	ebx
	push	ebp
	xor	ebp,ebp
.position_check:
	mov	  ax,[es:esi+12]
	mov	  bx,[es:esi+14]
	cmp	  cx,ax
	jb	  .next_position
	add	  ax,[es:esi+8]
	cmp	  cx,ax
	ja	  .next_position
	cmp	  dx,bx
	jb	  .next_position
	add	  bx,[es:esi+10]
	cmp	  dx,bx
	ja	  .next_position
	add	  esp,4
	jmp	  .position_changed
	.next_position:
	cmp	  ebp,edi
	jae	  .no_position
	inc	  ebp
	add	  esi,16
	jmp	  .position_check
	.no_position:
	pop	ebp
	.position_changed:
	pop	ebx
	ret

timer_int:
	pushad
	use16
	push	fs
	xor	ax,ax
	push	ax
	pop	fs
	cmp	ax,[fs:0]
	mov	al,20h
	out	20h,al			; ...and interrupt controller
	pop	fs
	use32
	popad
	iretd

include 'routines.inc'
struc butt esi,edi,cx,dx,xpos,ypos
{
.esi dd esi
.edi dd edi
.cx dw cx
.dx dw dx
.xpos dw xpos
.ypos dw ypos
}
Counter 		dw	0
IFlag			db	01h
BKeyboard:		times 080h  db	0
timer			dw	0
OfsOldTimeInt		dd	0
SelOldTimeInt		dw	0
TMemoryErrorMsg 	db	"Not enough conventional memory.",13,10,'$'
TOutOfMemoryErrorMsg	db	'Out of memory',13,10,'$'
TVESAErrorMsg		db	"Your graphic card doesn't support VESA 640*480*256 mode!",13,10,'$'
TDPMIErrorMsg		db	'DPMI error!',13,10,'$'
TFileErrorMsg		db	'File error!',13,10,'$'
TMessage:		db	'Wpisz nazwe pliku [gpf], ktory chcesz otworzyc',10,13,'$'
LogoName		db	'data\Logo.gpf',0
FMenuName		db	'data\menu.gpf',0
FConfigName		db	'data\config.dat',0
FileSize		dd	0
FileHandle		dd	0
AlocHandleSi		dw	0
AlocHandleDi		dw	0

OptionsButt:
options1 butt 1071*640+1024,Video+640*420+20,170,50,20,420
options2 butt 1071*640+1024+170,Video+640*420+20+170+20,220,50,210,420
options3 butt 1071*640+1024+170+220,Video+640*420+20+390+40,170,50,450,420
OptionsKeys:
options4 butt 0,Video+640*100+20,300,20,20,100
options5 butt 0,Video+640*120+20,300,20,20,120
options6 butt 0,Video+640*140+20,300,20,20,140
options7 butt 0,Video+640*200+20,300,20,20,200
options8 butt 0,Video+640*220+20,300,20,20,220
options9 butt 0,Video+640*240+20,300,20,20,240
options10 butt 0,Video+640*260+20,300,20,20,260
options11 butt 0,Video+640*320+20,300,20,20,320
options12 butt 0,Video+640*340+20,300,20,20,340
options13 butt 0,Video+640*360+20,300,20,20,360
options14 butt 0,Video+640*140+320,300,20,320,140
options15 butt 0,Video+640*160+320,300,20,320,160
options16 butt 0,Video+640*180+320,300,20,320,180
options17 butt 0,Video+640*240+320,300,20,320,240
options18 butt 0,Video+640*260+320,300,20,320,260
options19 butt 0,Video+640*280+320,300,20,320,280
MenuButt:
menu1 butt 640*480+1024,Video+640*180+210,220,50,210,180
menu2 butt 640*480+220+1024,Video+640*255+210,220,50,210,255
menu3 butt 640*530+1024,Video+640*330+210,220,50,210,330
menu4 butt 640*530+220+1024,Video+640*405+210,220,50,210,405
MenuJmp 	       dd      menu_main,menu_options,menu_main,ending
OptionsJmp	       dd      menu_options,menu_options,menu_main
DefaultKeys		db	1,1ch,19h,4bh,4dh,48h,50h,1eh,20h,11h,0,24h,26h,17h,0,53h,51h,47h
;                               esc,ent,p,1l, 1p   1g  1d  2l  2p  2g   3l   3p  3g    4l  4p  4g
AErrorMsg		dd	0
OldVideoMode		dw	0
SelOldKeyInt		dw	0
OfsOldKeyInt		dd	0
SelAloc 		dw	0
Key			db	0
RMRegs: 		times 32h  db  0
UsersKeys:		times 18   db  0
Video rb 640*480

virtual at RMRegs
RMedi		dd	?
RMesi		dd	?
RMebp		dd	?
RMreserved	dd	?
RMebx		dd	?
RMedx		dd	?
RMecx		dd	?
RMeax		dd	?
RMflags 	dw	?
RMes		dw	?
RMds		dw	?
RMfs		dw	?
RMgs		dw	?
RMip		dw	?
RMcs		dw	?
RMsp		dw	?
RMss		dw	?
end virtual
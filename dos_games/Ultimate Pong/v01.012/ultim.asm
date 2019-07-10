format mz
;program do wyswietlania plikow gpf z rozjasnieniem i wyciemnieniem
;wersja niekozystajaca z instrukcji movsd
heap   1000h
stack 2000h
include 'loader.inc'
;fs= 0-based segment ;ds=es-data segnt cs=code segment gs=wolny
segment _code  use32
macro	VWAIT  wait,time
	{push edx ecx eax
	wait:
	 mov	 ecx,time
	 mov	 dx,3dah
	.v1:	 in	 al,dx
	test	al,8
	jz	.v1
	.v2: in      al,dx
	test	al,8
	jnz	.v2
	dec	ecx
	jnz	.v1
       pop     eax ecx edx}



code32:
alloc_dos:
	mov	 [AErrorMsg],TMemoryErrorMsg
	mov	 eax,100h			       ;alokuj pamiec dosa
	mov	 ebx,40h*6			       ;400h bajtow 40h paragrafow 1024 bajty
	int	 31h				       ;do dx=selektor segmentu[PM] do ax=segment [RM]
	jc	 error				       ;jc to blad

	push	 dx
	mov	 [RMes],ax
	pop	 gs				       ;do edx ofset bufora sel:fs

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
	mov	ax,[gs:10h]			       ;DWORD w gs:0eh=adres
	shl	eax,4
	mov	ax,[gs:0eh]			       ;eax=adres struktury z obslugiwanymi modulami
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
	mov	ax,0204h		    ; zmien int 09
	mov	ebx,09
	int	31h
	mov	[OfsOldKeyInt],edx
	mov	[SelOldKeyInt],cx

	mov	ax,0205h		    ; zmien int 09
	mov	edx,keyboard_int
	push	cs
	pop	cx
	mov	ebx,09
	int	31h

	mov	edx,LogoName
	call	open_file
	call	get_file_size

	call	aloc_extended
	add	esp,8				;przywroc stos
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

	mov	ecx,70
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
	mov	ebp,esp
	call	get_file_size

	call	resize_aloc
	mov	esp,ebp 			  ;przywroc stos
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

	mov	esi,1024
	call	get_video
	call	show_video_p0

	xor	ecx,ecx
	call	menu_draw


menu_loop:
	mov	dl,[es:UsersKeys]
	mov	al,[es:BKeyboard+edx]
	test	al,al
	jnz	ending
	@@:
	mov	dl,[es:UsersKeys+5]
	mov	al,[es:BKeyboard+edx]
	test	al,al
	jnz	menu_up
	@@:
	mov	dl,[es:UsersKeys+6]
	mov	al,[es:BKeyboard+edx]
	test	al,al
	jnz	menu_down

	jmp	menu_loop


ending: 			       ;dzialanie: konczy program
	push	es
	pop	ds
	call	free_aloc
	mov	cx,[SelOldKeyInt]
	mov	edx,[OfsOldKeyInt]
	mov	bl,09h
	mov	ax,0205
	int	31h
	mov	ecx,20
	call	wait_time
	mov	bx,[OldVideoMode]
	mov	eax,4f02h				;przywroc tryb
	int	10h

Ending:
	mov	eax,4c00h				;wyjdz
	int	21h

include 'routines.inc'

menu_draw:
	push	ecx
	mov	esi,1024
	call	get_video
	pop	ecx
	push	ecx
	call	get_button
	pop	ecx
	ret

get_button:
	xor	ebx,ebx
	shl	ecx,2
	mov	esi,[es:TMenuAnim+ecx]
	shr	ecx,2
	mov	edi,Video
	add	edi,640*180+210
	test	ecx,ecx
	jz	move_button
	add	edi,640*75
	dec	ecx
	jz	move_button
	add	edi,640*75
	dec	ecx
	jz	move_button
	add	edi,640*75
	dec	ecx

move_button:
	mov	eax,[ds:esi]			      ;zaladuj do eax obraz
	mov	dword[es:edi],eax
	add	esi,4
	add	edi,4
	inc	ecx
	cmp	ecx,55
	jne	move_button
	xor	ecx,ecx
	inc	ebx
	add	edi,420
	add	esi,420
	cmp	ebx,50
	jb	move_button
	call	show_video_p0
	VWAIT	dupa,10
	ret

menu_up:
	dec	ecx
	cmp	ecx,-1
	je	@f
	call	menu_draw
	jmp	menu_loop
@@:
	mov	ecx,3
	call	menu_draw
	jmp	menu_loop
menu_down:
	inc	ecx
	cmp	ecx,4
	je	@f
	call	menu_draw
	jmp	menu_loop
@@:
	xor	ecx,ecx
	call	menu_draw
	jmp	menu_loop

Counter 		dw	0

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
TMenuAnim		dd	640*480+1024,640*480+220+1024,640*530+1024,640*530+220+1024
DefaultKeys		db	1,1ch,19h,4bh,4dh,48h,50h,1eh,20h,11h,0,24h,26h,17h,0,53h,51h,47h
;                               esc,ent,p,1l, 1p   1g  1d  2l  2p  2g   3l   3p  3g    4l  4p  4g
AErrorMsg		dd	0
OldVideoMode		dw	0
SelOldKeyInt		dw	0
OfsOldKeyInt		dd	0
SelAloc 		dw	0
Key			db	0
BKeyboard:		times 80h  db  0
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
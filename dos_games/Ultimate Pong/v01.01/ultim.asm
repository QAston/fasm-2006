format mz
;program do wyswietlania plikow gpf z rozjasnieniem i wyciemnieniem
;wersja niekozystajaca z instrukcji movsd
heap   1000h
stack 1000h
include 'loader.inc'
;fs= 0-based segment ;ds=es-data segnt cs=code segment gs=wolny
segment _code  use32



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

	push	es
	pop	ds
	call	show_video_p

	mov	ecx,70
	call	make_delay

	push	[SelAloc]
	pop	ds

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
	mov	[Key],0

	call	free_aloc
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
	mov	ax,3f00h
	mov	cx,18
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

	push	es
	pop	ds
	call	show_video_p0
	push	[SelAloc]
	pop	ds

	mov	ecx,100
	call	wait_time

	call	free_aloc

ending: 			       ;dzialanie: konczy program
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

get_file_size:

	xor	ecx,ecx
	mov	eax,4202h
	xor	edx,edx 		    ;pobierz rozmiar pliku
	int	21h
	push	dx
	push	ax
	shl	edx,16
	mov	dx,ax
	push	edx

	xor	edx,edx
	mov	eax,4200h
	xor	ecx,ecx
	int	21h

	pop	ecx
	mov	[FileSize],ecx
	mov	[FileHandle],ebx
	jmp	word [ss:esp+4]

resize_aloc:
	mov	si,[AlocHandleSi]
	mov	di,[AlocHandleDi]
	mov	eax,0503h
	mov	cx,[esp+4];pop     cx
	mov	bx,[esp+6];pop     bx
	int	31h
	mov	[AlocHandleSi],si
	mov	[AlocHandleDi],di
	ret

aloc_extended:
	mov	eax,0501h
	mov	cx,[esp+4];pop     cx
	mov	bx,[esp+6];pop     bx
	add	cx,1024*7
	jnc	@f
	inc	bx
@@:
	int	31h
	mov	[AlocHandleSi],si
	mov	[AlocHandleDi],di
	ret

create_selector:
	push	bx
	push	cx
	mov	cx,1
	xor	ax,ax
	int	31h
	mov	dx,ds
	lar	cx,dx
	mov	si,ax
	shr	cx,8
	mov	bx,ax
	or	cx,1100000000000000b
	mov	ax,9
	int	31h
	pop	dx
	pop	cx
	mov	bx,si
	mov	ax,7
	int	31h
	mov	cx,0ffffh
	mov	dx,0ffffh
	mov	eax,8
	mov	bx,si
	int	31h
	mov	[es:SelAloc],si
	ret

get_picture_p:
	mov	ecx,[es:FileSize]
	mov	edx,1024*7			;mov     edx,1024*7
	sub	ecx,1024
get_picture:			     ;dzialanie: pobiera obraz z pliku do bufora
				     ;wymagania:ebx=uchwyt pliku ds=aloc  ecx=rozmiar pliku edx=adres bufora
				     ;zwraca: ebx=nowy uchwyt pliku
	mov	eax,3f00h			      ;czytaj z pliku

	int	21h				      ;zaladuj obraz
	ret

get_video:
	mov	ecx,4b000h/4
	mov	edi,Video
	rep	movsd
	ret

free_aloc:
	mov	eax,1
	mov	bx,[SelAloc]
	int	31h
	mov	eax,502h
	mov	si,[AlocHandleSi]
	mov	di,[AlocHandleDi]
	int	31h
	ret

error:			      ;wymaga: es=_code
			      ;dzialanie: wyswietla errormsg
	push	es
	pop	ds
	mov	edx,[AErrorMsg]
	mov	eax,0900h				  ;jesli wystapil blad
	int	21h
	xor	eax,eax 				 ;czekaj na klawisz
	int	16h
	jmp	Ending

keyboard_int:
	pushfd
	push	eax
      .read:
	in	al,60h			; read scan code
	movzx	eax,al
	cmp	al,0E0h
	jae	.done
	test	al,80h
	jz	.pressed
	and	al,7Fh
	mov	byte[BKeyboard+eax],0
	jmp	.done
      .pressed:
	cmp	byte[BKeyboard+eax],0
	jne	.done
	mov	[es:Key],1
	mov	byte[BKeyboard+eax],1
      .done:
	in	al,61h			; give finishing information
	mov	bx,bx
	out	61h,al			; to keyboard...
	mov	al,20h
	out	20h,al			; ...and interrupt controller
	pop	eax
	popfd
	iret

open_file:			  ;dzialanie: otwiera plik
				  ;wymaga: ds=_code edx=nazwa pliku
				  ;zwraca:ebx=uchwyt pliku edx=uchwyt do nazwy pliku
	mov	  [AErrorMsg],TFileErrorMsg
	mov	  eax,3d00h
	xor	  cx,cx
	int	  21h
	jc	  error
	mov	  ebx,eax
	ret
load_palette:
		 ;dzialanie: laduje palete z pliku do zaalokowanej pamieci
		 ;niszczy:eax,edx,ecx
		 ;wymaga ds=segment DOS es=_code
		 ;zwraca ecx=1024 ebx=nowy uchwyt pliku edx=0
	mov	eax,3f00h			      ;zaladuj palete z pliku
	mov	ecx,1024			      ;1024 bajty
	xor	edx,edx 			      ;ofset bufora
	int	21h
	jc	Ending
	ret

move_palette:	;dialanie: przenosi palete spod ds:esi do gs:edi
		;niszczy: eax, edi,esi, ebp
		;wymaga  ds=_segment palety gs_=selektor zaalokowanej pamieci DOS [edi=0 esi=skad ma przeniesc palete]
		;zwraca: edi=1024 esi=1024 ebp=1024
	xor	edi,edi
	mov	ebp,esi
	add	ebp,1024
@@:
	mov	eax,dword[ds:esi]
	mov	[gs:edi],eax
	add	esi,4
	add	edi,4
	cmp	esi,ebp
	jb	@r
	ret

show_video_p0:
	xor	dx,dx
	xor	bx,bx
	mov	esi,Video
	mov	edi,0a000h*16
	mov	ax,4F05h			      ;zmien bank
	int	10h
	jmp	show_video
show_video_p:
	xor	dx,dx
	xor	bx,bx
	mov	esi,Video
	mov	edi,0a000h*16
show_video:			  ;dzialanie:przenosi obraz z Video do pamieci karty graficznej
				  ;wymagania: dflag=0 dx=0 bx=0 fs=0-based esi=ofset obrazu edi=ofset pamieci video
				  ;zwraca: dx=4 edi=0a000h*16+0b000h  esi=Video+640*480 ax=004fh
	mov	eax,[ds:esi]			      ;zaladuj do eax obraz
	mov	dword[fs:edi],eax		      ;przenies do pamieci karty graf.
	add	edi,4				      ;aktualizuj indexy
	add	esi,4
	cmp	dx,4				      ;czy ostatni bank
	jb	@f
	cmp	edi,0a000h*16+0b000h		      ;czy koniec obrazu
	jb	show_video
	ret
@@:
	cmp	edi,0a000h*16+0ffffh		      ;czy trzeba zmienic bank?
	jb	show_video
	mov	edi,0a000h*16			      ;jesli tak, to ustaw segment pamieci
	add	dx,1
	mov	ax,4F05h			      ;zmien bank
	int	10h
	jmp	show_video

copy_palette:	 ;dzialanie:przenosielement palety spod ds:edx do 5 kolejnych palet zmniejszajac jasnosc
		 ;niszczy: bp,edi,al
		 ;wymaga ds=aloc edx=adres palety
	mov	  edi,edx
	mov	  bp,6
	mov	  al,[edx]

     @@:
	shr	  al,1
	add	  edi,1024
	mov	  [edi],al
	dec	  bp
	jnz	  @r
	ret

set_palette_p:
	mov	[es:RMebx],0				 ;flagi
	mov	[es:AErrorMsg],TVESAErrorMsg		 ;
	mov	[es:RMecx],256				 ;ilosc zmienionych pozycji
	mov	[es:RMedx],0				 ;index startu palety
	mov	[es:RMedi],0				 ;ofset bufora palety RMes segment bufora palety
set_palette: ;dzialanie: ustawia palete spod [RMes:0]
	     ;niszczy:ax
	     ;wymaga:RMebx,RMedx,RMedi=0 RMecx=256 es=_code[edi=RMRegs RMeax=4f09h  RMes=segment DOS z paleta cx=0 bx=0010]
	     ;zwraca:ax=kod bledu DPMI RMeax=kod bledu VESA
	xor	cx,cx				      ;
	mov	edi,RMRegs			      ;
	mov	[es:RMeax],4f09h			 ;funkcja ustaw palete
	mov	bx,0010h			      ;int 10h
	mov	ax,0300h			      ;emuluj przerwanie 16-bit
	int	31h				      ;ustaw palete
	cmp	[es:RMeax],004fh
	jne	error				      ;czy blad
	ret

make_delay:		 ;dzialanie: tworzy odstep czasowy dlugosci cx*1/70 sec.
			 ;niszczy:dx,ax,[counter]
			 ;wymaga: ds=_code cx= odstep czasowy
			 ;zwraca: al=0
	mov	word[es:Counter],0
@@:
	call	delay
	cmp	[es:Key],0
	jne	@f
	cmp	word [es:Counter],cx
	jne	@r
@@:
	ret

wait_time:		;dzialanie: tworzy odstep czasowy dlugosci cx*1/70 sec.
			 ;niszczy:dx,ax,[counter]
			 ;wymaga: ds=_code cx= odstep czasowy
			 ;zwraca: al=0
	mov	word[es:Counter],0
@@:
	call	delay
	cmp	word [es:Counter],cx
	jne	@r
	ret

delay:
	mov    dx,3dah
@@:
	in     al,dx
	test   al,8
	jnz    @r		;Czekaj na rozpoczecie Vertical Retace
@@:
	in     al,dx
	test   al,8
	jz     @r		;Czekaj na zakonczenie Vertical Retace
	add    word[es:Counter],1
	ret


Counter 		dw	0
RMRegs: 		times	  32h  db  0
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
AlocHandleDi	       dw      0
TMenuAnim		dd	640*480,640*480+220,640*530,640*530+220
DefaultKeys		db	1,1ch,19h,4bh,4dh,48h,50h,1eh,20h,11h,0,24h,26h,17h,0,53h,51h,47h
;                               esc,ent,p,1l, 1p   1g  1d  2l  2p  2g   3l   3p  3g    4l  4p  4g
UsersKeys:		times 18    db	    0
AErrorMsg		dd	0
OldVideoMode		dw	0
SelOldKeyInt		dw	0
OfsOldKeyInt		dd	0
SelAloc 		dw	0
Key			db	0
BKeyboard:		times 80h db 0
Video: rb 640*480

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
format mz
;program do wyswietlania plikow gpf z rozjasnieniem i wyciemnieniem
;wersja niekozystajaca z instrukcji movsd
heap   01000h
stack 500h
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
	mov	bl,09
	int	31h
	mov	[OfsOldKeyInt],edx
	mov	[SelOldKeyInt],cx

	mov	ax,0205h		    ; zmien int 09
	mov	edx,keyboard_int
	push	cs
	pop	cx
	mov	bl,09
	int	31h
	mov	edx,LogoName

	call	open_file

	mov	edx,BPalette
			       ;ebx uchwyt pliku
	mov	ecx,4
	mov	esi,1024
prepare_palettes:		      ;dzialanie: tworzy z 1 6 palet ,kazda nastepna jest ciemniejsza
				      ;wymaga: ebx=uchwyt pliku ecx=4 edx=bufor na palete ds=_code esi=1024
				      ;niszczy: eax,ebx,esi,edx,bp,edi
				      ;zwraca: esi=0 bp=0 edx=bufor na palete+1024
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
	test	esi,esi
	jne	prepare_palettes

	push	ebx				      ;zachowaj uchwyt pliku
	mov	esi,BPalette+1024*6
	call	move_palette
	call	set_palette
	pop	ebx		     ;przywroc uchwyt pliku

	call	get_picture

	mov	eax,3e00h
	int	21h

	cld
	mov	edi,0a000h*16			      ;fs:edi -adres pamieci video
	mov	esi,Picture			      ;ds:esi- adres obrazu
	xor	dx,dx				      ;zeruj index
	xor	bx,bx				      ;bh=00=select memory window bl=00=windowA

	call	show_picture

	mov	cx,70
	call	make_delay

	mov	ecx,6
	mov	esi,BPalette+1024*5		 ;wymagane przez move_palette
	mov	[RMedi],0			 ;\
	mov	[RMedx],0			 ;|
	mov	[RMecx],256			 ;- wymagane przez set palette
	mov	[AErrorMsg],TVESAErrorMsg	 ;|
	mov	[RMebx],0			 ;/
@@:
	push	esi cx
	call	move_palette
	mov	cx,8
	call	make_delay
	call	set_palette
	pop	cx esi
	sub	esi,1024
	loop	@r

	mov	cx,90
	call	make_delay

	mov	esi,BPalette+1024		;wymagane przez move_palette
	mov	ecx,6
@@:
	push	esi cx
	call	move_palette
	mov	cx,8
	call	make_delay
	call	set_palette
	pop	cx esi
	add	esi,1024
	loop	@r

	mov	cx,20
	call	make_delay
	mov	[Key],0
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
	push	gs
	pop	ds
	call	load_palette
	push	es
	pop	ds
	push	ebx
	call	set_palette
	pop	ebx
	call	get_picture
draw_menu:
	mov	edi,0a000h*16			      ;fs:edi -adres pamieci video
	mov	esi,Picture			      ;ds:esi- adres obrazu
	xor	dx,dx				      ;zeruj index
	xor	bx,bx				      ;bh=00=select memory window bl=00=windowA
	mov	ax,4F05h			      ;zmien bank
	int	10h
	call	show_picture

menu_loop:
	call	menu_keys
	jmp	menu_loop

ending: 			       ;dzialanie: konczy program
	mov	[Key],0
	mov	cx,10
	call	make_delay
	mov	cx,[SelOldKeyInt]
	mov	edx,[OfsOldKeyInt]
	mov	bl,09h
	mov	ax,0205
	int	31h
	mov	bx,[OldVideoMode]
	mov	eax,4f02h				;przywroc tryb
	int	10h

Ending:
	mov	eax,4c00h				;wyjdz
	int	21h

menu_keys:
	mov	dl,[UsersKeys]
	mov	al,[BKeyboard+edx]
	cmp	al,1
	test	al,al
	jnz	ending
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
	mov	[Key],1
	cmp	byte[BKeyboard+eax],0
	jne	.done
	mov	byte[BKeyboard+eax],1
      .done:
	in	al,61h			; give finishing information
	out	61h,al			; to keyboard...
	mov	al,20h
	out	20h,al			; ...and interrupt controller
	pop	eax
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

get_picture:			     ;dzialanie: pobiera obraz z pliku do bufora
				     ;wymagania:ebx=uchwyt pliku ds=_code
				     ;zwraca: ebx=nowy uchwyt pliku eax=ecx=4b000h edx= picture
	mov	eax,3f00h			      ;czytaj z pliku
	mov	ecx,4b000h			      ;caly plik
	mov	edx,Picture			      ;ofset obrazu
	int	21h				      ;zaladuj obraz
	ret

show_picture:			    ;dzialanie:przenosi obraz z pliku do pamieci karty graficznej
				    ;wymagania: dflag=0 dx=0 bx=0 es=0-based esi=ofset obrazu edi=ofset pamieci video
				    ;zwraca: dx=4 edi=0a000h*16+0b000h  esi=picture+640*480 ax=004fh
	mov	eax,[ds:esi]			      ;zaladuj do eax obraz
	mov	dword[fs:edi],eax		      ;przenies do pamieci karty graf.
	add	edi,4				      ;aktualizuj indexy
	add	esi,4
	cmp	dx,4				      ;czy ostatni bank
	jb	@f
	cmp	edi,0a000h*16+0b000h		      ;czy koniec obrazu
	jb	show_picture
	ret
@@:
	cmp	edi,0a000h*16+0ffffh		      ;czy trzeba zmienic bank?
	jb	show_picture
	mov	edi,0a000h*16			      ;jesli tak, to ustaw segment pamieci
	add	dx,1
	mov	ax,4F05h			      ;zmien bank

	int	10h
	jmp	show_picture



copy_palette:	 ;dzialanie:przenosielement palety spod ds:edx do 5 kolejnych palet zmniejszajac jasnosc
		 ;niszczy: bp,edi,al
		 ;wymaga ds=_code edx=adres palety
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

load_palette:
		 ;dzialanie: laduje palete z pliku do zaalokowanej pamieci
		 ;niszczy:eax,edx,ecx
		 ;wymaga ds=segment DOS es=_code
		 ;zwraca ecx=1024 ebx=nowy uchwyt pliku edx=0
	mov	eax,3f00h			      ;zaladuj palete z pliku
	mov	ecx,1024			      ;1024 bajty
	xor	edx,edx 			      ;ofset bufora
	int	21h
	jc	error
	ret

move_palette:	;dialanie: przenosi palete spod ds:esi do gs:edi
		;niszczy: eax, edi,esi, ebp
		;wymaga  ds=_code gs_=selektor zaalokowanej pamieci DOS [edi=0 esi=skad ma przeniesc palete]
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

set_palette: ;dzialanie: ustawia palete spod [RMes:0]
	     ;niszczy:ax
	     ;wymaga:RMebx,RMedx,RMedi=0 RMecx=256 es=_code[edi=RMRegs RMeax=4f09h  RMes=segment DOS z paleta cx=0 bx=0010]
	     ;zwraca:ax=kod bledu DPMI RMeax=kod bledu VESA
	xor	cx,cx				      ;                                                \
	mov	edi,RMRegs			      ;                                                |
	mov	[RMeax],4f09h			      ;funkcja ustaw palete                            |
;        mov     [RMebx],0                             ;flagi                                          |
;        mov     [AErrorMsg],TVESAErrorMsg             ;                                               -wymagane przez set_palette
;        mov     [RMecx],256                           ;ilosc zmienionych pozycji                      |
;        mov     [RMedx],0                             ;index startu palety                            |
;        mov     [RMedi],0                             ;ofset bufora palety RMes segment bufora palety |
	mov	bx,0010h			      ;int 10h                                        /
	mov	ax,0300h			      ;emuluj przerwanie 16-bit
	int	31h				      ;ustaw palete
	cmp	[RMeax],004fh
	jne	error				      ;czy blad
	ret


make_delay:		 ;dzialanie: tworzy odstep czasowy dlugosci cx*1/70 sec.
			 ;niszczy:dx,ax,[counter]
			 ;wymaga: ds=_code cx= odstep czasowy
			 ;zwraca: al=0
	mov	word[Counter],0
@@:
	call	delay
	cmp	[Key],0
	jne	@f
	cmp	word [Counter],cx
	jne	@r
@@:
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
	add    word[Counter],1
	ret

Counter 		dw	0
TMemoryErrorMsg 	db	"Not enough conventional memory.",13,10,'$'
TOutOfMemoryErrorMsg	db	'Out of memory',13,10,'$'
TVESAErrorMsg		db	"Your graphic card doesn't support VESA 640*480*256 mode!",13,10,'$'
TDPMIErrorMsg		db	'DPMI error!',13,10,'$'
TFileErrorMsg		db	'File error!',13,10,'$'
RMRegs: 		times 32  db ?
TMessage:		db	'Wpisz nazwe pliku [gpf], ktory chcesz otworzyc',10,13,'$'
LogoName		db	'data\Logo.gpf',0
FMenuName		db	'data\menu.gpf',0
FConfigName		db	'data\config.dat',0
DefaultKeys		db	1,1ch,19h,4bh,4dh,48h,50h,1eh,20h,11h,0,24h,26h,17h,0,53h,51h,47h
;                               esc,ent,p,1l, 1p   1g  1d  2l  2p  2g   3l   3p  3g    4l  4p  4g
UsersKeys:		times 18    db	    0
BKeyboard:		times 80h db ?
AErrorMsg		dd	0
OldVideoMode		dw	0
SelOldKeyInt		dw	0
OfsOldKeyInt		dd	0
Key			db	0



BPalette:		times 1024*7 db ?
Picture:		times 640*480  db ?


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




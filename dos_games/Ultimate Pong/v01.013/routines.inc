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
	mov	[es:FileSize],ecx
	mov	[es:FileHandle],ebx
	jmp	word [ss:esp+4]

resize_aloc:
	mov	si,[es:AlocHandleSi]
	mov	di,[es:AlocHandleDi]
	mov	eax,0503h
	mov	cx,[esp+4];pop     cx
	mov	bx,[esp+6];pop     bx
	int	31h
	mov	[es:AlocHandleSi],si
	mov	[es:AlocHandleDi],di
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
	mov	[es:AlocHandleSi],si
	mov	[es:AlocHandleDi],di
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
	mov	bx,[es:SelAloc]
	int	31h
	mov	eax,502h
	mov	si,[es:AlocHandleSi]
	mov	di,[es:AlocHandleDi]
	int	31h
	ret

error:			      ;wymaga: es=_code
			      ;dzialanie: wyswietla errormsg
	push	es
	pop	ds
	mov	edx,[es:AErrorMsg]
	mov	eax,0900h				  ;jesli wystapil blad
	int	21h
	xor	eax,eax 				 ;czekaj na klawisz
	int	16h
	jmp	Ending


open_file:			  ;dzialanie: otwiera plik
				  ;wymaga: ds=_code edx=nazwa pliku
				  ;zwraca:ebx=uchwyt pliku edx=uchwyt do nazwy pliku
	mov	  [es:AErrorMsg],TFileErrorMsg
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
	xor	edx,edx
	xor	ebx,ebx
	mov	esi,Video
	mov	edi,0a000h*16
	mov	eax,4F05h			       ;zmien bank
	int	10h
	jmp	show_video
show_video_p:
	xor	edx,edx
	xor	ebx,ebx
	mov	esi,Video
	mov	edi,0a000h*16
show_video:			  ;dzialanie:przenosi obraz z Video do pamieci karty graficznej
				  ;wymagania: dflag=0 dx=0 bx=0 fs=0-based esi=ofset obrazu edi=ofset pamieci video
				  ;zwraca: dx=4 edi=0a000h*16+0b000h  esi=Video+640*480 ax=004fh


	mov	eax,[es:esi]			      ;zaladuj do eax obraz

;check_vr:
;        push    edx eax
;        mov     dx,3dah
;        .v2: in      al,dx
;        test    al,8
;        jz     .v2
;       pop     eax edx

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
	xor	ecx,ecx 				;
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

menu_draw:
	mov	esi,1024
	call	get_video
	call	get_button
	call	get_mouse
	call	show_video_p0
	ret

get_button:
	xor	ebx,ebx
	mov	ecx,ebp
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
	ret

menu_up:
	dec	ebp
	cmp	ebp,-1
	jne	menu_loop
	mov	ebp,3
	jmp	menu_loop
menu_down:
	inc	ebp
	cmp	ebp,4
	jne	menu_loop
	xor	ebp,ebp
	jmp	menu_loop
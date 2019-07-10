;wlacza obsluge game.fnt i tryb 80/50 w programie

	mov	ax, 0013h			      ;zmus windows do fullscreen
	cld
	int	10h

	mov	eax,100h			      ;alokuj pamiec dosa
	mov	ebx,1				      ;400h bajtow 40h paragrafow 1024 bajty
	int	31h				      ;do dx=selektor segmentu[PM] do ax=segment [RM]

	push	dx				      ;selektor pamieci dos do gs
	mov	[RMes],ax			      ;segment pamieci dos do RMes
	pop	gs

	mov	ax, 0003h			      ; tryb 3 (80x25x16)
	int	10h

	mov	ax,1112h			     ; funkcja wyboru generatora
	xor	bl,bl				     ; nr. generatora 0
	int	10h

change_fonts:
	mov	ax,1112h			     ; funkcja wyboru generatora
	xor	bl,bl				     ; nr. generatora 0
	int	10h

	mov	edx,FFontName			      ;otworz plik z fontami
	mov	ax,3d00h			      ;tylko do odczytu
	xor	ecx,ecx
	int	21h
.get_file_size:
	mov	ebx,eax 			      ;do ebx uchwyt do pliku
	xor	ecx,ecx
	mov	ax,4202h			     ;przenies na koniec pliku
	xor	edx,edx 			     ;pobierz rozmiar pliku
	int	21h
	mov	[RMebp],1			     ;przesuniecie w RMes
	shl	edx,16
	mov	[RMeax],1100h			     ;Generator znak¢w
	mov	dx,ax				     ;rozmiar pliku do edx
	mov	[RMecx],1			     ;liczba znak¢w do zamiany
	push	edx				     ;zachowaj rozmiar pliku
	xor	ecx,ecx
	mov	[RMebx],800h			     ;znak 8-bitowy do bloku 0
	mov	ax,4200h			     ;przejdz na poczatek pliku
	xor	edx,edx
	int	21h
	lea	edi,[RMRegs]			     ;laduj do edi adres struktury z rejestrami rm
	pop	eax				     ;przywroc rozmiar pliku
	xor	edx,edx
	mov	ecx,9
	div	ecx				     ;eax/9= liczba fontow zapisanych w pliku
	mov	ebp,eax 			     ;liczba fontow do ebp
.check_font:
	test	ebp,ebp
	je	.fonts_changed
	xor	edx,edx
	push	gs
	mov	ecx,9				     ;czytaj 9 bajtow
	pop	ds
	mov	ax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	movzx	eax,byte[edx]			     ;pobierz numer fonta
	push	es
	pop	ds
	mov	[RMedx],eax			     ;podaj numer fonta
	push	ebx
.new_fonts:
	mov	eax,0300h			     ;symuluj przerwanie dos
	mov	ebx,10h 			     ;przerwanie 10h
	xor	ecx,ecx
	int	31h
	pop	ebx
	dec	ebp
	jmp	.check_font
.fonts_changed:
	mov	ax,3e00h			     ;zamknij plik
	int	21h
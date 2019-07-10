format mz
stack  100h
;engine textowy w DPMI
include 'loader.inc'
segment _code  use32
code32:
	mov	ax, 0013h			      ;zmus windows do fullscreen
	cld
	int	10h

	mov	ecx,SizeBuffer
	mov	edi,BUFFER			      ;zeruj bufory
	call	zeroize_buffer			      ;inicjuj pamiec

	movzx	eax,word[fs:43h*4]		      ;pobierz offset fontow 8/8
	movzx	ebx,word[fs:43h*4+2]		      ;pobierz segment
	shl	ebx,4
	add	eax,ebx 			      ;oblicz adres rzeczywisty
	mov	[ActualFonts1],eax		      ;zapisz adres

generate_ascii_buttons:
	;tworzy tablice z buttonami
	mov	edi,ASCIIButtons+2		      ;edi=adres docelowy tablicy
	mov	ax,04f0h			      ;na poczatek tablicy kolor buttonow i ich dlugosc
	mov	[edi-2],ax
;        xor     ecx,ecx                              ;ecx=0
.ascii_loop:
	mov	ebx,ecx 			      ;ebx=ecx
	and	bl,1111b			      ;bl=bl mod 16
	lea	eax,[ebx*4+ebx] 		      ;eax=ebx*5
	mov	ebx,ecx
	shr	ebx,4				      ;ebx=ebx/16
	mov	ah,bl
	add	ebx,13
	or	ebx,10000000b
	add	ah,bl
	mov	[edi+ecx*2],ax			      ;przenies adres buttona do tablicy
	inc	cl
	jnz	.ascii_loop

	mov	eax,100h			      ;alokuj pamiec dosa
	mov	ebx,1				      ;400h bajtow 40h paragrafow 1024 bajty
	int	31h				      ;do dx=selektor segmentu[PM] do ax=segment [RM]

	push	dx				      ;selektor pamieci dos do gs
	mov	[RMes],ax			      ;segment pamieci dos do RMes
	pop	gs

	mov	ax, 0003h			      ; tryb 3 (80x25x16)
	int	10h
	mov	ax,0001h
	int	33h

generate_font_buttons:
	mov	edi,FontButtons+2		      ;edi=adres docelowy tablicy
	mov	ax,111001111b			      ;ax= kolor i dlugosc bufora
	mov	[edi-2],ax
;        xor     ecx,ecx
.ascii_loop:
	mov	eax,ecx
	and	al,111b 			      ;al=al mod 8
	mov	ah,cl
	add	eax,35
	shr	ah,3				      ;ah=ah/8
	add	ah,20
	or	ah,10000000b
	mov	[edi+ecx*2],ax			      ;przenies adres buttona do tablicy
	inc	cl
	cmp	cl,64				      ;czy juz wszystko?
	jnz	.ascii_loop

aloc_mem_for_fonts:				      ;alokuj pamiec dla tablicy fontow
	mov	ax,0501h
	mov	ecx,900h
	xor	ebx,ebx
	int	31h
	shl	ebx,16				      ;oblicz adres pliku wzgledem _code
	mov	eax,_code
	mov	bx,cx
	shl	eax,4
	sub	ebx,eax
	mov	[AFonts],ebx			      ;zapisz adres fontow do zmiennej

read_from_file:
	mov	ecx,900h
	mov	edi,[AFonts]			      ;zeruj bufor na fonty
	call	zeroize_buffer


	mov	edx,FFontName			      ;otworz plik z fontami
	mov	ax,3d00h			      ;tylko do odczytu
;        xor     ecx,ecx
	int	21h
	jnc	file_present			      ;jc to nie ma pliku

	push	menu_start			      ;powrot z procedury
default_fonts:
	;przenosi standardowe fonty do zaalokowanego bufora
	;zwraca: ecx=0 al= numer ostatniego fonta esi=[adres ostatniego fonta+1] ebx=[AFonts]
	mov	esi,FONTS			      ;esi=adres standardowych fontow
	mov	ebx,[AFonts]
.mov_font:
	movzx	eax,byte[esi]			      ;do al numer fonta
	lea	edi,[eax*8+eax]
	mov	ecx,9				      ;przenies 9  bajtow
	add	edi,ebx
	rep	movsb				      ;przenies font i jego numer do bufora
	cmp	al,[esi]
	jb	.mov_font			      ;jesli numer obecnego fonta mniejszy od poprzedniego to juz
	ret

file_present:
	mov	ebx,eax 			      ;do ebx uchwyt do pliku
get_file_size:
;        xor     ecx,ecx
	mov	ax,4202h			     ;przenies na koniec pliku
	xor	edx,edx 			     ;pobierz rozmiar pliku
	int	21h
	shl	edx,16
	mov	dx,ax				     ;rozmiar pliku do edx
	push	edx				     ;zachowaj rozmiar pliku
	mov	ax,4200h			     ;przejdz na poczatek pliku
	xor	edx,edx
	xor	ecx,ecx
	int	21h

	pop	eax				     ;przywroc rozmiar pliku
	xor	edx,edx
	mov	ecx,9
	div	ecx				     ;eax/9= liczba fontow zapisanych w pliku
	mov	ebp,eax

	mov	edi,[AFonts]
	inc	ebp
.check_font:
	dec	ebp				     ;czy juz wszystkie fonty
	jz	.fonts_changed
	mov	edx,edi
	mov	ecx,1
	mov	ax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	movzx	eax,byte[edx]			     ;pobierz numer fonta
	lea	ecx,[eax*8+eax] 		     ;ecx=eax*9
	add	edx,ecx
	mov	[edx],al			     ;przenies numer fonta
	mov	ecx,8				     ;czytaj 8 bajtow
	inc	edx
	mov	ax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	jmp	.check_font
.fonts_changed:
	mov	ax,3e00h			     ;zamknij plik
	mov	[edi],al			     ;zeruj bufor
	int	21h

menu_start:
	call	change_fonts			     ;zmien fonty
to_menu:
	xor	bx,bx				     ;menu do pozycji 0
to_main_menu:
	push	bx				     ;zachwaj pozycje menu
	call	reset_bvideo			     ;zeruj bufor video
	mov	esi,TProgramTitle
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS			     ;pokaz txty

	mov	esi,TMenu
	mov	bx,500h
	call	show_text_DOS

	mov	esi,TMessage
	mov	bx,0b00h
	call	show_text_DOS
	pop	bx				     ;przywroc pozyje menu
main_menu:
	mov	[MenuPosition],bx		     ;ustaw pozycje menu
main_loop:
	mov	eax,0f00h			     ;ah= kolor znaku
	mov	edx,811h			     ;dx,kolor i znak <
	mov	edi,160*13+BVideo		     ;edi= index do bufora obrazu
.show_ascii:
	push	ax				     ;zachowaj kolor znaku
	mov	[edi],ax			     ;pokaz ascii
	add	edi,2				     ;aktualizuj index
	mov	[edi],dx			     ;pokaz znak
	add	edi,2

	mov	ah,4				     ;do ah kolor
	call	show_num			     ;pokaz kod ascii znaku
	pop	ax				     ;przywroc kolor znaku
	mov	cx,1				     ;liczba spacji gdy liczba dwucyfrowa
	cmp	al,15				     ;ile ma byc spacji?
	ja	.show_space
	inc	cx				     ;cx=liczba spacji
.show_space:
	push	ax				     ;zachowaj kolor i kod ostatniego znaku
	shl	cx,1				     ;cx*2
	call	zeroize_buffer			     ;czy wszystkie spacje???
	pop	ax				     ;przywroc kolor i kod ostatniego znaku
	mov	bl,al
	inc	bl
	and	bl,1111b			     ;czy podzielne przez 16
	jnz	@f
	add	edi,160 			     ;jesli tak przeskocz 1 linie
	@@:
	inc	al				     ;nastepny znak
	jnz	.show_ascii			     ;czy wszystkie znaki???

	mov	esi,ASCIIButtons		     ;ktory button aktywny?
	call	get_button
	call	show_buffer			     ;pokaz zawartosc bufora na ekranie

get_main_key:					     ;sprawdza czy sa polecenia
	mov	esi,ASCIIButtons		     ;adres procedury z buttonami
	mov	ebp,257 			     ;ilosc + 1
	call	check_keys			     ;sprawdz klawiature i mysz

	test	ax,ax
	je	get_main_key			     ;gdy ax=0 brak polecen

	cmp	ax,0ffh
	je	main_menu			     ;jesli tak to mysz wskazuje na button

	mov	edi,main_menu			     ;adres skoku do edi
	mov	bx,[MenuPosition]		     ;pozycja w menu do bx
	cmp	ah,4dh				     ;prawo
	jnz	@f
	inc	bx
	mov	cx,bx
	and	cx,1111b			     ;czy przekroczylo granice
	jnz	main_menu			     ;jesli nie to wyjdz
	sub	bx,16				     ;jesli tak to koryguj
	jmp	edi				     ;i wyjdz

	@@:
	cmp	ah,4bh				    ;lewo
	jnz	@f
	dec	bx
	mov	cx,bx
	inc	cx
	and	cx,1111b
	jne	main_menu
	add	bx,16
	jmp	dword edi

	@@:
	cmp	ah,48h				   ;gora
	jnz	@f
	sub	bx,16
	cmp	bx,0
	jge	main_menu
	add	bx,256
	jmp	dword edi

	@@:
	cmp	ah,50h				   ;dol
	jnz	@f
	add	bx,16
	cmp	bx,256
	jb	main_menu
	sub	bx,256
	jmp	dword edi

	@@:
	cmp	ah,1h				  ;esc
	jz	ending				  ; jesli tak to wyjdz z programu

	cmp	ah,3bh				  ;f1-zapisz fonty do pliku
	jnz	@f

	mov	edx,FFontName			  ;utworz plik
	mov	eax,3c00h
	xor	ecx,ecx 			  ;do odczytu i zapisu
	int	21h
	mov	ebx,eax 			  ;uchwyt do ebx
	mov	esi,[AFonts]			  ;adres fontow do esi
	xor	edi,edi
	mov	ecx,9
	sub	edi,ecx
.f1:						  ;pobiera numer fonta i oblicza adres
	add	edi,ecx
	mov	edx,esi
	add	edx,edi
	movzx	eax,byte[edx]			  ;pobierz numer fonta do eax
	cmp	edi,256*9			  ;czy wszystkie fonty?
	jne	.f11
	xor	ecx,ecx
	jmp	.f111
.f11:						  ;sprawdza czy font pusty
	test	al,al				  ;czy font nr 0?
	jnz	.f111				  ;jesli nie to zapisz go do pliku
	test	edi,edi 			  ;czy jest pierwszym fontem?
	jne	.f1				  ;jesli nie to do nastepnego fonta
	xchg	edx,edi
	push	ecx edi
	repe	scasb				  ;czy font jest pusty
	pop	edi ecx
	xchg	edi,edx
	je	.f1				  ;jesli tak to do nastepnego
.f111:
	mov	eax,4000h
	int	21h				  ;zapisz do pliku font
	test	ecx,ecx 			  ;czy wszystkie fonty?
	jne	.f1
	mov	eax,3e00h
	int	21h				  ;zamknij plik
	jmp	get_main_key

	@@:
	cmp	ah,3ch				  ;f2- wyczysc tablice fontow
	jne	@f
	mov	edi,[AFonts]			  ;adres fontow do edi
	mov	ecx,900h			  ;zeruj 900h bajtow
	call	zeroize_buffer
	call	change_fonts			  ;zmien fonty na wyzerowane
	jmp	get_main_key

	@@:
	cmp	ah,3dh				  ;f3- zaladuj domyslna tablice fontow
	jne	@f
	call	default_fonts			  ;przywroc fonty standardowe
	call	change_fonts			  ;zmien fonty
	jmp	get_main_key

	@@:
	cmp	ah,3eh				  ;f4- czytaj z pliku
	je	read_from_file

	cmp	ah,3fh				  ;f5- autor
	jne	@f
	call	reset_bvideo			  ;czysc bufor video
	mov	esi,TAuthor
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS			  ;pokaz tekst
	call	show_buffer			  ;wyswietl bufor
	push	to_menu
wait4key:
	xor	ebp,ebp
	call	check_keys			  ;sprawdz czy wcisnieto klawisz lub przycisk
	test	ah,ah
	jz	wait4key			 ;az do skutku
	ret

	@@:
	cmp	ah,40h				  ;f6- pomoc
	jne	@f
	call	reset_bvideo			  ;czysc bufor video
	mov	esi,THelp
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS			  ;pokaz tekst
	call	show_buffer			  ;wyswietl bufor
	call	wait4key			  ;czekaj na klawisz
	jmp	to_menu

	@@:
	cmp	ah,1ch				  ;enter
	jne	get_main_key			  ;jesli enter to przechodzi na inny ekran
go_to_edit:
	movzx	ebp,[MenuPosition]		  ;ebp=stara pozycja w menu
	mov	esi,[AFonts]
	lea	eax,[ebp*8+ebp] 		  ;eax= ebp*8
	add	esi,eax
	mov	[OldMenuPos],bp
	mov	[AEditedFont],esi		  ;zapisz adres edytowanego fonta
	test	bp,bp
	je	.font_exists			  ;czy font 0?
	cmp	byte[esi],0
	jne	.font_exists			  ;czy font byl edytowany?
.font_low:
	mov	eax,[ActualFonts1]		  ;pobierz adres ze zdefiniowanymi fontami
	shl	ebp,3
	add	eax,ebp 			  ;eax= adres potrzebnego fonta
	mov	edi,Font
@@:
	mov	ebx,[fs:eax]			  ;pobierz czesc fonta
	mov	[edi],ebx			  ;przenies do bufora edycji
	add	edi,4
	add	eax,4
	cmp	edi,Font+8
	jne	@r
	jmp	font_reset
.font_exists:
	mov	ecx,8
	inc	esi
	mov	edi,Font
	call	strncpy 			  ;kopiuj edytowany font do bufora
font_reset:
	call	reset_bvideo			  ;czysc bufor video

show_sign:
	mov	ax,[OldMenuPos] 		  ;pobierz edytowany znak
	mov	ah,4				  ;kolor znaku
	mov	bx,0fdch
	mov	cx,6
	mov	edi,(AFont-(240)*2)+2		  ;adres na znak
@@:
	mov	[edi],bx
	add	edi,2				  ;wyswietla gorna belke nad edytowanym znakiem
	dec	cx
	jnz	@r

	mov	edi,(AFont-(160)*2)+2		  ;adres na znak
	inc	bl
	mov	[edi],bx			  ;wyswietl lewa scianke
	add	edi,2
	mov	[edi],ax			  ;wyswietl edytowany znak
	add	edi,4				  ;zrob odstep
	push	ax
	call	show_num			  ;pokaz numer edytowanego znaku
	pop	ax
	inc	bl
	cmp	al,15				  ;czy znak jednocyfrowy
	ja	@f
	add	edi,2				  ;jesli tak to zrob dodatkowy odstep
	@@:
	mov	[edi],bx			  ;wyswietl prawa scianke

	mov	esi,TProgramTitle
	mov	edi,BVideo
	xor	bx,bx
	mov	ah,15
	call	show_text_DOS			  ;pokaz teksty

	mov	esi,TFont
	mov	bx,500h
	call	show_text_DOS
	xor	bx,bx
font_redraw:
	mov	[MenuPosition],bx		  ;zapisz zmiane pozycji menu
font_edit:
	mov	esi,FontEditor			  ;adres z znakami scian ramki
	mov	edi,BVideo+160*19+68		  ;adres w ktorym wyswietlic reamke
	mov	ah,15				  ;ah= kolor fonta[bialy]
	mov	dx,7

font_frame:
	mov	ebx,[esi]			  ;pobierz elementy ramki
	mov	[edi+1],ah			  ;przenies kolor
	mov	cx,8
	mov	[edi],bl			  ;i znak lewego elementu na ekran
	shr	bx,8				  ; do bl znak 8 srodkowych elementow
	mov	bh,ah				  ;kolor do bh
	@@:
	add	edi,2				  ;do nastepnej komorki ekranu
	mov	[edi],bx			  ;przenies znak na ekran
	dec	cx				  ;i tak 8 razy
	jnz	@r
	add	edi,2				  ;do nastepnej komorki ekranu
	shr	ebx,16				  ;do bl znak gornego prawego rogu
	mov	bh,ah				  ;do bh kolor
	mov	[edi],bx			  ;wyswietl
	add	esi,3				  ;do nastepnych elementow
	add	edi,160-18			  ;linijke w dol
	cmp	esi,FontEditor+6		  ;czy juz wszystko?
	jne	@f
	test	dx,dx
	jz	@f
	dec	dl				  ; i tak 7 razy
	sub	esi,3
	@@:
	cmp	esi,FontEditor+9		  ; czy wszystko?
	jne	font_frame

show_font:					  ; pokaz znak do edycji
	mov	ebx,dword[Font] 		  ;I polowa znaku
	mov	ecx,dword[Font+4]		  ;II polowa znaku
	xor	esi,esi 			  ;esi= wspolrzedna X
	xor	edi,edi 			  ;edi=wspolrzedna Y
	sub	esi,2
.mov_font:					  ;wyswietla 1 linijke fonta
	clc					  ;wyczysc carry zeby rcl dzialal poprawnie
	add	esi,2				  ;wspolrzednaX+1
	rcl	bl,1				  ;bit do carry
	jnc	.mov_font			  ;jesi carry=0 to nastepny
	test	bl,bl				  ;czy sprawdzone wszystkie bity?  czy koliec linii?
	jz	.font
	mov	eax,160
	mul	edi				  ;eax=edi*160
	mov	word[AFont+eax+esi],0fdbh	  ;przenies na ekran kawalek znaku
	jmp	.mov_font
.font:
	xor	esi,esi 			  ;zeruj wspolrzedna X
	sub	esi,2
	inc	edi				  ;wspolrzedna Y+1
	shrd	ebx,ecx,8			  ;nastepna linijka do bl
	shr	ecx,8
	push	ebx
	or	ebx,ecx 			  ;czy juz wszystko wyswietlone?
	pop	ebx
	jnz	.mov_font			  ;jesli nie to nastepna linijke

	mov	edi,AFont+18
	mov	ah,04h
	mov	dx,0710h			  ;dx,kolor i znak <
	xor	esi,esi
.num_loop:
	mov	[edi],dx
	mov	al,[Font+esi]
	mov	[edi],dx
	add	edi,2
	push	edi
	call	show_num
	pop	edi
	inc	esi
	add	edi,158
	cmp	esi,8
	jne	.num_loop
	mov	esi,FontButtons
	call	get_button			  ;zaznacz aktywna pozycje menu
	call	show_buffer

get_edit_keys:
	mov	esi,FontButtons 		  ;adres tablicy z buttonami
	mov	ebp,65				  ;sprawdz 65 buttonow
	call	check_keys			  ;sprawdz klawiature i mysz

	test	ax,ax
	je	get_edit_keys			  ;czy nic nie wcisniete?

	cmp	ax,0ffh
	je	font_redraw			  ;czy mysz na buttonie?

	mov	edi,font_redraw
	mov	bx,[MenuPosition]
	cmp	ah,4dh				  ;prawo
	jnz	@f
	inc	bx
	mov	cx,bx
	and	cx,111b
	jne	font_redraw
	sub	bx,8
	jmp	edi
	@@:
	cmp	ah,4bh				 ;lewo
	jnz	@f
	dec	bx
	mov	cx,bx
	and	cx,111b
	cmp	cx,7
	jne	font_redraw
	add	bx,8
	jmp	edi
	@@:
	cmp	ah,48h				;gora
	jnz	@f
	sub	bx,8
	cmp	bx,0
	jge	font_redraw
	add	bx,64
	jmp	edi
	@@:
	cmp	ah,50h				;dol
	jnz	@f
	add	bx,8
	cmp	bx,64
	jb	font_redraw
	sub	bx,64
	jmp	edi
	@@:

	cmp	ah,1h				;esc- wyjscie z edycji fonta
	jnz	@f
	mov	bx,[OldMenuPos] 		;przywroc stara pozycje menu
	jmp	to_main_menu
	@@:

	cmp	ah,3bh				;f1- zapisz do tablicy fontow
	jnz	@f
	mov	ax,[OldMenuPos] 		;numer edytowanego fonta
	mov	edi,[AEditedFont]		;adres w tablicy fontow edytowanedo fonta
	mov	[edi],al
	inc	edi
	push	ax
	mov	esi,Font			;przenies fonta z bufora edycji do bufora ze wszystkimi fontami
	mov	ecx,8				;przenies 8 bajtow
	call	strncpy
	call	change_fonts			;zmien fonty na te z buora fontow
	pop	bx
	jmp	to_main_menu			;wyjdz
	@@:
	cmp	ah,3ch				;f2- usun z bufora edycji i z bufora wszystkich fontow
	jne	@f
	mov	edi,Font			;adres bufora edycji
	mov	ecx,8				;8 bajtow
	call	zeroize_buffer			;zeruj
	mov	edi,[AEditedFont]		;adres edytowanego fonta w buforze
	mov	ecx,9
	call	zeroize_buffer			;zeruj 9 bajtow
	call	change_fonts			;zmien fonty
	mov	bx,[OldMenuPos] 		;przywroc stara pozycje menu
	jmp	to_main_menu			;wyjdz
	@@:
	cmp	ah,1ch				;enter- edycja fonta
	jne	get_edit_keys
	mov	bx,[MenuPosition]		;pobierz numer edytowanego piksela fonta
	movzx	ecx,bx
	shr	cx,3				;numer/8 = wspolrzedna X
	and	bx,111b 			;numer mod 8= wspolrzedna Y

       ; mov     si,bx
	mov	ax,100000000b
	inc	bx
	@@:					;stworz maske do odwrocenia odpowiedniego bitu fonta
	shr	ax,1				;1 bit w prawo
	dec	bx				;czy maska utworzona?
	jnz	@r

	lea	edi,[Font]			;adres bufora z edytowanym fontem
	add	edi,ecx 			;dodaj wspolrzedna Y
	mov	dl,[edi]			;pobierz linijke z modyfikowanym bitem
	xor	dl,al				;odwroc bit
	mov	[edi],dl			;zapisz spowrotem w buforze
	jmp	font_edit


ending:
	mov	ax, 0003h			;przywroc tryb graficzny
	int	10h
Ending:
	mov	ax,4c00h			;zamknij program
	int	21h

change_fonts:
	mov	esi,[AFonts]
	;zmienia fonty 8/8
	;ds:esi= adres struktury z fontami
	mov	ax,1112h			     ; funkcja wyboru generatora
	xor	bl,bl				     ; nr. generatora 0
	int	10h
	mov	[RMebp],0			     ;przesuniecie 0 w RMes
	mov	[RMeax],1100h			     ;Generator znak¢w
	mov	[RMecx],1			     ;liczba znak¢w do zamiany
	mov	[RMedx],0			     ;adres,skad maja byc pobrane znaki
	mov	[RMebx],800h			     ;znak 8-bitowy do bloku 0
	xor	bp,bp				     ;licznik zmienionych fontow
	dec	bp
.move_fonts:
	inc	bp
	cmp	bp,100h 			     ;czy wszystkie fonty zmienione?
	je	.no_fonts
	xor	edi,edi 			     ;index do pamieci dos
	movzx	bx,byte[esi]			     ;do bl numer fonta w matrycy
	add	esi,9
	test	bl,bl				     ;czy font oznaczony 0?
	jnz	@f				     ;jesli nie to zmien
	or	bx,bp				     ;czy font nr 0 jest pusty
	jnz	.move_fonts			     ;jesli tak to do nastepnego
	@@:
	sub	esi,9
	add	esi,1				     ;esi=adres fonta
.fonts:
	mov	eax,[esi]			     ;przenies fonty do pamieci dosa
	mov	[gs:edi],eax			     ;skad zostana ustawione na ekran
	add	edi,4
	add	esi,4
	cmp	edi,8
	jne	.fonts
	lea	edi,[RMRegs]			     ;laduj do esi adres struktury z rejestrami rm
.new_fonts:
	mov	byte[RMedx],bl			     ;podaj numer fonta
	mov	eax,0300h			     ;symuluj przerwanie dos
	mov	ebx,10h 			     ;przerwanie 10h
	int	31h
	jmp	.move_fonts
.no_fonts:
	mov	ah,01h
	mov	cx,0ffffh			     ;ukryj kursor
	int	10h
	ret

show_buffer:
	;przenosi obraz z bufora do pamieci karty graficznej
	;wymaga: fs=0-based ds=data seg
	;zwraca: ecx=0 edi=0B8000h+160*50 esi=BVideo+160*50 ax=ostatni przeniesiony znak
	mov	edi,0B8000h			     ;adres pamieci obrazu
	mov	esi,BVideo			     ;adres bufora zrodlowego
	mov	ecx,80*50/2			     ;ilosc dwordow do przeniesienia
.get_screen:
	mov	eax,[esi]
	mov	[fs:edi],eax			     ;przenies 4 bajty
	add	edi,4
	add	esi,4				     ;uaktualnij indexy
	dec	ecx
	jnz	.get_screen
	ret

reset_bvideo:
	mov	edi,BVideo			    ;adres bufora video
	mov	ecx,80*50*2			    ;ilosc bajtow
zeroize_buffer:
	;zeruje bufor o podanym adresie i dlugosci
	;wymaga:es:edi= adres bufora do wyzerowania
	;ecx= liczba bajtow do wyzerowania
	;zwraca: eax=0 ecx=0 edx=ecx mod 4  edi=adres ostatniego bajtu bufora
	xor	eax,eax 			    ;zeruj eax
	push	ecx				    ;zachowaj liczbe bajtow do zerowania
	shr	ecx,2				    ;podziel liczbe bajtow przez 4
	rep	stosd				    ;przenies eax do es:edi i zwieksz index o 4
	pop	ecx				    ;liczba bajtow mod 4
	and	ecx,11b 			    ;przenies reszte z dzielenia przez 4
	rep	stosb				    ;przenies al do es:edi i zwieksz index o 1
	ret

strncpy:
	;kopiuje ciag o podanej dlugosci z podanego adresu
	;wymaga:es:edi= adres docelowy ds:esi adres zrodlowy
	;ecx= liczba bajtow do przeniesienia
	;zwraca: eax=ostatni przenoszony bajt ecx=0
	;edi = edi+ecx esi=esi+ecx
	push	ecx				   ;zachwaj liczbe bajtow do przeniesienia
	shr	ecx,2				   ;liczba dwordow
	rep	movsd				   ;przenies ds:esi do es:edi i zwieksz index o 4
	pop	ecx
	and	ecx,11b 			   ;liczba bajtow mod 4
	rep	movsb				   ;przenies ds:esi do es:edi i zwieksz index o 1
	ret
check_keys:
	;sprawdza czy wcisnieto przycisk myszy, pozycje kursora i wcisniety klawisz
	;wymaga: ebp=rozmiar bufora na buttony+1 esi adres bufora buttonow gdy:ebp=0 nie sprawdza buttonow
	;zwraca: gdy wcisnieto klawisz: ah-skankod klawisza
	;gdy wcisnieto przycisk: ah=1ch
	;gdy kursor na buttonie ax=0ffh
	;gdy nic: ax=0

	mov	ah,1				   ;czy wcisnieto jakis klawisz?
	int	16h
	jz	.no_key
	xor	ah,ah				   ;jesli tak to pobierz klawisz
	int	16h
	ret
.no_key:
	mov	ax,3h				   ;pobierz stan myszy
	int	33h				   ;bx:klawisze cx:kolumna8* dx:rzad*8
	mov	ah,1ch
	test	bx,bx				   ;czy wcisnieto przycisk myszy
	jnz	.enter				   ;gdy wcisnieto przycisk to symuluj enter
	test	ebp,ebp 			   ;czy sprawdzac buttony?
	je     .no_mouse
	shr	cx,3				   ;cx:kolumna
	mov	bx,bp				   ;bx: ilosc buttonow+1
	shr	dx,3				   ;dx:rzad
.get_position:
	dec	bx				   ;czy wszystkie buttony
	jz	.no_mouse
	mov	ch,[esi+1]			   ;pobierz dlugosc buttona
	mov	ax,[ebx*2+esi]			   ;pobierz polozenie buttona
	and	ah,111111b			   ;usun smieci
	cmp	dl,ah				   ;czy rzedy takie same?
	jne	.get_position
.pos_loop:
	cmp	al,cl				   ;czy kolumny takie same?
	je	.pos_good
	inc	al				   ;jesli nie to zwieksz pozycje X buttona o 1
	dec	ch				   ;porownaj tyle razy ile wynosi dlugosc buttona
	jnz	.pos_loop
	jmp	.get_position
.pos_good:					   ;gdy mysz na buttonie
	dec	ebx				   ;ebx: nowa pozycja menu
	xor	ax,ax
	dec	al				   ;ax=ffh
	ret
.enter:
	mov    dx,3dah				   ;3dah=VGA feature control regirster
	mov    cx,10				   ;ile razy opoznic
.delay:
	in     al,dx
	test   al,8				  ;czy vr rozpoczeta?
	jnz    .delay				  ;jesli nie to jeszcze raz
@@:
	in     al,dx
	test   al,8				  ;czy vr zakonczona?
	jz     @r				  ;jesli nie to sprawdz jeszcze raz
	dec    cx				  ;10 razy
	jnz    .delay
	ret
.no_mouse:
	xor	ax,ax
	ret

get_button:
	;zmienia kolor buttona o pozycji podanej w tablicy
	;wymaga:esi=adres tablicy:1bajt dlugosc 1bajt kolor ,XY,XY...
	;zwraca: dx=0 bh=0
	movzx	ecx,word[MenuPosition]		  ;pozycja menu do ecx
	mov	bx,word[esi]			  ;bh:dlugosc bl:kolor
	shl	ebx,16				  ;zachowaj w gornej polowie ebx
	inc	ecx
.go_butt:					  ;oblicza adres buttona okreslonego w ecx
	add	esi,2				  ;do nastepnego buttona
	mov	bx,[esi]			  ;pobierz XY
	test	bh,10000000b			  ;czy button jest samodzielny?
	jz	.go_butt
	dec	ecx
	jnz	.go_butt
.button:
	mov	bx,[esi]			  ;pobierz XY
	xor	dx,dx
	test	bh,01000000b			  ;czy button jest czescia innego
	je	@f
	mov	dx,1				  ;flaga gdy button jest czescia innego
	@@:
	and	bh,not 11000000b		  ;usun modyfikatory
	call	calc_v_position 		  ;oblicz bh*160+bl do ecx
	shr	ebx,16				  ;przywroc z gornej polowy ebx
	add	ecx,BVideo+1			  ;ecx:adres miejsca, ktore ma miec zmieniony kolor
	@@:
	mov	[ecx],bl			  ;przenies kolor
	add	ecx,2				  ;do nastepnego punktu
	dec	bh				  ;czy ostatnia czesc buttona?
	jnz	@r
	add	esi,2				  ;do nastepnego buttona
	test	dx,dx				  ;czy button ma dalsza czesc?
	jnz	.button
	ret

show_num:
	mov	ebp,esp 			  ;zapisz stos
.num:
	mov	cx,ax
	and	cl,not 0f0h			  ;pobierz reszte z dzielenia numeru /16
	cmp	cl,9				  ;czy cyfry czy litery
	ja	.num_hex
	add	cl,'0'
	jmp	@f
.num_hex:
	sub	cl,10
	add	cl,'A'
	@@:
	push	cx				  ;zapisz digit numeru ascii
	shr	al,4
	test	al,al
	jne	.num				  ;i tak az do konca liczby
.show:
	pop	cx				  ;pobierz digit
	mov	[edi],cx			  ;i go wyswietl
	add	edi,2
	cmp	ebp,esp 			  ;sprawdz czy juz wszystkie
	jne	.show
	ret

show_text_DOS:
	;procedura wyswietla ciag znakow ASCIIZ z formatowaniem DOS
	;wymaga: ds:esi= adres textu do wyswietlenia ds:edi= adres video
	;bl=wspolrzedna X poczatku textu bh= wspolrzedna Y textu ah= kolor textu
	;zwraca:al=0 ds:edi+ecx=adres ostatniego wyswietlonego znaku

.mov_letter:
	mov	al,[esi]			  ;pobierz znak z bufora
	cmp	al,10				  ;sprawdz formatowanie
	je	.line_feed
	cmp	al,13
	je	.carriage_return
	cmp	al,09
	je	.tab
	test	al,al				  ;czy koniec textu
	je	.end
	call	calc_v_position 		  ;oblicz pozycje w ktorej ma byc wyswietlony text
	mov	[edi+ecx],ax			  ;wypisz litere
	inc	bl				  ;do nastepnej litery
	inc	esi				  ;do nastepnego znaku w buforze
	jmp	.mov_letter
.end:
	ret
.carriage_return:
	xor	bl,bl				  ;do poczatku linijki
	inc	esi				  ;do nastepnego znaku w buforze
	jmp	.mov_letter

.line_feed:
	inc	bh				  ;linijka w dol
	inc	esi				  ;do nastepnego znaku w buforze
	jmp	.mov_letter

.tab:
	mov	ax,0f20h			  ;kolor i znak spacji
	mov	dl,9				  ;tab=8 spacji
.tab_loop:
	call	calc_v_position 		  ;oblicz pozycje w buforze
	inc	bl				  ;o 1 w prawo
	mov	[edi+ecx],ax			  ;przenies spacje do bufora ekranu
	dec	dl				  ;czy juz wszystkie spacje?
	jnz	.tab_loop
	jmp	.mov_letter

;correct_position:
;        cmp     bl,80
;        jb      @f
;        xor     bl,bl
;        inc     bh
;        @@:
calc_v_position:
	;wymaga:bh: pozycja Y bl: pozycja X
	;zwraca:ecx=bh*160+bl*2
	push	ax bx				  ;zachowaj rejestry
	mov	al,160
	mul	bh				  ;ax=bl*160
	xor	bh,bh				  ;bh=0
	shl	bx,1				  ;bl=bl*2
	add	ax,bx				  ;ax=bh*160+bl*2
	movzx	ecx,ax				  ;wynik do ecx
	pop	bx ax				  ;przywroc rejestry
	ret

π equ 86h	;wstawiam kodowanie Mazovia
Ê equ 8dh
• equ 8fh
  equ 90h
Í equ 91h
≥ equ 92h
∆ equ 95h
å equ 98h
£ equ 9ch
ú equ 9eh
è equ 0a0h
Ø equ 0a1h
Û equ 0a2h
” equ 0a3h
Ò equ 0a4h
— equ 0a5h
ü equ 0a6h
ø equ 0a7h

FFontName:	db 'game.fnt',0
TProgramTitle:	db 'GreenT Text Game Interpreter Font Editor v 0.9.5.',0
TMessage:	db 'Wybierz znak, kt',Û,'ry chcesz zmieni',Ê,'[Enter]:',0
TMenu:		db 'Zapisz[F1] Wyczy',ú,Ê,'[F2] Zalecane[F3] Z pliku[F4] Autor[F5] Pomoc[F6] Wyj',ú,'cie[Esc]',0
TFont:		db '             Anuluj [Esc]        Zatwierd',ü,' [F1]        Usu',Ò,' [F2]',0
THelp:		db '[Pomoc]',10,13,10,10
		db '1.G',≥,Û,'wny ekran:',10,13
		db 'Na g',≥,Û,'wnym ekranie dost',Í,'pne s',π,' nast',Í,'puj',π,'ce funkcje:',10,13
		db '-Funkcja "Zapisz" zapisuje tabel',Í,' czcionek do pliku "game.fnt".',10,13
		db '-Funkcja "Wyczy',ú,Ê,'" usuwa wszystkie edytowane znaki z tabeli.',10,13
		db '-Funkcja "Zalecane" ',≥,'aduje do tabeli zalecane czcionki',10,13
		db '-Funkcja "Autor" wyswietla zasady licencji i ksywk',Í,' autora programu.',10,13
		db '-Funkcja "Pomoc" wyswietla ten ekran',10,13
		db 'Z do',≥,'u g',≥,Û,'wnego ekranu znajduje siÍ tabela z fontami.',10,13
		db 'Kursorami i [Enter] mo',ø,'na wybra',Ê,' znak, kt',Û,'ry chce si',Í,' edytowa',Ê,'.',10,13,10
		db '2.Ekran edycji:',10,13
		db '-Na ekranie edycji dost',Í,'pne s',π,' nast',Í,'puj',π,'ce funkcje:',10,13
		db '-Funkcja "Anuluj" przechodzi go g',≥,Û,'wnego ekranu nie zachowuj',π,'c zmian',10,13
		db '-Funkcja "Zatwierd',ü,'" przechodzi do g',≥,Û,'wnego ekranu zachowuj',π,'c zmieniony znak',10,13
		db '-Funkcja "Usu',Ò,'" przywraca domy',ú,'lny znak',10,13
		db 'Na ekranie edycji mo',ø,'na zaprojektowaÊ znak u',ø,'ywajπc kursorÛw i [Enter]',10,13,10
		db '3.Uwaga!',10,13
		db '-Numery znak',Û,'w podawane s',π,' w systemie szestnastkowym.',10,13
		db '-Program u',ø,'ywa kodowania Mazovia.',10,13
		db '-Z "game.fnt" korzystaj',π,' tylko GreenT Engine i do',≥,π,'czone do niego narz',Í,'dzia!!!',0

TAuthor:
		db '[Autor]',10,13,13,13
		db 'Autorem programu jest ??? <???@wp.pl>.',10,13
		db 'Autor jest cz',≥,'onkiem Green Grass Studio(c)2007.',10,13
		db 'GreenT Text Game Interpreter Font Editor jest cz',Í,ú,'ci',π,' pakietu GreenT Tools.',10,13
		db 'GreenT Text Game Interpreter(c) oraz GreenT Tools(c) s',π,' rozpowszechniane na' ,10,13,'licencji freeware. '
		db 'Oznacza to, ',ø,'e program ten mo',ø,'na dowolnie kopiowa',Ê,' pod ',10,13,'warunkiem, ',ø,'e nie b',Í,'dzie modyfikowany. '
		db 'Autor programu ani Green Grass Studio nie',10,13
		db 'ponosz',π,' odpowiedzialno',ú,'ci za wszelkie skutki korzystania z programu.',0
FontEditor:		   db	   0dbh,0dfh,0dbh,0ddh,020h,0deh,0dbh,0dch,0dbh
FONTS:
NewFontUp		   db	   30,0,0,0,18h,3ch,7eh,0ffh,0ffh
NewFontDn		   db	   31,0ffh,0ffh,7eh,3ch,18h,0,0,0
NewFontPLa		   db	   π,0h,0h,78h,0ch,07ch,0cch,7eh,0ch
NewFontPLc		   db	   Ê,8h,10h,78h,0cch,0c0h,0cch,78h,0
NewFontPLA		   db	   •,30h,78h,0cch,0cch,0fch,0cch,0cch,6
NewFontPLE		   db	    ,0feh,062h,68h,078h,068h,062h,0fch,06h
NewFontPLe		   db	   Í,0,0h,78h,0cch,0fch,0c0h,78h,0ch
NewFontPLl		   db	   ≥,70h,30h,30h,38h,70h,30h,78h,0h
NewFontPLC		   db	   ∆,04,3ch,56h,0c0h,0c0h,066h,3ch,0
NewFontPLS		   db	   å,8h,78h,0d4h,070h,038h,08ch,078h,0
NewFontPLL		   db	   £,0f0h,60h,60h,70h,0e2h,066h,0feh,0h
NewFontPLs		   db	   ú,8h,10h,7ch,0c0h,078h,0ch,0f8h,0
NewFontPLZ		   db	   è,10h,0feh,0ach,098h,032h,066h,0feh,0
NewFontPLZ2		   db	   Ø,0feh,0c6h,8ch,07ch,032h,066h,0feh,0
NewFontPLo		   db	   Û,8h,10h,78h,0cch,0cch,0cch,78h,0h
NewFontPLO		   db	   ”,08h,38h,06ch,0c6h,0c6h,06ch,38h,0
NewFontPLn		   db	   Ò,10h,20h,0f0h,0d8h,0d8h,0d8h,0d8h,0h
NewFontPLN		   db	   —,8h,0d6h,0e6h,0f6h,0deh,0ceh,0c6h,0h
NewFontPLz		   db	   ü,8h,10h,0fch,098h,030h,064h,0fch,0
NewFontPLz2		   db	   ø,20h,0h,0fch,098h,030h,064h,0fch,0


SizeBuffer = 1+(80*50*2)+32h+28+(257*2)+(65*2)+4+4;rozmiar zmiennych niezainicjowanych
AFont  = BVideo+3270				;adres adres poczatku ramki fonta + 1
BUFFER:  rb  SizeBuffer
RMRegs=BUFFER+1 				;adres do struktury z rejestrami RM
virtual at BUFFER
	EndFontByte		db	?	;bajt zerowy, po ktorym procedura sprawdza koniec domyslnych fontow
	RMedi			dd	?
	RMesi			dd	?
	RMebp			dd	?
	RMreserved		dd	?
	RMebx			dd	?
	RMedx			dd	?
	RMecx			dd	?
	RMeax			dd	?
	RMflags 		dw	?
	RMes			dw	?	;segment zaalokowanej pamieci DOS
	RMds			dw	?
	RMfs			dw	?
	RMgs			dw	?
	RMip			dw	?
	RMcs			dw	?
	RMsp			dw	?
	RMss			dw	?
	AFonts			dd	?	;adres bloku zaalokowanego na fonty
	ActualFonts1		dd	?
	ActualFonts2		dd	?
	MenuPosition		dw	?	;pozycja menu
	AEditedFont		dd	?	;adres fonta edytowanego
	OldMenuPos		dw	?	;stara pozycja w menu, zawiera numer edytowanego fonta
	Font			db	?,?,?,?,?,?,?,?;bufor na edycje fonta
	ASCIIButtons:times 257*2 db	?	;bufor na buttony do glownego menu
	FontButtons: times 65*2 db	?	;bufor na buttony w menu edycji
	BVideo:   times 80*50*2 db	?	;bufor na ekran
end virtual

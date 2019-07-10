format mz
heap   200h
stack  100h
AFont  = BVideo+3270
;engine textowy w DPMI
include 'loader.inc'
segment _code  use32
code32:
	mov	ax, 0013h			      ;zmus windows do fullscreen
	cld
	int	10h

	mov	ecx,SizeBuffer
	mov	edi,BUFFER			      ;zeruj bufory
	call	zeroize_buffer

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

aloc_mem_for_fonts:
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
	mov	edi,[AFonts]
	call	zeroize_buffer


	mov	edx,FFontName			      ;otworz plik z fontami
	mov	ax,3d00h			     ;tylko do odczytu
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
	xor	edx,edx 			      ;pobierz rozmiar pliku
	int	21h
	shl	edx,16
	mov	dx,ax				      ;rozmiar pliku do edx
	push	edx
	mov	ax,4200h			     ;przejdz na poczatek pliku
	xor	edx,edx
	xor	ecx,ecx
	int	21h

	pop	eax
	xor	edx,edx
	mov	ecx,9
	div	ecx				      ;eax/9= liczba fontow zapisanych w pliku
	mov	ebp,eax

	mov	edi,[AFonts]
	inc	ebp
.check_font:
	dec	ebp				      ;czy juz wszystkie fonty
	jz	.fonts_changed
	mov	edx,edi
	mov	ecx,1
	mov	ax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	movzx	eax,byte[edx]			     ;pobierz numer fonta
	lea	ecx,[eax*8+eax] 		     ;ecx=eax*9
	add	edx,ecx
	mov	[edx],al			     ;przenies numer fonta
	mov	ecx,8
	inc	edx
	mov	ax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	jmp	.check_font
.fonts_changed:
	mov	ax,3e00h
	mov	[edi],al			     ;zeruj bufor
	int	21h

menu_start:
	call	change_fonts			     ;zmien fonty
to_menu:
	xor	bx,bx
to_main_menu:
	push	bx
	call	reset_bvideo			     ;zeruj bufor video
	mov	esi,TProgramTitle
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS			     ;pokaz teksty

	mov	esi,TMenu
	mov	bx,500h
	call	show_text_DOS

	mov	esi,TMessage
	mov	bx,0b00h
	call	show_text_DOS
	pop	bx
main_menu:
	mov	[MenuPosition],bx
main_loop:
	mov	eax,0f00h			     ;ah, kolor znaku
	mov	edx,811h			     ;dx,kolor i znak <
	mov	edi,160*13+BVideo		     ;edi= index do bufora obrazu
.show_ascii:
	push	ax
	mov	[edi],ax			     ;pokaz ascii
	add	edi,2				     ;aktualizuj index
	mov	[edi],dx			     ;pokaz znak
	add	edi,2

	mov	ah,4
	call	show_num			     ;pokaz kod ascii znaku
	pop	ax
	mov	cx,1				     ;liczba spacji gdy liczba dwucyfrowa
	cmp	al,15
	ja	.show_space
	inc	cx				     ;liczba spacji gdy liczba jednocyfrowa
.show_space:
	push	ax
	shl	cx,1
	call	zeroize_buffer			     ;czy wszystkie spacje???
	pop	ax
	mov	bl,al
	inc	bl
	and	bl,1111b			     ;czy podzielne przez 16
	jnz	@f
	add	edi,160 			     ;przeskocz 1 linie
	@@:
	inc	al
	jnz	.show_ascii			     ;czy wszystkie znaki???

	mov	esi,ASCIIButtons		     ;ktory button aktywny?
	call	get_button
	call	show_buffer			     ;pokaz zawartosc bufora na ekranie

get_main_key:
get_mouse_buttons:
	mov	esi,ASCIIButtons
	mov	ebp,257
	call	check_keys

	cmp	ax,0ffh
	je	main_loop

	test	ax,ax
	je	get_main_key


	mov	edi,main_menu
	mov	bx,[MenuPosition]
	cmp	ah,4dh				    ;prawo
	jnz	@f
	inc	bx
	mov	cx,bx
	and	cx,1111b
	jnz	main_menu
	sub	bx,16
	jmp	edi

	@@:
	cmp	ah,4bh				   ;lewo
	jnz	@f
	dec	bx
	mov	cx,bx
	inc	cx
	and	cx,1111b
	jne	main_menu
	add	bx,16
	jmp	dword edi

	@@:
	cmp	ah,48h				  ;gora
	jnz	@f
	sub	bx,16
	cmp	bx,0
	jge	main_menu
	add	bx,256
	jmp	dword edi

	@@:
	cmp	ah,50h				  ;dol
	jnz	@f
	add	bx,16
	cmp	bx,256
	jb	main_menu
	sub	bx,256
	jmp	dword edi

	@@:
	cmp	ah,1h				  ;esc
	jz	ending

	cmp	ah,3bh				  ;f1-zapisz fonty do pliku
	jnz	@f

	mov	edx,FFontName			  ;utworz plik
	mov	eax,3c00h
	xor	ecx,ecx
	int	21h
	mov	ebx,eax
	mov	esi,[AFonts]			  ;adres fontow do esi
	xor	edi,edi
	mov	ecx,9
	sub	edi,ecx
.f1:
	add	edi,ecx
	mov	edx,esi
	add	edx,edi
	movzx	eax,byte[edx]			  ;pobierz numer fonta do eax
	cmp	edi,256*9			  ;czy wszystkie fonty?
	jne	.f11
	xor	ecx,ecx
	jmp	.f111
.f11:
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
	call	change_fonts
	jmp	get_main_key

	@@:
	cmp	ah,3dh				  ;f3- zaladuj domyslna tablice fontow
	jne	@f
	call	default_fonts
	call	change_fonts
	jmp	get_main_key

	@@:
	cmp	ah,3eh				  ;f4- czytaj z pliku
	je	read_from_file

	cmp	ah,3fh				  ;f5- autor
	jne	@f
	call	reset_bvideo			  ;czysc bufor
	mov	esi,TAuthor
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS			  ;pokaz tekst
	call	show_buffer			  ;wyswietl bufor
	push	to_menu
wait4key:
	call	check_keys			  ;sprawdz czy wcisnieto klawisz
	test	ax,ax
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
	call	wait4key			 ;czekaj na klawisz
	jmp	to_menu

	@@:
	cmp	ah,1ch				  ;enter
	jne	get_main_key
	movzx	ebp,[MenuPosition]		  ;ebp=stara pozycja w menu
	mov	esi,[AFonts]
	lea	eax,[ebp*8+ebp] 		  ;eax= ebp*8
	add	esi,eax
	mov	[OldMenuPos],bp
	mov	[AEditedFont],esi		  ;zapisz adres edytowanego fonta
	mov	ecx,8
	inc	esi
	mov	edi,Font
	call	strncpy 			  ;kopiuj edytowany font do bufora
font_reset:
	call	reset_bvideo			  ;czysc bufor video

show_sign:
	mov	ax,[OldMenuPos]
	mov	ah,4
	mov	bx,0fdch
	mov	cx,6
	mov	edi,(AFont-(240)*2)+2
@@:
	mov	[edi],bx
	add	edi,2
	dec	cx
	jnz	@r

	mov	edi,(AFont-(160)*2)+2
	inc	bl
	mov	[edi],bx
	add	edi,2
	mov	[edi],ax
	add	edi,4
	push	ax
	call	show_num
	pop	ax
	inc	bl
	cmp	al,15
	ja	@f
	add	edi,2
	@@:
	mov	[edi],bx

	mov	esi,TProgramTitle
	mov	edi,BVideo
	xor	bx,bx
	mov	ah,15
	call	show_text_DOS

	mov	esi,TFont
	mov	bx,500h
	call	show_text_DOS
	xor	bx,bx
font_redraw:
	mov	[MenuPosition],bx		  ;zapisz zmiane w pozycji pliku
font_edit:
	mov	esi,FontEditor
	mov	edi,BVideo+160*19+68
	mov	ah,15
	mov	dx,7

font_frame:
	mov	ebx,[esi]
	mov	[edi+1],ah
	mov	cx,8
	mov	[edi],bl
	shr	bx,8
	mov	bh,ah
	@@:
	add	edi,2
	mov	[edi],bx
	dec	cx
	jnz	@r
	add	edi,2
	shr	ebx,16
	mov	bh,ah
	mov	[edi],bx
	add	esi,3
	add	edi,160-18
	cmp	esi,FontEditor+6
	jne	@f
	test	dx,dx
	jz	@f
	dec	dl
	sub	esi,3
	@@:
	cmp	esi,FontEditor+9
	jne	font_frame

show_font:
	mov	ebx,dword[Font]
	mov	ecx,dword[Font+4]
	xor	esi,esi
	xor	edi,edi
	sub	esi,2
.mov_font:
	clc
	add	esi,2
	rcl	bl,1
	jnc	.mov_font
	test	bl,bl
	jz	.font
	mov	edx,edi
	mov	eax,-160
	inc	edx
@@:
	add	eax,160
	dec	edx
	jnz	 @r


	add	eax,esi
	mov	word[AFont+eax],0fdbh
	jmp	.mov_font
.font:
	xor	esi,esi
	sub	esi,2
	inc	edi
	shrd	ebx,ecx,8
	shr	ecx,8
	push	ebx
	or	ebx,ecx
	pop	ebx
	jnz	.mov_font

	mov	esi,FontButtons
	call	get_button
	call	show_buffer

get_edit_keys:
	mov	esi,FontButtons
	mov	ebp,65
	call	check_keys

	test	ax,ax
	je	get_edit_keys

	cmp	ax,0ffh
	je	font_edit

	mov	edi,font_redraw
	mov	bx,[MenuPosition]
	cmp	ah,4dh	      ;prawo
	jnz	@f
	inc	bx
	mov	cx,bx
	and	cx,111b
	jne	font_redraw
	sub	bx,8
	jmp	edi
	@@:
	cmp	ah,4bh	      ;lewo
	jnz	@f
	dec	bx
	mov	cx,bx
	and	cx,111b
	cmp	cx,7
	jne	font_redraw
	add	bx,8
	jmp	edi
	@@:
	cmp	ah,48h	      ;gora
	jnz	@f
	sub	bx,8
	cmp	bx,0
	jge	font_redraw
	add	bx,64
	jmp	edi
	@@:
	cmp	ah,50h	      ;dol
	jnz	@f
	add	bx,8
	cmp	bx,64
	jb	font_redraw
	sub	bx,64
	jmp	edi
	@@:

	cmp	ah,1h
	jnz	@f
	mov	bx,[OldMenuPos]
	jmp	to_main_menu
	@@:

	cmp	ah,3bh
	jnz	@f
	mov	ax,[OldMenuPos]
	mov	edi,[AEditedFont]
	mov	[edi],al
	inc	edi
	push	ax
	mov	esi,Font
	mov	ecx,8
	call	strncpy
	call	change_fonts
	pop	bx
	jmp	to_main_menu
	@@:
	cmp	ah,3ch
	jne	@f
	mov	edi,Font
	mov	ecx,8
	call	zeroize_buffer
	mov	edi,[AEditedFont]
	mov	ecx,9
	call	zeroize_buffer
	call	change_fonts
	mov	bx,[OldMenuPos]
	jmp	to_main_menu
	@@:
	cmp	ah,1ch
	jne	get_edit_keys
	mov	bx,[MenuPosition]
	movzx	ecx,bx
	shr	cx,3
	and	bx,111b

	mov	si,bx
	mov	ax,100000000b
	inc	bx
	@@:
	shr	ax,1
	dec	bx
	jnz	@r

	lea	edi,[Font]
	add	edi,ecx
	mov	dl,[edi]
	xor	dl,al
	mov	[edi],dl
	jmp	font_edit


ending:
	mov	ax, 0003h    ; tryb 3 (80x25x16)
	int	10h
Ending:
	mov	ax,4c00h
	int	21h

change_fonts:
	mov	esi,[AFonts]
	;zmienia fonty 8/8
	;ds:esi= adres struktury z fontami
	mov	ax,1112h			     ; funkcja wyboru generatora
	xor	bl,bl				     ; nr. generatora 0
	int	10h
	mov	[RMebp],0
	mov	[RMeax],1100h			     ;Generator znak¢w
	mov	[RMecx],1			     ;liczba znak¢w do zamiany
	mov	[RMedx],0			     ;adres,skad maja byc pobrane znaki
	mov	[RMebx],800h			     ;znak 8-bitowy do bloku 0
	xor	bp,bp
	dec	bp
.move_fonts:
	inc	bp
	cmp	bp,100h
	je	.no_fonts
	xor	edi,edi 			     ;index do pamieci dos
	movzx	bx,byte[esi]				 ;do bl numer fonta w matrycy
	add	esi,9
	test	bl,bl
	jnz	@f
	or	bx,bp
	jnz	.move_fonts
	@@:
	sub	esi,9
	add	esi,1				     ;esi=maska fonta
.fonts:
	mov	eax,[esi]
	mov	[gs:edi],eax
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
	mov	edi,0B8000h   ; segment pamieci obrazu
	mov	esi,BVideo
	mov	ecx,80*50/2
.get_screen:
	mov	eax,[esi]
	mov	[fs:edi],eax
	add	edi,4
	add	esi,4
	dec	ecx
	jnz	.get_screen
	ret

reset_bvideo:
	mov	edi,BVideo
	mov	ecx,80*50*2
zeroize_buffer:
	;zeruje bufor o podanym adresie i dlugosci
	;wymaga:es:edi= adres bufora do wyzerowania
	;ecx= liczba bajtow do wyzerowania
	;zwraca: eax=0 ecx=0 edx=ecx mod 4  edi=adres ostatniego bajtu bufora
	xor	eax,eax
	push	ecx
	shr	ecx,2
	rep	stosd
	pop	ecx
	and	ecx,11b
	rep	stosb
	ret

strncpy:
	;kopiuje ciag o podanej dlugosci z podanego adresu
	;wymaga:es:edi= adres docelowy ds:esi adres zrodlowy
	;ecx= liczba bajtow do przeniesienia
	;zwraca: eax=ostatni przenoszony bajt ecx=0 edx= ecx mod 4
	;edi = edi+ecx esi=esi+ecx
	mov	edx,ecx
	shr	ecx,2
	rep	movsd
	and	edx,11b
	mov	ecx,edx
	rep	movsb
	ret
check_keys:
	;sprawdza czy wcisnieto przycisk myszy, pozycje kursora i wcisniety klawisz
	;wymaga: ebp=rozmiar bufora na buttony+1 esi adres bufora buttonow gdy:ebp=0 nie sprawdza buttonow
	;zwraca: gdy wcisnieto klawisz: ah-skankod klawisza
	;gdy wcisnieto przycisk: ah=1ch
	;gdy kursor na buttonie ax=0ffh
	;gdy nic: ax=0
	test	ebp,ebp
	je	.no_mouse
	mov	ax,3h
	int	33h
	mov	ah,1ch
	test	bx,bx
	jnz	.enter
	shr	cx,3
	shr	dx,3
.get_position:
	dec	bp
	jz	.no_mouse
	mov	ch,[esi+1]
	mov	ax,[ebp*2+esi]
	and	ah,111111b
	cmp	dl,ah
	jne	.get_position
.pos_loop:
	cmp	al,cl
	je	.pos_good
	inc	al
	dec	ch
	jnz	.pos_loop
	jmp	.get_position
.pos_good:
	dec	ebp
	xor	ax,ax
	mov	[MenuPosition],bp
	dec	al
.enter:
	ret
.no_mouse:
	mov	ah,1
	int	16h
	jnz	.key_avalible
	xor	ax,ax
	ret
.key_avalible:
	xor	ah,ah
	int	16h
	ret

get_button:
	movzx	ecx,word[MenuPosition]
	mov	bx,word[esi]
	shl	ebx,16
	inc	ecx
.go_butt:
	add	esi,2
	mov	bx,[esi]
	test	bh,10000000b
	jz	.go_butt
	dec	ecx
	jnz	.go_butt
.button:
	mov	bx,[esi]
	xor	dx,dx
	test	bh,01000000b
	je	@f
	mov	dx,1
	@@:
	and	bh,not 11000000b
	call	calc_v_position
	shr	ebx,16
	add	ecx,BVideo+1
	@@:
	mov	[ecx],bl
	add	ecx,2
	dec	bh
	jnz	@r
	add	esi,2
	test	dx,dx
	jnz	.button
	ret

show_num:
	mov	ebp,esp 			     ;zapisz stos
.num:
	mov	cx,ax
	and	cl,not 0f0h			     ;pobierz reszte z dzielenia numeru /16
	cmp	cl,9				     ;czy cyfry czy litery
	ja	.num_hex
	add	cl,'0'
	jmp	@f
.num_hex:
	sub	cl,10
	add	cl,'A'
	@@:
	push	cx				     ;zapisz digit numeru ascii
	shr	al,4
	test	al,al
	jne	.num				     ;i tak az do konca liczby
.show:
	pop	cx				     ;pobierz digit
	mov	[edi],cx			     ;i go wyswietl
	add	edi,2
	cmp	ebp,esp 			     ;sprawdz czy juz wszystkie
	jne	.show
	ret

show_text_DOS:
	;procedura wyswietla ciag znakow ASCIIZ z formatowaniem DOS
	;wymaga: ds:esi= adres textu do wyswietlenia ds:edi= adres video
	;bl=wspolrzedna X poczatku textu bh= wspolrzedna Y textu ah= kolor textu
	;zwraca:al=0 ds:edi+ecx=adres ostatniego wyswietlonego znaku

.mov_letter:
	mov	al,[esi]
	cmp	al,10
	je	.line_feed
	cmp	al,13
	je	.carriage_return
	cmp	al,09
	je	.tab
	test	al,al
	je	.end
	call	calc_v_position
	mov	[edi+ecx],ax
	inc	bl
	inc	esi
	jmp	.mov_letter
.end:
	ret
.carriage_return:
	inc	bh
	inc	esi
	jmp	.mov_letter

.line_feed:
	xor	bl,bl
	inc	esi
	jmp	.mov_letter

.tab:
	mov	ax,0f20h
	mov	dl,9
.tab_loop:
	call	calc_v_position
	inc	bl
	mov	[edi+ecx],ax
	dec	dl
	jnz	.tab_loop
	jmp	.mov_letter


calc_v_position:
;correct_position:
;        cmp     bl,80
;        jb      @f
;        xor     bl,bl
;        inc     bh
;        @@:
	push	ax bx
	mov	al,160
	mul	bh
	xor	bh,bh
	shl	bx,1
	add	ax,bx
	movzx	ecx,ax
	pop	bx ax
	ret


FFontName:	db 'game.fnt',0
TProgramTitle:	db 'GreenT Text Game Interpreter Font Editor by Mi≥orzπb Z Brzuchaci≥. 2007',0
TMessage:	db 'Wybierz znak, ktÛry chcesz zmieniÊ [Enter]:',0
TMenu:		db 'Zapisz[F1] WyczyúÊ[F2] Zalecane[F3] Z pliku[F4] Autor[F5] Pomoc[F6] Wyjúcie[Esc]',0
TFont:		db '             Anuluj [Esc]        Zatwierdü [F1]        UsuÒ [F2]',0
THelp:		db '[Pomoc]',10,13,13,13
		db '1.G≥Ûwny ekran:',10,13
		db 'Na g≥ownym ekranie dostÍpne sπ nastÍpujπce funkcje:',10,13
		db '-Funkcja "Zapisz" zapisuje tabelÍ czcionek do pliku "game.fnt".',10,13
		db '-Funkcja "WyczyúÊ" usuwa wszystkie edytowane znaki z tabeli.',10,13
		db '-Funkcja "Zalecane" ≥aduje do tabeli zalecane czcionki',10,13
		db '-Funkcja "Autor" wyswietla zasady licencji i ksywkÍ autora programu.',10,13
		db '-Funkcja "Pomoc" wyswietla ten ekran',10,13
		db 'Z do≥u g≥Ûwnego ekranu znajduje siÍ tabela z fontami.',10,13
		db 'Kursorami i [Enter] moøna wybraÊ znak, ktÛry chce siÍ edytowaÊ.',10,13,13
		db '2.Ekran edycji:',10,13
		db '-Na ekranie edycji dostÍpne sπ nastÍpujπce funkcje:',10,13
		db '-Funkcja "Anuluj" przechodzi go g≥Ûwnego ekranu nie zachowujπc zmian',10,13
		db '-Funkcja "Zatwierz" przechodzi do g≥Ûwnego ekranu zachowujπc zmieniony znak',10,13
		db '-Funkcja "UsuÒ" przywraca domyúlny znak',10,13
		db 'Na ekranie edycji moøna zaprojektowaÊ znak uøywajπc kursorÛw i [Enter]',10,13,13
		db '3.Uwaga!',10,13
		db '-Bezpiecznie moøna zmieniaÊ znaki: 80-85,87-8C,8E,93,94,99,9A.',10,13
		db '-Zmiana innych znakÛw moøe powodowaÊ b≥Ídy.',10,13
		db '-Numery znakÛw podawane sπ w systemie szestnastkowym.',10,13
		db '-Program uøywa kodowania Mazovia.',10,13
		db '-Z "game.fnt" korzystajπ tylko GreenT Engine i do≥πczone do niego narzÍdzia!!!',0

TAuthor:
		db '[Autor]',10,13,13,13
		db 'Autorem programu jest Mi≥orzπb z Brzuchaci≥ <zbrzuchacil@wp.pl>.',10,13
		db 'Autor jest cz≥onkiem Green Grass Studio(c).',10,13
		db 'GreenT Text Game Interpreter Font Editor jest czÍúciπ pakietu GreenT Tools.',10,13
		db 'GreenT Text Game Interpreter(c) oraz GreenT Tools(c) sπ rozpowszechniane na' ,10,13,'licencji freeware. '
		db 'Oznacza to, øe program ten moøna dowolnie kopiowaÊ pod ',10,13,'warunkiem, øe nie bÍdzie modyfikowany. '
		db 'Autor programu ani Green Grass Studio nie',10,13
		db 'ponoszπ odpowiedzialnoúci za wszelkie skutki korzystania z programu.',0
FontEditor:		   db	   0dbh,0dfh,0dbh,0ddh,020h,0deh,0dbh,0dch,0dbh
FONTS:
NewFontUp		   db	   30,0,0,0,18h,3ch,7eh,0ffh,0ffh
NewFontDn		   db	   31,0ffh,0ffh,7eh,3ch,18h,0,0,0
NewFontPLS		   db	   'å',8h,78h,0d4h,070h,038h,08ch,078h,0	;8c
NewFontPLZ		   db	   'è',10h,0feh,0ach,098h,032h,066h,0feh,0	;8f
NewFontPLs		   db	   'ú',8h,10h,7ch,0c0h,078h,0ch,0f8h,0		;9c
NewFontPLz		   db	   'ü',8h,10h,0fch,098h,030h,064h,0fch,0	;9f
NewFontPLL		   db	   '£',0f0h,60h,60h,70h,0e2h,066h,0feh,0h	;a3
NewFontPLA		   db	   '•',30h,78h,0cch,0cch,0fch,0cch,0cch,6	;a5
NewFontPLZ2		   db	   'Ø',0feh,0c6h,8ch,07ch,032h,066h,0feh,0	;af
NewFontPLl		   db	   '≥',70h,30h,30h,38h,70h,30h,78h,0h		;b3
NewFontPLa		   db	   'π',0h,0h,78h,0ch,07ch,0cch,7eh,0ch		;b9
NewFontPLz2		   db	   'ø',20h,0h,0fch,098h,030h,064h,0fch,0	;bf
NewFontPLC		   db	   '∆',04,3ch,56h,0c0h,0c0h,066h,3ch,0		;c6
NewFontPLE		   db	   ' ',0feh,062h,68h,078h,068h,062h,0fch,06h	;ca
NewFontPLN		   db	   '—',8h,0d6h,0e6h,0f6h,0deh,0ceh,0c6h,0h	;dl
NewFontPLO		   db	   '”',08h,38h,06ch,0c6h,0c6h,06ch,38h,0	;d3                      08h,7ch,0e6h,0c6h,0c6h,0c6h,07ch,0
NewFontPLc		   db	   'Ê',8h,10h,78h,0cch,0c0h,0cch,78h,0		;e6
NewFontPLe		   db	   'Í',0,0h,78h,0cch,0fch,0c0h,78h,0ch		;ea
NewFontPLn		   db	   'Ò',10h,20h,0f0h,0d8h,0d8h,0d8h,0d8h,0h	;fl
NewFontPLo		   db	   'Û',8h,10h,78h,0cch,0cch,0cch,78h,0h 	;f3
SizeBuffer = 1+(80*50*2)+32h+32+(257*2)+(65*2)
BUFFER:  rb  SizeBuffer
RMRegs=BUFFER+1
virtual at BUFFER
	EndFontByte		db	?
	RMedi			dd	?
	RMesi			dd	?
	RMebp			dd	?
	RMreserved		dd	?
	RMebx			dd	?
	RMedx			dd	?
	RMecx			dd	?
	RMeax			dd	?
	RMflags 		dw	?
	RMes			dw	?
	RMds			dw	?
	RMfs			dw	?
	RMgs			dw	?
	RMip			dw	?
	RMcs			dw	?
	RMsp			dw	?
	RMss			dw	?
	AFonts			dd	?
	FileSize		dd	?
	FileHandle		dd	?
	AlocHandle		dd	?
	MenuPosition		dw	?
	AEditedFont		dd	?
	OldMenuPos		dw	?
	Font			db	?,?,?,?,?,?,?,?
	ASCIIButtons:times 257*2 db	?
	FontButtons: times 65*2 db	?
	BVideo:   times 80*50*2 db	?
end virtual

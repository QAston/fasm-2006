format mz
heap   1000h
stack  1000h
AFont  = BVideo+3270
;engine textowy w DPMI
include 'loader.inc'
segment _code  use32
code32:
	mov	ax, 0013h			      ;zmus windows do fullscreen
	int	10h

	mov	ecx,SizeBuffer
	mov	edi,BUFFER			      ;zeruj bufory
	call	zeroize_buffer

	mov	eax,100h			      ;alokuj pamiec dosa
	mov	ebx,1				      ;400h bajtow 40h paragrafow 1024 bajty
	int	31h				      ;do dx=selektor segmentu[PM] do ax=segment [RM]

	push	dx
	mov	[RMes],ax
	pop	gs				      ;trzeba jeszcze pozniej zwolnic!!!

	mov	ax, 0003h			      ; tryb 3 (80x25x16)
	int	10h

generate_ascii_buttons:
	mov	edi,ASCIIButtons
	mov	ax,04f0h
	mov	[edi],ax
	add	edi,2
	xor	ecx,ecx
.ascii_loop:
	mov	ebx,ecx
	and	bl,1111b
	lea	eax,[ebx*4+ebx]
	mov	ebx,ecx
	shr	ebx,4
	add	ebx,13
	or	ebx,10000000b
	mov	edx,ecx
	shr	edx,4
	add	ebx,edx
	mov	ah,bl
	mov	[edi+ecx*2],ax
	inc	cl
	jnz	.ascii_loop

generate_font_buttons:
	mov	edi,FontButtons
	mov	ax,111001111b
	mov	[edi],ax
	add	edi,2
	xor	ecx,ecx
.ascii_loop:
	mov	eax,ecx
	and	al,111b
	add	eax,35
	mov	ebx,ecx
	shr	ebx,3
	add	ebx,20
	or	ebx,10000000b
	mov	ah,bl
	mov	[edi+ecx*2],ax
	inc	cl
	cmp	cl,64
	jnz	.ascii_loop

aloc_mem_for_fonts:
	mov	eax,0501h
	mov	cx,900h
	xor	bx,bx
	int	31h
	mov	[AlocHandleSi],si
	mov	[AlocHandleDi],di
	shl	ebx,16				      ;oblicz adres pliku wzgledem ds
	mov	bx,cx
	mov	eax,_code
	shl	eax,4
	sub	ebx,eax
	mov	edx,ebx
	mov	[AFonts],edx

read_from_file:
	mov	edi,[AFonts]
	mov	ecx,900h
	call	zeroize_buffer

	mov	edx,FFontName			      ;otworz plik z fontami
	mov	eax,3d00h			      ;tylko do odczytu
	xor	ecx,ecx
	int	21h
	jnc	file_present

	push	to_main_menu
default_fonts:
	;przenosi standardowe fonty do zaalokowanego bufora
	mov	esi,FONTS
	mov	ebx,[AFonts]
	cld
.mov_font:
	mov	ecx,9
	movzx	eax,byte[esi]
	lea	edi,[eax*8+eax]
	add	edi,ebx
	rep	movsb
	cmp	al,[esi]
	jb	.mov_font
	ret

file_present:
	mov	ebx,eax
get_file_size:
	xor	ecx,ecx
	mov	eax,4202h
	xor	edx,edx 		    ;pobierz rozmiar pliku
	int	21h
	shl	edx,16
	mov	dx,ax
	push	edx
	xor	edx,edx
	mov	eax,4200h
	xor	ecx,ecx
	int	21h

	pop	eax
	xor	edx,edx
	mov	ecx,9
	div	ecx
	mov	ebp,eax

	mov	edi,[AFonts]

.check_font:
	test	ebp,ebp
	jz	.fonts_changed
	mov	edx,edi
	mov	ecx,1
	mov	eax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	movzx	eax,byte[edx]
	lea	ecx,[eax*8+eax]
	add	edx,ecx
	mov	[edx],al
	inc	edx
	mov	ecx,8
	mov	eax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	dec	ebp
	jmp	.check_font
.fonts_changed:
	mov	byte[edi],0
	mov	eax,3e00h
	int	21h

to_main_menu:
	mov	[MenuPosition],0
to_main_loop:
	mov	esi,[AFonts]			     ;do esi adres pamieci z fontami
	call	change_fonts

main_loop:
	call	reset_bvideo

	mov	esi,TProgramTitle
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS

	mov	esi,TMenu
	mov	bx,500h
	call	show_text_DOS

	mov	esi,TMessage
	mov	bx,0b00h
	call	show_text_DOS

	mov	eax,0f00h			     ;ah, kolor znaku
	mov	edx,811h			     ;dx,kolor i znak
	xor	ecx,ecx
	xor	ebx,ebx 			     ;bx, odstep
	;xor     edi,edi                              ;edi= index do bufora obrazu
	mov	 edi,160*13+BVideo
show_ascii:
	push	ax
	mov	[edi],ax			     ;pokaz ascii
	add	edi,2				     ;aktualizuj index
	mov	[edi],dx			     ;pokaz znak
	add	edi,2

	mov	ah,4
	call	show_num
	pop	ax
	mov	cx,1				     ;liczba spacji gdy liczba dwucyfrowa
	cmp	al,15
	ja	.show_space
	mov	cx,2				     ;liczba spacji gdy liczba jednocyfrowa
.show_space:
	xor	bx,bx
	mov	[edi],bx			     ;zrob odstep
	add	edi,2
	dec	cx
	jnz	.show_space			     ;czy wszystkie spacje???
	mov	bl,al
	and	bl,1111b
	cmp	bl,15
	jnz	@f
	add	edi,160
	@@:
	inc	al
	jnz	show_ascii			     ;czy wszystkie znaki???

	mov	esi,ASCIIButtons
	call	get_button
	call	show_buffer
	call	check_keys
	test	ax,ax
	jz	main_loop

	mov	bx,[MenuPosition]
	cmp	ah,4dh	      ;prawo
	jnz	@f
	inc	bx
	mov	cx,bx
	and	cx,1111b
	cmp	cx,0
	jne	@f
	sub	bx,16
	@@:
	cmp	ah,4bh	      ;lewo
	jnz	@f
	dec	bx
	mov	cx,bx
	and	cx,1111b
	cmp	cx,15
	jne	@f
	add	bx,16
	@@:
	cmp	ah,48h	      ;gora
	jnz	@f
	sub	bx,16
	cmp	bx,0
	jge	@f
	add	bx,256
	@@:
	cmp	ah,50h	      ;dol
	jnz	@f
	add	bx,16
	cmp	bx,256
	jb	@f
	sub	bx,256
	@@:
	mov	[MenuPosition],bx
	cmp	ah,1h	     ;dol
	jz	ending

;do poprawki
	cmp	ah,3bh	      ;f1
	jnz	pof1

	mov	edx,FFontName
	mov	eax,3c00h
	int	21h
	mov	ebx,eax
	mov	esi,[AFonts]
	xor	edi,edi
	sub	edi,9
	mov	ecx,9
f1:
	add	edi,9
	mov	edx,esi
	add	edx,edi
	movzx	eax,byte[edx]
	cmp	edi,256*9
	jne	f11
	xor	ecx,ecx
	jmp	@f
	f11:
	test	al,al
	jnz	@f
	test	edi,edi
	jne	f1
	xchg	edx,edi
	push	ecx edi
	repe	scasb
	pop	edi ecx
	xchg	edi,edx
	je	f1
	@@:
	mov	eax,4000h
	int	21h
	test	ecx,ecx
	jne	f1
	mov	eax,3e00h
	int	21h
	jmp	main_loop

;do poprawki

	pof1:
	cmp	ah,3ch
	jne	@f
	mov	edi,[AFonts]
	mov	ecx,900h
	call	zeroize_buffer
	jmp	to_main_loop

	@@:
	cmp	ah,3dh
	jne	@f
	call	default_fonts
	jmp	to_main_loop

	@@:
	cmp	ah,3eh
	je	read_from_file


	cmp	ah,3fh
	jne	@f
	call	reset_bvideo
	mov	esi,TAuthor
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS
	call	show_buffer
	xor	ax,ax
	int	16h
	jmp	main_loop

	@@:

	cmp	ah,40h
	jne	@f
	call	reset_bvideo
	mov	esi,THelp
	mov	edi,BVideo
	mov	ah,15
	xor	bx,bx
	call	show_text_DOS
	call	show_buffer
	xor	ax,ax
	int	16h
	jmp	main_loop

	@@:
	cmp	ah,1ch
	jne	main_loop

	movzx	ebp,[MenuPosition]
	mov	[OldMenuPos],bp
	mov	[MenuPosition],0
	mov	esi,[AFonts]
	mov	eax,9
	mul	ebp
	add	esi,eax
	mov	[AEditedFont],esi
	inc	esi
	mov	eax,[esi]
	mov	dword[Font],eax
	mov	eax,[esi+4]
	mov	dword[Font+4],eax
font_edit:
	call	reset_bvideo

	mov	esi,TProgramTitle
	mov	edi,BVideo
	xor	bx,bx
	mov	ah,15
	call	show_text_DOS

	mov	esi,TFont
	mov	bx,500h
	call	show_text_DOS

	mov	esi,FontEditor
	mov	edi,BVideo+160*19+68
	mov	ah,15
	MOV	DX,7

font_frame:
	mov	ebx,[esi]
	mov	[edi],bl
	mov	[edi+1],ah
	mov	cx,8
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
	jz	@F
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
	push	ebx ecx
	or	ebx,ecx
	pop	ecx ebx
	jnz	.mov_font

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
	mov	esi,FontButtons
	call	get_button
	call	show_buffer

	call	check_keys
	test	ax,ax
	jz	font_edit

	mov	bx,[MenuPosition]
	cmp	ah,4dh	      ;prawo
	jnz	@f
	inc	bx
	mov	cx,bx
	and	cx,111b
	cmp	cx,0
	jne	@f
	sub	bx,8
	@@:
	cmp	ah,4bh	      ;lewo
	jnz	@f
	dec	bx
	mov	cx,bx
	and	cx,111b
	cmp	cx,7
	jne	@f
	add	bx,8
	@@:
	cmp	ah,48h	      ;gora
	jnz	@f
	sub	bx,8
	cmp	bx,0
	jge	@f
	add	bx,64
	@@:
	cmp	ah,50h	      ;dol
	jnz	@f
	add	bx,8
	cmp	bx,64
	jb	@f
	sub	bx,64
	@@:

	cmp	ah,1h
	jnz	@f
	movzx	eax,[OldMenuPos]
	mov	[MenuPosition],ax
	jmp	to_main_loop
	@@:
	mov	[MenuPosition],bx
	cmp	ah,3bh
	jnz	@f

	mov	edi,[AEditedFont]
	movzx	eax,[OldMenuPos]
	mov	[MenuPosition],ax
	mov	[edi],al
	inc	edi
	mov	esi,Font
	mov	ecx,8
	call	strncpy
	jmp	to_main_loop
	@@:
	cmp	ah,3ch
	jne	@f
	mov	edi,Font
	mov	ecx,8
	call	zeroize_buffer
	mov	edi,[AEditedFont]
	mov	ecx,9
	call	zeroize_buffer
	@@:
	cmp	ah,1ch
	jne	font_edit
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
	mov	eax,502h
	mov	si,[AlocHandleSi]
	mov	di,[AlocHandleDi]
	int	31h
	mov	ax, 0003h    ; tryb 3 (80x25x16)
	int	10h
Ending:
	mov	ax,4c00h
	int	21h

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
	mov	edx,ecx
	shr	ecx,2
	rep	stosd
	and	edx,2
	mov	ecx,edx
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
	and	edx,2
	mov	ecx,edx
	rep	movsb
	ret

change_fonts:
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

check_keys:
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
TProgramTitle:	db 'GreenT Text Game Interpreter Font Editor by Mi≥orzπb Z Brzuchaci≥.',0
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
		db 'Autor programu ami Green Grass Studio nie',10,13,'ponoszπ odpowiedzialnoúci za wszelkie skutki korzystania z programu.',0
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
SizeBuffer = 1+(80*50*2)+32h+36+(257*2)+(65*2)
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
	AlocHandleSi		dw	?
	AlocHandleDi		dw	?
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

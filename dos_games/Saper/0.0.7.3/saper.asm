format mz
heap 100h
stack  100h
;engine textowy w DPMI
include 'loader.inc'
segment code_seg  use32

code_offs:
include 'fontuse.inc'
	mov	ah,01h
	mov	cx,0ffffh			     ;ukryj kursor
	int	10h

	mov	esi,code_seg
	shl	esi,4
	mov	[CodeSegmentBase],esi
	mov	edi,0B8000h
	sub	edi,esi
	mov	[GraphicCardAdress],edi

	xor	ah,ah				    ; do ah numer pierwszego koloru w palecie
	call	use_pal_colors

	call	set_16_pal
	mov	ax,1
	int	33h

	xor	bx,bx
	mov	edx,NazwaPliku
show_tfcg_file:

	;edx-adres nazwy pliku filmu
	;bx-pozycja na której ma byc wyswietlony
	;dd 0            ;do zwolnienia alokacji
	;dd 0            ;adres animacji[nalezy dodac 4!]
	;dd 0            ;uchwyt pliku
	;dd 0            ;wskaznik na bufor animacji
	;db 0            ;pozycja x
	;db 0            ;pozycja y
	;dd 0            ;signature

	;db 0            ;kolor domyslny
	;db 0            ;ustawienia
	;dd 0            ;liczba klatek do odczekania
	pozycja = 16
	uchwyt = 8
	rozmiar =28
	ffile = 18
	settings = 23
	push	bx;-zachowaj pozycje wyswietlenia
	mov	ax,3d00h			      ;tylko do odczytu
	xor	ecx,ecx
	int	21h
	pop	dx
	push	eax				      ;uchwyt pliku
;        jc      nofile                               ;jc to nie ma pliku
.file_present:
	mov	cx,rozmiar
	xor	bx,bx
	mov	ax,0501h			  ;alokuj pamiec na blok
	int	31h
	shl	ebx,16
	mov	bx,cx
	sub	ebx,[CodeSegmentBase]
	mov	[ebx],si
	mov	[ebx+2],di
	mov	[ebx+pozycja],dx
	mov	ebp,ebx
	mov	edx,ebp
	pop	ebx				  ;do ebx uchwyt do pliku
	mov	cx,6
	add	edx,ffile
	mov	ax,3f00h
	int	21h
	mov	al,[ds:ebp+settings]
	shl	eax,16
	test	eax,20000h
	jz	.changingfps
	add	edx,6
	mov	cx,4
	mov	ax,3f00h
	int	21h
	mov	[ds:ebp+uchwyt],ebx
.changingfps:
	mov	cx,6
	xor	bx,bx
	mov	ax,0501h
	int	31h
	mov	dx,bx
	shl	edx,16
	mov	dx,cx
	sub	edx,[CodeSegmentBase]
	mov	[edx],si
	mov	[edx+2],di
	mov	[ds:ebp+4],edx
.draw_loop:
	call	reset_bvideo
	mov	ebx,[ds:ebp+uchwyt]
	add	edx,4
	xor	esi,esi
	mov	cx,2
.check_loop:
	mov	ax,3f00h
	int	21h
	add	si,cx
	cmp	byte[edx],00
	jne	.check_loop	   ;sprawdzanie, czy koniec klatki
	cmp	byte[edx+1],7fh
	jne	.check_loop
	mov	[ds:ebp+uchwyt],ebx
	mov	cx,si
	push	ecx
	add	cx,4
	mov	esi,[ds:ebp+4]
	call	free_allocated_memory
	xor	bx,bx
	mov	ax,0501h
	int	31h
	mov	dx,bx
	shl	edx,16
	mov	dx,cx
	sub	edx,[CodeSegmentBase]
	mov	[edx],si
	mov	[edx+2],di
	add	edx,4
	mov	ebx,[ds:ebp+uchwyt]
	pop	ecx
	mov	ax,3f00h
	int	21h
	mov	esi,edx
	mov	edi,BVideo
	mov	bx,[ds:ebp+pozycja]

	mov	ah,[esi]
	inc	esi
.draw_line:
	mov	al,[esi]
	test	al,al
	je	.specjal_byte
.draw:
	call	calc_v_position
	mov	[edi+ecx],ax
	inc	bl
.predraw_line:
	inc	esi
	jmp	.draw_line
.line_done:
	inc	esi
	inc	bh
	mov	bl,[ds:ebp+pozycja]
	jmp	.draw_line
.specjal_byte:
	inc	esi
	mov	al,[esi]
	cmp	al,10000000b
	ja	.dup_sign
	cmp	al,124
	je	.film_end
	cmp	al,126
	je	.line_done
	cmp	al,127
	je	.animation_done
	cmp	al,125
	je	.change_color
	test	al,al
	je	.draw
	cmp	al,80
	jb	.go_right
	;error
.change_color:
	inc	esi
	mov	ah,[esi]
	jmp	.predraw_line
.dup_sign:
	and	al,1111111b
	inc	al
	inc	esi
	ror	ebx,16
	mov	bl,al
	mov	al,[esi]
.dup:
	dec	bl
	rol	ebx,16
	jnz	.predraw_line
	call	calc_v_position
	inc	bl
	mov	[edi+ecx],ax
	jmp	.dup
.go_right:
	add	bl,al
	jmp	.predraw_line
.animation_done:
	inc	esi
	call	show_buffer
	xor	esi,esi
.key_loop:
	mov	eax,1
	call	make_delay
	inc	esi
	cmp	esi,[ds:ebp+24]
	je	.draw_loop
	jmp	.key_loop

.film_end:
	jmp	ending


	push	bx esi edi
;        mov     ecx,animalocsize
	xor	ebx,ebx
	mov	ax,0501h
	int	31h
;       jc      error
	shl	ebx,16				      ;oblicz adres pliku wzgledem _code
	mov	eax,[CodeSegmentBase]
	mov	bx,cx
	sub	ebx,eax
	mov	[ebx+2],di
;        mov     ecx,animalocsize-4
	mov	edi,ebx
	add	edi,4
	mov	[ebx],si
	call	zeroize_buffer
	pop	edi
	mov	[edi],ebx
.inic_struct:
	mov	edx,ebx
	pop	esi
;        mov     [edx+animaddr],esi
	pop	bx
;        mov     [edx+position],bx
	ret


main_menu_loop:
	mov	[MenuPosition],0
	mov	[Timer],0
.draw:						;rysuj ekran
	mov	ax,2				;ukryj kursor na czas rysowania
	int	33h
	call	reset_bvideo			;czysc bufor ekranu

	mov	esi,MainMenu
	mov	edi,BVideo
	mov	bx,1600h
	mov	ah,15
	call	show_text_DOS
	mov	ebp,[AnimAlocHandle]
;        call    draw_comp_anim_frame            ;rysuj animacje

	mov	esi,MainMenuButtons
	call	show_button		   ;pokaz aktualny button
	call	show_buffer			;pokaz ekran
	mov	ax,1				;pokaz kursor
	int	33h
.key_loop:
	mov	eax,1
	call	make_delay
	inc	[Timer]
	cmp	[Timer],1000
	je	.redraw

	call	check_keys
	test	ax,ax
	jnz	.handle_keys

	mov	bp,4
	mov	esi,MainMenuButtons
	call	check_mouse_position
	cmp	[MenuPosition],bx
	je	.key_loop
	mov	[MenuPosition],bx
	jmp	.draw
.handle_keys:
	jmp	ending
	jmp	.key_loop

.redraw:					;gdy nastepna klatka animacji
	mov	[Timer],0
	mov	ebp,[AnimAlocHandle]
	call	update_comp_anim_frame
	jmp	.draw

ending:
	mov	ax, 0003h			;przywroc tryb graficzny
	int	10h
Ending:
	mov	ax,4c00h			;zamknij program
	int	21h

check_mouse_position:
	shr	cx,3
	shr	dx,3
	xor	ebx,ebx
	sub	esi,4
.get_position:
	cmp	bx,bp
	jz	.no_mouse
	add	esi,4
	movzx	eax,word[esi]
	test	ah,10000000b
	jz	.get_position
	inc	bx
.continue:
	mov	dh,[esi+3]
	test	ah,01000000b
	jz	@f
	or	ebx,80000000h
	@@:					   ;czy wszystkie buttony
	mov	ch,dh				   ;pobierz dlugosc buttona
	and	ah,111111b			   ;usun smieci
	cmp	dl,ah				   ;czy rzedy takie same?
	jne	.check_next
.pos_loop:
	cmp	al,cl				   ;czy kolumny takie same?
	je	.pos_good
	inc	al				   ;jesli nie to zwieksz pozycje X buttona o 1
	dec	ch				   ;porownaj tyle razy ile wynosi dlugosc buttona
	jnz	.pos_loop
.check_next:
	test	ebx,80000000h
	jz	.get_position
	and	ebx,0ffffh
	add	esi,4
	movzx	eax,word[esi]
	jmp	.continue
.pos_good:					   ;gdy mysz na buttonie
	dec	bx
	ret
.no_mouse:
	mov	bx,[MenuPosition]
	ret

check_mouse_position_l_c:
	shr	cx,3
	shr	dx,3
	mov	dh,[esi+1]
	xor	ebx,ebx
.get_position:
	cmp	bx,bp
	jz	.no_mouse
	add	esi,2
	movzx	eax,word[esi]
	test	ah,10000000b
	jz	.get_position
	inc	bx
.continue:
	test	ah,01000000b
	jz	@f
	or	ebx,80000000h
	@@:					   ;czy wszystkie buttony
	mov	ch,dh				   ;pobierz dlugosc buttona
	and	ah,111111b			   ;usun smieci
	cmp	dl,ah				   ;czy rzedy takie same?
	jne	.check_next
.pos_loop:
	cmp	al,cl				   ;czy kolumny takie same?
	je	.pos_good
	inc	al				   ;jesli nie to zwieksz pozycje X buttona o 1
	dec	ch				   ;porownaj tyle razy ile wynosi dlugosc buttona
	jne	.pos_loop
.check_next:
	test	ebx,80000000h
	jz	.get_position
	xor	ebx,80000000h
	add	esi,2
	movzx	eax,word[esi]
	jmp	.continue
.pos_good:					   ;gdy mysz na buttonie
	dec	bx
	ret
.no_mouse:
	mov	bx,[MenuPosition]
	ret

show_button:
	movzx	ecx,word[MenuPosition]
	sub	esi,4
	inc	ecx
.go_butt:
	add	esi,4
	mov	ebx,[esi]
	test	bh,10000000b
	jz	.go_butt
	dec	ecx
	jnz	.go_butt
.button:
	mov	ebx,[esi]
	xor	cx,cx
	test	bh,01000000b
	je     @f
	mov	cx,1
	@@:
	and	bh,not 11000000b
	movzx	edi,bh
	mov	eax,160
	mul	edi
	movzx	edi,bl
	shl	edi,1
	add	edi,eax
	shr	ebx,16
	add	edi,BVideo
	@@:
	mov	[edi+1],bl
	add	edi,2
	dec	bh
	jnz	@r
	add	esi,4
	test	cx,cx
	jnz	.button
	ret

check_keys:
	;sprawdza czy wcisnieto przycisk myszy, wcisniety klawisz
	;zwraca: gdy wcisnieto klawisz: ah-skankod klawisza
	;gdy wcisnieto przycisk: al=0ffh  ah=status przyciskow
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
	test	bx,bx				   ;czy wcisnieto przycisk myszy
	jnz	.m_b_pressed			   ;gdy wcisnieto przycisk to symuluj enter
	xor	ax,ax
	ret
.m_b_pressed:
	shr	dx,3
	shr	cx,3				   ;cx-kolumna dx-rzad
	mov	al,0ffh
	mov	ah,bl
	ret

show_button_l_c:
	;zmienia kolor buttona o pozycji podanej w tablicy
	;wymaga:esi=adres tablicy:1bajt dlugosc 1bajt kolor ,XY,XY...
	;zwraca: dx=0 bh=0
	movzx	ecx,word[MenuPosition]		  ;pozycja menu do ecx
	movzx	eax,word[esi]			  ;bh:dlugosc bl:kolor
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
	mov	ebx,eax 			  ;przywroc z gornej polowy ebx
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

make_delay:
	mov  ebx, 6629
	mov  ecx, 100
	mul  ebx
	div  ecx
	mov  ecx, eax

	in   al, 61h
	and  al, 10h
	mov  ah, al
.delay_loop:
	in   al, 61h
	and  al, 10h
	cmp  al, ah
	je   .delay_loop
	mov  ah, al
	dec  ecx
	jnz  .delay_loop
	ret

show_buffer:
	;przenosi obraz z bufora do pamieci karty graficznej
	;wymaga: fs=0-based ds=data seg
	;zwraca: ecx=0 edi=0B8000h+160*50 esi=BVideo+160*50 ax=ostatni przeniesiony znak
	mov	edi,[GraphicCardAdress]   ; segment pami‘ci obrazu
	mov	esi,BVideo
	mov	ecx,80*50*2
	mov	dx,3dah 			    ;3dah=VGA feature control regirster
.wait_for_VR:
	in	al,dx
	test	al,8				   ;czy vr rozpoczeta?
	jnz	.wait_for_VR				 ;jesli nie to jeszcze raz
@@:
	in	al,dx
	test	al,8				   ;czy vr zakonczona?
	jz	@r				   ;jesli nie to sprawdz jeszcze raz
.get_screen:
	call	strncpy
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
	inc	esi
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

use_pal_colors:
	;przyporzadkowuje numery kolorow w trybie graficznym do palety kolorow VGA
	;wymaga: ah=numer koloru 0
	mov	dx, 03DAh
	in	al, dx	    ;przygotuj port do wpisywania do palety
	xor	cl,cl	    ; licznik rejestrow palety
	mov	dx,03C0h
.set_pal_reg:
	mov	al,cl
	out	dx,al	    ; wybierz rejestr
	mov	al,ah
	out	dx,al	    ; numer koloru z palety
	inc	ah
	inc	cl
	cmp	cl,16
	jne	.set_pal_reg
	mov	al,20h	    ; zatwierdz zmiany i wlacz wyswietlanie
	out	dx,al
	ret

set_16_pal:
	mov	esi,DefaultPalLette
	mov	ah,0
	mov	edx,16
set_pal:
	;ustawia palete VGA od koloru 0
	;wymaga: esi=adres palety ah=muner koloru obrzeza edx-liczba kolorow do zmiany
	lea	ecx,[edx*2+edx]       ; na kazdy kolor 3 bajty
	mov	dx, 03C8h

	xor	al, al
	out	dx, al		      ; wlacz wpisywanie palety
	inc	dx		      ; dx = 03C9h
.set_rgb:
	mov	al, [esi]
	shr	al, 2		      ; konwersja z 8 na 6 bitow
	out	dx, al		      ; wyslij skladowa koloru
	inc	si		      ; do nastepnego bajtu
	loop	.set_rgb

	mov	dx, 03DAh
	in	al, dx		      ; przelaczenie portu 03C0h w tryb indeksowy
	mov	dx, 03C0h
	mov	al, 11h
	out	dx, al		      ; wybierz rejestr OverScan
	mov	al, ah
	out	dx, al		      ; wpisz numer koloru obrzeza
	mov	al, 20h
	out	dx, al		      ; ustaw bit nr.5 - odblokuj wyswietlanie
	ret

update_comp_anim_frame:
;        mov     esi,[ds:ebp+animaddr]
;        mov     eax,[ds:ebp+actualframe]
	add	eax,1
;        cmp     eax,[esi+maxframe]
	je	.reset_frame
;        mov     [ds:ebp+actualframe],eax
;        mov     dl,byte[esi+settings]
;        mov     esi,[ds:ebp+lastaddr]
	cmp	byte[esi],1
	je	 .redraw
	ret
.reset_frame:
	xor	eax,eax
;        mov     dword[ds:ebp+actualframe],eax
;        mov     [ds:ebp+redrawframe],eax
	ret
.redraw:
;        mov     [ds:ebp+redrawaddr],esi
;        mov     eax,[ds:ebp+actualframe]
;        mov     dword[ds:ebp+redrawframe],eax
	ret



initialize_animation:
	;bx-pozycja
	;esi-adres animacji
	;edi-adres wskaŸnika na funkcjê
.aloc_mem_for_anim_struct:
	push	bx esi edi
;        mov     ecx,animalocsize
	xor	ebx,ebx
	mov	ax,0501h
	int	31h
;       jc      error
	shl	ebx,16				      ;oblicz adres pliku wzgledem _code
	mov	eax,[CodeSegmentBase]
	mov	bx,cx
	sub	ebx,eax
	mov	[ebx+2],di
;        mov     ecx,animalocsize-4
	mov	edi,ebx
	add	edi,4
	mov	[ebx],si
	call	zeroize_buffer
	pop	edi
	mov	[edi],ebx
.inic_struct:
	mov	edx,ebx
	pop	esi
;        mov     [edx+animaddr],esi
	pop	bx
;        mov     [edx+position],bx
	ret



free_allocated_memory:
	;esi-wskaŸnk na animacjê
	mov	di,[esi+2]
	mov	si,[esi]
	mov	ax,0502h
	int	31h
;       jc      error
	ret


AnimAlocHandle:  dd  0
;dd 0            ;do zwolnienia alokacji
;dd Animation    ;wskaznik na animacje
;dd 0            ;aktualna klatka na sekunde
;dd 0            ;wskaznik na redrawowan¹ klatkê
;dd 0            ;ostatnia redrawowana klatka
;db 0            ;pozycja x
;db 0            ;pozycja y

MainMenu:
db 09,09,09,09,'Nowa Gra',10,13
db 09,09,09,09,'Ustawienia',10,13
db 09,09,09,09,'Rekordy',10,13
db 09,09,09,09,'Wyj',œ,'cie',10,13
db 0

MainMenuButtons:
db     36,16h or 11000000b,4,4
db     41,16h or 00000000b,4,3
db     36,17h or 10000000b,4,10
db     36,18h or 10000000b,4,7
db     36,19h or 10000000b,4,7
;db 4,2
;db     36,16h or 11000000b
;db     41,16h or 00000000b
;db     36,17h or 10000000b
;db     36,18h or 10000000b
;db     36,19h or 10000000b
FontButtons:
Arrow:
db '=>',0
MenuPosition		dw	0
Timer			dd	0
CodeSegmentBase 	dd	0
GraphicCardAdress	dd	0

NazwaPliku	db 'anim.bin',0
FFontName:	db 'game.fnt',0
DefaultPalLette:   db	  0,0,0,  0,0,170,  0,170,0, 0,170,170, 170,0,0,   170,0,170, 170,85,0
		   db	  170,170,170, 85,85,85, 0,0,255, 0,255,0,   0,255,255, 255,0,0,   255,0,255
		   db	  255,255,0,   255,255,255


RMRegs: 	times 32h  db	   0
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
BVideo:  rb 80*50*2
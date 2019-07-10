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

main_menu_loop:
	mov	[MenuPosition],0
.redraw:
	mov	ax,2
	int	33h
	call	reset_bvideo
	mov	[Timer],0
	mov	esi,MainMenu
	mov	edi,BVideo
	mov	bx,0
	mov	ah,15
	call	show_text_DOS
	mov	ebp,AnimAlocMem
	call	draw_animation_frame
	call	show_buffer
	mov	ax,1
	int	33h
.key_loop:
	mov	eax,1
	call	make_delay
	inc	[Timer]
	cmp	[Timer],1000
	je	.redraw
	xor    ebp,ebp
	call   check_keys
	test	ax,ax
	je	.key_loop



;time_loop:

;


;        mov     [Timer],0




;        call    show_buffer
;        jmp     _loop



;         xor     ax,ax
;         int     16h
ending:
	mov	ax, 0003h			;przywroc tryb graficzny
	int	10h
Ending:
	mov	ax,4c00h			;zamknij program
	int	21h

check_keys:
	;sprawdza czy wcisnieto przycisk myszy, pozycje kursora i wcisniety klawisz
	;wymaga: ebp=rozmiar bufora na buttony+1 esi adres bufora buttonow gdy:ebp=0 nie sprawdza buttonow
	;zwraca: gdy wcisnieto klawisz: ah-skankod klawisza
	;gdy wcisnieto przycisk: al=0ffh  ah=status przyciskow
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
	test	bx,bx				   ;czy wcisnieto przycisk myszy
	jnz	.m_b_pressed			   ;gdy wcisnieto przycisk to symuluj enter
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
.m_b_pressed:
	mov	al,0ffh
	mov	ah,bl
;.delay:
;        mov     eax,1000
;        call    make_delay
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

¹ equ 86h					  ;kodowanie Mazovia
æ equ 8dh
¥ equ 8fh
Ê equ 90h
ê equ 91h
³ equ 92h
Æ equ 95h
Œ equ 98h
£ equ 9ch
œ equ 9eh
 equ 0a0h
¯ equ 0a1h
ó equ 0a2h
Ó equ 0a3h
ñ equ 0a4h
Ñ equ 0a5h
Ÿ equ 0a6h
¿ equ 0a7h

AnimAlocMem:
dd AnimPicture	  ;wskaznik na animacje
dd 0	;aktualna klatka na sekunde
db 78	;pozycja x
db 48	;pozycja y

AnimPicture:
db 2	;rozmiar x
db 2	;rozmiar y
dd 2	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 0	;zarezerwowany (ew. ilosc powtorzen czy nieskopnczonosc)
db "1",15,"2",15,"3",15,"4",15,"5",15,"6",15,"7",15,"8",15

draw_animation_frame:
	mov	edi,BVideo
	mov	esi,[ds:ebp]
	mov	bl,[ds:ebp+8]
	mov	bh,[ds:ebp+9]
	call	calc_v_position
	mov	edx,[ds:ebp+4]
	movzx	eax,word[esi]
	mul	ah
	shl	ax,1
	mul	edx
	add	edi,ecx
	mov	ecx,eax
	mov	ah,[esi+1]     ;ah-roz y
.next_line:
	test	ah,ah
	je	.animation_done
	mov	al,[esi]
.draw_line:
	test	al,al
	je	.line_done
	mov	dx,[esi+ecx+8]
	mov	[edi],dx
	add	ecx,2
	add	edi,2
	dec	al
	jmp	.draw_line
.line_done:
	movzx	edx,byte[esi+1]
	shl	edx,1
	add	edi,160
	sub	edi,edx
	dec	ah
	jmp	.next_line
.animation_done:
	xor	eax,eax
	mov	edx,[ds:ebp+4]
	inc	edx
	cmp	[esi+2],edx
	cmove	edx,eax
	mov	[ds:ebp+4],edx
	ret

MenuPosition		dw	0
Timer			dd	0
CodeSegmentBase 	dd	0
GraphicCardAdress	dd	0
FFontName:	db 'game.fnt',0
DefaultPalLette:   db	  0,0,0,  0,0,170,  0,170,0, 0,170,170, 170,0,0,   170,0,170, 170,85,0
	  db	 170,170,170, 85,85,85, 0,0,255, 0,255,0,   0,255,255, 255,0,0,   255,0,255
	  db	 255,255,0,   255,255,255
MainMenu:
db 'Nowa Gra',10,13
db 'Ustawienia',10,13
db 'Rekordy',10,13
db 'Wyj',œ,'cie',10,13
db 0
Arrow:
db '=>',0

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
format mz
stack  100h
;engine textowy w DPMI
include 'loader.inc'
segment code_seg  use32
code_offs:
include 'encoding.inc'
include 'fontuse.inc'

	mov	esi,code_seg
	shl	esi,4
	mov	[CodeSegmentBase],esi
	mov	edi,0B8000h
	sub	edi,esi
	mov	[GraphicCardAdress],edi

	xor	ah,ah				    ; do ah numer pierwszego koloru w palecie
	call	use_pal_colors

	mov	esi,DefaultPalette
	mov	ah,0
	mov	edx,16
	call	set_pal

	mov	bx,17h
	mov	cx,40h
	call	aloc_mem_block
	mov	[BVideo],edi			    ;alokuj pamiec na bufor wideo
	mov	bx,17h
	mov	cx,40h
	call	aloc_mem_block
	mov	[BVideo2],edi			    ;alokuj pamiec na 2gi bufor

	mov	edi,[BVideo2]			    ;adres bufora video2
	mov	ecx,80*50*2			    ;ilosc bajtow
	call	zeroize_buffer

	mov	ax,1				    ;pokaz kursor myszy
	int	33h

main_tui_loop:
	jmp	.draw
.main:
	mov	edi,[BVideo]			    ;adres bufora video
	mov	ecx,80*50*2			    ;ilosc bajtow
	call	zeroize_buffer			    ;czysc bufor ekranu
	mov	ah,1				    ;czy wcisnieto jakis klawisz?
	int	16h
	jz	.no_key
	add	[testvar],1
	xor	ah,ah
	int	16h
	.no_key:
	mov	edi,[BVideo]
	mov	ecx,[testvar]
	mov	ax,0686h
	cld
	rep	stosw

	;zapisanie do bufora

	mov	edi,[BVideo2]
	mov	esi,[BVideo]
	mov	ecx,1740h
	call	strncmp 			;czy trzeba cos narysowac?
	je	.main
.draw:						;rysuj ekran
	mov	eax,2				;ukryj kursor na czas rysowania
	int	33h

	mov	edi,[BVideo2]
	mov	esi,[BVideo]
	mov	ecx,1740h
	call	strncpy 			;czy trzeba cos narysowac?
	call	show_buffer			;pokaz ekran

	mov	eax,1				 ;pokaz kursor
	int	33h
	jmp	.main

;.wait4key:
;        xor     eax,eax
;        int     16h
exit:
	mov	edi,[BVideo2]
	call	free_mem_block
	mov	edi,[BVideo]
	call	free_mem_block
	mov	eax,3h
	int	10h
	mov	eax,4c00h			 ;zamknij program
	int	21h

show_buffer:
	;przenosi obraz z bufora do pamieci karty graficznej
	push	ecx edi esi eax edx
	mov	edi,[GraphicCardAdress] 	    ; segment pami‘ci obrazu
	mov	esi,[BVideo]
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
	pop	edx eax esi edi ecx
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


zeroize_buffer:
	;zeruje bufor o podanym adresie i dlugosci
	;wymaga:es:edi= adres bufora do wyzerowania
	;ecx= liczba bajtow do wyzerowania
	push	eax ecx edx edi
	xor	eax,eax 			    ;zeruj eax
	push	ecx				    ;zachowaj liczbe bajtow do zerowania
	shr	ecx,2				    ;podziel liczbe bajtow przez 4
	rep	stosd				    ;przenies eax do es:edi i zwieksz index o 4
	pop	ecx				    ;liczba bajtow mod 4
	and	ecx,11b 			    ;przenies reszte z dzielenia przez 4
	rep	stosb				    ;przenies al do es:edi i zwieksz index o 1
	pop	edi edx ecx eax
	ret

strncpy:
	;kopiuje ciag o podanej dlugosci z podanego adresu
	;wymaga:es:edi= adres docelowy ds:esi adres zrodlowy
	;ecx= liczba bajtow do przeniesienia
	push	eax ecx edi esi
	push	ecx				   ;zachwaj liczbe bajtow do przeniesienia
	shr	ecx,2				   ;liczba dwordow
	rep	movsd				   ;przenies ds:esi do es:edi i zwieksz index o 4
	pop	ecx
	and	ecx,11b 			   ;liczba bajtow mod 4
	rep	movsb				   ;przenies ds:esi do es:edi i zwieksz index o 1
	pop	esi edi ecx eax
	ret
strncmp:
	;porownuje ciag o podanej dlugosci z podanego adresu
	;wymaga ds:esi adres zrodlowy    wymaga:es:edi= adres docelowy
	;ecx= liczba bajtow do porownania
	push	eax ecx edi esi
	push	ecx					;zachwaj liczbe bajtow do przeniesienia
	and	ecx,11b 			   ;liczba bajtow mod 4
	jz	.dalej
	rep	cmpsb				   ;przenies ds:esi do es:edi i zwieksz index o 1
	.dalej:
	pop	ecx
	shr	ecx,2				   ;liczba dwordow
	rep	cmpsd				   ;przenies ds:esi do es:edi i zwieksz index o 4
	pop	esi edi ecx eax
	ret

aloc_mem_block:
	;wymaga:
	;bx:cx=rozmiar
	;zwraca:
	;edi=adres
	;edi-4=uchwyt si, edi-2 uchwyt di
	push	ebx eax esi ecx
	mov	ax,0501h
	int	31h
	shl	ebx,16
	mov	bx,cx
	mov	[ebx],si
	mov	[ebx+2],di
	pop	ecx esi eax
	mov	edi,ebx
	pop	ebx
	add	edi,4
	ret

free_mem_block:
	;wymaga:
	;edi=adres bloku pamieci do zwolnienia
	push	eax esi edi
	mov	eax,edi
	mov	di,[eax-2]
	mov	si,[eax-4]
	mov	ax,0502h
	int	31h
	pop	edi esi eax
	ret

hide_cursor:
	mov	ah,02h
	mov	bh,2			;ukryj kursor
	xor	edx,edx 		;kursor na pozycji 0,0 na 2 stronie
	int	10h
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

;DATA:
CodeSegmentBase 	dd	0
GraphicCardAdress	dd	0
DefaultPalette: 	db     0,0,0,  0,0,170,  0,170,0, 0,170,170, 170,0,0,	170,0,170, 170,85,0
			db     170,170,170, 85,85,85, 0,0,255, 0,255,0,   0,255,255, 255,0,0,	255,0,255
			db     255,255,0,   255,255,255
BVideo: 		dd     0
BVideo2:		dd     0
testvar 		dd     0

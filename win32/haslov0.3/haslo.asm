format mz
heap 100h
stack  100h
;engine textowy w DPMI
include 'loader.inc'
segment code_seg  use32

code_offs:

	mov	ax, 0003h			      ; tryb 3 (80x25x16)
	jmp	@f
	password db 7,'b'or 10000000b,'a'shl 1,'n'or 10000000b,'a'shl 1,'l'or 10000000b,'n'shl 1,'e'or 10000000b
	@@:
	int	10h

	mov	esi,code_seg
	shl	esi,4
	mov	[CodeSegmentBase],esi
	mov	edi,0B8000h
	sub	edi,esi
	mov	[GraphicCardAdress],edi

main_loop:
	call	reset_bvideo

	mov	ah,15
	mov	esi,tekst
	mov	edi,BVideo
	xor	bx,bx
	call	show_text_DOS
	call	show_buffer

	mov	esi,bufor
	call	read_key_DOS

	mov	esi,password
	mov	edi,BVideo
	mov	cl,[esi]
	mov	ch,cl
	inc	esi
.packed_procedure:
	mov	al,[esi]
	and	al,01111111b
	dec	cl
	jz	.end1
	mov	ah,[esi+1]
	shr	ah,1
	mov	[edi],ax
	dec	cl
	jz	.cont
	add	esi,2
	add	edi,2
	jmp	.packed_procedure
.end1:
	mov	[edi],al
.cont:
	mov	 edi,BVideo
	mov	 esi,bufor+3
.check_loop:
	mov	 al,[esi]
	dec	 ch
	cmp	 al,[edi]
	jne	 .false
	inc	 esi
	inc	 edi
	cmp	 byte[esi],0
	jne	 .check_loop
	test	 ch,ch
	jnz	 .false
.true:
	call	reset_bvideo
	mov	ah,15
	mov	esi,tekst2
	mov	edi,BVideo
	xor	bx,bx
	call	show_text_DOS
	call	show_buffer
	jmp	ending
.false:
	call	reset_bvideo
	mov	ah,15
	mov	esi,tekst3
	mov	edi,BVideo
	xor	bx,bx
	call	show_text_DOS
	call	show_buffer

ending:
	xor	ax,ax
	int	16h
Ending:
	mov	ax, 0003h			;przywroc tryb graficzny
	int	10h

	mov	ax,4c00h			;zamknij program
	int	21h

tekst db 'Podaj haslo:',0
tekst2 db 'Haslo poprawne!',0
tekst3 db 'Haslo niepoprawne!',0
bufor db 255,0,1
times 255 db 0


read_key_DOS:
	;esi-adres struktury
	mov	ah,3
	xor	bh,bh
	int	10h
	push	dx
	push	bx
	mov	cl,[esi]
	mov	edi,esi
	add	edi,3
	mov	ah,2
	mov	bh,0
	mov	dx,[esi+1]
	int	10h
	xor	ch,ch
.read_key:
	xor	ax,ax
	int	16h

	cmp	ah,0eh	;backspace
	jne	.nie_bckp
	test	ch,ch
	je	.read_key
	dec	ch
	dec	edi
	mov	byte[edi],0
	push	cx
	xor	bx,bx
	mov	AH,03h	 ;odczytaj kursor
	int	10h
	test	dl,dl
	jne	@f
	dec	dh
	mov	dl,80
	jmp	.go_back
	@@:
	dec	dl
.go_back:
	mov	ah,02h
	int	10h
	mov	al,' '
	mov	ah,09h
	mov	cx,1
	mov	bl,15
	int	10h
	pop	cx
	jmp	.read_key
.nie_bckp:
	cmp	ah,01h
	je	.string_end
	cmp	ah,1ch
	je	.string_end
	cmp	ch,cl
	jae	.read_key

	mov	ebp,not_modify_keys
	@@:
	cmp	ah, [ds:ebp]
	je	.read_key
	cmp	byte[ds:ebp],0
	je	@f
	inc	ebp
	jmp	@r
	@@:

	push	cx
	xor	bx,bx
	mov	AH,03h	 ;odczytaj kursor
	int	10h
	mov	[edi],al
	inc	edi
	mov	ah,09h
	mov	cx,1
	mov	bl,15
	int	10h

	cmp	dl,80
	jnb	@f
	inc	dl
	jmp	.zwieksz
	@@:
	inc	dh
	xor	dl,dl
.zwieksz:
	mov	ah,02h
	int	10h
	pop	cx
	inc	ch
	jmp	.read_key
.string_end:
	mov	byte[edi],0
	pop	bx
	pop	dx
	cmp	ah,01
	je	Ending
	mov	ah,2
	int	10h
	ret

not_modify_keys db 0fh,1dh, 2ah, 36h, 38h,3ah, 3bh, 3ch, 3dh, 3eh, 3fh, 40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h,48h, 49h,4ah, 4bh, 4ch, 4dh, 4eh, 4fh, 50h, 51h, 52h, 53h ,0



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
	mov	ecx,80*25*2			    ;ilosc bajtow
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


CodeSegmentBase 	dd	0
GraphicCardAdress	dd	0
BVideo:  rb 80*25*2


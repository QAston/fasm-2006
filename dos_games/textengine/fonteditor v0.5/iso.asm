format mz
heap   1000h
stack  1000h
;engine textowy w DPMI
include 'loader.inc'
segment _code  use32
code32:
	mov	ax, 0013h			      ;zmus windows do fullscreen
	int	10h

	mov	eax,100h			      ;alokuj pamiec dosa
	mov	ebx,1				      ;400h bajtow 40h paragrafow 1024 bajty
	int	31h				      ;do dx=selektor segmentu[PM] do ax=segment [RM]
	push	dx
	mov	[RMes],ax
	pop	gs				      ;trzeba jeszcze pozniej zwolnic!!!

	mov	ax, 0003h			      ; tryb 3 (80x25x16)
	int	10h

	mov	edx,FFontName			      ;otworz plik z fontami
	mov	eax,3d00h			      ;tylko do odczytu
	xor	ecx,ecx
	int	21h
	mov	ebx,eax
	jnc	file_present

	mov	esi,FONTS			       ;do esi adres pamieci z fontami
	call	change_fonts
file_loop:
	mov	esi,TNoFileMsg
	mov	edi,BVideo
	mov	ah,07h
	call	get_text
	mov	esi,NoFileButtons
	call	get_button
	call	show_buffer
	call	check_keys
	test	ax,ax
	jz	file_loop

	mov	bx,[MenuPosition]
	cmp	ah,4dh	      ;prawo
	jnz	@f
	cmp	bx,2
	jne	@f
	xor	bx,bx
	@@:
	cmp	ah,4bh	      ;lewo
	jnz	@f
	dec	bx
	cmp	bx,-1
	jne	@f
	mov	bx,1
	@@:
	mov	[MenuPosition],bx

	cmp	ah,1ch	      ;enter
	jnz	file_loop

	cmp	[MenuPosition],1
	je	file_created

	mov	edx,FFontName
	mov	eax,3c00h
	int	21h
	mov	ebx,eax
	mov	eax,3e00h
	int	21h
	jmp	file_created

file_present:

	call	get_file_size			      ;pobierz rozmiar pliku
	call	aloc_extended			      ;zaalokuj pamiec dla pliku

	shl	ebx,16				      ;oblicz adres pliku wzgledem ds
	mov	bx,cx
	mov	eax,_code
	shl	eax,4
	sub	ebx,eax
	mov	edx,ebx
	mov	ebx,[FileHandle]
	mov	ecx,[FileSize]
	mov	eax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h

	mov	esi,edx 			     ;do esi adres pamieci z fontami
	call	change_fonts

	mov	eax,502h
	mov	si,[AlocHandleSi]
	mov	di,[AlocHandleDi]
	int	31h

file_created:
	mov	[MenuPosition],0
main_loop:
	call	reset_buffer
			     ;domyslny scroll 30,177,219,31
	mov	esi,TProgramTitle
	mov	edi,BVideo
	mov	ah,15
	call	get_text

	mov	esi,TMessage
	mov	edi,BVideo+160*3
	mov	ah,15
	call	get_text

	mov	eax,0f00h			     ;ah, kolor znaku
	mov	edx,811h			     ;dx,kolor i znak
	xor	ecx,ecx
	xor	ebx,ebx 			     ;bx, odstep
	;xor     edi,edi                              ;edi= index do bufora obrazu
	mov	 edi,160*5
show_ascii:
	mov	[BVideo+edi],ax 		     ;pokaz ascii
	add	edi,2				     ;aktualizuj index
	mov	[BVideo+edi],dx 		     ;pokaz znak
	add	edi,2

	mov	ch,4				     ;do ch kolor numeru znaku ascii
	mov	bl,al				     ;do bl numer znaku ascii
	mov	ebp,esp 			     ;zapisz stos
.show_num:
	mov	cl,bl
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
	shr	bl,4
	test	bl,bl
	jne	.show_num			     ;i tak az do konca liczby
.show:
	pop	cx				     ;pobierz digit
	mov	[BVideo+edi],cx 		     ;i go wyswietl
	add	edi,2
	cmp	ebp,esp 			     ;sprawdz czy juz wszystkie
	jne	.show
	mov	cx,1				     ;liczba spacji gdy liczba dwucyfrowa
	cmp	al,15
	ja	.show_space
	mov	cx,2				     ;liczba spacji gdy liczba jednocyfrowa
.show_space:
	mov	[BVideo+edi],bx 		     ;zrob odstep
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
	cmp	ah,1h	     ;dol
	jz	ending
	mov	[MenuPosition],bx
	jmp	main_loop

ding:
	xor	ax,ax
	int	16h
ending:
	mov	ax, 0003h    ; tryb 3 (80x25x16)
	int	10h
Ending:
	mov	ax,4c00h
	int	21h

show_buffer:
	;przenosi obraz z bufora do pamieci karty graficznej
	;wymaga: fs=0-based ds=data seg
	;zwraca: ecx=0 edi=0B8000h+160*50 esi=BVideo+160*50 ax=ostatni przeniesiony znak
	mov	edi,0B8000h   ; segment pamiëci obrazu
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

reset_buffer:
	mov	edi,BVideo
	mov	ecx,80*50/2
	xor	eax,eax
	repz	stosd
	ret

FFontName	db 'game.fnt',0
AlocHandleSi	dw 0
AlocHandleDi	dw 0
FileSize	dd 0
FileHandle	dd 0
AlocHandle	dd 0
MenuPosition	dw 0
TNoFileMsg	db 'Plik "game.fnt" nie zostaí odnaleziony! Czy chcesz go utworzyç? Tak/Nie',0
TProgramTitle	db 'GreenT Text Game Interpreter Font Editor by MiíorzÜb Z Brzuchacií.',0
TMessage	db '±ÊÍ≥ÒÛ∂øº°∆ —”¶Ø¨',0
TMenu:		db 'Zapisz[F1] Wyczysc[F2] Standardowe[F3] Autor [F4] Pomoc [F5] Wyjscie [Esc]',0
struc butt lenght,color ,x,y
{
.lenght db lenght
.color db color
.x db x
.y db y
}
NoFileButtons:
.ButtTak		    butt     64,10000000b,4,3
.ButtNie		    butt     68,10000000b,4,3
ASCIIButtons:
A=0
repeat	256

db ((%-1) mod 16)*5,((%-1)/16+5)or 10000000b+(%-1)/16,0f0h,4
end repeat
FONTS:
NewFontPLS		   db	   '¶',8h,78h,0d4h,070h,038h,08ch,078h,0	;8c
NewFontPLZ		   db	   '¨',10h,0feh,0ach,098h,032h,066h,0feh,0	;8f
NewFontPLs		   db	   '∂',8h,10h,7ch,0c0h,078h,0ch,0f8h,0		;9c
NewFontPLz		   db	   'º',8h,10h,0fch,098h,030h,064h,0fch,0	;9f
NewFontPLL		   db	   '£',0f0h,60h,60h,70h,0e2h,066h,0feh,0h	;a3
NewFontPLA		   db	   '°',30h,78h,0cch,0cch,0fch,0cch,0cch,6	;a5
NewFontPLZ2		   db	   'Ø',0feh,0c6h,8ch,07ch,032h,066h,0feh,0	;af
NewFontPLl		   db	   '≥',70h,30h,30h,38h,70h,30h,78h,0h		;b3
NewFontPLa		   db	   '±',0h,0h,78h,0ch,07ch,0cch,7eh,0ch		;b9
NewFontPLz2		   db	   'ø',20h,0h,0fch,098h,030h,064h,0fch,0	;bf
NewFontPLC		   db	   '∆',04,3ch,56h,0c0h,0c0h,066h,3ch,0		;c6
NewFontPLE		   db	   ' ',0feh,062h,68h,078h,068h,062h,0fch,06h	;ca
NewFontPLN		   db	   '—',8h,0d6h,0e6h,0f6h,0deh,0ceh,0c6h,0h	;dl
NewFontPLO		   db	   '”',08h,38h,06ch,0c6h,0c6h,06ch,38h,0	;d3                      08h,7ch,0e6h,0c6h,0c6h,0c6h,07ch,0
NewFontPLc		   db	   'Ê',8h,10h,78h,0cch,0c0h,0cch,78h,0		;e6
NewFontPLe		   db	   'Í',0,0h,78h,0cch,0fch,0c0h,78h,0ch		;ea
NewFontPLn		   db	   'Ò',10h,20h,0f0h,0d8h,0d8h,0d8h,0d8h,0h	;fl
NewFontPLo		   db	   'Û',8h,10h,78h,0cch,0cch,0cch,78h,0h 	;f3

			   db	   0

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

change_fonts:
	mov	ax,1112h			     ; funkcja wyboru generatora
	xor	bl,bl				     ; nr. generatora 0
	int	10h				     ;zmiana na 80x50
	mov	[RMebp],0
	mov	[RMeax],1100h			     ;Generator znak¢w
	mov	[RMecx],1			     ;liczba znak¢w do zamiany
	mov	[RMedx],0			     ;adres,skad maja byc pobrane znaki
	mov	[RMebx],800h			     ;znak 8-bitowy do bloku 0
.move_fonts:
	xor	edi,edi 			     ;index do pamieci dos
	mov	bl,[esi]			     ;do bl numer fonta w matrycy
	add	esi,1				     ;esi=maska fonta
.fonts:
	mov	eax,[esi]
	mov	[gs:edi],eax			     ;podaj numer fonta
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
	cmp	byte[esi],0
	jne	.move_fonts			     ;tak wszystkie fonty
	mov	ah,01h
	mov	cx,0ffffh    ;ukryj kursor
	int	10h
	ret
get_file_size:
	xor	ecx,ecx
	mov	eax,4202h
	xor	edx,edx 		    ;pobierz rozmiar pliku
	int	21h
	pop	ebp
	push	dx
	push	ax
	push	ebp
	shl	edx,16
	mov	dx,ax
	push	edx

	xor	edx,edx
	mov	eax,4200h
	xor	ecx,ecx
	int	21h

	pop	ecx
	mov	[FileSize],ecx
	mov	[FileHandle],ebx
	ret

aloc_extended:
	mov	eax,0501h
	pop	ebp
	pop	cx
	pop	bx
	push	ebp
	add	cx,1024*7
	jnc	@f
	inc	bx
@@:
	int	31h
	mov	[AlocHandleSi],si
	mov	[AlocHandleDi],di
	ret


get_text:
	;przenosi do bufora kolorowy ciag znakow zakonczony zerem[wyswietlone]
	;wymaga:esi,adres tekstu  edi:adres bufora  ah:ustawienie wyswietlania ds=data segment
	;zwraca: al=0 ah=ustawienie wyswietlania edi=adres nastepnego znaku po zerze esi=dlugosc tekstu wraz z 0 plus 1
.move_text:
	mov	al,[esi]
	mov	[edi],ax
	add	edi,2
	inc	esi
	test	al,al
	jnz	.move_text
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


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
	push	eax
	jnc	file_present
	pop	eax
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
	inc	bx
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
	je	to_main_menu

	call	create_file

	jmp	to_main_menu

file_present:

	mov	eax,0501h
	mov	cx,9f8h
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
	mov	esi,edx
	mov	ecx,574
	call	clean_buffer
	pop	ebx
	add	edx,9
	xor	ebp,ebp
.check_font:
	mov	ecx,1
	inc	ebp
	mov	eax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	movzx	eax,byte[edx]
	cmp	al,0ffh
	je	.fonts_changed
	cmp	eax,ebp
	je	@f
	mov	byte[edx],0
	add	edx,9
	push	edx
	mov	ecx,-1
	mov	edx,-1
	mov	eax,4201h
	int	21h
	pop	edx
	jmp	.check_font
	@@:
	inc	edx
	mov	ecx,8
	mov	eax,3f00h			     ;czytaj z pliku do zaalokowanego bloku pamieci
	int	21h
	add	edx,8
	jmp	.check_font
.fonts_changed:
	mov	eax,3e00h
	int	21h

to_main_menu:
	mov	[MenuPosition],0
to_main_loop:
	mov	esi,[AFonts]			     ;do esi adres pamieci z fontami

	call	change_fonts

main_loop:
	call	reset_buffer
	mov	esi,TProgramTitle
	mov	edi,BVideo
	mov	ah,15
	call	get_text

	mov	esi,TMenu
	mov	edi,BVideo + 160*5
	mov	ah,15
	call	get_text

	mov	esi,TMessage
	mov	edi,BVideo+160*11
	mov	ah,15
	call	get_text

	mov	eax,0f00h			     ;ah, kolor znaku
	mov	edx,811h			     ;dx,kolor i znak
	xor	ecx,ecx
	xor	ebx,ebx 			     ;bx, odstep
	;xor     edi,edi                              ;edi= index do bufora obrazu
	mov	 edi,160*13
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
	cmp	ah,1ch
	jne	main_loop

	cmp	[MenuPosition],0
	je	to_main_loop
	cmp	[MenuPosition],0ffh
	je	to_main_loop
	movzx	ebp,[MenuPosition]
	mov	[OldMenuPos],bp
	mov	[MenuPosition],0
	mov	esi,[AFonts]
	mov	eax,9
	mul	ebp
	add	esi,eax
	push	esi
	inc	esi
	mov	eax,[esi]
	mov	dword[Font],eax
	mov	eax,[esi+4]
	mov	dword[Font+4],eax
font_edit:
	call	reset_buffer

	mov	esi,TProgramTitle
	mov	edi,BVideo
	mov	ah,15
	call	get_text

	mov	esi,TFont
	mov	edi,BVideo + 160*5
	mov	ah,15
	call	get_text

	mov	esi,FontEditor
	mov	edi,BVideo+160*19+68
	mov	ah,15
	MOV	DX,7
font_frame:
	mov	ebx,[esi]
	mov	[edi],bl
	mov	[edi+1],ah
	shr	bx,8
	mov	bh,ah
	mov	cx,8
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
	cmp	esi,FontEditor+12
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

	cmp	ah,3bh
	jnz	@f

	pop	esi
	movzx	 eax,[OldMenuPos]
	mov	[esi],al
	inc	esi
	mov	eax,dword[Font]
	mov	[esi],eax
	add	esi,4
	mov	eax,dword[Font+4]
	mov	[esi],eax

	jmp	to_main_loop
	@@:
	mov	[MenuPosition],bx
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
	;edi= adres bufora do wyzerowania
	;ecx= liczba dwordow do wyzerowania
clean_buffer:
	xor	eax,eax
	repz	stosd
	ret

FFontName	db 'game.fnt',0
AlocHandleSi	dw 0
AlocHandleDi	dw 0
AFonts		dd 0
FileSize	dd 0
FileHandle	dd 0
AlocHandle	dd 0
MenuPosition	dw 0
TNoFileMsg	db 'Plik "game.fnt" nie zosta≥ odnaleziony! Czy chcesz go utworzyÊ? Tak/Nie',0
TProgramTitle	db 'GreenT Text Game Interpreter Font Editor by Mi≥orzπb Z Brzuchaci≥.',0
TMessage	db 'Wybierz znak, ktÛry chcesz zmieniÊ [Enter]:',0
TMenu:		db 'Zapisz [F1] WyczyúÊ [F2] Standardowe [F3] Autor [F4] Pomoc [F5] Wyjúcie [Esc]',0
TFont:		db '                  Anuluj [Esc]                  Zatwierdü [F1]',0
OldMenuPos	dw 0
Font		db 0,0,0,0,0,0,0,0
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
db ((%-1) mod 16)*5,((%-1)/16+13)or 10000000b+(%-1)/16,0f0h,4
end repeat
FontButtons:
repeat 64
db ((%-1) mod 8)+35,(((%-1)/8)+20)or 10000000b,011001111b,1
end repeat
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
EndFontFile:		   db	   0ffh
FontEditor:		   db	   0dbh,0dfh,0dbh,0ddh,020h,0deh,0dbh,0dch,0dbh



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
	add	esi,9
	test	bl,bl
	jz	.move_fonts
	sub	esi,9
	cmp	bl,0ffh
	je	.no_fonts
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
	mov	cx,0ffffh    ;ukryj kursor
	int	10h
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

create_file:
	mov	edx,FFontName
	mov	eax,3c00h
	int	21h
	mov	ebx,eax
	mov	edx,EndFontFile
	mov	ecx,1
	mov	eax,4000h
	int	21h
	mov	eax,3e00h
	int	21h
	ret

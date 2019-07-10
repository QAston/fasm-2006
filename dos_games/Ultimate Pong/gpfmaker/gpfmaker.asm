format MZ

include 'loader.inc'
;fs= 0-based segment ;ds=es-data segnt cs=code segment gs=wolny
segment _code  use32

code32:
	      mov	eax,0900h	    ;wypisz komunikat
	      lea	edx,[TMessage]	;zaladuj adres do dx
	      int	21h		 ;przerwanie dosa

	      mov	edx,FileName	     ;adres bufora na nazwe
	      mov	byte[edx],253

pobierz_nazwe:
	      mov	eax,0a00h	    ;funkcja buffered input
					    ;zaladuj adres do dx
	      int	21h		    ;przerwanie dosa

	      movzx	di,byte [edx+1];licznik znakow z bufora do di
	      add	edx,2	       ;edx=adres nazwy pliku
	      add	edi,edx        ;edi= adres ostatniego znaku w pliku
	      mov	byte[edi],0   ;usun [enter] na koncu bufora

check_file:
	      sub     edi,4				   ;edx ostatnie znaki w buforze

	      mov     eax,[edi] 			   ;zaladuj 4 ostatnie znaki
	      or      eax,00100000001000000010000000000000b;zmien litery na male
	      cmp     eax,'.bmp'			   ;sprawdz, czy plik .gpf
	      jne     error				   ;jesli nie to blad
	      mov     [RozAdr],edi


otworz_plik:
	      mov	eax,3d00h    ;funkcja otworz plik
	      mov	[ErrorCode],TErrorFile2
	      xor	ecx,ecx
	      int	21h	    ;przerwanie dos
	      jc	error	    ;gdy jest jakis blad +++++++
	      mov	ebx,eax

get_file_size:

		xor	ecx,ecx
		mov	eax,4202h
		xor	edx,edx 		    ;pobierz rozmiar pliku
		int	21h
		push	dx
		push	ax
		shl	edx,16
		mov	dx,ax
		push	edx

		xor	edx,edx
		mov	eax,4200h
		xor	ecx,ecx
		int	21h

		pop	ecx
		mov	[FileLenght],ecx
		mov	[FileHandle],ebx

alocate:
		mov	eax,0501h
		pop	cx
		pop	bx
		int	31h

create_selector:
		push	bx
		push	cx
		mov	cx,1
		xor	ax,ax
		int	31h
		mov	dx,ds
		lar	cx,dx
		mov	si,ax
		shr	cx,8
		mov	bx,ax
		or	cx,1100000000000000b
		mov	ax,9
		int	31h
		pop	dx
		pop	cx
		mov	bx,si
		mov	ax,7
		int	31h
		mov	cx,0ffffh
		mov	dx,0ffffh
		mov	eax,8
		mov	bx,si
		int	31h
		mov	[es:SelAloc],si
		push	si
		pop	ds

czytajnaglowek:mov	ebx,[es:FileHandle]
	       mov	 ecx,54       ;czytaj 54 bajty
	       xor	 edx,edx
	       mov	 ax,3f00h     ;funkcja czytaj z pliku
	       int	 21h
	       jc	 error

	      mov	cx,4
ustawpalete:  mov	ax,3f00h      ;funkcja czytaj z pliku
	      int	21h
	      mov	al,[edx]      ;przenies kolor r do palety
	      shr	al,2
	      mov	[edx],al
	      inc	edx
	      mov	al,[edx]      ;przenies kolor g do palety
	      shr	al,2
	      mov	[edx],al
	      inc	edx
	      mov	al,[edx]      ;przenies kolor b do palety
	      shr	al,2
	      mov	[edx],al
	      inc	edx
	      mov	al,[edx]      ;przenies kolor b do palety
	      shr	al,2
	      mov	[edx],al
	      inc	edx
	      cmp	edx,1024     ;czy juz wszystko?
	      jb	ustawpalete ;jesli nie to jeszcze raz

ladujobraz:
	      mov      edx,400h
	      mov      ecx,[es:FileLenght]
	      sub      ecx,1024+54
	      mov      eax,3f00h			     ;czytaj z pliku
	      int      21h				     ;zaladuj obraz
	      push     es
	      pop      ds
utworz_plik:
	      mov	edi,[RozAdr]
	      mov	eax,'.gpf'	   ;zmien rozszerzenie w nazwie pliku
	      mov	[es:edi],eax
	      mov	edx,FileName+2	    ;adres nazwy pliku
	      mov	eax,3c00h	 ;funkcja utworz plik
	      xor	ecx,ecx
	      int	21h

	      jc	error	      ;gdy jakis blad
	      xor	edx,edx
	      push	[SelAloc]
	      pop	ds

zapisz_palete:mov	ebx,eax 	;uchwyt do bx
	      mov	ecx,1024	;zapisz 1024 bajty  do pliku
	      mov	eax,4000h	 ;zapisz palete do pliku
	      int	21h
zapisz_obraz:
	      mov	edx,0	   ;edx=adres konca pliku
	      add	edx,[es:FileLenght]
	      sub	edx,54
	      mov	ecx,640      ;zapisz 640 bajtow
@@:				     ;procedura zapisujaca obraz z bufora do pliku
	      sub	edx,ecx
	      mov	eax,4000h
	      int	21h	     ;zapisz do pliku
	      cmp	edx,400h     ;czy juz caly obraz?
	      ja	@r
	      push	es
	      pop	ds


zakoncz_program:
	      mov	edx,TSuccess
	      mov	eax,0900h
	      int	21h
zakoncz:
	      xor	eax,eax ;czekaj na klawisz
	      int	16h

	      mov	eax,4c00h  ;wyjdz
	      int	21h
error:
	      mov	ax,0900h	;wyswietl tekst bledu
	      mov	edx,[ErrorCode]
	      int	21h
	   jmp		zakoncz


ErrorCode dd TErrorFile1
TErrorFile1: db 'Niewlasciwa nazwa pliku$'
TErrorFile2: db 'Blad operacji na pliku $'
TMessage: db 'Wpisz nazwe pliku, ktory chcesz przekonwertowac z bmp na gpf',10,13,'$'
TSuccess db "Operacja zakonczona pomyslnie!$"
FileHandle  dd	      0
FileLenght: dd 0
SelAloc     dw 0
RozAdr	    dd 0
FileName:   times 256 db 0
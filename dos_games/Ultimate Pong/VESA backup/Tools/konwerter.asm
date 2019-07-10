format MZ
use16
entry	main:start
segment main

start:	      push	program_data	;segment do ds i fs
	      mov	ah,09h		 ;wypisz komunikat
	      lea	dx,[TMessage]  ;zaladuj adres do dx
	      pop	ds
	      int	21h		 ;przerwanie dosa

pobierz_nazwe:mov	ah,0ah		 ;funkcja buffered input
	      lea	dx,[BFileName]	 ;zaladuj adres do dx
	      int	21h		 ;przerwanie dosa

	      movzx	bx,byte [FileNameCounter];licznik znakow z bufora do di
	      lea	di,[FileName+bx];adres ciagu znakow idzie do bx
	      xor	dx,dx	  ;zeruj dx
	      mov	[ErrorCode],TErrorFile1
	      mov	[di],dl   ;usun [enter] na koncu bufora

sprawdz_plik: sub	di,4
	      mov	ax,[di]
	      cmp	ax,'.b'
	      jne	error
	      add	di,2
	      mov	ax,[di]   ;sprawdz rozszerzenie pliku
	      cmp	ax,'mp'
	      jne near	error	  ;jesli nie .bmp zla nazwa

otworz_plik:  mov	[ErrorCode],TErrorFile2
	      mov	ax,3d00h    ;funkcja otworz plik
	      lea	dx,[FileName];zaladuj bufor z nazwa
	      int	21h	    ;przerwanie dos
	      jc near	error	    ;gdy jest jakis blad

czytajnaglowek:mov	bx,ax	    ;przenies uchwyt pliku z bx do ax
	      mov	cx,54	    ;czytaj 54 bajty
	      lea	dx,[BPaleta];offset
	      mov	ah,3fh	    ;funkcja czytaj z pliku
	      int	21h
	      jc near	error

	      xor	si,si	    ;index do palety
	      mov	cx,4	    ;czytaj po 4 bajty
ustawpalete:  mov	ah,3fh	    ;funkcja czytaj z pliku
	      lea	dx,[b]	    ;zaladuj adres b do dx
	      int	21h
	      mov	dl,[r]	    ;przenies kolor r do paleta
	      ;shl      dl,2
	      mov	[BPaleta+si],dl
	      mov	dl,[g]	    ;przenies kolor g do paleta
	      ;shl      dl,2
	      mov	[BPaleta+si+1],dl
	      mov	dl,[b]	    ;przenies kolor z b do paleta
	      ;shl      dl,2
	      mov	[BPaleta+si+2],dl
	      mov	dl,[x]	    ;przenies aligment bit do paleta
	      ;shl      dl,2
	      mov	byte [BPaleta+si+3],dl
	      add	si,4	    ;dodaj 4 do indexu
	      cmp	si,1024     ;czy juz wszystko?
	      jb short	ustawpalete ;jesli nie to jeszcze raz

ladujobraz:
	      push	file_buffer1;1czesc bufora do ds
	      pop	ds
	      mov	cx,07f80h   ;ilosc odczytywanych bajtow
	      call near PLadujObraz ;skocz do procedury ladujacej dane
	      push	file_buffer2
	      pop ds
	      call near PLadujObraz
	      push	file_buffer3
	      pop ds
	      call near PLadujObraz
	      push	file_buffer4
	      pop ds
	      call near PLadujObraz
	      push	file_buffer5
	      mov	dx,0	    ;laduj ostatnia czesc pliku do bufora              mov       cx,0b400h
	      mov	cx,0b400h
	      mov	ah,3fh
	      pop	ds
	      int	21h

utworz_plik:  push	program_data ;laduj segment z danymi do ds
	      mov	dx,'pf'
	      pop	ds
	      mov	[di],dx
				;zmien nazwe z bufora na nowa
	      sub	di,2
	      mov	dx,'.g'
	      mov	[di],dx
	      mov	ah,3ch	      ;funkcja utworz plik
	      xor	cx,cx
	      lea	dx,[FileName]
	      int	21h
	      jc near	error	      ;gdy jakis blad

zapisz_palete:mov	bx,ax	      ;uchwyt do bx
	      mov	cx,1024
	      lea	dx,[BPaleta]
	      mov	ah,40h	      ;zapisz palete do pliku
	      int	21h

zapisz_obraz:
	      push	file_buffer5
	      mov	dx,0b400h     ;zapisz obraz do pliku
	      pop	ds
	      call near PZapiszObraz   ;wywolaj procedure zapisujaca do pliku
	      push	file_buffer4
	      mov	dx,0ff00h
	      pop	ds
	      call near PZapiszObraz
	      push	file_buffer3
	      mov	dx,0ff00h
	      pop	ds
	      call near PZapiszObraz
	      push	file_buffer2
	      mov	dx,0ff00h
	      pop	ds
	      call near PZapiszObraz
	      push	file_buffer1
	      mov	dx,0ff00h
	      pop	ds
	      call near PZapiszObraz

zakoncz_program:
	      xor	ah,ah ;czekaj na klawisz
	      int	16h

	      mov	ax,4c00h  ;wyjdz
	      int	21h
error:
	      push	program_data
	      pop	ds
	      mov	ah,09h	      ;wyswietl tekst bledu
	      mov	dx,[ErrorCode]
	      int	21h
	   jmp		zakoncz_program

PLadujObraz:
	      xor	dx,dx	     ;procedura ladujaca obraz do bufora
	      mov	ah,3fh
	      int	21h
	      mov	dx,cx
	      mov	ah,3fh
	      int	21h
	   ret
PZapiszObraz:
	      mov	cx,640
@@:				     ;procedura zapisujaca obraz z bufora do pliku
	      sub	dx,cx
	      mov	ah,40h
	      int	21h
	      test	dx,dx
	      jnz	@r
	   ret

segment program_data
ErrorCode dw 0
TErrorFile1: db 'Niewlasciwa nazwa pliku$'
TErrorFile2: db 'Blad pliku $'
TMessage: db 'Wpisz nazwe pliku, ktory chcesz przekonwertowac z bmp na gpf',10,13,'$'
BFileName db 199
FileNameCounter db 0
FileName: times 200 db 0
b		db 0
g		db 0
r		db 0
x		db 0
BPaleta: rb 1024

segment file_buffer1
rb 0ff00h
segment file_buffer2
rb 0ff00h
segment file_buffer3
rb 0ff00h
segment file_buffer4
rb 0ff00h
segment file_buffer5
rb 0b400h
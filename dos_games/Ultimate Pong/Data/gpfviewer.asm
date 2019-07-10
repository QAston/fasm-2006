format mz
;program do wyswietlania plikow gpf
;wersja kozystajaca z instrukcji movsd
heap   0h
include 'loader.inc'
;fs= 0-based segment ;ds=es-data segnt cs=code segment gs=wolny
segment _code  use32


code32:
alloc_dos:
	mov	 [AErrorMsg],TMemoryErrorMsg
	mov	 eax,100h			       ;alokuj pamiec dosa
	mov	 ebx,40h			       ;400h bajtow 40h paragrafow 1024 bajty
	int	 31h				       ;do dx=selektor segmentu[PM] do ax=segment [RM]
	jc	 error				       ;jc to blad

	push	 dx
	mov	 [RMes],ax
	pop	 gs				       ;do edx ofset bufora sel:fs

get_vesa:
	lea	edi,[RMRegs]			       ;edi=indeks do struktury z rejestrami RM
	mov	ebx,0010h			       ;ebx=przerwanie 10h
	mov	ecx,0				       ;cx=liczba slow do skopiowanie do stosu RM
	mov	[RMeax],4f00h			       ;funkcja pobierz informacje SVGA
	mov	eax,0300h			       ;funkcja symuluj przerwanie 16-bit
	int	31h

	mov	[AErrorMsg],TDPMIErrorMsg
	jc	error
	mov	[AErrorMsg],TVESAErrorMsg
	cmp	[RMeax],004fh
	jne	error				       ;gs:0 bufor na informacje SVGA
	cmp	dword[gs:0],'VESA'		       ;sprawdz, czy VESA obslugiwana
	jne	error
	mov	ax,[gs:10h]			       ;DWORD w gs:0eh=adres
	shl	eax,4
	mov	ax,[gs:0eh]			       ;eax=adres struktury z obslugiwanymi modulami
detect_mode:						 ;petla sprawdzania obslugi mode 101h
	mov	dx,[fs:eax]
	cmp	dx,0ffffh
	je	error				       ;je to nie obsluguje
	add	eax,2
	cmp	dx,101h 			       ;sprawdz czy obsluguje 101h
	jne	detect_mode
get_101:
	mov	[RMeax],4f01h			       ;emuluj funkcje 4f01h int 10h
	mov	[RMecx],edx
	mov	eax,0300h
	int	31h
	cmp	[RMeax],004fh
	jne	error

	mov	eax,4f03h
	int	10h
	mov	[OldVideoMode],bx		      ;pobierz stary tryb
	mov	eax,4f02h
	mov	ebx,101h			       ;zmien tryb na 101h
	int	10h
	cmp	eax,004fh
	jne	error

send_message:
	mov	eax,0900h			     ;wypisz komunikat
	lea	edx,[TMessage]			     ;zaladuj adres do edx
	int	21h				     ;przerwanie dosa

	push	gs
	pop	ds				     ;do ds segment bufora
	xor	edx,edx 			     ;zaladuj przesuniecie do dx
	mov	byte[edx],253			     ;rozmiar bufora do [edx]

get_file_name:
	mov	eax,0a00h			     ;funkcja buffered input

	int	21h				     ;przerwanie dosa
	jc	error
	movzx	edx,byte[1]			     ;licznik znakow z bufora do edi
	mov	[es:AErrorMsg],TFileErrorMsg
	add	edx,2

	mov	byte[edx],0			     ;usun [enter] na koncu bufora


check_file:
	sub	edx,4				     ;edx ostatnie znaki w buforze
	cmp	edx,0
	jl	error

	mov	eax,[edx]			     ;zaladuj 4 ostatnie znaki
	or	eax,00100000001000000010000000000000b;zmien litery na male
	cmp	eax,'.gpf'			     ;sprawdz, czy plik .gpf
	jne	error				     ;jesli nie to blad


open_file:
	mov	[es:AErrorMsg],TFileErrorMsg	     ;otworz plik
	mov	eax,3d00h
	mov	edx,2				     ;edx=ofset bufora
	int	21h
	jc	error

load_palette:
	mov	ebx,eax 			      ;ebx uchwyt pliku
	mov	eax,3f00h			      ;zaladuj palete z pliku
	mov	ecx,1024			      ;1024 bajty
	xor	edx,edx 			      ;ofset bufora
	int	21h
	jc	error

	push	es				      ;przywroc segment
	pop	ds
	push	ebx				      ;zachowaj uchwyt pliku

set_palette:
	mov	[RMeax],4f09h			      ;funkcja ustaw palete
	mov	[RMebx],0			      ;flagi
	mov	[AErrorMsg],TVESAErrorMsg
	mov	[RMecx],256			      ;ilosc zmienionych pozycji
	mov	[RMedx],0			      ;index startu palety
	mov	[RMedi],0			      ;ofset bufora palety RMes segment bufora palety
	mov	bx,0010h			      ;int 10h
	mov	ax,0300h			      ;emuluj przerwanie 16-bit
	int	31h				      ;ustaw palete
	cmp	[RMeax],004fh
	jne	error				      ;czy blad

get_picture:
	pop	ebx				      ;przywroc uchwyt pliku
	mov	eax,3f00h			      ;czytaj z pliku
	mov	ecx,640*100				     ;caly plik
	mov	edx,Picture			      ;ofset obrazu
	int	21h				      ;zaladuj obraz
	mov	eax,3f00h			      ;czytaj z pliku
	mov	ecx,4b000h				    ;caly plik
	mov	edx,Picture			      ;ofset obrazu
	int	21h

	mov	edi,0a000h*16			      ;fs:eax -adres pamieci video
	mov	esi,Picture			      ;ds:ebx- adres obrazu
	push	fs
	pop	es
	xor	dx,dx				      ;zeruj index
load_picture:
	movsd
	cmp	dx,4				      ;czy ostatni bank
	jb	@f
	cmp	edi,0a000h*16+0b000h		      ;czy koniec obrazu
	je	picture_loaded
@@:
	cmp	edi,0a000h*16+0ffffh		      ;czy trzeba zmienic bank?
	jb	load_picture
	mov	edi,0a000h*16			      ;jesli tak, to ustaw segment pamieci
	add	dx,1
	mov	ax,4F05h			      ;zmien bank
	xor	bx,bx				      ;bez flag
	int	10h
	jmp	load_picture
picture_loaded:
	push	ds
	pop	es

ending:

	xor	eax,eax 				 ;czekaj na klawisz
	int	16h
Ending:
	mov	bx,[OldVideoMode]
	mov	eax,4f02h				;przywroc tryb
	int	10h
	mov	eax,4c00h
	int	21h

error:
	push	es
	pop	ds
	mov	edx,[AErrorMsg]
	mov	eax,0900h				  ;jesli wystapil blad
	int	21h
	jmp	ending

TMemoryErrorMsg 	db	"Not enough conventional memory.",13,10,'$'
TOutOfMemoryErrorMsg	db	'Out of memory',13,10,'$'
TVESAErrorMsg		db	"Your graphic card doesn't support VESA 640*480*256 mode!",13,10,'$'
TDPMIErrorMsg		db	'DPMI error!',13,10,'$'
TFileErrorMsg		db	'File error!',13,10,'$'
TMessage:		db	'Wpisz nazwe pliku [gpf], ktory chcesz otworzyc',10,13,'$'
AErrorMsg		dd	0
OldVideoMode		dw	0
Picture rb 640*480
RMRegs rb  32
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




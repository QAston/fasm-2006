format mz
heap   1000h
stack  1000h
include 'loader.inc'
;fs= 0-based segment ;ds=es-data segnt cs=code segment gs=wolny
segment _code  use32

code32:
	mov	  eax,0900h	      ;wypisz komunikat
	lea	  edx,[TMessage]      ;zaladuj adres do edx
	int	  21h		      ;przerwanie dosa

pobierz_nazwe:
	mov	  eax,0a00h	      ;funkcja buffered input
	lea	  edx,[BFileName]     ;zaladuj adres do dx
	int	  21h		      ;przerwanie dosa

	movzx	  bx,byte[FileNameCounter];licznik znakow z bufora do edi
	lea	  edi,[FileName+bx]	  ;adres ciagu znakow idzie do bx
	xor	  edx,edx		  ;zeruj edx
	mov	  [AErrorMsg],TFileErrorMsg
	mov	  [edi],dl		  ;usun [enter] na koncu bufora

sprawdz_plik:
	sub	  edi,4 			       ;edi ostatnie znaki w buforze
	mov	  eax,[edi]			       ;zaladuj 4 ostatnie znaki
	or	  eax,00100000001000000010000000000000b;zmien litery na male
	cmp	  eax,'.gpf'			       ;sprawdz, czy plik .gpf
	jne	  error 			       ;jesli nie to blad

	mov	[AErrorMsg],TMemoryErrorMsg
	mov	eax,100h			       ;alokuj pamiec dosa
	mov	ebx,20h 			       ;200h bajtow 20h paragrafow
	int	31h				       ;do dx=selektor segmentu[PM] do ax=segment [RM]
	jc	error				       ;jc to blad

	lea	edi,[RMRegs]			       ;edi=indeks do struktury z rejestrami RM
	push	dx
	pop	gs				       ;gs=segment zaalokowany
	mov	ebx,0010h			       ;ebx=przerwanie 10h
	mov	ecx,0				       ;cx=liczba slow do skopiowanie do stosu RM
	mov	[RMes],ax			       ;RMes=zaalokowany segment
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
modepetla:					       ;petla sprawdzania obslugi mode 101h
	mov	dx,[fs:eax]
	cmp	dx,0ffffh
	je	error
	add	eax,2
	cmp	dx,101h
	jne	modepetla
	mov	[RMeax],4f01h			       ;emuluj funkcje 4f01h int 10h
	mov	[RMecx],edx
	mov	eax,0300h
	int	31h
	cmp	[RMeax],004fh
	jne	error

	mov	si,[gs:04]			       ;gs:04= granurality
	mov	ax,64
	xor	dx,dx
	div	si				       ;ax=64/gran
	mov	[GranularityMask],ax

	mov	eax,4f03h
	int	10h
	mov	[OldVideoMode],bx		       ;pobierz stary tryb
	mov	ax,4f02h
	mov	bx,101h 			       ;zmien tryb na 101h
	int	10h
	cmp	ax,004fh
	jne	error

	mov	[AErrorMsg],TMemoryErrorMsg
	mov	ax,100h
	mov	bx,40h				      ;alokuj pamiec na palete
	int	31h
	jc	error

	mov	[RMes],ax
	push	dx				      ;otworz plik
	mov	[AErrorMsg],TFileErrorMsg
	mov	ax,3d00h
	mov	edx,FileName
	int	21h
	jc	error


	pop	ds
	mov	ebx,eax
	mov	eax,3f00h			      ;zaladuj palete
	mov	ecx,1024
	xor	edx,edx
	int	21h
	jc	error
	push	es
	pop	ds
	push	ebx

	mov	[RMeax],4f09h
	mov	[RMebx],0
	mov	[AErrorMsg],TVESAErrorMsg	      ;ustaw palete
	mov	[RMecx],256
	mov	[RMedx],0
	mov	[RMedi],0
	mov	bx,0010h
	mov	ax,0300h
	int	31h
	cmp	[RMeax],004fh
	jne	error

	pop	ebx
	mov	eax,3f00h
	mov	ecx,4b000h			      ;zaladuj obraz
	mov	edx,Picture
	int	21h

	mov	edi,0a000h*16	     ;fs:eax -adres pamieci video
	mov	ebp,edi
	mov	esi,Picture	     ;ds:ebx- adres obrazu
	xor	dx,dx
	xor	cx,cx
pikczer:
	mov eax,[ds:esi]
	mov dword[fs:edi],eax
	add edi,4
	add esi,4				       ;przenies obraz do pamieci video
	cmp dx,4
	jb pikczer1
	cmp cx,02bffh
	je popikczer
pikczer1:
	cmp cx,03fffh
	inc cx
	jb pikczer
	mov edi,ebp;0a000h*16
	xor cx,cx
	add dx,1;[GranularityMask]
	mov ax,4F05h
	xor bx,bx
	int 10h
	cmp ax,004fh
	jne error
	jmp pikczer
popikczer:


koniec:

	xor	ax,ax				       ;czekaj na klawisz
	int	16h
Koniec:
	mov	bx,[OldVideoMode]
	mov	ax,4f02h			       ;przywroc tryb
	int	10h
	mov	ax,4c00h
	int	21h

error:
	mov	edx,[AErrorMsg]
	mov	ah,09h				       ;jesli wystapil blad
	int	21h
	jmp	koniec

BFileName db 253
FileNameCounter db 0
FileName: times 254 db 0
TMemoryErrorMsg 	db	"Not enough conventional memory.",13,10,'$'
TOutOfMemoryErrorMsg	db	'Out of memory',13,10,'$'
TVESAErrorMsg		db	"Your graphic card doesn't support VESA 640*480*256 mode!",13,10,'$'
TDPMIErrorMsg		db	'DPMI error!',13,10,'$'
TFileErrorMsg		db	'File error!',13,10,'$'
TMessage:		db	'Wpisz nazwe pliku [gpf], ktory chcesz otworzyc',10,13,'$'
AAlocDos		dd	0
SegDos			dw	0
SelDos			dw	0
AErrorMsg		dd	0
APSP			dw	0
GranularityMask 	dw	0
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




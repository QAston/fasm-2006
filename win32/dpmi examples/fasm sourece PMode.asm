format mz
heap 0
entry main:start

segment main use16

start:

	mov	ax,ds		   ;ds wskazuje na Program Segment Prefix
	mov	dx,[2Ch]
	push	cs cs
	pop	ds es
	mov	[cs:SPSP],ax	   ;[SPSP:2ch]- numer segmentu z kopia zmiennych srodowiskowych
	mov	[cs:SEnvVar],dx

test386:
	pushf
	xor	ah,ah
	mov	[cs:AErrorCode],T386ErrorCode
	push	ax
	popf
	pushf
	pop	ax
	and	ah,0f0h
	cmp	ah,0f0h
	je	error	;jesli nie 386
	mov	ah,70h
	push	ax
	popf
	pushf
	pop	ax
	and	ah,70h
	jz	error	;jesli nie 386
	popf

present_386:			      ;jesli jest conajmniej 386
	mov	eax,ds
	shl	eax,4
	mov	[cs:AProgramBase],eax ;adres bazowy programu =ds/16
;       mov     [cs:AErrorCode],TPModeErrorCode
	mov	eax,buffer
	shl	eax,4
	sub	eax,[cs:AProgramBase]  ;adres bufora=(buffer/16)-adres bazowy programu
	mov	[cs:ABuffer],eax
	smsw	ax
;       test    al,1                   ;czy procesor jest w PM
;       jz      error                  ;jesli nie to error

	push	cs code32
dpmi:
	mov	ax,1687h		;funkcja DPMI installation check
	int	2Fh
	mov	[cs:AErrorCode],TDPMIErrorCode
	test	ax,ax			;gdy ax=0 to DPMI zainstalowane
	jnz	error
	test	bl,1			;czy obsluguje programy 32-bitowe
	jz	error
	mov	word [cs:ADPMIModeSwitch],di ;zapisz adres procedury DPMI
	mov	word [cs:ADPMIModeSwitch+2],es
	mov	bx,si			;si=liczba paragrafow zajeta przez DPMI
	mov	ah,48h
	int	21h			;Alokuj pamiec na dane DPMI
	mov	[cs:AErrorCode],TMemoryErrorCode
	jc	error
	mov	ds,[SEnvVar]		;ds=segment zmiennych srodowiskowych
	mov	es,ax			;es=segment danych DPMI
	mov	ax,1			;gdy ax=1 zmien na PMode
	mov	[cs:AErrorCode],TDPMIErrorCode
	call	far [cs:ADPMIModeSwitch] ;wywolaj procedure DPMI zmieniajaca tryb na PMode
	jc	error
	mov	cx,1			;alokuj 1 deskryptor
	xor	ax,ax			;ax=0 int 31h-alokuj deskryptor LTD
	int	31h			;alokuj deskryptor dla kodu gry
	mov	si,ax			;bazowy selektor kodu do si
	xor	ax,ax
	int	31h			;alokuj deskryptor dla danych gry
	mov	di,ax			;bazowy selektor danych do di
	mov	dx,cs
	lar	cx,dx			;lar-Load Access Rights  cl=0 ch=accesrights
	shr	cx,8			;ch=cl cl=0
	or	cx,1100000000000000b ;ustaw 14 i 15 bit cx
	mov	bx,si			;selektor kodu do bx
	mov	ax,9
	int	31h			;ustaw prawa dostepu do deskryptora kodu
	mov	dx,ds
	lar	cx,dx
	shr	cx,8
	or	cx,1100000000000000b
	mov	bx,di
	int	31h			;ustaw prawa dostepu do deskryptora danych
	mov	ecx,main
	shl	ecx,4			;w bx selektor danych
	mov	dx,cx			;do cx:dx liniowy adres segmentu main
	shr	ecx,16
	mov	ax,7
	int	31h			;ustaw bazowy adres deskryptora danych
	movzx	ecx,word[esp+2] 	;do ecx stary cs
	shl	ecx,4
	mov	dx,cx
	shr	ecx,16
	mov	bx,si
	int	31h			;ustaw bazowy adres deskryptora kodu
	mov	cx,0FFFFh
	mov	dx,0FFFFh
	mov	ax,8			;ustaw limit segmentu kodu na 4Gb
	int	31h
	mov	bx,di			;ustaw limit segmentu danych na 4Gb
	int	31h
	mov	ax,ds
	mov	ds,di			;ds=es=selektor danych
	mov	[SPSP],es		;cs=selektor kodu
	mov	[SEnvVar],ax
	mov	es,di
	pop	ebx
	movzx	ebx,bx
	use32
	push	esi
	push	ebx			;powroc do kodu (do code32)
	retfd
code32:
	use32
	mov	dx,100
	call	aloc_mem
	call	free_mem

koniec:
	xor ah,ah
	int 16h
Koniec:
	mov ax,4c00h
	int 21h

aloc_mem:			;na wejsciu podaj w dx liczbe KB do alokacji
	push	eax ebx ecx edi esi
	mov	ax,500h 		;funkcja pobierz informacje o wolnej pamieci
	mov	edi,[ABuffer]		;do bufora
	int	31h
	mov	ebx,[edi]		;zaladuj maksymalna liczbe bajtow do zaalokowania do ebx
    allocate_dpmi_memory:
	shl	edx,10
	jz	dpmi_memory_size_ok
	cmp	ebx,edx 		;sprawdz czy da sie zaalokowac zadana liczbe KBajtow
	jbe	dpmi_memory_size_ok
	mov	ebx,edx
    dpmi_memory_size_ok:
	mov	[AMemoryEnd],ebx
	mov	ecx,ebx
	shr	ebx,16
	mov	ax,501h
	int	31h
	jnc	dpmi_memory_ok
	mov	ebx,[AMemoryEnd]
	shr	ebx,1
	mov	[AErrorCode],TOutOfMemoryErrorCode
	cmp	ebx,4000h
	jb	error
	jmp	allocate_dpmi_memory
    dpmi_memory_ok:
	shl	ebx,16
	mov	bx,cx
	sub	ebx,[AProgramBase]
	jc	error
	mov	[AMemoryStart],ebx
	mov	word[MemoryBlockHandle],si
	mov	word[MemoryBlockHandle+2],di
	add	[AMemoryEnd],ebx
	mov	edx,ebx
	pop	esi edi ecx ebx eax
	ret			     ;na wyjsciu prosedura podaje w edx miejsce w ktorymsa zaalokowane KB

free_mem:
	push ax si di
	mov ax,0502h
	mov si,word[MemoryBlockHandle]
	mov di,word[MemoryBlockHandle+2]
	int 31h
	jc Koniec
	pop di si ax
	ret
error:
	mov	ah,9
	mov	dx,[AErrorCode]
	push	cs
	pop	ds
	int	21h
	jmp	koniec


TMemoryErrorCode       db      "Not enough conventional memory.",13,10,'$'
TOutOfMemoryErrorCode  db      'Out of memory',13,10,'$'
;TPModeErrorCode       db      'Sorry, this game must be run in protected mode!',13,10,'$'
TDPMIErrorCode	       db      'Sorry, this game requires 32-bit DPMI to run!',13,10,'$'
T386ErrorCode	       db      'Sorry, this game requires at least a 80386 CPU!',13,10,'$'
AErrorCode	       dw      0
SPSP		       dw      0
SEnvVar 	       dw      0
AProgramBase	       dd      0
ABuffer 	       dd      0
ADPMIModeSwitch        dd      0
AMemoryStart	       dd      0
AMemoryEnd	       dd      0
AAdditionalMemory      dd      0
AAdditionalMemoryEnd   dd      0
MemoryBlockHandle      dd      0

segment buffer
rb 1000h
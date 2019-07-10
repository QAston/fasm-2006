segment _loader use16
;wersja loadera bez PSP
start:
test386:
	pushf
	xor	ah,ah
	mov	[AError16Msg],T386Error16Msg
	push	ax
	mov	bx,cs	    ;cs=ds=es
	popf
	pushf
	pop	ax
	and	ah,0f0h
	mov	es,bx	    ;cs=ds=es
	cmp	ah,0f0h
	je	error16   ;jesli nie 386
	mov	ah,70h
	push	ax
	popf
	mov	ds,bx	    ;cs=ds=es
	pushf
	pop	ax
	and	ah,70h
	jz	error16   ;jesli nie 386
	popf

dpmi:
	mov	ax,1687h		;funkcja DPMI installation check
	int	2Fh
	or	ax,ax			;gdy ax=0 to DPMI zainstalowane
	mov	[AError16Msg],TDPMIError16Msg
	jnz	error16
	test	bl,1			;czy obsluguje programy 32-bitowe
	jz	error16

	mov	word [ADPMIModeSwitch],di ;zapisz adres procedury DPMI
	mov	bx,si			;si=liczba paragrafow zajeta przez DPMI
	mov	word [ADPMIModeSwitch+2],es
	mov	ah,48h
	mov	[AError16Msg],TMemoryError16Msg
	int	21h			;Alokuj pamiec na dane DPMI
	jc	error16
	mov	es,ax			;es=segment danych DPMI
	mov	[AError16Msg],TDPMIError16Msg
	mov	ax,1			;gdy ax=1 zmien na PMode
	call	far [ADPMIModeSwitch] ;wywolaj procedure DPMI zmieniajaca tryb na PMode
	jc	error16

	mov	ax,168Ah
	mov	esi,TMSDOS		;Czy DPMI jest True?
	int	2Fh
	test	al,al
	mov	[AError16Msg],TTrueError16Msg
	jnz	error16

	mov	cx,1			;alokuj cx deskryptorow
	xor	ax,ax			;ax=0 int 31h-alokuj deskryptor LTD
	int	31h			;alokuj deskryptor dla kodu gry
	mov	si,ax			;bazowy selektor kodu do si
	xor	ax,ax
	int	31h			;alokuj deskryptor dla danych gry
	mov	di,ax			;bazowy selektor danych do di

	xor	ax,ax
	int	31h
	mov	dx,fs
	lar	cx,dx
	mov	bp,ax
	shr	cx,8
	mov	bx,ax
	or	cx,1100000000000000b
	mov	ax,9
	int	31h

	mov	dx,cs
	lar	cx,dx			;lar-Load Access Rights  cl=0 ch=accesrights
	mov	bx,si			;selektor kodu do bx
	shr	cx,8			;ch=cl cl=0
	or	cx,1100000000000000b	;ustaw 14 i 15 bit cx
	int	31h			;ustaw prawa dostepu do deskryptora kodu

	mov	dx,ds
	lar	cx,dx
	mov	bx,di
	shr	cx,8
	or	cx,1100000000000000b
	int	31h			;ustaw prawa dostepu do deskryptora danych

	mov	ecx,_code
	shl	ecx,4			;w bx selektor danych
	mov	dx,cx			;do cx:dx liniowy adres segmentu main
	mov	ax,7
	shr	ecx,16
	int	31h			;ustaw bazowy adres deskryptora danych
	mov	bx,si
	int	31h			;ustaw bazowy adres deskryptora kodu
	xor	dx,dx
	mov	bx,bp
	xor	cx,cx
	int	31h
	dec	dx			;dx=0ffffh
	dec	cx			;cx=0ffffh
	inc	ax		      ;ustaw limit segmentu kodu na 4Gb
	int	31h
	mov	bx,di			;ustaw limit segmentu danych na 4Gb
	int	31h
	mov	bx,bp
	int	31h
	mov	ds,di			;ds=es=selektor danych
	push	si
	mov	fs,bp
	push	dword code32		;powroc do kodu (do code32)
	mov	es,di
	retfd
	;cs=ds=es=_code
	;fs;0-based segment

error16:
	mov	ah,9
	mov	dx,TRequirements
	int	21h
	mov	ah,9
	mov	dx,[AError16Msg]
	int	21h
	xor	ah,ah
	int	16h
	mov	ax,4c00h
	int	21h

TMemoryError16Msg	 db	 "Not enough conventional memory.",13,10,'$'
TDPMIError16Msg 	 db	 "You don't have 32-bit DPMI!",13,10,'$'
TTrueError16Msg 	 db	 "Your DPMI isn't True!",13,10,'$'
T386Error16Msg		 db	 "You don't have 80386 or later CPU!",13,10,'$'
TRequirements:		 db	 'Requirements:',13,10
			 db	 '-80386 or later CPU',13,10,'-True 32-bit DPMI host',13,10,'-SVGA graphics card with VESA support',13,10,'$'
TMSDOS			 db	 'MS-DOS',0
AError16Msg		 dw	 0
ADPMIModeSwitch 	 dd	 0



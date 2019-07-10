
Virtual at FILEBUFFER
		bftype dw ?
		bfsize dd ?
		bfreserved dd ?
		bfoffbits dd ?
		bmprozmiar dd ?
		bmpszerokosc dd ?
		bmpwysokosc dd ?
		biplanes dw ?
		bibitcount dw ?
		bicompression dd ?
		bisizeimag  dd ?
		bixpelspermeter dd ?
		biypelspermeter dd ?
		bmpliczbakolorow dd ?
		biclrimportant dd ?
end virtual
macro	MSHOWBMP ekranX,filename,startX,startY{
	push	eax ebx ecx edx esi edi ebp ds
	mov	ax, 3d00h
	mov	si,dataseg
	mov	ds,si
	mov	dx,filename
	int	21h
	jc	fileerror

	mov	bx, ax
	mov	ah, 3fh
	mov	cx,54
	mov	dx,0
	mov	si,filebuffer
	mov	ds,si
	int	21h
	jc	fileerror
	mov	edi,[bmpszerokosc]
	mov	ebp,[bmpwysokosc]
	xor	esi, esi
@@:
	mov	ah, 3fh
	mov	cx, 4
	mov	dx, b
	int	21h
	jc	fileerror
	mov	al, [r]
	shr	al, 2
	mov	[paleta+si], al
	mov	al, [g]
	shr	al, 2
	mov	[paleta+si+1], al
	mov	al, [b]
	shr	al, 2
	mov	[paleta+si+2], al
	add	si, 3
	cmp	esi,768
	jb	@r
	xor	ax, ax
	xor	si, si
	mov	dx, 3c8h
@@:
	out	dx, al
	inc	dx
	push	eax
	mov	al, [paleta+si]
	out	dx, al
	mov	al, [paleta+si+1]
	out	dx, al
	mov	al, [paleta+si+2]
	out	dx, al
	pop	eax
	add	si, 3
	dec	dx
	inc	eax
	cmp	eax,256
	jb	@r
	mov	ax, 0a000h
	mov	ds, ax

	mov	ecx,edi
	mov	eax,4
	xchg	eax,edi
	xor	edx,edx
	div	edi
	cmp	edx,0
	je	@f
	inc	ecx
	cmp	edx,3
	je	@f
	inc	ecx
	cmp	edx,2
	je	@f
	inc	ecx
@@:
	mov	eax,ebp
	xor	edx,edx
	mov	edi,ekranX
	mul	edi
	mov	edx,eax
	add	edx,startY*320+startX
@@:
	mov	ah, 3fh
	int	21h
	jc	fileerror
	sub	edx,ekranX
	jnc	@r
	mov	ah, 3eh
	int	21h
	pop	ds ebp edi esi edx ecx ebx eax}        ; zamknij plik


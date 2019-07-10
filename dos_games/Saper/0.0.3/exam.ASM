	xor	ah,ah
	mov	al,31
	mov	edi,BVideo
	@@:
	mov	[edi],ax
	add	edi,2
	inc	ah
	cmp	ah,0
	jne	@r
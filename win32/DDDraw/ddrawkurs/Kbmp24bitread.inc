
CZytaj BMP FileName WidthAndHeight DestAdres

virtual at buffer
BMPHEADER:
bfType		     dw ?
bfSize		     dd ?
bfReserved	     dd ?
bfOffBits	     dd ?
biSize		     dd ?
biWidth 	     dd ?
biHeight	     dd ?
biPlanes	     dw ?
biBitCount	     dw ?
biCompression	     dd ?
biSizeImage	     dd ?
biXPelsPerMeter      dd ?
biYPelsPerMeter      dd ?
biClrUsed	     dd ?
biClrImportant	     dd ?
end virtual

	 call SetFileAttributesA,esi,FILE_ATTRIBUTE_NORMAL
	 call CreateFileA,esi,GENERIC_READ,0,0,OPEN_EXISTING,\
			  FILE_ATTRIBUTE_NORMAL,0
	 mov ebx,eax
	 call SetFilePointer,ebx,54,0,FILE_BEGIN

	 mov  eax,WidthAndHeight	;
	 mul  eax			;ile bajtow przeczytac
	 push eax			;
	 mov  ecx,3			;
	 mul  eax			;
	 mov  edx,eax			;
	
	 call ReadFile,ebx,DestAdres,eax,esi,0

	mov	[ddsd.dwSize],sizeof.DDSURFACEDESC
	mov	[ddsd.dwFlags],DDSD_CAPS+DDSD_WIDTH+DDSD_HEIGHT+DDSD_CKSRCBLT
	mov	[ddsd.ddsCaps.dwCaps],DDSCAPS_OFFSCREENPLAIN+DDSCAPS_SYSTEMMEMORY
	mov	[ddsd.dwWidth],ebx
	mov	[ddsd.dwHeight],eax
	xor	eax,eax
	cominv  DDSetColorKey,lpDDSObraz,eax
	cominvk DDraw,CreateSurface,\
		ddsd,DDSPicture,0
	or	eax,eax
	cominvk DDSPicture,Lock,\
		0,ddsd,DDLOCK_WAIT,0

	 mov edi,DestAdres
	 add edi,2
	 mov esi,DestAdres

	 pop eax
	 zamien_kolory_R_z_B:

		mov dl,byte ptr [esi]
		mov dh,byte ptr [edi]

		mov byte ptr [edi],dl
		mov byte ptr [esi],dh

		add edi,3
		add esi,3

		dec  eax
	 jnz zamien_kolory_R_z_B

 call CloseHandle,ebx
ret

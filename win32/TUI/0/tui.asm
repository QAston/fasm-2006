format mz
;stack  100h
;engine textowy w DPMI
include 'loader.inc'
segment code_seg  use32
code_offs:
wait4key:
	xor ax,ax
	int 16h
exit
	mov ax,4c00h			    ;zamknij program
	int 21h
	`
read:


zeroize_buffer:
	;zeruje bufor o podanym adresie i dlugosci
	;wymaga:es:edi= adres bufora do wyzerowania
	;ecx= liczba bajtow do wyzerowania
	push	eax ecx edx edi
	xor	eax,eax 			    ;zeruj eax
	push	ecx				    ;zachowaj liczbe bajtow do zerowania
	shr	ecx,2				    ;podziel liczbe bajtow przez 4
	rep	stosd				    ;przenies eax do es:edi i zwieksz index o 4
	pop	ecx				    ;liczba bajtow mod 4
	and	ecx,11b 			    ;przenies reszte z dzielenia przez 4
	rep	stosb				    ;przenies al do es:edi i zwieksz index o 1
	pop	edi edx ecx eax
	ret

strncpy:
	;kopiuje ciag o podanej dlugosci z podanego adresu
	;wymaga:es:edi= adres docelowy ds:esi adres zrodlowy
	;ecx= liczba bajtow do przeniesienia
	push	eax ecx edi esi
	push	ecx				   ;zachwaj liczbe bajtow do przeniesienia
	shr	ecx,2				   ;liczba dwordow
	rep	movsd				   ;przenies ds:esi do es:edi i zwieksz index o 4
	pop	ecx
	and	ecx,11b 			   ;liczba bajtow mod 4
	rep	movsb				   ;przenies ds:esi do es:edi i zwieksz index o 1
	pop	esi edi ecx eax
	ret

aloc_mem_block:
	;wymaga:
	;bx:cx=rozmiar
	;zwraca:
	;edi=adres
	;edi-4=uchwyt si, edi-2 uchwyt di
	push	ebx eax esi ecx
	mov	ax,0501h
	int	31h
	shl	ebx,16
	mov	bx,cx
	mov	[ebx],si
	mov	[ebx+2],di
	pop	ecx esi eax
	mov	edi,ebx
	pop	ebx
	add	edi,4
	ret

free_mem_block:
	;wymaga:
	;edi=adres bloku pamieci do zwolnienia
	push	eax esi edi
	mov	eax,edi
	mov	di,[eax-2]
	mov	si,[eax-4]
	mov	ax,0502h
	int	31h
	pop	edi esi eax
	ret
segment _loader use16
;wersja loadera bez testu na 386,zapisuje adres PSP
start:
	mov	ax,_loader
	mov	ds,ax
dpmi:
	mov	ax,1687h		  ;funkcja DPMI installation check
	int	2Fh
	test	ax,ax			  ;gdy ax=0 to DPMI zainstalowane
	jnz	error16
	test	bl,1			  ;czy obsluguje programy 32-bitowe
	jz	error16

	mov	word [ADPMIModeSwitch],di ;zapisz adres procedury DPMI
	mov	bx,si			  ;si=liczba paragrafow zajeta przez DPMI
	mov	word [ADPMIModeSwitch+2],es
	mov	ah,48h
	int	21h			  ;Alokuj pamiec na dane DPMI
	jc	error16
	mov	es,ax			  ;es=segment danych DPMI
	mov	ax,1			  ;gdy ax=1 zmien na PMode
	call	far [ADPMIModeSwitch]	  ;wywolaj procedure DPMI zmieniajaca tryb na PMode
	jc	error16

	mov	ax,168Ah
	mov	esi,TMSDOS		  ;Czy DPMI jest True?
	int	2Fh
	test	al,al
	jnz	error16

	mov	bx, ds
	mov	es, bx

	; alokujemy deskryptor segmentu danych
	xor	ax,ax
	mov	cx,1
	int	31h
	
	; ustawiamy deskryptor segmentu danych
	mov	bx, ax
	mov	ax, 0ch
	mov	edi,DescData32
	int	31h
	mov	fs,bx

	mov	eax,_code	       ; znajdujemy adres fizyczny segmentu code32
	shl	eax,4

	mov	ebx,eax 	       ; uzupelniamy deskryptory o obliczony adres
	shr	ebx,16
	
	mov	di,DescCode32
	mov	word [di+2],  ax
	mov	byte [di+4],  bl
	mov	byte [di+7],  bh

	mov	di,DescData32
	mov	word [di+2],  ax
	mov	byte [di+4],  bl
	mov	byte [di+7],  bh

	xor	ax,ax
	mov	cx,1
	int	31h		    ; alokujemy deskryptor segmentu kodu (poprzez funkcje DPMI)
	push	ax

	mov	bx,ax
	mov	ax,0ch
	mov	edi,DescCode32	   ; ustawiamy deskryptor segmentu kodu
	int	31h

	xor	ax,ax
	mov	cx,1		   ; alokujemy deskryptor segmentu danych
	int	31h

	mov	bx, ax
	mov	ax, 0ch 	  ; ustawiamy deskryptor segmentu danych
	mov	edi,DescData32
	int	31h

	mov	ax,bx
;        mov     esi,[APSP]      ; skaczemy do segmentu code32 - ladujemy CS selektorem segmentu
				; kodu, a EIP przemieszczeniem etykiety code32
	mov	ds,ax
	mov	es,ax
	push	code32
	retf

error16:
	mov	ah,9
	mov	dx,T16ErrorMsg
	int	21h
	xor	ah,ah
	int	16h
	mov	ax,4c00h
	int	21h

T16ErrorMsg		 db	 "Nie mozna zaladowac 32-bitowego DPMI handlera!$"
TMSDOS			 db	 'MS-DOS',0
ADPMIModeSwitch 	 dd	 0
APSP			 dd	 0
DescCode32		 db	 0ffh, 0ffh, 0h, 0h, 0h, 0fah, 0cfh, 0h
DescData32		 db	 0ffh, 0ffh, 0h, 0h, 0h, 0f2h, 0cfh, 0h

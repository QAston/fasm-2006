segment _loader use16
;wersja flat loadera bez PSP i testu na 386
start:
	mov	ax,_loader
	mov	ds, ax

dpmi:
	mov	ax,1687h		  ;funkcja DPMI installation check
	int	2Fh
	or	ax,ax			  ;gdy ax=0 to DPMI zainstalowane
	mov	[AError16Msg],TDPMIError16Msg
	jnz	error16
	test	bl,1			  ;czy obsluguje programy 32-bitowe
	jz	error16

	mov	word [ADPMIModeSwitch],di ;zapisz adres procedury DPMI
	mov	bx,si			  ;si=liczba paragrafow zajeta przez DPMI
	mov	word [ADPMIModeSwitch+2],es
	mov	ah,48h
	mov	[AError16Msg],TMemoryError16Msg
	int	21h			  ;Alokuj pamiec na dane DPMI
	jc	error16
	mov	es,ax			  ;es=segment danych DPMI
	mov	[AError16Msg],TDPMIError16Msg
	mov	ax,1			  ;gdy ax=1 zmien na PMode
	call	far [ADPMIModeSwitch]	  ;wywolaj procedure DPMI zmieniajaca tryb na PMode
	jc	error16

	mov	ax,168Ah
	mov	esi,TMSDOS		  ;Czy DPMI jest True?
	int	2Fh
	test	al,al
	mov	[AError16Msg],TTrueError16Msg
	jnz	error16

	mov	ax, ds
	mov	es, ax

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

	; znajdujemy adres fizyczny segmentu code32
	mov	eax,_code
	shl	eax,4

	; uzupelniamy deskryptory o obliczony adres

	mov	ebx,eax
	shr	ebx,16
	
	mov	di,DescCode32
	mov	word [di+2],  ax
	mov	byte [di+4],  bl
	mov	byte [di+7],  bh

	mov	di,DescData32
	mov	word [di+2],  ax
	mov	byte [di+4],  bl
	mov	byte [di+7],  bh

	; jestesmy juz w trybie chronionym, ale 16-bit
	
	; alokujemy deskryptor segmentu kodu (poprzez funkcje DPMI)
	xor	ax,ax
	mov	cx,1
	int	31h
	push	ax

	
	; ustawiamy deskryptor segmentu kodu (dopisujemy go do tablicy
	; deskryptorow?)
	mov	bx,ax
	mov	ax,0ch
	mov	edi,DescCode32
	int	31h

	; alokujemy deskryptor segmentu danych
	xor	ax,ax
	mov	cx,1
	int	31h
	push	ax
	
	; ustawiamy deskryptor segmentu danych
	mov	bx, ax
	mov	ax, 0ch
	mov	edi,DescData32
	int	31h
	
	; skaczemy do segmentu code32 - ladujemy CS selektorem segmentu
	; kodu, a EIP przemieszczeniem etykiety start32
	pop	ax
	mov	ds,ax
	mov	es,ax
	push	code32
	retf

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
TTrueError16Msg 	 db	 "Your DPMI doesn't handle 32-bit DOS API",13,10,'$'
T386Error16Msg		 db	 "You don't have 80386 or later CPU!",13,10,'$'
TRequirements:		 db	 'Requirements:',13,10
			 db	 '-80386 or later CPU',13,10,'-True 32-bit DPMI host',13,10,'-SVGA graphics card with VESA support',13,10,'$'
TMSDOS			 db	 'MS-DOS',0
AError16Msg		 dw	 0
ADPMIModeSwitch 	 dd	 0
DescCode32		 db	 0ffh, 0ffh, 0h, 0h, 0h, 0fah, 0cfh, 0h
DescData32		 db	 0ffh, 0ffh, 0h, 0h, 0h, 0f2h, 0cfh, 0h

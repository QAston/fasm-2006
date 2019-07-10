format MZ
			       ; no additional memory

segment loader use16

	push	cs
	pop	ds

	mov	ax,1687h
	int	2Fh
	or	ax,ax			; DPMI installed?
	jnz	error
	test	bl,1			; 32-bit programs supported?
	jz	error
	mov	word [mode_switch],di
	mov	word [mode_switch+2],es
	mov	bx,si			; allocate memory for DPMI data
	mov	ah,48h
	int	21h
	jc	error
	mov	es,ax
	mov	ax,1
	call	far [mode_switch]	; switch to protected mode
	jc	error

	mov	cx,1
	xor	ax,ax
	int	31h			; allocate descriptor for code
	mov	si,ax
	xor	ax,ax
	int	31h			; allocate descriptor for data
	mov	di,ax
	mov	dx,cs
	lar	cx,dx
	shr	cx,8
	or	cx,0C000h
	mov	bx,si
	mov	ax,9
	int	31h			; set code descriptor access rights
	mov	dx,ds
	lar	cx,dx
	shr	cx,8
	or	cx,0C000h
	mov	bx,di
	int	31h			; set data descriptor access rights
	mov	ecx,main
	shl	ecx,4
	mov	dx,cx
	shr	ecx,16
	mov	ax,7			; set descriptor base address
	int	31h
	mov	bx,si
	int	31h
	mov	cx,0FFFFh
	mov	dx,0FFFFh
	mov	ax,8			; set segment limit to 4 GB
	int	31h
	mov	bx,di
	int	31h

	mov	ds,di
	mov	es,di
	mov	fs,di
	mov	gs,di
	push	si
	push	dword start
	retfd

    error:
	mov	ax,4CFFh
	int	21h

  mode_switch dd ?

segment main use32

  start:

; VESA

SOMEMEMORY = $100000		; 1 MB , more than high enough (code < 1KB, segment 4 MB)
BUF32	  = SOMEMEMORY		; $32 = #50 bytes 
DOSMEMSEL = SOMEMEMORY + $32	; 2 bytes 
DOSMEMSEG = SOMEMEMORY + $34	; 2 bytes 
DOSMEMLIN = SOMEMEMORY + $36	; 4 bytes 
VESABUF   = SOMEMEMORY + $3A	; $200 bytes 
VESAOK	  = SOMEMEMORY + $023A	; 1 byte 
PBUF	  = SOMEMEMORY + $023B	; $50 = #80 bytes 
VESABUFPO = SOMEMEMORY + $028B	; 2 bytes  ;

; *** Print text using DOS API Translation *** 

    mov    ax,$0900 
    mov    edx,t8 
    int    21h 
    jmp @f 

t8 db 'Hello (API Trans) !!!',0Dh,0Ah,24h 

@@: 

; *** Create ZERO-based segment *** 

    mov cx,1 
    xor ax,ax 
    int 31h	      ; allocate descriptor for data 
    mov di,ax 
    mov dx,ds 
    lar cx,dx 
    shr cx,8 
    or	cx,0C000h 
    mov bx,di 
    int 31h	      ; set data descriptor access rights 
    mov ecx,0	;ZERO 
    mov edx,0 
    mov ax,7	      ; set descriptor base address CX:DX // CX high 
    int 31h 
    mov bx,di	;HACK ??? 
    int 31h 
    mov cx,0FFFFh 
    mov dx,0FFFFh 
    mov ax,8	      ; set segment limit to 4 GB 
    int 31h	      ; result : di : data descriptor 

    mov fs,di	      ; store low segment 

; *** Report success *** 

    mov    ax,0900h 
    mov    edx,t9 
    int    21h 
    jmp    @f 

t9 db 'Zero-based seg created (API Trans) !!!',0Dh,0Ah,24h 

@@: 

; *** Prepare INT $300 - zeroize $32 buffer *** 

	mov cl,$32 
	mov al,0 
	mov ebx,BUF32 
@@:	mov byte [ebx],al  ; Clear $32 bytes buffer 
	inc ebx 
	dec cl 
	jnz @b 

; *** Alloc DOS memory *** 

	 xor	 ax,ax 
	 mov	 [VESAOK],al	      ; Failure 
	 mov	 [DOSMEMSEL],ax       ; Not yet alloced 
	 mov	 ax,$0100	      ; Alloc DOS memory
	 mov	 bx,$40 	      ; $0400 bytes (some buggy cards write > $0200 ???) 
	 int	 $31		      ; Alloc returns: DX: selector AX: segment 
	 jc	 xxfail 	      ; Failure in alloc 
	 mov	 [DOSMEMSEL],dx 
	 mov	 [DOSMEMSEG],ax 
	 movzx	 eax,ax 	      ; Fill upper 16 bits with 0 
	 shl	 eax,4 
	 mov	 [DOSMEMLIN], eax     ; Linear absolute addr 

; *** Zeroize the  $0400 buffer *** 

	   cld			      ; !!! Important !!! 
	   mov	   edi,eax 
	   mov	   ecx,$0100	      ; $100 of 32-bit writes 
	   xor	   eax,eax 
	   push  es 
	   push  fs		      ; Here our ZERO-based selector is stored 
	   pop	 es		      ; ES:EDI is dest for STOSD 
	   rep	 stosd 
	   pop	 es		      ; Restore ES 

; *** Write "VBE2" into "buffer" *** 

	  mov	  ebx, [DOSMEMLIN] 
;         mov     eax,"ASEV" 
	  mov	  eax,"VBE2" 
	  mov	  [fs:ebx],eax 

; *** INT $0300 register block & boom *** 

	mov word [BUF32+$1C],$4F00  ; AX: INT $21,$4F00 // [ES:DI]: buffer 
	mov word ax, [DOSMEMSEG] 
	mov word [BUF32+$22],ax     ; Set ES // DI=0  

	push ds 		    ; & 
	pop  es 		    ; & 
	mov  edi,BUF32		    ; & [ES:EDI] for INT $0300 

	mov   bx,$0010	     ; Should be INT $10 finally 
	mov   cx,0	     ; No stack junk 
	mov   ax,$0300	     ; The "simulate real mode INT" thing 
	int   $31 
	jc xxfail	     ; INT $0300 failed 

; *** Check the result *** 

	mov ax,[BUF32+$1C]   ; Capture AX from "simulate" buffer 
	cmp ax,$004F	     ; !!! Was $4F00 now must be $004F otherwise failure !!! 
	jne xxfail	     ; INT $10 failed 
	inc byte [VESAOK]    ; Report success 

; *** Move from DOS memory to DPMI memory *** 

	  cld		      ; !!! 
	  mov	  esi,[DOSMEMLIN] 
	  mov	  edi,VESABUF 
	  mov	  ecx,$0200   ; Number of bytes 
	  push	  ds 
	  push	  ds 
	  pop	  es 
	  push	  fs	      ; Our ZERO-based selector 
	  pop	  ds 
	  rep	  movsb       ; MOVE [DS:ESI] -> [ES:EDI], ECX (bytes) 
	  pop	  ds 

; *** Dealloc DOS mem ? *** 

xxfail:   mov	dx, [DOSMEMSEL] 
	  and	dx,dx		 ; cmp dx,0 
	  jz	  @F 
	  mov	  ax,$0101	 ; Deallocate 
	  int	  $31 
@@: 

; *** Report *** 

	mov  al,[VESAOK] 
	cmp  al, 0 
	jne xxok2     ; OK 

	mov    ax,0900h 
	mov    edx,t10 
	int    21h    ; Grrrrhhh (((( 
	jmp xxend 

t10 db 'No VESA or FATAL VESA error !!!',0Dh,0Ah,$24 


xxok2:	mov    ax,0900h 
	mov    edx,t11 
	int    21h   ; Great  
	jmp    @f 

t11 db 'VESA info captured !!! Let',$27,'s have a look:',0Dh,0Ah,24h


@@: 

; *** Dump the stuff *** 

	xor ax,ax 
	mov [VESABUFPO],ax  ; Pointer inside VESABUF 

	call xxcpbuf	    ; Clear and prepare print buffer 

xxdump: mov   dx, [VESABUFPO] 
	movzx ebx, dx 
	add   ebx, VESABUF 
	mov   al, [ebx]    ; Pick one byte  
	and   dl, $0F	   ; VESABUFPO MOD 16 // offset in line  

	mov dh,al 
	mov ah,al 
	and ah,$0F    ; & Low 4 bits // reversed : LITTLE ENDIAN 
	shr al,4      ; & High 4 bits 
	add  ax,$3030 ; Convert 0 -> ASCII "0" 
	cmp al,$3A 
	jb @f	       ; "b":below // OK, a number 
	add   al, 7 
@@:	cmp   ah, $3A 
	jb @f	       ; "b":below // OK, a number 
	add   ah, 7 
@@:	mov   cx, ax	 ; Move the HEX to cx 
	mov   al, dl	 ; *1 
	add   al, dl	 ; *2 
	add   al, dl	 ; *3 
	movzx ebx, al 
	add   ebx, PBUF 
	mov [ebx], cx	 ; Write the HEX number 

	cmp dh,$24 
	je  xxfaultychar ; $24 ("$") is THE MOST faulty char !!! 
	cmp dh,$20 
	jb  xxfaultychar ; <$20, faulty char 
	cmp dh,$7E 
	jb  @f		 ; <$7E, good char 
xxfaultychar:

	mov dh, $2E	 ; Replace faulty char with "." 

@@:	movzx ebx, dl	 ; dl still is offset in line 
	add   ebx, PBUF+50 
	mov [ebx], dh	 ; Write the ASCII char 

	cmp dl,$0F 
	jne xxnyp	 ; Not yet print 

	mov    ax,$0900 
	mov    edx,PBUF 
	int    $21	 ; Print content 
	call xxcpbuf	 ; And kick it out from buffer 

	mov eax,0ffffffffh ; 10 Mega
@@:	nop 
;        or  eax,eax      ; Silly delay
	dec eax 
	jnz @b


xxnyp:	mov ax, [VESABUFPO] 
	inc ax 
	cmp ax,$0200 
	je xxend	    ; End 
	mov [VESABUFPO], ax 
	jmp xxdump 

xxend:
	   xor ah,ah
	   int 16h
	   mov	ax,$4C00
	   int	$21 

; *** PROC: Clear PBUF buffer *** 

;Trashes EAX,EBX,ECX // EDX remains intact 

xxcpbuf: 
	mov ebx,PBUF 
	mov ecx,$4C	    ; Count of passes 
	mov al,$20 
@@:	mov [ebx],al	    ; Clear $4C bytes in $50 buffer 
	inc ebx 
	dec ecx 
	jnz @b 
	mov dword [PBUF+$4C],$240A0D20 ; SPC CR LF EOT 
	ret 

;END. 

;00 DWORD EDI 
;04 DWORD ESI 
;08 DWORD EBP 
;0C DWORD reserved (00h) 
;10 DWORD EBX 
;14 DWORD EDX 
;18 DWORD ECX 
;1C DWORD EAX 
;20 WORD flags 
;22 WORD ES 
;24 WORD DS 
;26 WORD FS 
;28 WORD GS 
;2A WORD IP 
;2C WORD CS 
;2E WORD SP 
;30 WORD SS 

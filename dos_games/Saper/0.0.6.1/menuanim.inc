AnimPicture:
db 2	;rozmiar x
db 2	;rozmiar y
dd 2	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 0	;zarezerwowany (ew. ilosc powtorzen czy nieskopnczonosc)
db "1",15,"2",15,"3",15,"4",15,"5",15,"6",15,"7",15,"8",15

include "menuanim.inc"
;db 15
;AnimPicture_nc:
;db 2    ;rozmiar x
;db 2    ;rozmiar y
;dd 2    ;liczba klatek
;db 0    ;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
;db 0    ;zarezerwowany (ew. ilosc powtorzen czy nieskopnczonosc)
;db "12345678"

draw_animation_frame:
	mov	edi,BVideo
	mov	esi,[ds:ebp]
	mov	bx,[ds:ebp+8]
	call	calc_v_position
	mov	edx,[ds:ebp+4]
	movzx	eax,word[esi]
	mul	ah
	shl	ax,1
	mul	edx
	add	edi,ecx
	mov	ecx,eax
	mov	ah,[esi+1]     ;ah-roz y
.next_line:
	test	ah,ah
	je	.animation_done
	mov	al,[esi]
.draw_line:
	test	al,al
	je	.line_done
	mov	dx,[esi+ecx+8]
	mov	[edi],dx
	add	ecx,2
	add	edi,2
	dec	al
	jmp	.draw_line
.line_done:
	movzx	edx,byte[esi]
	shl	edx,1
	add	edi,160
	sub	edi,edx
	dec	ah
	jmp	.next_line
.animation_done:
	ret

draw_animation_frame_nc:
	mov	edi,BVideo
	mov	esi,[ds:ebp]
	mov	bx,[ds:ebp+8]
	call	calc_v_position
	mov	edx,[ds:ebp+4]
	movzx	eax,word[esi]
	mul	ah
	mul	edx
	add	edi,ecx
	mov	ecx,eax
	mov	ah,[esi+1]     ;ah-roz y
.next_line:
	test	ah,ah
	je	.animation_done
	mov	al,[esi]
.draw_line:
	test	al,al
	je	.line_done
	mov	dl,[esi+ecx+8]
	mov	dh,[esi-1]
	mov	[edi],dx
	add	ecx,1
	add	edi,2
	dec	al
	jmp	.draw_line
.line_done:
	movzx	edx,byte[esi]
	shl	edx,1
	add	edi,160
	sub	edi,edx
	dec	ah
	jmp	.next_line
.animation_done:
	ret



db 15
AnimPicture_nc:
db 4	;rozmiar x
db 3	;rozmiar y
dd 4	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 0	;zarezerwowany (ew. ilosc powtorzen czy nieskopnczonosc)
db " () "
db " [] "
db " || "
db " () "
db "/[]\"
db " || "
db " () "
db "-[]-"
db " || "
db "\()/"
db " [] "
db " || "

update_frame:
	mov	esi,[ds:ebp]
	xor	eax,eax
	mov	edx,[ds:ebp+4]
	inc	edx
	cmp	[esi+2],edx
	cmove	edx,eax
	mov	[ds:ebp+4],edx
	ret

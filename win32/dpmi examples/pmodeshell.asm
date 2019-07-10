format mz
heap 1000h
stack 1000h
include 'loader.inc'

segment _code use32
code32:
	xor	eax,eax
	mov	ax,gs
	shl	eax,4
	mov	[APSP],eax     ;fs:APSP -32 bit adres PSP
koniec:
	xor ah,ah
	int 16h
Koniec:
	mov ax,4c00h
	int 21h


APSP	      dd      0


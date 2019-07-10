format PE GUI 4.0
include 'win32a.inc'
entry start
section '.data' data readable writeable
;program pobiera liczbe milisekund od startu windows
TTytul db 'Licznik Milisekund:',0
BWyswietl: dd 0
dd 0
BLiczba: dd 89abch
BWTemp: dd 0h
section '.code' code readable executable
start:
invoke	GetTickCount,0

mov	ebx,10h
lea	esi,[BWTemp]
lea	edi,[BWyswietl]
zrobascii:
xor	edx,edx
div	ebx
cmp	dl,0ah
jb	dzie
add	dl,57h
dalej:
mov	[esi],dl
test	eax,eax
jz	przenies
inc	esi
jmp	zrobascii
przenies:
mov	al,[esi]
mov	[edi],al
test	al,al
jz	wyswietl
inc	edi
dec	esi
jmp	przenies

dzie:
add	dl,30h
jmp dalej

wyswietl:

invoke	MessageBox,0,BWyswietl,TTytul,MB_OK
invoke	ExitProcess,0
section '.idata' import data readable writeable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
  import kernel32,\
	ExitProcess,'ExitProcess',\
	GetModuleHandle,'GetModuleHandleA',\
	GetTickCount,'GetTickCount'
  import user32,\
	MessageBox,'MessageBoxA'
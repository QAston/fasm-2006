format PE GUI 4.0
include 'win32a.inc'
entry start
section '.data' data readable writeable
TTytul db 'Liczba Hexadecynalna:',0
BWyswietl: dd 0,0,0
BLiczba: dd 0ffffffffh
db 0
BWTemp: dd 0h
db 0
section '.code' code readable executable
start:
mov	eax,[BLiczba]
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
mov	byte [edi],'h'
invoke	MessageBox,0,BWyswietl,TTytul,MB_OK
invoke	ExitProcess,0
section '.idata' import data readable writeable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
  import kernel32,\
	ExitProcess,'ExitProcess',\
	GetModuleHandle,'GetModuleHandleA'
  import user32,\
	MessageBox,'MessageBoxA'
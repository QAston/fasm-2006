format PE GUI 4.0
include 'win32a.inc'
entry start
section '.data' data readable writeable
TTytul db 'Liczba Hexadecynalna:',0
BWyswietl: times 8 db 0
db "h"
db 0
BLiczba: dd 0134abcdh
section '.code' code readable executable
start:
mov	eax,[BLiczba]
mov	ecx,10000000h
lea	edi,[BWyswietl]
xor bx,bx
petla:
xor	edx,edx
div	ecx
cmp	al,0ah
jb	dzie
add	al,57h
dalej:
mov	[edi],al
test	edx,edx
jz	kon
inc	edi
shr	ecx,4
mov	eax,edx
jmp	petla
dzie:
add	al,30h
jmp dalej

kon:
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
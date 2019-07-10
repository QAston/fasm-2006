format PE GUI 4.0
include 'win32a.inc'
entry start
section '.data' data readable writeable
TTytul db 'Liczba Hexadecynalna:',0
BWyswietl dd 0,0,0
BLiczba: dd 0ffffffffh ,0
section '.code' code readable executable
start:
mov	eax,[BLiczba]
mov	ebx,10d
mov	ecx,1000000000d
lea	edi,[BWyswietl]
petla:
xor	edx,edx
div	ecx
add	al,30h
mov	[edi],al
test	edx,edx
jz	kon
mov	eax,ecx
push	edx
xor	edx,edx
div	ebx
mov	ecx,eax
inc	edi
pop	eax
jmp	petla

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
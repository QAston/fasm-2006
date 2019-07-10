format PE GUI 4.0
include 'win32ax.inc'
entry start
macro dzwiek arg1,arg2
{
invoke Beep,arg1,arg2
}
proc sprdata
locals
syt SYSTEMTIME
endl
invoke GST,addr syt
mov ax,[syt.wMonth]
mov bx,[syt.wDay]
cmp ax,1
jne koniec
cmp bx,6
jne koniec
ret
endp
zyczenia db 'Jakieœ tam ¿yczenia!!!',0
tytul db 'Wszystkiego najlepszego!!!',0
pytanie db 'Czy chcesz jeszcze raz?',0
cze1 equ 37
cze2 equ 900
cze3 equ 1000
dlu1 equ 200
dlu2 equ 180
dlu3 equ 300
dlu4 equ 120
dlu5 equ 100
dlu6 equ 220
dlu7 equ 250
dlu8 equ 150
dlu9 equ 130
dlu10 equ 280
section '.code' code executable
start:
call sprdata
mov bx,3
dzwieki:
dec bx
dzwiek cze1,dlu1
dzwiek cze2,dlu2
dzwiek cze1,dlu3
dzwiek cze3,dlu4
dzwiek cze1,dlu1
dzwiek cze3,dlu5
dzwiek cze1,dlu5
dzwiek cze3,dlu5
dzwiek cze1,dlu5
dzwiek cze3,dlu5
dzwiek cze1,dlu5
dzwiek cze3,dlu5
dzwiek cze1,dlu5
dzwiek cze3,dlu6
dzwiek cze1,dlu7
dzwiek cze2,dlu6
cmp bx,0
jne dzwieki
dzwieki2:
dzwiek cze1,dlu5
dzwiek cze2,dlu8
dzwiek cze1,dlu4
dzwiek cze2,dlu8
dzwiek cze1,dlu4
dzwiek cze2,dlu1
dzwiek cze1,dlu9
dzwiek cze3,dlu1
dzwiek cze1,dlu10
dzwiek cze2,dlu8
dzwiek cze1,dlu8
dzwiek cze3,dlu7
kom:
invoke MessageBox,0,zyczenia,tytul,MB_OK or MB_DEFBUTTON1 or MB_ICONINFORMATION
invoke MessageBox,0,pytanie,tytul,MB_YESNO or MB_DEFBUTTON1 or MB_ICONQUESTION
cmp eax,IDYES
je start
koniec:
invoke ExitProcess,0
section '.idata' import data readable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
 import kernel32,ExitProcess,'ExitProcess',Beep,'Beep',GST,'GetSystemTime'
 import user32,MessageBox,'MessageBoxA'
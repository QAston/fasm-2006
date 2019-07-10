format PE GUI 4.0
include 'win32ax.inc'
entry start
macro dzwiek arg1,arg2
{
invoke Beep,arg1,arg2
}
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
section '.data' data readable writeable
hInstance dd 0
hwnd dd 0
zyczenia db 'Jakies tam zyczenia',0
tytul db 'Wszystkiego najlepszego!!!',0
pytanie db 'Czy chcesz jeszcze raz?',0
klasa db 'widowc1',0
section '.code' code executable
start:
call sprdata
call window
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

proc sprdata
locals
syt SYSTEMTIME
endl
invoke GST,addr syt
mov ax, word [syt.wMonth]
mov bx, word [syt.wDay]
cmp ax,1
jne koniec
cmp bx,20
jne koniec
ret
endp

proc window
locals
wc WNDCLASSEX
msg MSG
endl
invoke GMH,0
mov [hInstance],eax
mov [wc.cbSize],48
mov [wc.style],CS_VREDRAW or CS_HREDRAW
mov [wc.lpfnWndProc],winproc
mov [wc.cbClsExtra],0
mov [wc.cbWndExtra],0
mov [wc.hInstance],eax
mov [wc.hIcon],0
mov [wc.hCursor],0
mov [wc.hbrBackground],COLOR_BACKGROUND
mov [wc.lpszMenuName],0
mov [wc.lpszClassName],klasa
mov [wc.hIcon],0
invoke RegC,addr wc
invoke CreWin,0,addr klasa,addr tytul,WS_OVERLAPPEDWINDOW,\
CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,0,0,[hInstance],0
mov [hwnd],eax
invoke SW,[hwnd],SW_SHOWDEFAULT
invoke UW,[hwnd]
    msgloop:
      invoke GM,addr msg,NULL,0,0
      cmp eax,0
      je kom
      invoke TM,addr msg
      invoke DM,addr msg
    jmp msgloop
ret
endp
proc winproc hWnd:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
cmp [uMsg],WM_DESTROY
jne dalej
    invoke PQM,0
dalej:
    invoke DWP,[hWnd],[uMsg],[wParam],[lParam]
    ret
endp
section '.idata' import data readable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
 import kernel32,\
	ExitProcess,'ExitProcess',\
	Beep,'Beep',\
	GST,'GetSystemTime',\
	GMH,'GetModuleHandleA'
 import user32,\
	MessageBox,'MessageBoxA',\
	RegC,'RegisterClassExA',\
	CreWin,'CreateWindowExA',\
	SW,'ShowWindow',\
	GM,'GetMessageA',\
	TM,'TranslateMessage',\
	DM,'DispatchMessageA',\
	DWP,'DefWindowProcA',\
	PQM,'PostQuitMessage',\
	UW,'UpdateWindow'

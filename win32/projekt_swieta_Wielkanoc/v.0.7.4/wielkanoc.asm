format PE GUI 4.0
include 'win32ax.inc'
include 'encoding\win1250.inc'
macro dzwiek arg1,arg2
{
invoke Beep,arg1,arg2
}
entry start
section '.data' data readable writeable
GFX1 equ 5
wc WNDCLASSEX
msg MSG
hInstance dd ?
HWND dd ?
HGFX1 dd ?
licz db ?
CStatic db "STATIC",0
CKlasa db 'WinClass',0
TZyczenia db 'Du¿o zdrowia, szêœcia, weso³ego jajka, du¿o prezentów, dobrej zabawy i smacznego baranka ¿yczy Ci Darek',0
TTytul db 'Wszystkiego najlepszego!!!',0
TPytanie db 'Czy chcesz jeszcze raz?',0
section '.code' code readable executable
start:
call window
kom:
invoke MessageBox,0,TZyczenia,TTytul,MB_OK or MB_DEFBUTTON1 or MB_ICONINFORMATION
cmp [licz],1
jb koniec
invoke MessageBox,0,TPytanie,TTytul,MB_YESNO or MB_DEFBUTTON1 or MB_ICONQUESTION
cmp eax,IDNO
je koniec
call dzwiecz
jmp kom
koniec:
invoke ExitProcess,0

proc dzwiecz
dzwieki:
dzwiek 700,150
dzwiek 800,150
dzwiek 900,150
dzwiek 1000,150
ret
endp

proc sprdata
locals
syt SYSTEMTIME
endl
invoke GST,addr syt
mov ax, word [syt.wMonth]
mov bx, word [syt.wDay]
cmp ax,4
jne koniec
cmp bx,8
jne koniec
ret

endp
proc window
invoke GMH,0
mov [hInstance],eax
mov [wc.cbSize],sizeof.WNDCLASSEX
mov [wc.style],CS_VREDRAW or CS_HREDRAW
mov[wc.lpfnWndProc],winproc
mov [wc.cbClsExtra],0
mov [wc.cbWndExtra],0
mov [wc.hInstance],eax
invoke LI,eax,17
mov [wc.hIcon],eax
mov [wc.hIconSm],eax
invoke LC,0,IDC_ARROW
mov [wc.hCursor],eax
mov [wc.hbrBackground],COLOR_BACKGROUND
mov [wc.lpszMenuName],0
mov [wc.lpszClassName],CKlasa
invoke RegC,wc
invoke CreWin,0,CKlasa,TTytul,WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
CW_USEDEFAULT,648,510,NULL,NULL,[hInstance],NULL
mov [HWND],eax
invoke SW,eax,SW_SHOWDEFAULT
invoke UW,[HWND]
	nasza_petla:
		invoke GM,msg,0,0,0
		cmp eax,0
		je	koniec_while
		invoke TM,msg
		invoke DM,msg
		jmp	short nasza_petla
	koniec_while:
	mov	eax,[msg.wParam]
	ret
endp
proc winproc  hwnd,wmsg,wparam,lparam
	mov	eax,[wmsg]
	cmp	eax,WM_DESTROY
	je	.wmdestroy
	cmp	eax,WM_CREATE
	je	.wmcreate
	cmp	eax,WM_KEYDOWN
	je	.wmkeydown
	cmp	[licz],0
	jne	.finish
	cmp	eax,WM_COMMAND
	je	.wmcommand
    .defwindowproc:
	invoke	DWP,[hwnd],[wmsg],[wparam],[lparam]
	jmp	.finish
    .wmdestroy:
	invoke	PQM,0
	xor	eax,eax
	jmp	.finish
    .wmcreate:
	invoke CreWin,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],GFX1,[hInstance], 0
	mov    [HGFX1],eax
	invoke LB,[hInstance],19
	invoke SM,[HGFX1],STM_SETIMAGE,IMAGE_BITMAP,eax
	xor eax,eax
	jmp .finish
    .wmkeydown:
	inc [licz]
	cmp [wparam],VK_ESCAPE
	je koniec
    .wmcommand:
	inc [licz]
	invoke CreWin,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],GFX1,[hInstance], 0
	mov    [HGFX1],eax
	invoke LB,[hInstance],18
	invoke SM,[HGFX1],STM_SETIMAGE,IMAGE_BITMAP,eax
	call dzwiecz
	jmp kom
    .finish:
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
	SetFocus,'SetFocus',\
	EndPaint,'EndPaint',\
	TextOut,'TabbedTextOutA',\
	BeginPaint,'BeginPaint',\
	GetWindowText,'GetWindowTextA',\
	MessageBox,'MessageBoxA',\
	RegC,'RegisterClassExA',\
	CreWin,'CreateWindowExA',\
	SW,'ShowWindow',\
	GM,'GetMessageA',\
	TM,'TranslateMessage',\
	DM,'DispatchMessageA',\
	DWP,'DefWindowProcA',\
	PQM,'PostQuitMessage',\
	UW,'UpdateWindow',\
	LI,'LoadIconA',\
	LC,'LoadCursorA',\
	LB,'LoadBitmapA',\
	SM,'SendMessageA'

section '.rsrc' resource data readable
directory\
RT_ICON,icons,\
RT_GROUP_ICON,group_icons,\
RT_BITMAP,bitmaps
resource icons,\
	   1,LANG_NEUTRAL,icon_data
resource group_icons,\
	   17,LANG_NEUTRAL,main_icon
resource bitmaps,\
18,LANG_NEUTRAL,pekr,\
19,LANG_NEUTRAL,dekr

icon main_icon,icon_data,'data\main.ico'
bitmap pekr,'data\ekr.bmp'
bitmap dekr,'data\2ekr.bmp'

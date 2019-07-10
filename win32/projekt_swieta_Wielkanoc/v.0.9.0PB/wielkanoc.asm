format PE GUI 4.0
include 'win32axp.inc'
include 'bibl\doascii.asm'
include 'encoding\win1250.inc'
macro dzwiek arg1,arg2
{invoke Beep,arg1,arg2}
entry start
section '.data' data readable writeable
Edit equ 1
Button equ 3
GFX1 equ 5
wc WNDCLASSEX
msg MSG
licz db ?
hInstance dd ?
HWND dd ?
hGFX1 dd ?
hEdit dd ?
hButton dd ?
bufor: times 45 db 0
zyczenia db ' ,du¿o zdrowia, szêœcia, weso³ego jajka, mnóstwa prezentów, dobrej zabawy, smacznego baranka z ro¿na i ¿eby Ci jajca nie przeœmiard³y :P, ¿yczy Darek',0
nzyczenia: times 200 db 0
wyswietl: times 246 db 0
CStatic db "STATIC",0
polecenie db "Wpisz swoje imiê:"
polecenie2 db "¯yczenia:"
CButton db 'button',0
CEdit db 'edit',0
CEdit2 db 'edit',0
klasa db 'WinClass',0
klasa2 db 'WinClass2',0
tytul db 'Wszystkiego najlepszego!!!',0
pytanie db 'Czy chcesz jeszcze raz? Jak ¿yczenia Ci siê nie spodoba³y to je ANULUJ i wpisz swoje! (Tylko 245 znaków!)',0
TButton db 'OK!'
section '.code' code readable executable
start:
call sprdata
call window1
dalej:
call window2
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
proc window1
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
mov [wc.hbrBackground],COLOR_WINDOW+1
mov [wc.lpszMenuName],0
mov [wc.lpszClassName],klasa
invoke RegC,wc
invoke CreWin,0,klasa,tytul,WS_POPUP or WS_SYSMENU or WS_CAPTION ,CW_USEDEFAULT,\
CW_USEDEFAULT,644,560,NULL,NULL,[hInstance],NULL
mov [HWND],eax
invoke SW,eax,SW_SHOWDEFAULT
invoke UW,[HWND]
  .msg_loop:
	invoke	GM,msg,NULL,0,0
	cmp	eax,1
	jb	.end_loop
	jne	.msg_loop
	invoke	TM,msg
	invoke	DM,msg
	jmp	.msg_loop
  .end_loop:
	cmp [licz],3
	je	dalej
	invoke	ExitProcess,[msg.wParam]
ret
endp
proc winproc  hwnd,wmsg,wparam,lparam
locals
ps PAINTSTRUCT
endl
	mov	eax,[wmsg]
	cmp	eax,WM_DESTROY
	je	.wmdestroy
	cmp	eax,WM_KEYDOWN
	je	.wmkeydown
	cmp	eax,WM_PAINT
	je	.wmpaint
	cmp	eax,WM_COMMAND
	je	.wmcommand
	cmp	eax,WM_CREATE
	je	.wmcreate
    .defwindowproc:
	invoke	DWP,[hwnd],[wmsg],[wparam],[lparam]
	jmp	.finish
    .wmpaint:
	cmp [licz],1
	jb .wmnpaint
	invoke BeginPaint,[hwnd],addr ps
	mov  [ps.hdc],eax
	cmp [licz],1
	jne .wmdpaint
	invoke CreWin,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],60,[hInstance], 0
	mov    [hGFX1],eax
	invoke LB,[hInstance],18
	invoke SM,[hGFX1],STM_SETIMAGE,IMAGE_BITMAP,eax
     .wmdpaint:
	invoke TTextOut,[ps.hdc],5,500,addr polecenie,17,0,0,0
	test eax,eax
	jz .wmpaint
	invoke EndPaint,[hwnd],addr ps
    .wmnpaint:
	invoke UW,[hwnd]
	jmp .finish
    .wmcreate:
	invoke CreWin,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],GFX1,[hInstance], 0
	mov    [hGFX1],eax
	invoke LB,[hInstance],19
	invoke SM,[hGFX1],STM_SETIMAGE,IMAGE_BITMAP,eax
	jmp .finish
    .wmkeydown:
	cmp [wparam],VK_ESCAPE
	je .wmdestroy
    .wmcommand:
	mov	eax,[wparam]
	cmp	ax,Button
	je	.wmcom1
	cmp	ax,GFX1
	jne	.finish
	cmp	[licz],1
	jae	 .finish
	invoke CreWin,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],60,[hInstance], 0
	mov    [hGFX1],eax
	invoke LB,[hInstance],18
	invoke SM,[hGFX1],STM_SETIMAGE,IMAGE_BITMAP,eax
	inc    [licz]
	call   dzwiecz
	invoke CreWin,WS_EX_CLIENTEDGE,CEdit,0,WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL,200,497,200,25,[hwnd],Edit,[hInstance],0
	mov    [hEdit],eax
	invoke SetFocus,hEdit
	invoke CreWin,0,CButton,TButton,WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,500,498,80,25,[hwnd],3,[hInstance],0
	mov    [hButton],eax
	jmp    .finish
    .pkon:
	inc	[licz]
	jmp .wmdestroy
    .wmcom1:
	inc	[licz]
	invoke GetWindowText,[hEdit],bufor,45
	test   eax,eax
	jz     .finish
	mov    ebx,eax
	lea    esi,[bufor]
	mov    ax,ds
	mov    es,ax
	lea    edi,[wyswietl]
	cld
	xor	ecx,ecx
    .pimienia:
	movsb
	inc	ecx
	cmp    ebx,ecx
	jne    .pimienia
	lea    esi,[zyczenia]
	lea    edi,[wyswietl+ebx]
	mov    ecx,50
    .pzyczen:
	movsd
	dec	ecx
	test	ecx,ecx
	jnz	.pzyczen
    .pkom:
	cmp [licz],2
	jb .wmdestroy
	invoke MessageBox,[hwnd],wyswietl,tytul,MB_OK or MB_DEFBUTTON1 or MB_ICONWARNING
	cmp eax,IDOK
	invoke MessageBox,[hwnd],pytanie,tytul,MB_YESNOCANCEL or MB_DEFBUTTON1 or MB_ICONQUESTION
	cmp eax,IDCANCEL
	je  .pkon
	cmp eax,IDYES
	jne .wmdestroy
	call dzwiecz
	jmp .pkom
    .wmdestroy:
	invoke DestroyWindow,[HWND]
	invoke	PQM,0
	xor	eax,eax
    .finish:
ret
endp
proc window2
mov[wc.lpfnWndProc],winproc2
mov [wc.lpszClassName],klasa2
invoke RegC,wc
invoke CreWin,WS_EX_TOPMOST,klasa2,tytul,WS_POPUP or WS_SYSMENU or WS_CAPTION,CW_USEDEFAULT,\
CW_USEDEFAULT,540,65,NULL,NULL,[hInstance],NULL
mov [HWND],eax
invoke SW,eax,SW_SHOWDEFAULT
invoke UW,[HWND]
  .msg_loop:
	invoke	GM,msg,NULL,0,0
	cmp	eax,1
	jb	.end_loop
	jne	.msg_loop
	invoke	TM,msg
	invoke	DM,msg
	jmp	.msg_loop
  .end_loop:
	invoke	ExitProcess,[msg.wParam]
ret
endp
proc winproc2 hwnd,wmsg,wparam,lparam
locals
ps PAINTSTRUCT
endl
	mov	eax,[wmsg]
	cmp	eax,WM_DESTROY
	je	.wmdestroy
	cmp	eax,WM_CREATE
	je	.wmcreate
	cmp	eax,WM_KEYDOWN
	je	.wmkeydown
	cmp	eax,WM_COMMAND
	je	.wmcommand
    .defwindowproc:
	invoke	DWP,[hwnd],[wmsg],[wparam],[lparam]
	jmp	.finish
    .wmcreate:
	invoke CreWin,WS_EX_CLIENTEDGE,CEdit,0,WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL,100,0,400,25,[hwnd],Edit,[hInstance],0
	mov    [hEdit],eax
	invoke SetFocus,hEdit
	invoke CreWin,0,CButton,TButton,WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,0,0,80,25,[hwnd],3,[hInstance],0
	mov    [hButton],eax
	jmp .finish
    .wmkeydown:
	cmp [wparam],VK_ESCAPE
	je koniec
	jmp .finish
    .wmcommand:
	mov	eax,[wparam]
	cmp	ax,Button
	jne	.finish
	invoke GetWindowText,[hEdit],nzyczenia,245
	test   eax,eax
	jz     .finish
	mov    ebx,eax
	lea    esi,[nzyczenia]
	mov    ax,ds
	mov    es,ax
	lea    edi,[wyswietl]
	cld
	mov    ecx,50
    .pnzyczenia:
	movsd
	dec	ecx
	test	ecx,ecx
	jnz	.pnzyczenia
	invoke MessageBox,[hwnd],wyswietl,tytul,MB_OK or MB_DEFBUTTON1 or MB_ICONWARNING
	invoke ExitProcess,0
    .wmdestroy:
	invoke PQM,0
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
	DestroyWindow ,'DestroyWindow',\
	RedrawWindow,'RedrawWindow',\
	SetFocus,'SetFocus',\
	EndPaint,'EndPaint',\
	TTextOut,'TabbedTextOutA',\
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
RT_BITMAP,bitmaps,\
RT_VERSION,versions
resource icons,\
	1,LANG_NEUTRAL,icon_data
resource group_icons,\
	17,LANG_NEUTRAL,main_icon
resource bitmaps,\
	18,LANG_NEUTRAL,pekr,\
	19,LANG_NEUTRAL,dekr
resource versions,\
	1,LANG_NEUTRAL,version
 versioninfo version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
	      'FileDescription','Program ¿yczeniowy',\
	      'LegalCopyright','Wszystkie prawa zastrze¿one dla Dariusza Antoniuka.',\
	      'FileVersion','1.0',\
	      'ProductVersion','1.0',\
	      'OriginalFilename','Wielkanoc.exe',\
	      "Autor", "Dariusz Antoniuk",\
	      "Data wydania", "8.02.2007",\
	      "ProductName", "Wielkanoc",\
	      "Narzêdzia", "Program zosta³ skompilowany za pomoc¹ FASM-a, rysunki zosta³y zrobione w MS Paint",\
	      "Comments", "Program napisany specjalnie dla Agaty i Pauliny Antoniuk. Dzia³a tylko 8 Kwietnia!!!"

icon main_icon,icon_data,'data\main.ico'
bitmap pekr,'data\ekr.bmp'
bitmap dekr,'data\2ekr.bmp'

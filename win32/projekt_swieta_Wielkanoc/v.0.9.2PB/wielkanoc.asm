format PE GUI 4.0
include 'win32axp.inc'
include 'encoding\win1250.inc'
macro dzwiek arg1,arg2
{invoke Beep,arg1,arg2}
entry start
section '.data' data readable writeable
IDEdit1 equ 1
IDButton1 equ 3
IDGfx1 equ 5
;***
HInstance dd ?
HWND dd ?
HWrite dd ?
HGfx1 dd ?
HEdit dd ?
HButton dd ?
;***
TFile dw 600,0
wc WNDCLASSEX
msg MSG
;***
licz db ?
Liczba db 0
LiczbaC db 200
;***
CStatic db "STATIC",0
CButton db 'button',0
CEdit db 'edit',0
CKlasa db 'WinClass',0
;***
TButton db 'OK!',0
TPolecenie db "Wpisz swoje imiê:"
TTytul db 'Wszystkiego najlepszego!!!',0
TPytanie db 'Czy chcesz jeszcze raz?',0
;***
PDane db 'edytor\dane.bin',0
;***
BWyswietl: times 600 db 0
BImie: times 47 db 0
BData: times 600 rb 0
virtual at BData
VBZyczenia: times 500 db 0
VBDar:times 15 db 0 ;516b
VBLicz dw 0  ;liczba znaków do ¿yczeñ
VBMiesASCII dd 0
VBDzienASCII dd 0
VBMies dw 0,0
VBDzien dw 0,0
VBUru db 0
VBDarek db 0
VBUruch db 0
end virtual

;***
section '.code' code readable executable
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
invoke GetSystemTime,addr syt
mov ax, word [syt.wMonth]
mov bx, word [syt.wDay]
cmp ax,word [VBMies]
jne koniec
cmp bx,word [VBDzien]
jne koniec
ret
endp
    start:
       invoke CreateFile,PDane,GENERIC_READ,0,0,OPEN_ALWAYS,0,0
       mov    [HWrite],eax
       invoke ReadFile,[HWrite],BData,600,TFile,0
       invoke CloseHandle,[HWrite]
       call sprdata
       cmp    [VBUru],0
       je     uruchom
       cmp    [VBUruch],0
       jne    koniec
       inc    [VBUruch]
       invoke CreateFile,PDane,GENERIC_WRITE,0,0,OPEN_ALWAYS,0,0
       mov    [HWrite],eax
       invoke WriteFile,eax,BData,600,TFile,0
       invoke CloseHandle,[HWrite]
   uruchom:
       invoke GetModuleHandle,0
       mov [HInstance],eax
       mov [wc.cbSize],sizeof.WNDCLASSEX
       mov [wc.style],CS_VREDRAW or CS_HREDRAW
       mov[wc.lpfnWndProc],winproc
       mov [wc.cbClsExtra],0
       mov [wc.cbWndExtra],0
       mov [wc.hInstance],eax
       invoke LoadIcon,eax,17
       mov [wc.hIcon],eax
       mov [wc.hIconSm],eax
       invoke LoadCursor,0,IDC_ARROW
       mov [wc.hCursor],eax
       mov [wc.hbrBackground],COLOR_WINDOW+1
       mov [wc.lpszMenuName],0
       mov [wc.lpszClassName],CKlasa
       invoke RegirsterClassEx,wc
       invoke CreateWindowEx,0,CKlasa,TTytul,WS_POPUP or WS_SYSMENU or WS_CAPTION ,CW_USEDEFAULT,\
       CW_USEDEFAULT,644,560,NULL,NULL,[HInstance],NULL
       mov [HWND],eax
       invoke ShowWindow,eax,SW_SHOWDEFAULT
       invoke UpdateWindow,[HWND]
   .msg_loop:
	invoke	GetMessage,msg,NULL,0,0
	cmp	eax,1
	jb	.end_loop
	jne	.msg_loop
	invoke	TranslateMessage,msg
	invoke	DispatchMessage,msg
	jmp	.msg_loop
   .end_loop:
   koniec:
invoke ExitProcess,0

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
	invoke	DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
	jmp	.finish
    .wmpaint:
	cmp	[licz],1
	jb	.wmnpaint
	invoke	BeginPaint,[hwnd],addr ps
	mov	[ps.hdc],eax
	cmp	[licz],1
	jne	.wmdpaint
	invoke	CreateWindowEx,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],60,[HInstance], 0
	mov	[HGfx1],eax
	invoke	LoadBitmap,[HInstance],18
	invoke	SendMessage,[HGfx1],STM_SETIMAGE,IMAGE_BITMAP,eax
     .wmdpaint:
	invoke	TabbedTextOut,[ps.hdc],5,500,addr TPolecenie,17,0,0,0
	test	eax,eax
	jz	.wmpaint
	invoke	EndPaint,[hwnd],addr ps
    .wmnpaint:
	invoke	UpdateWindow,[hwnd]
	jmp	.finish
    .wmcreate:
	invoke	CreateWindowEx,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],IDGfx1,[HInstance], 0
	mov	[HGfx1],eax
	invoke	LoadBitmap,[HInstance],19
	invoke	SendMessage,[HGfx1],STM_SETIMAGE,IMAGE_BITMAP,eax
	jmp	.finish
    .wmkeydown:
	cmp	[wparam],VK_ESCAPE
	je	.wmdestroy
    .wmcommand:
	mov	eax,[wparam]
	cmp	ax,IDButton1
	je	.wmcom1
	cmp	ax,IDGfx1
	jne	.finish
	cmp	[licz],1
	jae	.finish
	invoke	CreateWindowEx,0,CStatic,0,WS_CHILD or WS_VISIBLE or SS_BITMAP or SS_NOTIFY,0,0,640,480,[hwnd],60,[HInstance], 0
	mov	[HGfx1],eax
	invoke	LoadBitmap,[HInstance],18
	invoke	SendMessage,[HGfx1],STM_SETIMAGE,IMAGE_BITMAP,eax
	inc	[licz]
	call	dzwiecz
	invoke	CreateWindowEx,WS_EX_CLIENTEDGE,CEdit,0,WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL,200,497,200,25,[hwnd],IDEdit1,[HInstance],0
	mov	[HEdit],eax
	invoke	SetFocus,HEdit
	invoke	CreateWindowEx,0,CButton,TButton,WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,500,498,80,25,[hwnd],3,[HInstance],0
	mov	[HButton],eax
	jmp	.finish
    .pkon:
	inc	[licz]
	jmp	.wmdestroy
    .wmcom1:
	inc	[licz]
	invoke	GetWindowText,[HEdit],BImie,45
	test	eax,eax
	jz	.finish
	mov	ebx,eax
	lea	esi,[BImie]
	mov	ax,ds
	mov	es,ax
	lea	edi,[BWyswietl]
	cld
	xor	ecx,ecx
    .pimienia:
	movsb
	inc	ecx
	cmp	ebx,ecx
	jne	.pimienia
	mov	byte [BWyswietl+ebx],'!'
	inc	ebx
	mov	byte [BWyswietl+ebx],' '
	inc	ebx
	lea	esi,[VBZyczenia]
	lea	edi,[BWyswietl+ebx]
	mov	ecx,500
    .pzyczen:
	movsb
	dec	ecx
	test	ecx,ecx
	jnz	.pzyczen
    .pkom:
	cmp	[licz],2
	jb	.wmdestroy
	invoke	MessageBox,[hwnd],BWyswietl,TTytul,MB_OK or MB_DEFBUTTON1 or MB_ICONWARNING
	cmp	eax,IDOK
	invoke	MessageBox,[hwnd],TPytanie,TTytul,MB_YESNO or MB_DEFBUTTON1 or MB_ICONQUESTION
	cmp	eax,IDYES
	jne	.wmdestroy
	call	dzwiecz
	jmp	.pkom
    .wmdestroy:
	invoke	DestroyWindow,[hwnd]
	invoke	PostQuitMessage,0
	xor	eax,eax
    .finish:
ret
endp
section '.idata' import data readable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
 import kernel32,\
	ExitProcess,'ExitProcess',\
	Beep,'Beep',\
	GetSystemTime,'GetSystemTime',\
	GetModuleHandle,'GetModuleHandleA',\
	CreateFile,'CreateFileA',\
	ReadFile,'ReadFile',\
	WriteFile,'WriteFile',\
	CloseHandle,'CloseHandle'
 import user32,\
	DestroyWindow ,'DestroyWindow',\
	SetWindowText,'SetWindowTextA',\
	RedrawWindow,'RedrawWindow',\
	SetFocus,'SetFocus',\
	EndPaint,'EndPaint',\
	TabbedTextOut,'TabbedTextOutA',\
	BeginPaint,'BeginPaint',\
	GetWindowText,'GetWindowTextA',\
	MessageBox,'MessageBoxA',\
	RegirsterClassEx,'RegisterClassExA',\
	CreateWindowEx,'CreateWindowExA',\
	ShowWindow,'ShowWindow',\
	GetMessage,'GetMessageA',\
	TranslateMessage,'TranslateMessage',\
	DispatchMessage,'DispatchMessageA',\
	DefWindowProc,'DefWindowProcA',\
	PostQuitMessage,'PostQuitMessage',\
	UpdateWindow,'UpdateWindow',\
	LoadIcon,'LoadIconA',\
	LoadCursor,'LoadCursorA',\
	LoadBitmap,'LoadBitmapA',\
	SendMessage,'SendMessageA'
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
	      "Data wydania", "8.04.2007",\
	      "ProductName", "Wielkanoc",\
	      "Narzêdzia", "Program zosta³ skompilowany za pomoc¹ FASM-a, rysunki zosta³y zrobione w MS Paint",\
	      "Comments", "Program napisany specjalnie dla Agaty i Pauliny Antoniuk!!!"

icon main_icon,icon_data,'data\main.ico'
bitmap pekr,'data\ekr.bmp'
bitmap dekr,'data\2ekr.bmp'

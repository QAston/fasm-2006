format PE GUI 4.0
include 'win32axp.inc'
entry start
section '.data' data readable writeable
IDEdit1 equ 11
IDEdit2 equ 12
IDEdit3 equ 13
IDButton1 equ 1
IDButton2 equ 2
IDButton3 equ 3
IDButton4 equ 4

HEdit1 dd ?
HEdit2 dd ?
HEdit3 dd ?
HButton1 dd ?
HButton2 dd ?
HButton3 dd ?
HButton4 dd ?
HInstance dd ?
HWrite dd ?
HWND dd ?
CKlasa db 'WindClass1',0
CStatic db 'STATIC',0
CButton db 'BUTTON',0
CEdit db 'EDIT',0

TFile dw 600,0
wc WNDCLASSEX
msg MSG

PDane db 'dane.bin',0
TBlad db 'W podanej dacie wyst¹pi³ b³¹d. Podaj datê jeszcze raz.',0
TTytul db 'Edytor dla programu Wielkanoc.exe',0
TCzyt db 'Czytaj',0
TZycz db 'Tu wpisz ¿yczenia [najwy¿ej 500 znaków!]:',0
TData db 'Tu wpisz date najbli¿szej wielkanocy [dd][mm]:',0
TUru db 'Program ma uruchamiac siê tylko raz dziennie.',0
TDar db 'Na koñcu ¿yczeñ bêdzie [ ,¿yczy Darek].',0
TZmien db 'Zapisz zmiany',0
TButton db 'OK!',0
TZyczdar db ' ,¿yczy Darek',0

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

section '.code' code readable executable
start:
invoke CreateFile,PDane,GENERIC_READ,0,0,OPEN_ALWAYS,0,0
mov [HWrite],eax
invoke ReadFile,[HWrite],BData,600,TFile,0
invoke CloseHandle,[HWrite]
mov [VBUruch],0
invoke GetModuleHandle,0
mov [HInstance],eax
mov [wc.cbSize],sizeof.WNDCLASSEX
mov [wc.style],CS_VREDRAW or CS_HREDRAW
mov [wc.cbClsExtra],0
mov [wc.cbWndExtra],0
mov [wc.hInstance],eax
mov [wc.lpfnWndProc],WinProc
invoke LoadIcon,0,IDI_APPLICATION
mov [wc.hIcon],eax
mov [wc.hIconSm],eax
invoke LoadCursor,0,IDC_ARROW
mov [wc.hCursor],eax
mov [wc.hbrBackground],COLOR_WINDOW

mov [wc.lpszMenuName],0
mov [wc.lpszClassName],CKlasa
invoke RegirsterClassEx,wc
invoke CreateWindowEx,0,CKlasa,TTytul,WS_POPUP or WS_CAPTION or WS_SYSMENU,CW_USEDEFAULT,\
CW_USEDEFAULT,640,200,NULL,NULL,[HInstance],NULL
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
proc WinProc hwnd,wmsg,wparam,lparam
locals
ps PAINTSTRUCT
endl
	mov	eax,[wmsg]
	cmp	eax,WM_ACTIVATE
	je	.wmactivate
	cmp	eax,WM_COMMAND
	je	.wmcommand
	cmp	eax,WM_PAINT
	je	.wmpaint
	cmp	eax,WM_DESTROY
	je	.wmdestroy
	cmp	eax,WM_CREATE
	je	.wmcreate
     .defwindowproc:
	invoke	DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
	jmp	.finish
    .wmpaint:
	invoke BeginPaint,[hwnd],addr ps
	mov  [ps.hdc],eax
	invoke TabbedTextOut,[ps.hdc],0,50,addr TZycz,41,0,0,0
	invoke TabbedTextOut,[ps.hdc],5,0,addr TData,45,0,0,0
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,CEdit,0,WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT,0,25,25,25,[hwnd],IDEdit1,[HInstance],0
	mov    [HEdit1],eax
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,CEdit,0,WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL,0,75,634,25,[hwnd],IDEdit3,[HInstance],0
	mov    [HEdit3],eax
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,CEdit,0,WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT,25,25,25,25,[hwnd],IDEdit2,[HInstance],0
	mov    [HEdit2],eax
	invoke CreateWindowEx,0,CButton,TUru,WS_CHILD or WS_VISIBLE or BS_CHECKBOX,0,100,640,25,[hwnd],IDButton1,[HInstance],0
	mov    [HButton1],eax
	invoke CreateWindowEx,0,CButton,TDar,WS_CHILD or WS_VISIBLE or BS_CHECKBOX,0,125,640,25,[hwnd],IDButton2,[HInstance],0
	mov    [HButton2],eax
	invoke CreateWindowEx,0,CButton,TZmien,WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,480,16,140,40,[hwnd],IDButton3,[HInstance],0
	mov    [HButton3],eax
	invoke CreateWindowEx,0,CButton,TCzyt,WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,320,16,140,40,[hwnd],IDButton4,[HInstance],0
	mov    [HButton4],eax
	invoke EndPaint,[hwnd],addr ps
	jmp    .finish
     .wmcommand:
	mov eax,[wparam]
	cmp ax,IDButton2
	jb  .wmcom1
	je  .wmcom2
	cmp ax,IDButton4
	jb  .wmcom3
	je  .wmcom4
	jmp .finish
     .wmcom1:
	invoke SendMessage,[HButton1],BM_GETCHECK,0,0
	test eax,eax
	jz   .wmcom1z
	invoke SendMessage,[HButton1],BM_SETCHECK,0,1
	jmp .finish
     .wmcom1z:
	invoke SendMessage,[HButton1],BM_SETCHECK,1,0
	jmp .finish
     .wmcom2:
	invoke SendMessage,[HButton2],BM_GETCHECK,0,0
	test eax,eax
	jz   .wmcom2z
	invoke SendMessage,[HButton2],BM_SETCHECK,0,1
	jmp .finish
     .wmcom2z:
	invoke SendMessage,[HButton2],BM_SETCHECK,1,0
	jmp .finish
     .wmcom3:
	invoke GetWindowText,[HEdit1],VBDzienASCII,4
	invoke GetWindowText,[HEdit2],VBMiesASCII,4
	invoke GetWindowText,[HEdit3],VBZyczenia,500
	mov    [VBLicz],ax
	mov al,byte [VBDzienASCII]
	sub al,'0'
	mov ah,10
	mul ah
	mov bl,byte[VBDzienASCII+1]
	sub bl,'0'
	add al,bl
	cmp al,31
	ja .blad
	mov byte[VBDzien],al
	mov al,byte [VBMiesASCII]
	sub al,'0'
	mov ah,10
	mul ah
	mov bl,byte[VBMiesASCII+1]
	sub bl,'0'
	add al,bl
	cmp al,12
	ja .blad
	mov byte[VBMies],al
	invoke SendMessage,[HButton1],BM_GETCHECK,0,0
	test eax,eax
	je   .wmcom31
	mov [VBUru],1
	jmp .wmcom32
     .wmcom31:
	mov [VBUru],0
     .wmcom32:
	invoke SendMessage,[HButton2],BM_GETCHECK,0,0
	test eax,eax
	je   .wmcom34
	mov [VBDarek],1
	mov ax,ds
	mov es,ax
	xor esi,esi
	mov si,[VBLicz]
	lea edi,[VBZyczenia]
	add edi,esi
	lea esi,[TZyczdar]
	mov cl,14
	cld
     .wmcom33:
	movsb
	dec cl
	test cl,cl
	jnz .wmcom33
     .wmcom3k:
	invoke CreateFile,PDane,GENERIC_WRITE,0,0,OPEN_ALWAYS,0,0
	mov    [HWrite],eax
	invoke WriteFile,eax,BData,600,TFile,0
	invoke CloseHandle,[HWrite]
	jmp .finish
     .wmcom34:
	mov byte [VBDarek],0
	jmp .wmcom3k
     .wmcom4:
	invoke SetWindowText,[HEdit3],VBZyczenia
	invoke SetWindowText,[HEdit1],VBDzienASCII
	invoke SetWindowText,[HEdit2],VBMiesASCII
	cmp [VBUru],1
	je .wmcom41
	invoke SendMessage,[HButton1],BM_SETCHECK,0,1
	jmp .wmcom42
     .wmcom41:
	invoke SendMessage,[HButton1],BM_SETCHECK,1,0
     .wmcom42:
	cmp [VBDarek],1
	je .wmcom43
	invoke SendMessage,[HButton2],BM_SETCHECK,0,1
	jmp .finish
     .wmcom43:
	invoke SendMessage,[HButton2],BM_SETCHECK,1,0
     .wmcreate:
	jmp .finish
     .wmactivate:
	invoke UpdateWindow,[hwnd]
	jmp .finish
     .blad:
	invoke MessageBox,[hwnd],TBlad,TTytul,0
	jmp .finish
     .wmdestroy:
	invoke PostQuitMessage,0
     .finish:
ret
endp
section '.idata' import data readable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
 import kernel32,\
	ExitProcess,'ExitProcess',\
	GetModuleHandle,'GetModuleHandleA',\
	CreateFile,'CreateFileA',\
	WriteFile,'WriteFile',\
	ReadFile,'ReadFile',\
	DeleteFile,'DeleteFileA',\
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
RT_VERSION,versions
resource versions,\
	1,LANG_NEUTRAL,version
 versioninfo version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
	      'FileDescription','Edytor danych programu Wielkanoc',\
	      'LegalCopyright','Wszystkie prawa zastrze¿one dla Dariusza Antoniuka.',\
	      'FileVersion','1.0',\
	      'ProductVersion','1.0',\
	      'OriginalFilename','edytor.exe',\
	      "Autor", "Dariusz Antoniuk",\
	      "Data wydania", "8.04.2007",\
	      "ProductName", "Wielkanoc-Edytor",\
	      "Narzêdzia", "Program zosta³ skompilowany za pomoc¹ FASM-a, rysunki zosta³y zrobione w MS Paint",\
	      "Comments", "Program napisany specjalnie dla Agaty i Pauliny Antoniuk!!!"
;-----------------------------------------------------------------------;
	call	GetModuleHandleA,0					;
	mov	UchwytProcesu,eax					;
									;
	mov	CGLW_caption, offset NazwaProgramu			;
	call	CreateGLWindow						;
;-----------------------------------------------------------------------;

;call objekt01                  ;gdy tworzymy liste obiektow

;-----------------------------------------------------------------------;
	mov	done,FALSE						;
PetlaKomunikatow:							;
									;
	call	PeekMessageA,offset Komunikat,0,0,0,PM_REMOVE		;
	test	eax,eax 						;
	jz	ZadnychKomunikatow					;
									;
	call	TranslateMessage,offset Komunikat			;
	call	DispatchMessageA,offset Komunikat			;
	cmp	done,TRUE						;
	jne	PetlaKomunikatow					;
	jmp	ZakonczProgram						;
									;
ZadnychKomunikatow:							;
	call	DrawGLScene						;
	call	SwapBuffers,hDC 					;
	cmp	done,TRUE						;
	jnz	PetlaKomunikatow					;
									;
ZakonczProgram: 							;
	call	KillGLWindow						;
									;
	call	ExitProcess,0						;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
WndProc PROC hwnd_okna:DWORD,wKomunikat:DWORD,wparam:DWORD,lparam:DWORD ;
	mov	eax,wKomunikat						;
									;
	cmp	eax,WM_KEYDOWN						;
	jz	Keydown 						;
									;
	cmp	eax,WM_KEYUP						;
	jz	Keyup							;
									;
	cmp	eax,WM_DESTROY						;
	jz	Destroy 						;
									;
	call	DefWindowProcA,hwnd_okna,wKomunikat,wparam,lparam	;
									;
ret									;
									;
Destroy:								;
	mov	done,TRUE						;
	ret								;
									;
Keydown:								;
	mov	eax,wparam						;
	mov	byte ptr KEY[eax],TRUE					;
	ret								;
									;
Keyup:									;
	mov	eax,wparam						;
	mov	byte ptr KEY[eax],FALSE 				;
	ret								;
WndProc ENDP								;
									;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
CreateGLWindow: 							;
									;
	push	0							;
	call	GetModuleHandleA					;
	mov	UchwytProcesu,eax					;
									;
	mov	[KlasaOkna.WC_style],CS_HREDRAW+CS_VREDRAW+CS_OWNDC	;
	mov	[KlasaOkna.WC_lpfnWndProc],offset WndProc		;
									;
	mov	[KlasaOkna.WC_cbClsExtra],0				;
	mov	[KlasaOkna.WC_cbWndExtra],0				;
	mov	eax,UchwytProcesu					;
	mov	[KlasaOkna.WC_hInstance],eax				;
									;
	push	32516							;
	push	0							;
	call	LoadIconA						;
	mov	[KlasaOkna.WC_hIcon],eax				;
									;
	push	32512							;
	push	0							;
	call	LoadCursorA						;
	mov	[KlasaOkna.WC_hCursor],eax				;
									;
	mov	[KlasaOkna.WC_hbrBackground],0				;
	mov	[KlasaOkna.WC_lpszMenuName],0				;
	mov	[KlasaOkna.WC_lpszClassName],offset NazwaKlasyOknaGL	;
	push	offset KlasaOkna					;
	call	RegisterClassA						;
									;
	mov	[dmScreenSettings.DM_dmSize],SIZE DEVMODE		;
	mov	ebx,CGLW_width						;
	mov	[dmScreenSettings.DM_dmPelsWidth],ebx			;
	mov	ebx,CGLW_height 					;
	mov	[dmScreenSettings.DM_dmPelsHeight],ebx			;
	xor	ebx,ebx 						;
	mov	bl,CGLW_bits						;
	mov	[dmScreenSettings.DM_dmBitsPerPel],ebx			;
	mov	[dmScreenSettings.DM_dmFields],DM_BITSPERPEL+\		;
		DM_PELSWIDTH+DM_PELSHEIGHT				;
									;
;       push    CDS_FULLSCREEN                                          ; odblokuj to
;       push    offset dmScreenSettings                                 ; jesli chcesz miec okno
;       call    ChangeDisplaySettingsA                                  ; na caly ekran
									;
	push	WS_EX_APPWINDOW 					;
	push	FALSE							;
	push	WS_POPUP						;
	push	offset WindowRect					;
	call	AdjustWindowRectEx					;
									;
	push	0							;
	push	UchwytProcesu						;
	push	0							;
	push	0							;
	push	CGLW_height						;
	push	CGLW_width						;
	push	0							;
	push	0							;
	push	WS_CLIPSIBLINGS+WS_CLIPCHILDREN+\			;
		WS_SYSMENU+WS_MINIMIZEBOX				;
	push	CGLW_caption						;
	push	offset NazwaKlasyOknaGL 				;
	push	WS_EX_APPWINDOW or WS_EX_DLGMODALFRAME			;
	call	CreateWindowExA 					;
	mov	UchwytOkna,eax						;
									;
	push	eax							;
	call	GetDC							;
	mov	hDC,eax 						;
									;
	mov	bl, CGLW_bits						;
	mov	[pfd.PFD_cColorBits],bl 				;
									;
	push	offset pfd						;
	push	eax							;
	call	ChoosePixelFormat					;
	mov	PixelFormat,eax 					;
									;
	push	offset pfd						;
	push	eax							;
	push	hDC							;
	call	SetPixelFormat						;
									;
	push	hDC							;
	call	wglCreateContext					;
	mov	hRC,eax 						;
									;
	push	hRC							;
	push	hDC							;
	call	wglMakeCurrent						;
									;
	push	SW_SHOW 						;
	push	UchwytOkna						;
	call	ShowWindow						;
									;
	push	UchwytOkna						;
	call	SetForegroundWindow					;
									;
	push	UchwytOkna						;
	call	SetFocus						;
									;
	mov	eax,CGLW_width						;
	mov	ebx,CGLW_height 					;
									;
	call	ResizeGLScene						;
	call	InitGL							;
									;
									;
ret									;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
InitGL: 								;
	push	GL_SMOOTH						;
	call	glShadeModel						;
									;
	pushfl	0.5							;
	pushfl	0.0							;
	pushfl	0.0							;
	pushfl	0.0							;
	call	glClearColor						;
									;
	push	GL_DEPTH_TEST						;
	call	glEnable						;

	call glEnable,GL_TEXTURE_2D
	call glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR
	call glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR
	call glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT
	call glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT

	call LoadTex,16,offset podloga
	mov  hPodloga,eax

	call LoadTex,16,offset sufit
	mov  hSufit,eax

	call LoadTex,16,offset sciana
	mov  hSciana,eax

									;
	push	GL_LEQUAL						;
	call	glDepthFunc						;
									;
	push	GL_LESS 						;
	call	glDepthFunc						;
									;
	push	GL_NICEST						;
	push	GL_PERSPECTIVE_CORRECTION_HINT				;
	call	glHint							;
ret									;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
KillGLWindow:								;
	push	0							;
	push	0							;
	call	ChangeDisplaySettingsA					;
									;
	push	0							;
	push	0							;
	call	wglMakeCurrent						;
									;
	push	hRC							;
	call	wglDeleteContext					;
	mov	hRC,0							;
									;
	push	hDC							;
	push	UchwytOkna						;
	call	ReleaseDC						;
									;
	push	UchwytOkna						;
	call	DestroyWindow						;
									;
	push	TRUE							;
	call	ShowCursor						;
									;
	push	UchwytProcesu						;
	push	offset NazwaKlasyOknaGL 				;
	call	UnregisterClassA					;
ret									;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
ResizeGLScene:								;
	push	CGLW_height						;
	push	CGLW_width						;
	push	0							;
	push	0							;
	call	glViewport						;
									;
	push	GL_PROJECTION						;
	call	glMatrixMode						;
									;
	call	glLoadIdentity						;
									;
	pushdfl 100.0							;
	pushdfl 0.1							;
	pushdfl 1.33333 						; obraz  4:3
	pushdfl 45.0							;
	call	gluPerspective						;
									;
	push	GL_MODELVIEW						;
	call	glMatrixMode						;
									;
	call	glLoadIdentity						;
ret									;
;-----------------------------------------------------------------------;
format MZ
use16
entry	main:start
segment main

macro PgDown
{push bx
 push dx
 xor bx,bx
 mov dx,[cs:winpos]
 add dx,[cs:disp64k]
 mov [cs:winpos],dx
 call [cs:winfunc]
 pop dx
 pop bx}

macro PgUp
 {push bx
 push dx
 xor bx,bx
 mov dx,[cs:winpos]
 sub dx,1
 mov [cs:winpos],dx
 call [cs:winfunc]
 add di,[cs:granmask]
 inc di
 pop dx
 pop bx}


start:
 call GetVESA  ;init variables related to VESA support

 mov ax,4f02h ;\
 mov bx,0101h ; VESA mode 101h (640x480x8bit)
 int 10h  ;/

 mov ax,0a000h
 mov ds,ax

 mov eax,1h  ;\
 mov ebx,13h
 mov ecx,20bh ;test Lin procedure
 mov edx,1a1h
 mov ebp,21h

 call Lin  ;/

 xor ah,ah
 int 16h
 mov ax,4c00h
 int 21h

GetVESA:
;This is just a hack to get the window-function address for a direct call,
;and to initialize variables based upon the window granularity
 mov ax,4f01h  ;\
 mov cx,0101h
 lea di,[buff]	 ; use VESA mode info call to
 push cs   ; get card stats for mode 101h
 pop es
 int 10h   ;/
 add di,4
 mov ax,word [es:di] ;get window granularity (in KB)
 shl ax,0ah
 dec ax
 mov [cs:granmask],ax  ; = granularity - 1 (in Bytes)
 not ax
 clc
GVL1: inc [cs:bitshift]  ;\
 rcl ax,1   ; just a way to get vars I need :)
 jc GVL1   ;/
 add [cs:bitshift],0fh
 inc ax
 mov [disp64k],ax
 add di,8
 mov eax,dword [es:di] ;get address of window control
 mov [cs:winfunc],eax
 ret

Lin:
;Codesegment: Lin
;Inputs: eax: x1, ebx: y1, cx: x2, dx: y2, bp: color
;Destroys: ax, bx, cx, edx, si, edi
;Global: winfunc(dd),winpos(dw),page(dw),granmask(dw),disp64k(dw),bitshift(db)
;Assumes: eax, ebx have clear high words

 cmp dx,bx   ;\
 ja LinS1   ; sort vertices
 xchg ax,cx
 xchg bx,dx   ;/

LinS1: sub cx,ax   ;\
 ja LinS2   ; calculate deltax and
 neg cx   ; modify core loop based on sign
 xor byte [cs:xinc1],28h  ;/

LinS2: sub dx,bx   ;deltay
 neg dx
 dec dx

 shl bx,7   ;\
 add ax,bx   ; calc linear start address
 lea edi,[eax+ebx*4] ;/

 mov si,dx   ;\
 xor bx,bx
 mov ax,[cs:page] ;\
 shl ax,2  ; pageOffset=page*5*disp64K
 add ax,[cs:page]
 mul [cs:disp64k] ;/
 push cx   ; initialize CPU window
 mov cl,[cs:bitshift]  ; to top of line
 shld edx,edi,cl
 pop cx
 add dx,ax
 and di,[cs:granmask]
 mov [cs:winpos],dx
 call [cs:winfunc]
 mov dx,si   ;/

 mov ax,bp
 mov bx,dx

;ax:color, bx:err-accumulator, cx:deltaX, dx:vertical count,
;di:location in CPU window, si:deltaY, bp:color

LinL1: mov [di],al   ;\
 add bx,cx
 jns LinS3
LinE1: add di,280h
 jc LinR2   ; core routine to
 inc dx   ; render line
 jnz LinL1
 jmp LinOut
LinL2: mov [di],al  ;\
xinc1: db 0
LinS3: add di,1  ; this deals with
 jc LinR1  ; horizontal pixel runs
LinE2: add bx,si
 jns LinL2  ;/
 jmp LinE1   ;/

LinR1: js LinS7   ;\
 PgDown    ; move page down 64k
 mov ax,bp
 jmp LinE2
LinS7: PgUp    ; or up by 'granularity'
 mov ax,bp
 jmp LinE2   ;/

LinR2: PgDown	 ;\
 mov ax,bp   ; move page down 64k
 inc dx
 jnz LinL1   ;/

LinOut: mov byte[cs:xinc1],0c7h
 ret

winfunc  dd ? ;fullpointer to VESA setwindow function
winpos	dw ?;temp storage of CPU window position
granmask dw ? ;masks address within window granularity
disp64k  dw ? ;number of 'granules' in 64k
page  dw 0 ;video page (0,1,2 for 1MB video)
bitshift db 0 ;used to extract high order address bits
    ;\ for setting CPU window
buff: times 100h db ?




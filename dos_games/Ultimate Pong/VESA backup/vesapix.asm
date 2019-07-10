format MZ
use16
entry	main:start
segment main
tryb_graficzny equ 103h
start:
mov ax,game_data
mov ds,ax
mov es,ax
mov ax,4f00h
lea di,[BVESAModeInfo]
int 10h
mov [AErrorCode],TVESAError1
cmp ax,004fh
jne error
mov [AErrorCode],TVESAError2
cmp [es:di],dword "VESA"
jne error
mov ax,4f01h
mov cx,tryb_graficzny
int 10h
mov [AErrorCode],TVESAError3
cmp ax,004fh
jne error
mov al,[es:di]
test al,1b
jz error
mov ax,4f03h
int 10h
mov [ds:OldVideoMode],bx
mov ax,4f02h
mov bx,tryb_graficzny
int 10h
cmp ax,004fh
jne error
mov ax,4f07h
xor bx,bx
xor cx,cx
xor dx,dx
int 10h
cmp ax,004fh
jne error
jmp koniec






koniec:
xor ax,ax
int 16h
mov ax,4f02h
mov bx,[ds:OldVideoMode]
int 10h
Koniec:
mov ax,4c00h		       ;wyjdz z programu
int 21h

error:			       ;gdy blad wyswietl tekst
;ds= game_data
mov ax,0900h
mov dx,[AErrorCode]
int 21h
jmp koniec

segment picture_bufer
Picture: times 320*480 db 0,15
segment game_data
AErrorCode dw 0
TVESAError1: db "VESA mode is not supported!$"
TVESAError2: db "Invalid VESA block!$"
TVESAError3: db "640x480x256 mode is not supported!$"
OldVideoMode dw 0
BVESAModeInfo rb 100h
virtual at BVESAModeInfo
	ModeAttributes	    dw	?  ; mode attributes
	WinAAttributes	    db	?  ; window A attributes
	WinBAttributes	    db	?  ; window B attributes
	WinGranularity	    dw	?  ; window granularity
	WinSize 	    dw	?  ; window size
	WinASegment	    dw	?  ; window A start segment
	WinBSegment	    dw	?  ; window B start segment
	WinFuncPtr	    dd	?  ; pointer to windor function
	BytesPerScanLine    dw	?  ; bytes per scan line

; formerly optional information (now mandatory)

	XResolution	    dw	?  ; horizontal resolution
	YResolution	    dw	?  ; vertical resolution
	XCharSize	    db	?  ; character cell width
	YCharSize	    db	?  ; character cell height
	NumberOfPlanes	    db	?  ; number of memory planes
	BitsPerPixel	    db	?  ; bits per pixel
	NumberOfBanks	    db	?  ; number of banks
	MemoryModel	    db	?  ; memory model type
	BankSize	    db	?  ; bank size in kb
	NumberOfImagePages  db	?  ; number of images
	Reserved4Page	    db	1  ; reserved for page function

; new Direct Color fields

	RedMaskSize	    db	?  ; size of direct color red mask in bits
	RedFieldPosition    db	?  ; bit position of LSB of red mask
	GreenMaskSize	    db	?  ; size of direct color green mask in bits
	GreenFieldPosition  db	?  ; bit position of LSB of green mask
	BlueMaskSize	    db	?  ; size of direct color blue mask in bits
	BlueFieldPosition   db	?  ; bit position of LSB of blue mask
	RsvdMaskSize	    db	?  ; size of direct color reserved mask in bits
	DirectColorModeInfo db	?  ; Direct Color mode attributes
	Reserved	    db	216 dup(?)	; remainder of ModeInfoBlock
end virtual





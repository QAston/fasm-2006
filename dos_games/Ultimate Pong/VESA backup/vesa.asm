format MZ
use16
entry	main:start
segment main
tryb_graficzny equ 101h

start:
mov ax,game_data
mov ds,ax
;mov es,ax
mov ah,3dh
mov al,0
mov dx,FileName
int 21h
mov bx,ax
mov ah,3fh
mov cx,1024
lea dx,[BPalette]
int 21h

push video_buffer;
pop ds		 ;
xor si,si
mov cx,08000h

loadpikczer:
mov ah,3fh
lea dx,[Picture]
int 21h
mov ah,3fh
lea dx,[Picture+8000h]
int 21h
loadpikczer1:
mov bp,ds
add bp,01000h
mov ds,bp
cmp si,3
je poloadzie
inc si
jmp loadpikczer

poloadzie:
mov cx,0b000h
mov ah,3fh
lea dx,[Picture]
int 21h

mov ax,game_data
mov ds,ax
mov es,ax
mov fs,ax
mov ax,4f00h
mov di,BVESAModeInfo
int 10h
mov [fs:AErrorCode],TVESAError1
cmp ax,004fh
jne error
mov [fs:AErrorCode],TVESAError2
cmp [fs:di],dword "VESA"
jne error
mov ax,4f01h
mov cx,tryb_graficzny
int 10h
mov [fs:AErrorCode],TVESAError3
cmp ax,004fh
jne error
mov al,[fs:di]
test al,1b
jz error
mov ax,4f03h
int 10h
mov [fs:OldVideoMode],bx
mov ax,4f02h
mov bx,tryb_graficzny
int 10h
cmp ax,004fh
jne error

mov ax,64
xor dx,dx
mov bx,[fs:WinGranularity]
div bx	;ax=64/gran
mov [fs:GranularityMask],ax

mov dx,ax
mov ax,4f07h
xor bx,bx
xor cx,cx
xor dx,dx
int 10h
cmp ax,004fh
jne error

mov ax,4f09h	      ;ustaw palete
mov dx,0
mov bl,0
mov cx,256
lea di,[BPalette]
int 10h

mov ax,[WinASegment]
mov bx,video_buffer
mov es,ax
mov ds,bx
xor di,di
xor si,si
xor dx,dx
xor cx,cx
mov [fs:AErrorCode],TVESAError4
cld



pikczer:
movsd
cmp dx,4
jne pikczer1
cmp cx,02bffh
je koniec
pikczer1:
cmp cx,03fffh
inc cx
jb pikczer
mov bp,ds
add bp,01000h
mov ds,bp
xor cx,cx
add dx,[fs:GranularityMask]
mov ax,4F05h
xor bx,bx
int 10h
cmp ax,004fh
jne error
jmp pikczer


koniec:
xor ax,ax
int 16h
mov ax,4f02h
mov bx,[fs:OldVideoMode]
int 10h
Koniec:
mov ax,4c00h		       ;wyjdz z programu
int 21h

error:			       ;gdy blad wyswietl tekst
;ds= game_data
mov ax,0900h
mov dx,[fs:AErrorCode]
int 21h
jmp koniec


segment game_data

GranularityMask dw 0
AErrorCode dw 0
TVESAError1: db "VESA mode is not supported!$"
TVESAError2: db "Invalid VESA block!$"
TVESAError3: db "640x480x256 mode is not supported!$"
TVESAError4: db "VESA function error!$"
OldVideoMode dw 0
FileName db 'dupa.gpf',0
BPalette: rb 1024

BVESAModeInfo: times 100h  db 0
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
end virtual

segment video_buffer
Picture:
times 640*30 db 6
times 640*30 db 2
times 640*30 db 3
times 640*30 db 4
times 640*30 db 5
times 640*30 db 0
times 640*30 db 7
times 640*30 db 8
times 640*30 db 9
times 640*30 db 10
times 640*30 db 11
times 640*30 db 12
times 640*30 db 13
times 640*30 db 14
times 640*30 db 15
times 640*30 db 1

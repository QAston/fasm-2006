format binary
org 100h
jmp poczatek
MSEC dw 0
TIMER dw 0
OldInt1C dd 0
TimerISR:
	 push ds
	 push ax
	 pushf
	 cli
	 mov ax,[MSEC]
	 add ax,55
	 mov fs,word[OldInt1C+2]
	 mov bp,word[OldInt1C]
	 cmp ax,10000
	 jb SetMSEC
	 inc dword[TIMER]
	 sub ax,10000
SetMSEC:
	 mov	 [MSEC],ax
	 popf
	 pop	 ax
	 pop	 ds
	 jmp far [fs:bp]

poczatek:
mov ax, 0
mov es, ax
cli
mov ax,[es:1ch*4]
mov word[OldInt1C], ax
mov ax,[es:1ch*4 + 2]
mov word [OldInt1C+2], ax
mov word [es:1Ch*4],TimerISR
mov [es:1Ch*4+2],cs
sti
TimerLoop:
cmp [TIMER],1
jbe TimerLoop
mov ax, 0
mov es, ax
cli
mov ax, word [OldInt1C]
mov [es:1Ch*4], ax
mov ax, word [OldInt1C+2]
mov [es:1Ch*4+2], ax
sti
mov ax,4c00h
int 21h
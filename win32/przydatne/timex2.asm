format binary
org 100h
OldInt8 dd 0
SumLatency dd 0
Executions dd 0
Average dd 0
Counter dw 0
jmp poczatek
Timer0_8254 equ 40h
Cntrl_8254 equ 43h
TimerISR:
		push ax
		mov eax, 0 ;Ch 0, latch & read data.
		out Cntrl_8254, al ;Output to 8253 cmd register.
		in al, Timer0_8254 ;Read latch #0 (LSB) & ignore.
		cmp al,0h
		ja koniec
		mov ah, al
		jmp SettleDelay ;Settling delay for 8254 chip.

SettleDelay:	in al, Timer0_8254 ;Read latch #0 (MSB)
		xchg ah, al
		neg ax ;Fix, ‘cause timer counts down.
		add [SumLatency], eax
		mov [Counter],ax

		inc [Executions]
		pop ax
		jmp [OldInt8]
poczatek:
zmienINT9:
		push	bx dx es ax		  ;zmien adres int 9
		mov	al,70h
		mov	ah,35h
		int	21h
		mov	word[staryint70],bx	    ;zachowaj stary adres
		mov	word[staryint70+2],es
		mov	al,70h
		mov	dx,TimerISR
		mov	ah,25h
		int	21h
		pop	ax es dx bx
TimerLoop:
cmp [Counter],01h
jb TimerLoop

		push	ds
		mov	al,08h			  ;przywroc int 09
		mov	dx,word[OldInt8]
		mov	ds,word[OldInt8+2]
		mov	ah,25h
		int	21h
		pop	ds
		koniec:
mov ax,4c00h
int 21h
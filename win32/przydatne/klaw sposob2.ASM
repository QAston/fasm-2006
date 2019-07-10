org $100
;cli 
mainloop: 
call clearkey 

call readkeyboard 

push ax 
mov bl,1 
mov bh,1 
mov ch,15 
mov dx,ax 
call writehexnibbles80x25z 
pop ax 

cmp al,1 
jne mainloop 
;sti 
int 20h 

readkeyboardrealtime: 
.wait: in al,$64 
       bt ax,0 
jnc .wait 
in al,$60 
ret 

readkeyboard: 
in al,$60 
ret 

waitkeyboardchange: ; does not wait busy, (windows and other) uses al,bl 
in al,$60; because buffer ready bit is cleared after reading 
mov bl,al 
.wait2: 
in al,$60 
cmp al,bl 
jz .wait2 
ret 

clearkey:   ;Clears keystroke buffer directly ( $0040:$001A := $0040:$001C ) 
push ds 
push es 
 mov ax,$40 
 mov es,ax 
 mov ds,ax 
 mov di,$1a 
 mov si,$1c 
 movsw 
pop es 
pop ds 
ret 

writehexnibbles80x25z: ; EDX = 32 bit input bl=x bh=y ch=color ( writes 8 nibbles from input ) 
push es 	       ; does not remove leading zeroes 
mov ax,$b800 
mov es,ax 
xor ax,ax 
xchg al,bh 
mov di,ax 
shl di,2 
add di,ax 
shl di,4 
add di,bx 
shl di,1 
mov cl,8 
.roll1: 
rol edx,4 
mov al,dl 
and al,$f 
cmp al,10 
sbb al,69h 
das 
mov ah,ch 
stosw 
dec cl 
;or cl,cl 
jnz .roll1 
pop es 
ret 

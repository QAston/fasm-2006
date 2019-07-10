format binary
org 100h
use16
wp2 equ wyswietlpaletke2
wp1 equ wyswietlpaletke1
wp equ wyswietlpilke
cp equ czyscpiksel
up equ ustawpiksel
poczatek:
mov ax,0013h
int 10h

wyswietlswiat:
mov cl,4
mov ax,0a000h
mov es,ax
sciany:
movzx di,cl
dec cl
mov ch,204
sciana1:
dec ch
mov byte [es:di],15
add di,320
test ch,ch
jnz sciana1
test cl,cl
jnz sciany
mov cl,179
sciany1:
movzx di,cl
dec cl
mov ch,204
sciana2:
dec ch
mov byte [es:di],15
add di,320
test ch,ch
jnz sciana2
cmp cl,174
jne sciany1

wyswietlelem:
mov bh,90
mov bl,100				   ;do bx pozycja pi³ki
mov di,75	      ;do di pozycja dolnej paletki
mov si,75		;pozycja górnej paletki
call wp
call wp1
call wp2
xor dx,dx
mov ax,40h
mov gs,ax
mov al,[gs:6ch]
and al,3
test al,1
je bit1to0
bit2:
test al,2
je bit2to0
jmp bitkon
bit1to0:
not dl
jmp bit2
bit2to0:
not dh
bitkon:


gra:
mov bp,[gs:1ch]
sub bp,2
sprklaw:
mov ax,[gs:bp]
;xor ah,ah
;int 16h
cmp ah,4bh
je ldol
cmp ah,4dh
je pdol
cmp ah,1eh
je lgor
cmp ah,20h
je pgor
cmp ah,01h
je koniec
pospr:
call pilkaproc
call czekaj
jmp gra


;--------S-1483-------------------------------
;INT 14 - COURIERS.COM - START INPUT
;        AH = 83h
;        ES:BX -> circular input buffer
;        CX = length of buffer
;                (should be at least 128 bytes if input flow control enabled)
;SeeAlso: AH=18h,AH=87h,AH=8Dh,AH=A5h"BAPI"


koniec:
mov ah,4ch
int 21h

;czas
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
czekaj:
mov bp,[gs:6ch]
czekpetla:
mov ax,[gs:6ch]
sub ax,bp
cmp ax,05h
jne czekpetla
ret
;animacje paletek
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ldol:
cmp di,5
je pospr
mov bp,di
add bp,320*195+30
call cp
sub di,5
mov bp,di
add bp,320*195
call up
jmp pospr
pdol:
cmp di,140
je pospr
mov bp,di
add bp,320*195
call cp
add di,5
mov bp,di
add bp,320*195+30
call up
jmp pospr
lgor:
cmp si,5
je pospr
mov bp,si
add bp,30
call cp
sub si,5
mov bp,si
call up
jmp pospr
pgor:
cmp si,140
je pospr
mov bp,si
call cp
add si,5
mov bp,si
add bp,30
call up
jmp pospr

;wyswietlenie elementow
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wyswietlpilke:
call konw
mov cl,5
pilka:
mov ch,5
pilka1:
mov byte [es:bp],15
inc bp
dec ch
test ch,ch
jnz pilka1
dec cl
add bp,315
test cl,cl
jnz pilka
wyswietlpaletke1:
mov bp,di
add bp,195*320
mov cl,5
paletka1:
mov ch,35
paletka2:
mov byte [es:bp],15
inc bp
dec ch
test ch,ch
jnz paletka2
dec cl
add bp,285
test cl,cl
jnz paletka1

wyswietlpaletke2:
mov bp,si
mov cl,5
paletka21:
mov ch,35
paletka22:
mov byte [es:bp],15
inc bp
dec ch
test ch,ch
jnz paletka22
dec cl
add bp,285
test cl,cl
jnz paletka21
ret

czyscpiksel:
mov cl,5
czysc1:
mov ch,5
czysc2:
mov byte [es:bp],0
inc bp
dec ch
test ch,ch
jnz czysc2
dec cl
add bp,315
test cl,cl
jnz czysc1
ret
ustawpiksel:
mov cl,5
ustaw1:
mov ch,5
ustaw2:
mov byte [es:bp],15
inc bp
dec ch
test ch,ch
jnz ustaw2
dec cl
add bp,315
test cl,cl
jnz ustaw1
ret

;animacja pilki
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
pilkadp:
call konw
call cp
add bh,5
add bl,5
call konw
call up
ret
pilkadl:
call konw
call cp
sub bh,5
add bl,5
call konw
call up
ret
pilkagl:
call konw
call cp
sub bh,5
sub bl,5
call konw
call up
ret
pilkagp:
call konw
call cp
add bh,5
sub bl,5
call konw
call up
ret

konw:
mov ax,320
movzx bp,bl
push dx
mul bp
pop dx
movzx bp,bh
add bp,ax
ret

;kolizje i ruch pilki
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
pilkaproc:
cmp dl,0ffh
je pilecz01  ;czy bit 0 jest zerem
cmp dh,0ffh
je  pilecz10 ;czy bit 1 jest zerem
call pilkagl	  ;00 goralewo
jmp pilkadal
pilecz01:
cmp dh,0ffh
je pilecz00  ;czy bit 1 jest zerem
call pilkadl	  ;10 dollewo
jmp pilkadal
pilecz10:
call pilkagp	  ;01 goraprawo
jmp pilkadal
pilecz00:
call pilkadp	  ;11 dolprawo
pilkadal:
cmp bh,5
je piodal1
cmp bh,170
je piodal2

cmp bl,190
jb pilkadalej
mov ax,di
test dh,dh
jz dsprukp
sub al,5
cmp bh,al
jb dsprdol2
add al,35
cmp bh,al
ja dsprdol2
sub al,35
cmp bh,al
ja odbzwykle
odbodwr:
not dx
jmp pilkakon
odbzwykle:
not dl
jmp pilkakon
dsprdol2:
mov ax,di
cmp bh,al
ja pilkakon
sub al,35
cmp bh,al
jb pilkakon
jmp odbzwykle

dsprukp:
add al,5
cmp bh,al
jb dsprdol
add al,30
cmp bh,al
ja dsprdol
cmp bh,al
jb odbzwykle
jmp odbodwr
dsprdol:
mov ax,di
cmp bh,al
jb pilkakon
add al,35
cmp bh,al
ja pilkakon
jmp odbzwykle

pilkadalej:
cmp bl,5
ja pilkakon
mov ax,si
test dh,dh
jz gsprukp
add al,5
cmp ah,al
jb gsprdol2
add al,35
cmp bh,al
ja gsprdol2
sub al,35
cmp bh,al
ja odbzwykle
jmp odbodwr
gsprdol2:
mov ax,si
cmp bh,al
jb pilkakon
add al,30
cmp bh,al
ja pilkakon
jmp odbzwykle
gsprukp:
add al,5
cmp bh,al
jb gsprdol
add al,30
cmp bh,al
ja gsprdol
cmp bh,al
jb odbzwykle
cmp bl,10
ja  odbzwykle
jmp odbodwr
gsprdol:
mov ax,si
cmp bh,al
jb pilkakon
add al,35
cmp bh,al
ja pilkakon
jmp odbzwykle
rog1:
mov ax,si
cmp bh,al
je odbodwr
jmp  pion
rog2:
mov ax,si
sub al,30
cmp bh,al
je odbodwr
jmp pion
rog3:
mov ax,di
cmp al,bh
je odbodwr
jmp pion
rog4:
mov ax,di
add al,30
cmp al,bh
je odbodwr
piodal1:
cmp bl,5
je rog1
cmp bl,190
je rog3
jmp pion
piodal2:
cmp bl,5
je rog2
cmp bl,190
je rog4
pion:
not dh
pilkakon:
ret

;dane
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
bufor: times 200 db 0
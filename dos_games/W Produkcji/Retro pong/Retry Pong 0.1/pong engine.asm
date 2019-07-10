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
mov bx,100*320+90	       ;do bx pozycja pi³ki
mov di,195*320+75	      ;do di pozycja dolnej paletki
mov si,75		;pozycja górnej paletki
call wp
call wp1
call wp2
xor dx,dx
push es
mov ax,40h
mov es,ax
mov al,[es:6ch]
pop es
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
call pilkaproc
xor ah,ah
int 16h
cmp ah,21h
ja gra1
cmp ah,1eh
je lgor
cmp ah,20h
je pgor
cmp ah,01h
je koniec
jmp gra

gra1:
cmp ah,4bh
je ldol
cmp ah,4dh
je pdol
jmp gra

koniec:
mov ah,4ch
int 21h

;animacje paletek
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ldol:
cmp di,195*320+5
je gra
mov bp,di
add bp,30
call cp
sub di,5
mov bp,di
call up
jmp gra
pdol:
cmp di,195*320+140
je gra
mov bp,di
call cp
add di,5
mov bp,di
add bp,30
call up
jmp gra
lgor:
cmp si,5
je gra
mov bp,si
add bp,30
call cp
sub si,5
mov bp,si
call up
jmp gra
pgor:
cmp si,140
je gra
mov bp,si
call cp
add si,5
mov bp,si
add bp,30
call up
jmp gra

;wyswietlenie elementow
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wyswietlpilke:
push bx
mov cl,5
pilka:
mov ch,5
pilka1:
mov byte [es:bx],15
inc bx
dec ch
test ch,ch
jnz pilka1
dec cl
add bx,315
test cl,cl
jnz pilka
pop bx
wyswietlpaletke1:
push di
mov cl,5
paletka1:
mov ch,35
paletka2:
mov byte [es:di],15
inc di
dec ch
test ch,ch
jnz paletka2
dec cl
add di,285
test cl,cl
jnz paletka1
pop di
wyswietlpaletke2:
push si
mov cl,5
paletka21:
mov ch,35
paletka22:
mov byte [es:si],15
inc si
dec ch
test ch,ch
jnz paletka22
dec cl
add si,285
test cl,cl
jnz paletka21
pop si
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

;czas
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
czekaj:
mov ah,86h
mov cx,0ffffh
push dx
mov dx,0ffffh
int 15h
pop dx
ret

;animacja pilki
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
pilkadp:
mov bp,bx
call cp
add bx,5*320+5
call wp
ret
pilkadl:
mov bp,bx
call cp
add bx,5*320-5
call wp
ret
pilkagl:
mov bp,bx
call cp
sub bx,5*320+5
call wp
ret
pilkagp:
mov bp,bx
call cp
sub bx,5*320-5
call wp
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
cmp bx,5*320+5
je rog1
cmp bx,10*320+5
je pion
cmp bx,15*320+5
je pion
cmp bx,20*320+5
je pion
cmp bx,25*320+5
je pion
cmp bx,30*320+5
je pion
cmp bx,35*320+5
je pion
cmp bx,40*320+5
je pion
cmp bx,45*320+5
je pion
cmp bx,50*320+5
je pion
cmp bx,55*320+5
je pion
cmp bx,60*320+5
je pion
cmp bx,65*320+5
je pion
cmp bx,70*320+5
je pion
cmp bx,75*320+5
je pion
cmp bx,80*320+5
je pion
cmp bx,85*320+5
je pion
cmp bx,90*320+5
je pion
cmp bx,95*320+5
je pion
cmp bx,100*320+5
je pion
cmp bx,105*320+5
je pion
cmp bx,110*320+5
je pion
cmp bx,115*320+5
je pion
cmp bx,120*320+5
je pion
cmp bx,125*320+5
je pion
cmp bx,130*320+5
je pion
cmp bx,135*320+5
je pion
cmp bx,140*320+5
je pion
cmp bx,145*320+5
je pion
cmp bx,150*320+5
je pion
cmp bx,155*320+5
je pion
cmp bx,160*320+5
je pion
cmp bx,165*320+5
je pion
cmp bx,170*320+5
je pion
cmp bx,175*320+5
je pion
cmp bx,180*320+5
je pion
cmp bx,185*320+5
je pion
cmp bx,190*320+5
je rog3
cmp bx,195*320+5
je pion
cmp bx,5*320+170
je rog2
cmp bx,10*320+170
je pion
cmp bx,15*320+170
je pion
cmp bx,20*320+170
je pion
cmp bx,25*320+170
je pion
cmp bx,30*320+170
je pion
cmp bx,35*320+170
je pion
cmp bx,40*320+170
je pion
cmp bx,45*320+170
je pion
cmp bx,50*320+170
je pion
cmp bx,55*320+170
je pion
cmp bx,60*320+170
je pion
cmp bx,65*320+170
je pion
cmp bx,70*320+170
je pion
cmp bx,75*320+170
je pion
cmp bx,80*320+170
je pion
cmp bx,85*320+170
je pion
cmp bx,90*320+170
je pion
cmp bx,95*320+170
je pion
cmp bx,100*320+170
je pion
cmp bx,105*320+170
je pion
cmp bx,110*320+170
je pion
cmp bx,115*320+170
je pion
cmp bx,120*320+170
je pion
cmp bx,125*320+170
je pion
cmp bx,130*320+170
je pion
cmp bx,135*320+170
je pion
cmp bx,140*320+170
je pion
cmp bx,145*320+170
je pion
cmp bx,150*320+170
je pion
cmp bx,155*320+170
je pion
cmp bx,160*320+170
je pion
cmp bx,165*320+170
je pion
cmp bx,170*320+170
je pion
cmp bx,175*320+170
je pion
cmp bx,180*320+170
je pion
cmp bx,185*320+170
je pion
cmp bx,190*320+170
je rog4
cmp bx,195*320+170
je pion
cmp bx,320*190
jb pilkadalej
mov bp,bx
test dh,dh
jz dsprukp
add bp,1605
cmp bp,di
jb dsprdol
sub bp,35
cmp bp,di
ja dsprdol
add bp,35
cmp bp,di
ja odbzwykle
odbodwr:
not dx
jmp pilkakon
odbzwykle:
not dl
jmp pilkakon

dsprukp:
add bp,1595
cmp bp,di
jb dsprdol
sub bp,30
cmp bp,di
ja dsprdol
cmp bp,di
jb odbzwykle
jmp odbodwr
dsprdol:
mov bp,bx
add bp,1600
cmp bp,di
jb pilkakon
sub bp,35
cmp bp,di
ja pilkakon
jmp odbzwykle

pilkadalej:
cmp bx,10*320
ja pilkakon
mov bp,bx
test dh,dh
jz gsprukp
sub bp,1595
cmp bp,si
jb gsprdol
add si,35
cmp bp,si
pushf
sub si,35
popf
ja gsprdol
cmp bp,si
ja odbzwykle
jmp odbodwr
gsprukp:
sub bp,1605
cmp bp,si
jb gsprdol
add si,30
cmp bp,si
pushf
sub si,30
popf
ja gsprdol
sub bp,30
cmp bp,si
jb odbzwykle
cmp bp,10*320
ja  odbzwykle
jmp odbodwr
gsprdol:
mov bp,bx
sub bp,1600
cmp bp,si
jb pilkakon
add si,35
cmp bp,si
pushf
sub si,35
popf
ja pilkakon
jmp odbzwykle
rog1:
mov bp,bx
sub bp,1600
cmp bp,si
je odbodwr
jmp  pion
rog2:
mov bp,bx
sub bp,1630
cmp bp,si
je odbodwr
jmp pion
rog3:
mov bp,bx
add bp,1600
cmp bp,di
je odbodwr
jmp pion
rog4:
mov bp,bx
add bp,1570
cmp bp,di
je odbodwr
pion:
not dh
pilkakon:
ret

;dane
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
bufor: times 200 db 0
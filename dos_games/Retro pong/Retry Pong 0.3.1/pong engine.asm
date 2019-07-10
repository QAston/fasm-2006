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

mov ax,0a000h
mov es,ax
mov al,4
sciany:
movzx di,al
dec al
mov ah,204
sciana1:
dec ah
mov byte [es:di],15
add di,320
test ah,ah
jnz sciana1
test al,al
jnz sciany
mov al,179
sciany1:
movzx di,al
dec al
mov ah,204
sciana2:
dec ah
mov byte [es:di],15
add di,320
test ah,ah
jnz sciana2
cmp al,174
jne sciany1
mov bp,320+200
call up
mov bp,320*6+200
call up
mov bp,320*11+200
call up
mov bp,320+230
call up
mov bp,320*6+230
call up
mov bp,320*11+230
call up
mov bp,320+236
call up
mov bp,320*6+236
call up
mov bp,320*11+236
call up

wyswietlelem:
mov bh,90
mov bl,100				   ;do bx pozycja pi³ki
call odswierzelem
call wp
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
xor ah,ah
int 16h
xor ax,ax
mov word [gs:1ah],1eh
mov word [gs:1ch],1eh
mov word[gs:1eh],0

gra:
mov fs,[gs:6ch]
czekpetla:
mov cx,[gs:6ch]
mov ax,fs
sub cx,ax
call sprklaw
cmp cx,1
jne czekpetla
call pilkaproc
call sprpunkty
jmp gra
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wyswpunkty:
mov al,[punktyd]
mov ah,[punktyg]
mov bp,320*20+200
wyswp1:
test al,al
jz wyswp2
push ax
call up
pop ax
add bp,320
dec al
jmp wyswp1
wyswp2:
mov bp,320*20+233
wyswp3:
test ah,ah
jz wyswp4
push ax
call up
pop ax
add bp,320
dec ah
jmp wyswp3
wyswp4:
ret
zwycdol:
jmp koniec
zwycgora:
jmp koniec

;sprawdzanie punktow i klawiszy
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sprklaw:
mov bp,[gs:1ch]
mov word [gs:1ch],1eh
sub bp,2
mov ax,[gs:bp]
test dl,dl
jz gklaw
cmp ah,4bh
je ldol
cmp ah,4dh
je pdol
cmp ah,01h
je koniec
jmp pospr
gklaw:
cmp ah,1eh
je lgor
cmp ah,20h
je pgor
cmp ah,01h
je koniec
pospr:
ret

sprpunkty:
cmp bl,5
jb punktd
cmp bl,195
jae punktg
jmp punktkon
punktg:
xor dl,dl
inc  byte[punktyg]
call wyswpunkty
cmp byte[punktyg],11
je zwycgora
call konw
call cp
call czyscekran
call odswierzelem
gsprklaw:
push si
mov bl,5
mov ax,si
add al,15
mov bh,al
call konw
call wp
call sprklaw
cmp si,[esp]
jne gsprcp
gsprdalej:
add esp,2
mov bp,[gs:1ah]
mov word [gs:1ah],1eh
mov ax,[gs:bp]
cmp ah,11h
jne gsprklaw
mov dl,0ffh
jmp punktkon
gsprcp:
call konw
call cp
jmp gsprdalej

punktd:
mov dl,0ffh
inc byte[punktyd]
call wyswpunkty
cmp byte[punktyd],11
je zwycdol	    ;zmieniæ
call konw
call cp
call czyscekran
call odswierzelem
dsprklaw:
push di
mov bl,190
mov ax,di
add al,15
mov bh,al
call konw
call wp
call sprklaw
cmp di,[esp]
jne dsprcp
dsprdalej:
add esp,2
mov bp,[gs:1ah]
mov word [gs:1ah],1eh
mov ax,[gs:bp]
cmp ah,48h
jne dsprklaw
xor dl,dl
jmp punktkon
dsprcp:
call konw
call cp
jmp dsprdalej
punktkon:
ret

koniec:
mov ah,4ch
int 21h

;animacje paletek
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
odswierzelem:
mov di,75
mov si,75
call wp1
call wp2
ret
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
mov al,5
pilka:
mov ah,5
pilka1:
mov byte [es:bp],15
inc bp
dec ah
test ah,ah
jnz pilka1
dec al
add bp,315
test al,al
jnz pilka
ret
wyswietlpaletke1:
mov bp,di
add bp,195*320
mov al,5
paletka1:
mov ah,35
paletka2:
mov byte [es:bp],15
inc bp
dec ah
test ah,ah
jnz paletka2
dec al
add bp,285
test al,al
jnz paletka1
ret
czyscekran:
mov bp,di
add bp,195*320
mov al,5
cpaletka1:
mov ah,35
cpaletka2:
mov byte [es:bp],0
inc bp
dec ah
test ah,ah
jnz cpaletka2
dec al
add bp,285
test al,al
jnz cpaletka1
mov bp,si
mov al,5
cpaletka21:
mov ah,35
cpaletka22:
mov byte [es:bp],0
inc bp
dec ah
test ah,ah
jnz cpaletka22
dec al
add bp,285
test al,al
jnz cpaletka21
ret
wyswietlpaletke2:
mov bp,si
mov al,5
paletka21:
mov ah,35
paletka22:
mov byte [es:bp],15
inc bp
dec ah
test ah,ah
jnz paletka22
dec al
add bp,285
test al,al
jnz paletka21
ret
czyscpiksel:
mov al,5
czysc1:
mov ah,5
czysc2:
mov byte [es:bp],0
inc bp
dec ah
test ah,ah
jnz czysc2
dec al
add bp,315
test al,al
jnz czysc1
ret
ustawpiksel:
mov al,5
ustaw1:
mov ah,5
ustaw2:
mov byte [es:bp],15
inc bp
dec ah
test ah,ah
jnz ustaw2
dec al
add bp,315
test al,al
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
je pion
cmp bh,170
je pion
pildal:
cmp bl,190
jb pilkadalej
mov ax,di
test dh,dh
jz dsprukp
sub al,5
cmp bh,al
jb dsprdol
add al,35
cmp bh,al
ja pilkakon
sub al,35
cmp bh,al
ja odbzwykle
odbodwr:
not dx
jmp pilkakon
odbzwykle:
not dl
jmp pilkakon

dsprukp:
add al,5
cmp bh,al
jb dsprdol
add al,30
cmp bh,al
ja pilkakon
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
mov bh,bh
test dh,dh
jz gsprukp
sub al,5
cmp bh,al
jb gsprdol
add al,35
cmp bh,al
ja pilkakon
sub al,35
cmp bh,al
ja odbzwykle
jmp odbodwr
gsprukp:
add al,5
cmp bh,al
jb gsprdol
add al,30
cmp bh,al
ja  pilkakon
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
pion:
not dh
jmp pildal
pilkakon:
ret

;dane
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
punktyd: db 0
punktyg: db 0
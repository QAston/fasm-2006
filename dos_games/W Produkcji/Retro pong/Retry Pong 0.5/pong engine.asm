format binary
org 100h
use16
wp2 equ wyswietlpaletke2
wp1 equ wyswietlpaletke1
wp equ wyswietlpilke
cp equ czyscpiksel
up equ ustawpiksel
poczatek:
menu:
mov ah,09h
mov dx,TMenu
int 21h
xor ah,ah
int 16h
cmp al,'1'
je wyswietlswiat
cmp al,'2'
je AIstart
cmp al,'3'
je menuz
cmp al,'4'
je menua
cmp al,'5'
je koniec
cmp ah,01h
je koniec
jmp menu
menuz:
mov ah,09h
mov dx,TZasady
int 21h
xor ah,ah
int 16h
jmp menu
menua:
mov ah,09h
mov dx,TAutor
int 21h
xor ah,ah
int 16h
jmp menu
AIstart:
mov dl,0ffh
mov [czyAI],dl
mov ah,09h
mov dx,TPoziom
int 21h
xor ah,ah
int 16h
xor dx,dx
inc dx
xor bx,bx
cmp al,'1'
cmove  bx,dx
inc dx
cmp al,'2'
cmove  bx,dx
inc dx
cmp al,'3'
cmove  bx,dx
cmp ah,01h
je koniec
mov [poziomAI],bl
wyswietlswiat:
mov ax,0013h
int 10h
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
mov bl,100				   ;do bx pozycja pi�ki
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
mov word [gs:1eh],0
cmp [czyAI],0ffh
je graAI

gra:
mov fs,[gs:6ch]
czekpetla:
mov cx,[gs:6ch]
mov ax,fs
sub cx,ax
call sprklaw
cmp cx,1
jb czekpetla
call pilkaproc
call sprpunkty
jmp gra

graAI:
mov fs,[gs:6ch]
czekpetlaAI:
mov cx,[gs:6ch]
mov ax,fs
sub cx,ax
call sprklawAI
cmp cx,1
jb czekpetlaAI
call pilkaproc
call sprpunkty
call ruchAI
jmp graAI
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

ruchAI:
mov al,[gs:6ch]
cmp [poziomAI],2
ja  ruch1
jb ruchp1
test al,2
jne ruch1
test al,1
jne ruch1
ruchp1:
test al,3
jne ruch1
jmp ruchAIkon
ruch1:
test dl,dl
jnz ruchAIkon
mov word [gs:1ah],1eh
mov word [gs:1ch],20h
mov ax,si
test dh,dh
jz sprlAI
sprpAI:
cmp al,bh
jae ruchAIkon
ruchAIp:
mov word[gs:1eh],0fefeh
jmp ruchAIkon
sprlAI:
add al,30
cmp al,bh
jbe ruchAIkon
ruchAIl:
mov word[gs:1eh],0ffffh
ruchAIkon:
ret

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
zwyc:
mov ah,0
mov al,3
int 10h
mov ah,09h
mov dx,TWygral
int 21h
mov al,[punktyd]
cmp [punktyg],al
ja zwycgora
mov ah,09h
mov dx,TWygral1
jmp zwyc2
zwycgora:
mov ah,09h
mov dx,TWygral2
zwyc2:
int 21h
mov byte[punktyg],0
mov byte[punktyd],0
mov byte[czyAI],0
mov byte[poziomAI],0
xor ah,ah
int 16h
jmp menu

;sprawdzanie punktow i klawiszy
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sprklawAI:
mov bp,[gs:1ch]
mov word [gs:1ch],1eh
sub bp,2
mov ax,[gs:bp]
cmp ah,19h
je pauza
cmp ah,01h
je koniec
test dl,dl
jz AIklaw
cmp ah,4bh
je ldol
cmp ah,4dh
je pdol
jmp pospr
AIklaw:
cmp ah,0FFh
je lgor
cmp ah,0FEh
je pgor
ret
sprklaw:
mov bp,[gs:1ch]
mov word [gs:1ch],1eh
sub bp,2
mov ax,[gs:bp]
cmp ah,01h
je koniec
cmp ah,19h
je pauza
test dl,dl
jz gklaw
cmp ah,4bh
je ldol
cmp ah,4dh
je pdol
jmp pospr
gklaw:
cmp ah,1eh
je lgor
cmp ah,20h
je pgor
pospr:
ret
pauza:
mov bp,[gs:1ch]
mov word [gs:1ch],1eh
sub bp,2
mov ax,[gs:bp]
cmp ah,19h
je pospr
jmp pauza

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
je zwyc
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
cmp [czyAI],0ffh
je  gsprklawAI
call sprklaw
mov bp,sp
cmp si,[ss:bp]
jne gsprcp
gsprdalej:
add sp,2
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
gsprklawAI:
add sp,2
mov dl,0ffh
jmp punktkon

punktd:
mov dl,0ffh
inc byte[punktyd]
call wyswpunkty
cmp byte[punktyd],11
je zwyc
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
mov bp,sp
cmp di,[ss:bp]
jne dsprcp
dsprdalej:
add sp,2
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
mov ax,4c00h
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
czyAI db 0
poziomAI db 0
TMenu:
db 10,13
db 10,13
db '   ___           _      ___   ___         _   ',10,13
db '   |  | | |\  | / \     |  | |   | |\  | / \  ',10,13
db '   |_/  | | \ || __     |_/  |   | | \ || __  ',10,13
db '   |    | |  \| \_|     |    |___| |  \| \_|   ',10,13
db 10,13
db 10,13
db 10,13
db '1.Gracz vs. Gracz',10,13
db '2.Gracz vs. Komputer',10,13
db '3.Zasady i sterowanie',10,13
db '4.Autor',10,13
db '5.Wyjscie',10,13
db 10,13
db 10,13
db 'Wcisnij 1,2,3,4 lub 5 aby wybrac.'
db 10,13,'$'
TZasady: db  10,13
db 'ZASADY GRY'
db 10,13
db 'Po uruchomieniu gry widzimy dwie paletki, sciany i miejsce na punktacje'
db ' (I i II z prawej strony ekranu). Wcisniecie dowolnego klawisza powoduje ,ze pilka leci w losowym kierunku'
db ' Zadaniem graczy jest umieszczenie pileczki za paletka przeciwnika. Ten, kto pierwszy uczyni to 11 razy wygrywa'
db ' Gracz, ktory zdobyl punkt ma dodana kropke w punktacji i serwuje pilke.'
db ' Milej zabawy!'
db 10,13
db 'STEROWANIE'
db 10,13
db '[Esc]- wyjscie'
db 10,13
db '[P]-pauza'
db 10,13
db 'Gracz I (dolny):'
db 10,13
db 'Strza�ki w prawo i w lewo- ruch paletki.'
db 10,13
db 'Strzalka w gore- serw.'
db 10,13
db 'Gracz II (gorny):'
db 10,13
db '[A]-paletka w lewo'
db 10,13
db '[D]-paletka w prawo'
db 10,13
db '[W]-serw.'
db 10,13
db 10,13,'$'
TAutor: db 10,13
db 'Projekt, wykonanie, grafika, dzwiek, postaci i fizyke obiektow w grze stworzyl:'
db 10,13
db 'Dariusz Antoniuk'
db 10,13
db 10,13
db 'Betatesterzy:'
db 10,13
db 'Paulina Antoniuk'
db 10,13
db 'Agata Antoniuk'
db 10,13
db   'To jest miejsce na twoja reklame'
db 10,13,'$'
TPoziom db 'Poziom inteligencji komputera: 1,2 lub 3.$'
TWygral:
db '     _______    ',10,13
db '  /\|\_____/|/\ ',10,13
db '  \/|       |\/ ',10,13
db '     \     /    ',10,13
db '      \   /   ',10,13
db '     _|   |_  ',10,13
db '    |_______| ',10,13
db 10,13,'$'
TWygral1: db 'Wygral gracz numer I!$'
TWygral2: db 'Wygral gracz numer II!$'

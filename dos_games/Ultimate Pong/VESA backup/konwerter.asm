format MZ
use16
entry	main:start
segment main

start:
mov bx,program_data
mov ds,bx
mov ah,09h
mov dx,TKomunikat
int 21h
mov ah,0ah
mov dx,BFileName
int 21h
movzx di,byte [FileNameCounter]
lea bx,[FileName]
add di,bx
xor ah,ah
mov [di],ah
sub di,4
mov ax,[di]
cmp ax,'.b'
jne zly_plik
add di,2
mov ax,[di]
cmp ax,'mp'
jne zly_plik
mov ah,3dh
mov al,010b
lea dx,[FileName]
int 21h
jc blad

mov bx,ax
mov ah,3fh
mov cx,54
lea dx,[BFile1]
int 21h
jc blad

xor si,si
mov cx,4
ustawpalete:
mov ah,3fh
mov dx,b
int 21h
mov dl,[r]
;shl dl,2
mov [BPaleta+si],dl
mov dl,[g]
;shl dl,2
mov [BPaleta+si+1],dl
mov dl,[b]
;shl dl,2
mov [BPaleta+si+2],dl
mov dl,[x]
;shl dl,2
mov byte [BPaleta+si+3],dl
add si,4
cmp si,1024
jb ustawpalete

push file_buffer1
pop ds
mov dx,0
mov cx,08000h
mov ah,3fh
int 21h
mov dx,cx
mov ah,3fh
int 21h
push file_buffer2
pop ds
mov dx,0
mov cx,08000h
mov ah,3fh
int 21h
mov dx,cx
mov ah,3fh
int 21h
push file_buffer3
pop ds
mov dx,0
mov cx,08000h
mov ah,3fh
int 21h
mov dx,cx
mov ah,3fh
int 21h
push file_buffer4
pop ds
mov dx,0
mov cx,08000h
mov ah,3fh
int 21h
mov dx,cx
mov ah,3fh
int 21h
push file_buffer5
pop ds
mov dx,0
mov cx,0b000h
mov ah,3fh
int 21h

mov ax,program_data
mov ds,ax
mov ax,'pf'
mov [di],ax
sub di,2
mov ax,'.g'
mov [di],ax
mov ah,3ch
xor cx,cx
lea dx,[FileName]
int 21h
jc blad
mov bx,ax
mov ah,40h
mov cx,1024
lea dx,[BPaleta]
int 21h


push file_buffer5
pop ds
mov dx,0b000h
mov cx,640
filepetla1:
sub dx,cx
mov ah,40h
int 21h
cmp dx,cx
ja filepetla1

push dx 	   ;dx-to co nie miesci sie w linijkach
mov bp,dx
mov cx,640	   ;cx-ilosc pikseli z nastej czesci
sub cx,bp
mov dx,0ffffh
sub dx,cx
inc dx
push file_buffer4
pop ds
mov ah,40h
int 21h
sub dx,cx
mov gs,dx
xor dx,dx
push file_buffer5
pop ds
pop cx
mov ah,40h
int 21h

mov dx,gs
sub dx,bp
mov cx,640
add dx,cx
push file_buffer4
pop ds
filepetla2:
sub dx,cx
mov ah,40h
int 21h
cmp dx,cx
jae filepetla2

push dx 	   ;dx-to co nie miesci sie w linijkach
mov bp,dx
mov cx,640	   ;cx-ilosc pikseli z nastej czesci
sub cx,bp
mov dx,0ffffh
sub dx,cx
inc dx
push file_buffer3
pop ds
mov ah,40h
int 21h
sub dx,cx
mov gs,dx
xor dx,dx
push file_buffer4
pop ds
pop cx
mov ah,40h
int 21h


mov dx,gs
sub dx,bp
mov cx,640
add dx,cx
push file_buffer3
pop ds
filepetla3:
sub dx,cx
mov ah,40h
int 21h
cmp dx,cx
jae filepetla3

push dx 	   ;dx-to co nie miesci sie w linijkach
mov bp,dx
mov cx,640	   ;cx-ilosc pikseli z nastej czesci
sub cx,bp
mov dx,0ffffh
sub dx,cx
inc dx
push file_buffer2
pop ds
mov ah,40h
int 21h
sub dx,cx
mov gs,dx
xor dx,dx
push file_buffer3
pop ds
pop cx
mov ah,40h
int 21h

mov dx,gs
sub dx,bp
mov cx,640
add dx,cx
push file_buffer2
pop ds
filepetla4:
sub dx,cx
mov ah,40h
int 21h
cmp dx,cx
jae filepetla4

push dx 	   ;dx-to co nie miesci sie w linijkach
mov bp,dx
mov cx,640	   ;cx-ilosc pikseli z nastej czesci
sub cx,bp
mov dx,0ffffh
sub dx,cx
inc dx
push file_buffer1
pop ds
mov ah,40h
int 21h
sub dx,cx
mov gs,dx
xor dx,dx
push file_buffer2
pop ds
pop cx
mov ah,40h
int 21h

mov dx,gs
sub dx,bp
mov cx,640
add dx,cx
push file_buffer1
pop ds
filepetla5:
sub dx,cx
mov ah,40h
int 21h
cmp dx,cx
jae filepetla5
mov cx,dx
xor dx,dx
mov ah,40h
int 21h

koniec:
xor ah,ah
int 16h
Koniec:
mov ax,4c00h
int 21h
zly_plik:
mov ah,09h
mov dx,TZlyPlik
int 21h
jmp koniec
blad:
mov ah,09h
mov dx,TBlad
int 21h
jmp koniec



segment program_data
TZlyPlik db 'Niewlasciwa nazwa pliku$'
TBlad db 'Blad pliku $'
TKomunikat db 'Wpisz nazwe pliku, ktory chcesz przekonwertowac z bmp na gpf',10,13,'$'
BFileName db 199
FileNameCounter db 0
FileName: times 200 db 0
b		db 0
g		db 0
r		db 0
x		db 0
BPaleta: times 1024 db 0

segment file_buffer1
BFile1: times 10000h db 0
segment file_buffer2
BFile2: times 10000h db 0
segment file_buffer3
BFile3: times 10000h db 0
segment file_buffer4
BFile4: times 10000h db 0
segment file_buffer5
BFile5: times 0b000h db 0


Virtual at BFile1
		bftype dw ?
		bfsize dd ?
		bfreserved dd ?
		bfoffbits dd ?
		bmprozmiar dd ?
		bmpszerokosc dd ?
		bmpwysokosc dd ?
		biplanes dw ?
		bibitcount dw ?
		bicompression dd ?
		bisizeimag  dd ?
		bixpelspermeter dd ?
		biypelspermeter dd ?
		bmpliczbakolorow dd ?
		biclrimportant dd ?
end virtual
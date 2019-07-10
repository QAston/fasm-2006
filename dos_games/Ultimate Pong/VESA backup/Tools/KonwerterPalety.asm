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
push file_buffer
pop ds
lea dx,[BFile]
int 21h
jc blad

xor si,si
mov cx,4
ustawpalete:
mov ah,3fh
mov dx,b
int 21h
mov dl,[r]
shr dl,2
mov [BPaleta+si],dl
inc si
mov dl,[g]
shr dl,2
mov [BPaleta+si],dl
inc si
mov dl,[b]
shr dl,2
mov [BPaleta+si],dl
cmp si,768
jb ustawpalete

mov ax,program_data
mov ds,ax
mov ax,'al'
mov [di],ax
sub di,2
mov ax,'.p'
mov [di],ax
mov ah,3ch
xor cx,cx
lea dx,[FileName]
int 21h
jc blad
mov dx,file_buffer
mov ds,dx
mov bx,ax
mov ah,40h
mov cx,768
lea dx,[BPaleta]
int 21h
jc blad

mov ax,program_data
mov ds,ax
mov ah,09h
lea dx,[TKoniec]
int 21h

koniec:
xor ah,ah
int 16h
mov ax,4c00h
int 21h
zly_plik:
mov ah,09h
mov dx,TZlyPlik
int 21h
jmp koniec
blad:
mov ax,program_data
mov ds,ax
mov ah,09h
mov dx,TBlad
int 21h
jmp koniec



segment program_data
TZlyPlik db 'Niewlasciwa nazwa pliku$'
TBlad db 'Blad pliku $'
TKomunikat db 'Wpisz nazwe pliku, ktory chcesz przekonwertowac z bmp na pal',10,13,'$'
TKoniec db 'Konwersja przebiegla pomyslnie. Nacisnij dowolny klawisz, by wyjsc.$'
BFileName db 199
FileNameCounter db 0
FileName: times 200 db 0


segment file_buffer
b		db 0
g		db 0
r		db 0
x		db 0
BPaleta: times 768 db 0
BFile: rb 301*1024



Virtual at BFile
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
Animation:
db 4	;rozmiar x
db 3	;rozmiar y
dd 4	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 11111111b   ;ustawienia
dd 15
db 4," () "
db 4," [] "
db 4," || "
dd 17
db 4," () "
db 4,"/",0,4,"[]\"

db 4," || "
dd 17
db 4," () "
db 4,"-[",13,1,"]",10,"-"
db 4," || "
dd 15
db 4,"\()/"
db 4," [] "
db 4," || "
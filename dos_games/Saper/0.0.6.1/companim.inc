Animation:
dd 4	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 11111111b   ;ustawienia
endl equ 0,126
endf equ 0,127
db " (",0,0,") ",endl
db " [] ",endl
db " || ",endl,endf

db " () ",endl
db "/",0,0fh,"[]\",endl
db " || ",endl,endf

db " () ",endl
db "-[",0,1b,"]-",endl
db " || ",endl,endf

db "\()/",endl
db " [",0,10000111b,1," ",endl
db " || ",endl,endf
Animation:
dd 4	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 110b   ;ustawienia
db 1111b
endl equ 0,126
endf equ 0,127
color equ 0,125
db " (",0,0,127,") ",endl
db " [] ",endl
db " || ",endl,endf

db " () ",endl
db "/",color,0,127,"[]\",endl
db " || ",endl,endf

db " () ",endl
db "-[",0,20,"]-",endl
db " || ",endl,endf

db "\()/",endl
db " [",0,10000111b,0,126,"%",endl
db " || ",endl,endf
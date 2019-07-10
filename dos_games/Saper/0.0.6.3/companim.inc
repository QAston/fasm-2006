Animation:
dd 4	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 111b   ;ustawienia
endl equ 0,126
endf equ 0,127
color equ 0,125
db 1,"0(",0,0,127,") ",endl
db " [] ",endl
db " || ",endl,endf

db 2,"0() ",endl
db "/",color,0,127,"[]\",endl
db " || ",endl,endf

db 3,"0() ",endl
db "-[",0,20,"]-",endl
db " || ",endl,endf

db 4,"\()/",endl
db " [",0,10000111b,0,126,"%",endl
db " || ",endl,endf
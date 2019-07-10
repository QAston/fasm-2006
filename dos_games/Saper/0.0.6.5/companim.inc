Animation:
dd 5	;liczba klatek
db 0	;fps 0-100 -klatki na sekunde 101-120 sekundy na klatki
db 101b   ;ustawienia
endl equ 0,126
endf equ 0,127
color equ 0,125
db 1,1, "0",endl,endf
db 0,2, 0,1,"1",endl,endf
db 0,3, 0,2,"2",endl,endf
db 0,4, 0,3,"3",endl,endf
db 0,5, 0,4,"4",endl,endf
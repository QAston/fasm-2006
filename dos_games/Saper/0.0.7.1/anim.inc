Animation:
;dd 0
dd 4   ;liczba klatek
dd 0
db 101b   ;ustawienia
endl equ 0,126
endf equ 0,127
color equ 0,125
;db 1,1, "0",endl,endf
;db 0,2, 0,1,"1",endl,endf
;db 1,3, 0,2,"2",endl,endf
;db 1,4, 0,3,"3",endl,endf
;db 1,5, 0,4,"4",endl,endf
db 1
db 1," () ",endl
db " [] ",endl
db " || ",endl,endf
db 1
db 2," () ",endl
db "/[]\",endl
db " || ",endl,endf
db  1
db 3," () ",endl
db "-[]-",endl
db " || ",endl,endf
db  1
db 4,"\()/",endl
db " [] ",endl
db " || ",endl,endf
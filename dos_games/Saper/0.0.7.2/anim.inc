db "tfcg";format ograniczajacy wielkosc animacji do 80/50  z mo�liwo�ci� czekania na klawisz i FPS okreslanym w 15us odst�pach
;dw 50   ;wysoko�� w znakach   0-50
;dw 80   ;szeroko�� w znakach  0-80
;dd 4   ;liczba klatek animacji
db 0   ;g��wny kolor
db 1110b  ;ustawienia     bit 0 0-redraw definiowany pierwszym bajtem 1-redraw za ka�dym razem  bit 1-czy fps jest sta�y czy zmienny
dd 10000   ;sta�a liczba klatek na sekund�  0-czekanie na klawisz
;ewentualna paleta
;ewentualne fonty


endl equ 0,126
endf equ 0,127
color equ 0,125

@@:
dw @f-@r
db 1
;dd odst�p czasowy
db " () ",endl
db " [] ",endl
db " || ",endl,endf
@@:
dw @f-@r
db 1
db " () ",endl
db "/[]\",endl
db " || ",endl
@@:
dw @f-@r
db 1
db " () ",endl
db "-[]-",endl
db " || ",endl
@@:
dw @f-@r
db 1
db "\()/",endl
db " [] ",endl
db " || ",endl,endf
@@:
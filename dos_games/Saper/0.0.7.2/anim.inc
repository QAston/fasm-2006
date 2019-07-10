db "tfcg";format ograniczajacy wielkosc animacji do 80/50  z mo¿liwoœci¹ czekania na klawisz i FPS okreslanym w 15us odstêpach
;dw 50   ;wysokoœæ w znakach   0-50
;dw 80   ;szerokoœæ w znakach  0-80
;dd 4   ;liczba klatek animacji
db 0   ;g³ówny kolor
db 1110b  ;ustawienia     bit 0 0-redraw definiowany pierwszym bajtem 1-redraw za ka¿dym razem  bit 1-czy fps jest sta³y czy zmienny
dd 10000   ;sta³a liczba klatek na sekundê  0-czekanie na klawisz
;ewentualna paleta
;ewentualne fonty


endl equ 0,126
endf equ 0,127
color equ 0,125

@@:
dw @f-@r
db 1
;dd odstêp czasowy
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
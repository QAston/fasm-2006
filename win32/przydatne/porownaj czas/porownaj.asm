BWynik dd 0,0,0,0,0,0,0
BWyswietl dd 0,0,0,0,0
BWyswietl1 dd 0,0,0,0,0
Bczas1 dd 0
Bczas2 dd 0
BWTemp dd 0,0,0,0,0,0
poczatek:
invoke GTC
mov [Bczas1],eax
koniec:
invoke GTC
mov [Bczas2],eax
mov eax,[Bczas1]
sub [Bczas2],eax

_DOASCIIDZ [BWyswietl1],[Bczas2]
invoke	MessageBox,0,BWyswietl1,0,MB_OK

	GTC,'GetTickCount'
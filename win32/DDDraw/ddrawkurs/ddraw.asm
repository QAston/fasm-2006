format PE GUI 4.0
entry start
include 'ddraw.inc'
include 'win32a.inc'
section '.data' data readable writeable
TTytul db 'Mój pierwszy engine :p',0
CKlasa db 'DDraw engine',0
PObraz1 db 'data/dupa.bmp',0
PObraz2 db 'data/dupa2.gif',0

section '.bss' readable writeable

DDraw DirectDraw
DDSEkran DirectDrawSurface
DDSBufor DirectDrawSurface
DDSObraz DirectDrawSurface
ddscaps  DDSCAPS
ddsd	 DDSURFACEDESC
wc	 WNDCLASS
msg	 MSG
ddbltfx  DDBLTFX

HOkno dd ?
HInstance dd ?

szerokosc = 640
wysokosc = 480
OBRAZ_X = 40
OBRAZ_Y = 40
Obrazx = 150
Obrazy = 150

buffer rb 50000h
bytes_count dd ?
LZW_bits db ?
LZW_table rd (0F00h-2)*2
rekr RECT
robr RECT
struct Obraz
x dw ?
y dw ?
ends

section '.code' code readable executable
Start:
;okno
Inicjalizacja:
invoke DirectDrawCreate,0,DDraw,0
cominv DDraw,SetCooperativeLevel,[HOkno],DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN
cominv DDraw,SetDisplayMode szerokosc,wysokosc,16

mov    [ddsd.dwSize],sizeof.DDSURFACEDESC
mov    [ddsd.dwFlags],DDSD_CAPS or DDSD_BACKBUFFERCOUNT
mov    [ddsd.ddsCaps.dwCaps],DDSCAPS_PRIMARYSURFACE + DDSCAPS_FLIP + DDSCAPS_COMPLEX
mov    [ddsd.dwBackBuferCount],1
cominv DDraw,CreateSurface,ddsd,DDSEkran,0
mov    [ddsd.dwSize],sizeof.DDSURFACEDESC
mov    [ddsd.dwFlags],DDSD_CAPS or DDSD_HEIGHT or DDSDWIDTH
mov    [ddsd.ddsCaps.dwCaps],DDSCAPS_OFFSCREENPLAIN
mov    [ddsd.dwWidth],szerokosc
mov    [ddsd.dwHeight],wysokosc
cominv DDrawCreateSurface,ddsd,DDSBufor,0
mov    [ddscaps.dwCaps],DDSCAPS_BACKBUFFER
cominv DDSEkran,GetAttachedSurface,ddsdcaps,DDSBufor
;
;£adowanieObrazka
;
end
Czysc_ekran:
mov    [ddbltfx.dwSize],sizeof.ddbltfx
xor    eax,eax
mov    [ddbltfx.dwFillColor],eax
cominv DDSBufor,Blt,0,0,0,DDBLT_WAIT + DDBLT_DDFX + DDBLT_COLORFILL, ddbltfx
end
Rysuj_Obraz:
mov	[robr.left],0
mov	[robr.top.],0
mov	[robr.right],OBRAZ_X
mov	[robr.bottom],OBRAZ_Y
mov	[rekr.left],Obrazx
mov	[rekr.top],Obrazy
mov	[rekr.right],Obrazx + OBRAZ_X
mov	[rekr.bottom],Obrazy + OBRAZY
cominv	DDSBufor,Blt,rekr,[DDSObraz],robr,DDBLT_KEYSRC+DDBLT_WAIT,0
end
Zwolnij:
test	[DDraw],0
jne	 zw2
test	[DDSEkran],0
jne	 zw1
cominv DDSBufor,Relase
cominv DDSObraz,Relase
zw1:
cominv DDraw,Relase
xor    [DDraw],[DDraw]
zw2:
end
RysujEkran:
;czysc ekran
;rysuj obrazek
cominv DDSEkran,Flip,0,DDFLIP_WAIT
end
Windowapi:









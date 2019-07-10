		format binary
		org 100h
		use16
;program equates
;*******************************************************************
		wp2 equ wyswietlpaletke2
		wp1 equ wyswietlpaletke1
		cp equ czyscpiksel
		up equ ustawpiksel
		klaw_p equ 0
		klaw_w equ 1
		klaw_a equ 2
		klaw_d equ 3
		klaw_gora equ 4
		klaw_prawo equ 5
		klaw_lewo equ 6
		klaw_esc equ 7
;start programu
;*******************************************************************
poczatek:	mov	ax,40h
		mov	gs,ax
		mov	ax,0013h
		int	10h
		mov	ax,0003h
		int	10h
		mov	ah,09h
		mov	dx,GrinGras
		int	21h
		xor	ah,ah
		int	16h
;menu
;*******************************************************************
menu:
		mov	ax,0003h       ;wybor opcji gry
		int	10h
		mov	ah,09h
		mov	dx,TMenu
		int	21h
menupobierzklawisz:
		xor	ah,ah
		int	16h
		cmp	al,'1'
		je	wyswietlswiat
		cmp	al,'2'
		je	AIstart
		cmp	al,'3'
		je	menuz
		cmp	al,'4'
		je	menua
		cmp	al,'5'
		je	koniec
		cmp	ah,01h
		je	koniec
		jmp	menupobierzklawisz

menuz:		mov	ah,09h
		mov	dx,TZasady
		int	21h
		xor	ah,ah
		int	16h
		jmp	menu

menua:		mov	ah,09h
		mov	dx,TAutor
		int	21h
		xor	ah,ah
		int	16h
		jmp	menu

AIstart:	mov	ah,09h	     ;wybor poziomu AI
		mov	dx,TPoziom
		int	21h
		xor	ah,ah
		int	16h
		xor	dx,dx
		inc	dx
		xor	bx,bx
		cmp	al,'1'
		cmove	bx,dx
		inc	dx
		cmp	al,'2'
		cmove	bx,dx
		inc	dx
		cmp	al,'3'
		cmove	bx,dx
		cmp	al,'4'
		jae	menu
		cmp	al,'1'
		jb	menu
		mov	byte[poziomAI],bl
;poczatek gry
;*******************************************************************
wyswietlswiat:	mov	ax,0013h
		int	10h
		mov	ax,0a000h
		mov	es,ax
		mov	al,4

sciany: 	movzx	di,al
		dec	al
		mov	ah,204

sciana1:	dec	ah
		mov	byte [es:di],15
		add	di,320
		test	ah,ah
		jnz	sciana1
		cmp	al,-1
		jnz	sciany
		mov	al,179

sciany1:	movzx	di,al
		dec	al
		mov	ah,204

sciana2:	dec	ah
		mov	byte [es:di],15
		add	di,320
		test	ah,ah
		jnz	sciana2
		cmp	al,174
		jne	sciany1
		mov	bp,320+200	      ;rysowanie nomerow
		call	up		      ;graczy
		mov	bp,320*6+200
		call	up
		mov	bp,320*11+200
		call	up
		mov	bp,320+230
		call	up
		mov	bp,320*6+230
		call	up
		mov	bp,320*11+230
		call	up
		mov	bp,320+236
		call	up
		mov	bp,320*6+236
		call	up
		mov	bp,320*11+236
		call	up

wyswietlelem:	mov	bh,90		     ;wyswietlenie pilki i paletek
		mov	bl,100			;do bx pozycja pi³ki
		call	odswierzelem
		call	konw
		call	up
					     ;losowanie kierunku lotu pilki
		xor	dx,dx
		mov	al,[gs:6ch]
		and	al,3
		test	al,1
		je	bit1to0

bit2:		test	al,2
		je	bit2to0
		jmp	bitkon

bit1to0:	not	dl
		jmp	bit2

bit2to0:	not	dh

bitkon:

zmienINT9:	push	ax es		   ;zmien adres int 9
		mov ax, 0
		mov es, ax
		cli
		mov ax,[es:9*4]
		mov word[staryint9], ax
		mov ax,[es:9*4 + 2]
		mov word [staryint9+2], ax
		mov word [es:9*4],scankeyboard
		mov [es:9*4+2],cs
		mov ax,[es:8h*4]
		mov word[staryint8], ax
		mov ax,[es:8*4 + 2]
		mov word [staryint8+2], ax
		mov word [es:8*4],scantime
		mov [es:8*4+2],cs
		sti
		pop	es ax

;glowna petla gry
;*******************************************************************
gra:
		inc	dword[licznik]
		call	sprklaw
		call	czekaj
		call	pilkaproc
		call	sprpunkty
		cmp	[poziomAI],0h
		jne	ruchAI
		jmp	gra

scantime:
		inc    [time]
		inc    [time]
		inc    [time]
		jmp    [staryint8]

;sprawdz bufor klawiatury
;*******************************************************************
sprklaw:	cmp	byte[bufor+klaw_lewo],01h
		je	ldol

posprdl:	cmp	byte[bufor+klaw_prawo],01h
		je	pdol

posprdp:	cmp	byte[bufor+klaw_a],01h
		je	lgor

posprgl:	cmp	byte[bufor+klaw_d],01h
		je	pgor

posprgp:	cmp	byte[bufor+klaw_esc],01h
		je	domenu1
		cmp	byte[bufor+klaw_p],01h
		je	pauza
		ret

pauza:		call	wyswp;obsluga pauzy
		PUSH	[time]
		mov	byte[bufor+klaw_p],0h

pauzap: 	call	czekaj
		cmp	byte[bufor+klaw_p],01h
		jne	pauzap
		call	czyscp
		call	czekaj
		mov	dword[time],0
		pop	[time]
		ret

;sprawdz klawisze
;*******************************************************************
scankeyboard:	push	ax cx
		in	al, 0x60
		cmp	al,04bh
		sete	cl
		cmp	al,0cbh
		sete	ch
		cmp	cl,ch
		je	scanprawo
		mov	byte[bufor+klaw_lewo],cl
scanprawo:	xor	cx,cx
		cmp	al,04dh
		sete	cl
		cmp	al,0cdh
		sete	ch
		cmp	cl,ch
		je	scangora
		mov	byte[bufor+klaw_prawo],cl
scangora:	xor	cx,cx
		cmp	al,048h
		sete	cl
		cmp	al,0c8h
		sete	ch
		cmp	cl,ch
		je	scana
		mov	byte[bufor+klaw_gora],cl
scana:		xor	cx,cx
		cmp	byte[poziomAI],0
		jne	scanp_esc
		cmp	al,01eh
		sete	cl
		cmp	al,09eh
		sete	ch
		cmp	cl,ch
		je	scand
		mov	byte[bufor+klaw_a],cl
scand:		xor	cx,cx
		cmp	al,020h
		sete	cl
		cmp	al,0a0h
		sete	ch
		cmp	cl,ch
		je	scanw
		mov	byte[bufor+klaw_d],cl
scanw:		xor	cx,cx
		cmp	al,011h
		sete	cl
		cmp	al,091h
		sete	ch
		cmp	cl,ch
		je	$+2
		mov	byte[bufor+klaw_w],cl
scanp_esc:	cmp	al,19h
		sete	[bufor+klaw_p]
		cmp	al,01h
		sete	[bufor+klaw_esc]
		mov	al, 0x20
		out	0x20, al
		pop	cx ax
		iret

czekaj: 	push ax cx
		xor ax,ax
		inc ax
		inc ax
		inc ax
		cmp [licznik],100
		cmovb cx,ax
		jb  czekczas
		dec ax
		dec ax
		cmp [licznik],400
		cmova cx,ax
		ja  czekczas
		inc ax
		mov cx,ax
czekczas:
		cmp [time],3
		jb czekczas
		cli
		sub [time],cx
		sti
		pop cx ax
		ret

;sprawdzanie punktow ,serwy
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sprpunkty:	cmp	bl,5	       ;czy ktos zdobywa punkt
		jb	punktd
		cmp	bl,195
		jae	punktg
		ret

ktoszwyciezyl:
		mov	byte[bufor+klaw_esc],01h
		ret

punktg: 	xor	dl,dl		;punkt dla gornego
		inc	byte[punktyg]
		mov	dword[licznik],0
		call	wyswpunkty
		cmp	byte[punktyg],11
		je	ktoszwyciezyl
		call	konw
		call	cp
		call	czyscekran
		call	odswierzelem

gsprklaw:	push	si		 ;gorny serwoje
		mov	bl,5
		mov	ax,si
		add	al,15
		mov	bh,al
		call	konw
		call	up
		cmp	[poziomAI],0
		jne	gsprklawAI
		call	czekaj
		call	sprklaw
		mov	bp,sp
		cmp	si,[ss:bp]
		jne	gsprcp

gsprdalej:	add	sp,2
		cmp	byte[bufor+klaw_w],01h
		jne	gsprklaw
		push	[time]
gsprpetla:
		mov	dx,02h
		mov	ax,0ffffh
		cmp	byte[bufor+klaw_d],01h
		cmove	dx,ax
		mov	ax,0ffh
		cmp	byte[bufor+klaw_a],01h
		cmove	dx,ax
		call	czekaj
		call	sprklaw
		cmp	dx,02h
		je	gsprpetla
		mov	dl,0ffh
		pop	[time]
		ret

gsprcp: 	call	konw
		call	cp
		jmp	gsprdalej

gsprklawAI:	add	sp,2
		mov	dl,0ffh
		ret

punktd: 	cmp	[poziomAI],0	 ;dolny gracz zdobywa punkt
		je	punktdzacznij
		call	czyscAI
punktdzacznij:
		mov	dl,0ffh
		inc	byte[punktyd]
		mov	dword[licznik],0
		call	wyswpunkty
		cmp	byte[punktyd],11
		je	ktoszwyciezyl
		call	konw
		call	cp
		call	czyscekran
		call	odswierzelem

dsprklaw:	push	di		  ;dolny gracz serwuje
		mov	bl,190
		mov	ax,di
		add	al,15
		mov	bh,al
		call	konw
		call	up
		call	czekaj
		call	sprklaw
		mov	bp,sp
		cmp	di,[ss:bp]
		jne	dsprcp

dsprdalej:	add	sp,2
		cmp	byte[bufor+klaw_gora],01h
		jne	dsprklaw
		push	[time]

dsprpetla:
		mov	dx,02h
		mov	ax,0ff00h
		cmp	byte[bufor+klaw_prawo],01h
		cmove	dx,ax
		xor	ax,ax
		cmp	byte[bufor+klaw_lewo],01h
		cmove	dx,ax
		call	sprklaw
		call	czekaj
		cmp	dx,02h
		je	dsprpetla
		xor	dl,dl
		pop	[time]
		ret

dsprcp: 	call	konw
		call	cp
		jmp	dsprdalej

punktkon:	ret

;wyjscie do menu i z gry
;********************************************************************
domenu1:	mov	byte[bufor+klaw_esc],0h  ;gdy wcisniento esc
		pop	ax
		call	domenu
		mov	al,[punktyd]
		mov	ah,[punktyg]
		cmp	al,11
		je	zwyc
		cmp	ah,11
		je	zwyc
		call	czysczmienne
		jmp	menu

domenu: 				      ;wyzeroj zmienne przed wyjsciem do menu
		push	ax es
		mov	ax, 0
		mov	es, ax
		cli
		mov	ax, word [staryint8]
		mov	[es:8*4], ax
		mov	ax, word [staryint8+2]
		mov	[es:8*4+2], ax
		mov	ax, word [staryint9]
		mov	[es:9*4], ax
		mov	ax, word [staryint9+2]
		mov	[es:9*4+2], ax
		sti
		pop	es ax
		ret
czysczmienne:
		mov	byte[bufor+klaw_esc],0
		mov	byte[bufor+klaw_prawo],0h
		mov	byte[bufor+klaw_lewo],0h
		mov	byte[bufor+klaw_w],0h
		mov	byte[bufor+klaw_gora],0h
		mov	byte[bufor+klaw_a],0h
		mov	byte[bufor+klaw_d],0h
		mov	byte[punktyg],0
		mov	byte[punktyd],0
		mov	byte[poziomAI],0
		mov	word[time],0
		mov	dword[licznik],0
		ret

;********************************************************************
zwyc:
		mov	ax,0003h
		int	10h
		mov	ah,09h
		mov	dx,TWygral	   ;wyswietl puchar
		int	21h
		mov	al,[punktyd]
		cmp	[punktyg],al
		ja	zwycgora
		mov	ah,09h		     ;jak wygral dolny
		mov	dx,TWygral1
		jmp	zwyc2

zwycgora:	mov	ah,09h		;jak wygral gorny
		mov	dx,TWygral2

zwyc2:		int	21h
		call	czysczmienne
		xor	ah,ah
		int	16h
		jmp	menu

koniec: 	mov	ax,4c00h		  ;zakoncz program
		int	21h

;animacje paletek
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

odswierzelem:	mov	di,75
		mov	si,75
		call	wp1
		call	wp2
		mov	bp,0
		call	up
		mov	bp,175
		call	up
		mov	bp,320*195+175
		call	up
		mov	bp,320*195
		call	up
		ret

ldol:		cmp	di,5
		je	posprdl
		mov	bp,di
		add	bp,320*195+30
		call	cp
		sub	di,5
		mov	bp,di
		add	bp,320*195
		call	up
		jmp	posprdl

pdol:		cmp	di,140
		je	posprdp
		mov	bp,di
		add	bp,320*195
		call	cp
		add	di,5
		mov	bp,di
		add	bp,320*195+30
		call	up
		jmp	posprdp

lgor:		cmp	si,5
		je	posprgl
		mov	bp,si
		add	bp,30
		call	cp
		sub	si,5
		mov	bp,si
		call	up
		jmp	posprgl

pgor:		cmp	si,140
		je	posprgp
		mov	bp,si
		call	cp
		add	si,5
		mov	bp,si
		add	bp,30
		call	up
		jmp	posprgp

;litera p
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

wyswp:		mov	bp,320*80+80
		call	up
		mov	bp,320*85+80
		call	up
		mov	bp,320*90+80
		call	up
		mov	bp,320*95+80
		call	up
		mov	bp,320*100+80
		call	up
		mov	bp,320*80+85
		call	up
		mov	bp,320*80+90
		call	up
		mov	bp,320*85+90
		call	up
		mov	bp,320*90+90
		call	up
		mov	bp,320*90+85
		call	up
		ret

czyscp: 	mov	bp,320*80+80
		call	cp
		mov	bp,320*85+80
		call	cp
		mov	bp,320*90+80
		call	cp
		mov	bp,320*95+80
		call	cp
		mov	bp,320*100+80
		call	cp
		mov	bp,320*80+85
		call	cp
		mov	bp,320*80+90
		call	cp
		mov	bp,320*85+90
		call	cp
		mov	bp,320*90+90
		call	cp
		mov	bp,320*90+85
		call	cp
		ret

;obsloga AI
;********************************************************************
czyscAI:	mov	byte[bufor+klaw_a],0h
		mov	byte[bufor+klaw_d],0h
		ret

ruchAI: 	mov	al,[gs:6ch]
		cmp	[poziomAI],2
		ja	poziom3
		jb	poziom1

poziom2:	test	al,1
		je	gra
		test	al,2
		je	gra
		test	al,3
		je	gra
		test	al,4
		je	gra
		jmp	ruch1

poziom1:	test	al,1
		jne	ruch1

wyjdzAI:	call	czyscAI
		jmp	gra

poziom3:	test	al,2
		jne	ruch1
		test	al,1
		jne	ruch1

ruchp1: 	test	al,3
		jne	ruch1
		jmp	wyjdzAI

ruch1:		test	dl,dl
		jz	ruch11
		call	czyscAI
		jmp	gra

ruch11: 	mov	ax,si
		test	dh,dh
		jz	sprlAI

sprpAI: 	cmp	al,bh
		jb	ruchAIp
		call	czyscAI
		jmp	gra

ruchAIp:	mov	byte[bufor+klaw_a],0h
		mov	byte[bufor+klaw_d],01h
		jmp	gra

sprlAI: 	add	al,30
		cmp	al,bh
		ja	ruchAIl
		call	czyscAI
		jmp	gra

ruchAIl:	mov	byte[bufor+klaw_d],0h
		mov	byte[bufor+klaw_a],01h
		jmp	gra
;wyswietlanie punktow
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

wyswpunkty:	mov	al,[punktyd]
		mov	ah,[punktyg]
		mov	bp,320*20+200

wyswp1: 	test	al,al
		jz	wyswp2
		push	ax
		call	up
		pop	ax
		add	bp,320
		dec	al
		jmp	wyswp1

wyswp2: 	mov	bp,320*20+233

wyswp3: 	test	ah,ah
		jz	wyswp4
		push	ax
		call	up
		pop	ax
		add	bp,320
		dec	ah
		jmp	wyswp3

wyswp4: 	ret

;wyswietlenie elementow
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wyswietlpaletke1:mov	bp,di
		add	bp,195*320
		mov	al,5

paletka1:	mov	ah,35
paletka2:	mov	byte [es:bp],15
		inc	bp
		dec	ah
		test	ah,ah
		jnz	paletka2
		dec	al
		add	bp,285
		test	al,al
		jnz	paletka1
		ret

czyscekran:	mov	bp,di
		add	bp,195*320
		mov	al,5

cpaletka1:	mov	ah,35
cpaletka2:	mov	byte [es:bp],0
		inc	bp
		dec	ah
		test	ah,ah
		jnz	cpaletka2
		dec	al
		add	bp,285
		test	al,al
		jnz	cpaletka1
		mov	bp,si
		mov	al,5

cpaletka21:	mov	ah,35
cpaletka22:	mov	byte [es:bp],0
		inc	bp
		dec	ah
		test	ah,ah
		jnz	cpaletka22
		dec	al
		add	bp,285
		test	al,al
		jnz	cpaletka21
		ret

wyswietlpaletke2:mov	bp,si
		mov	al,5
paletka21:	mov	ah,35
paletka22:	mov	byte [es:bp],15
		inc	bp
		dec	ah
		test	ah,ah
		jnz	paletka22
		dec	al
		add	bp,285
		test	al,al
		jnz	paletka21
		ret

czyscpiksel:	mov	al,5
czysc1: 	mov	ah,5
czysc2: 	mov	byte [es:bp],0
		inc	bp
		dec	ah
		test	ah,ah
		jnz	czysc2
		dec	al
		add	bp,315
		test	al,al
		jnz	czysc1
		ret

ustawpiksel:	mov	al,5
ustaw1: 	mov	ah,5
ustaw2: 	mov	byte [es:bp],15
		inc	bp
		dec	ah
		test	ah,ah
		jnz	ustaw2
		dec	al
		add	bp,315
		test	al,al
		jnz	ustaw1
		ret

;animacja pilki
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
pilkadp:	call	konw
		call	cp
		add	bh,5
		add	bl,5
		call	konw
		call	up
		ret

pilkadl:	call	konw
		call	cp
		sub	bh,5
		add	bl,5
		call	konw
		call	up
		ret

pilkagl:	call	konw
		call	cp
		sub	bh,5
		sub	bl,5
		call	konw
		call	up
		ret

pilkagp:	call	konw
		call	cp
		add	bh,5
		sub	bl,5
		call	konw
		call	up
		ret

konw:
		mov	ax,320
		movzx	bp,bl
		push	dx
		mul	bp
		pop	dx
		movzx	bp,bh
		add	bp,ax
		ret

;kolizje i ruch pilki
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
pilkaproc:	cmp	dl,0ffh
		je	pilecz01  ;czy bit 0 jest zerem
		cmp	dh,0ffh
		je	pilecz10 ;czy bit 1 jest zerem
		call	pilkagl      ;00 goralewo
		jmp	pildal

pilecz01:	cmp	dh,0ffh
		je	pilecz00  ;czy bit 1 jest zerem
		call	pilkadl      ;10 dollewo
		jmp	pildal

pilecz10:	call	pilkagp      ;01 goraprawo
		jmp	pildal
pilecz00:	call	pilkadp 	;11 dolprawo

pildal: 	cmp	bl,190
		jb	pilkadalej
		mov	ax,di
		test	dh,dh
		jz	dsprukp
		sub	al,5
		cmp	bh,al
		jb	dsprdol
		add	al,35
		cmp	bh,al
		ja	pilkakon
		sub	al,35
		cmp	bh,al
		ja	odbzwykle

odbodwr:	not	dx
		jmp	pilkadal
odbzwykle:	not	dl
		jmp	pilkadal

dsprukp:	add	al,5
		cmp	bh,al
		jb	dsprdol
		add	al,30
		cmp	bh,al
		ja	pilkadal
		cmp	bh,al
		jb	odbzwykle
		jmp	odbodwr

dsprdol:	mov	ax,di
		cmp	bh,al
		jb	pilkadal
		add	al,35
		cmp	bh,al
		ja	pilkadal
		jmp	odbzwykle

pilkadalej:	cmp	bl,5
		ja	pilkadal
		mov	ax,si
		mov	bh,bh
		test	dh,dh
		jz	gsprukp
		sub	al,5
		cmp	bh,al
		jb	gsprdol
		add	al,35
		cmp	bh,al
		ja	pilkadal
		sub	al,35
		cmp	bh,al
		ja	odbzwykle
		jmp	odbodwr

gsprukp:	add	al,5
		cmp	bh,al
		jb	gsprdol
		add	al,30
		cmp	bh,al
		ja	pilkadal
		cmp	bh,al
		jb	odbzwykle
		jmp	odbodwr

gsprdol:	mov	ax,si
		cmp	bh,al
		jb	pilkadal
		add	al,35
		cmp	bh,al
		ja	pilkadal
		jmp	odbzwykle

pilkadal:	cmp	bh,5
		je	pion
		cmp	bh,170
		je	pion
		ret

pion:		not	dh
pilkakon:	ret
;dane
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
punktyd:	db	0
punktyg:	db	0
poziomAI	db	0
TMenu:
db ' @@@@@@@@@',10,13
db '  @@     @@                                      [R]',10,13
db '  @@     @@                @@',10,13
db '  @@@   @@     @@@@@    @@@@@@@@  @@  @    @@@@@',10,13
db '  @@@@@@@     @@    @@     @@     @@@@@@  @@   @@',10,13
db '  @@    @@    @@    @@     @@     @@   @  @@   @@',10,13
db '  @@     @@   @@@@@@       @@     @@      @@   @@',10,13
db '  @@     @@   @@           @@     @@      @@   @@',10,13
db ' @@@@   @@@@   @@@@@@      @@     @@       @@@@@',10,13
db '                                      @@@@@@@@@',10,13
db '                                       @@     @@',10,13
db '         ###                           @@     @@',10,13
db '         ###                           @@@   @@   @@@@@   @@ @@@@     @@@@@',10,13
db '                                       @@@@@@@   @@   @@   @@@  @@   @@   @@',10,13
db '   #################                   @@        @@   @@   @@   @@   @@   @@',10,13
db '   #################                   @@        @@   @@   @@   @@   @@   @@',10,13
db '                                       @@        @@   @@   @@   @@   @@   @@',10,13
db '1.Gracz vs. Gracz                     @@@@        @@@@@   @@@@ @@@@   @@@@@@',10,13
db '2.Gracz vs. Komputer                                                      @@',10,13
db '3.Zasady i sterowanie                                                     @@',10,13
db '4.Autorzy                                                             @@  @@' ,10,13
db '5.Wyjscie                                                              @@@@',10,13
db 10,13
db 'Wcisnij 1,2,3,4 lub 5 aby wybrac.',10,13,'$'
db 10,13
TZasady: db  10,13
db 'ZASADY GRY'
db 10,13
db 'Po uruchomieniu gry widzimy dwie paletki, sciany i miejsce na punktacje'
db ' (I i II z prawej strony ekranu). Wcisniecie dowolnego klawisza powoduje, ze pilka leci w losowym kierunku'
db ' Zadaniem graczy jest umieszczenie pileczki za paletka przeciwnika. Ten, kto pierwszy uczyni to 11 razy wygrywa'
db ' Gracz, ktory zdobyl punkt ma dodana kropke w punktacji i serwuje pilke. Gdy wcisnie sie klawisz serwu nalezy wybrac kierunek lotu pilki'
db ' Milej zabawy!'
db 10,13
db 'STEROWANIE'
db 10,13
db '[Esc]- wyjscie'
db 10,13
db '[p]-pauza'
db 10,13
db 'Gracz I (dolny):'
db 10,13
db 'Strzalki w prawo i w lewo- ruch paletki.'
db 10,13
db 'Strzalka w gore- serw.'
db 10,13
db 'Gracz II (gorny):'
db 10,13
db '[a]-paletka w lewo'
db 10,13
db '[d]-paletka w prawo'
db 10,13
db '[w]-serw.$'
TAutor:
db 'AUTORZY',10,13
db 'Studio Green Grass, w skladzie:',10,13
db 'Projekt, wykonanie, grafika, dzwiek, postaci i fizyke obiektow w grze stworzyl:'
db 10,13
db 'Dariusz Antoniuk'
db 10,13
db 'Betatestesty, projekt loga:'
db 10,13
db 'Pawel Kondraciuk'
db 10,13
db 'Wspolpraca:'
db 10,13
db 'Paulina i Agata Antoniuk'
db 10,13
db 'TEN PROGRAM JEST FREEWARE.'
db 10,13
db 'To jest miejsce na twoja reklame.$'
TPoziom:
db 'Poziom inteligencji komputera: 1,2 lub 3.$'
TWygral:
db '   _______ ',10,13
db '/\|\_____/|/\',10,13
db '\/|       |\/',10,13
db '   \     /',10,13
db '    \   /',10,13
db '   _|   |_',10,13
db '  |_______|',10,13
db 10,13,'$'
GrinGras:
db '    #####',10,13
db '  #########',10,13
db ' ####    ###',10,13
db '####      ##  #### ##    ######       ######    #### ##',10,13
db '####           ####### ####  ####   ####  ####   ########',10,13
db '####   ######  ###  #  ###    ###   ###    ###   ###  ###',10,13
db '####    ####   ###     ##########   ##########   ###  ###',10,13
db '#####   ####   ###     ###          ###          ###  ###',10,13
db '  ##########   ###     ####   ###   ####   ###   ###  ###',10,13
db '    #####     #####      #######      ######    ##### #####',10,13
db 10,13
db '                        #####',10,13
db '                      #########',10,13
db '                     ####    ###',10,13
db '                    ####      ##  ####  ##     ####      #####      #####',10,13
db '                    ####           ########  ###  ###   ##   ##    ##   ##',10,13
db '                    ####   ######  ###  #    ##    ##   ###        ### ',10,13
db '                    ####    ####   ###         ######    #####      ####',10,13
db '                    #####   ####   ###       ###   ##        ###       ###',10,13
db '                      ##########   ###       ##    ##   ##    ##  ##    ##',10,13
db '                        #####     ######      ##### ##   ######    ######',10,13
db 10,13
db 10,13
db '                                   STUDIO',10,13 ,'$'
TWygral1:	db 'Wygral gracz numer I!$'
TWygral2:	db 'Wygral gracz numer II!$'
staryint9:	dd 0
staryint8	dd 0
bufor:		dd 0,0
time		dw 0
licznik 	dd 0




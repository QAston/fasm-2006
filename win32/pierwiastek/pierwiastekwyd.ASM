Format PE GUI 4.0
entry start
include 'win32axp.inc'
include 'bibl\doascii.asm'
section '.data' data readable writeable
DLiczba dd  1073741824,0,0
db 0
DStopien dd 30
BWynik dd 0
BWyswietl dd 0,0,0,0,0,0
BWTemp dd 0,0,0,0,0,0
LDziesiec dw 10,0
LCyfr dw 0
section '.code' code readable executable
start:

_ilecyfr:
fninit
fild word [LDziesiec]
fld1
fld dword [DLiczba]
_ilecyfr_p1:
fdiv st0,st2
inc [LCyfr]
fcomi st0,st1
jnb   _ilecyfr_p1
fincstp
ffree st7
			     ;st0: 10 st1: 1

_ilecyfr_ma_pierwiastek:
fild dword [DStopien]
fild word [LCyfr]
			     ;st0: Lcyfr st1:DStopien st2:1 st3:10
fdivrp st1,st0
fld st0
frndint
fxch st1
fcomip st0,st1
je _pierwiastkuj
fadd  st0,st1
fistp word[LCyfr]      ;st0:1    st1:10
_pierwiastkuj:
fldz
fild dword [DLiczba]
		;st0:DLiczba st1:0 st2:1 st3:10
fld st2
		;st0:1 st1:DLiczba st2:0 st3:1 st4:10
mov ax,[LCyfr]
_pierwiastkuj_p1:
dec ax
test ax,ax
je  _prepetla
fmul st0,st4
jmp  _pierwiastkuj_p1
		;st0:10^LCyfr st1:DLiczba st2:0 st3:1 st4:10
_prepetla:
fxch st2
		;st0:0 st1:DLiczba 2:10^LCyfr st3:1 st4:10
petla:
fadd st0,st2
fld st0
mov ax,word[DStopien]
_pierwiastkuj_p2:
dec ax
test ax,ax
je  _pierwiastkuj_p3
fmul st0,st1
jmp _pierwiastkuj_p2
_pierwiastkuj_p3:
fcomip st0,st2
je wyswietl
jb petla
fsub st0,st2
fxch st2
fdiv st0,st4
fxch st2
jmp petla

wyswietl:
fist [BWynik]
mov [LCyfr],0
_DOASCIID [BWyswietl],[BWynik]
invoke	MessageBox,0,BWyswietl,0,MB_OK


koniec:
invoke	ExitProcess,0
section '.idata' import data readable writeable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
  import kernel32,\
	ExitProcess,'ExitProcess'
  import user32,\
	MessageBox,'MessageBoxA'


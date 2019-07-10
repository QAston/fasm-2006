Format PE GUI 4.0
entry start
include 'win32axp.inc'
section ".data" data readable writweable
cyfry		times	5000	db	0
DLiczba tw 6.6
DDziesiec db 10
BWyswietl tw 0,0
dw 0
section '.code' readable executable
start:
fninit
fnstcw	[status]
or	word [status], (0ch << 8)	; zaokraglanie: obcinaj
fldcw	[status]
fld tword [DLiczba]
ftst
fstsw	[status]
mov	ax, [status]
and	ah, 01000101b
jz	._pjp_ok		; st(0) > 0?
cmp	ah, 01000101b		; zla liczba?
jne	._pjp_l_ok
jmp	koniec
._pjp_l_ok:
cmp	ah, 01000000b		; st(0)=0?
je	._pjp_zero
cmp	ah, 1
jne	koniec
fchs
mov	[BWyswietl], '-'
fild	word [DDziesiec]	   ; ladujemy liczbe calkowita 10

koniec:
invoke	ExitProcess,0
section '.idata' import data readable writeable
 library kernel32,'KERNEL32.DLL',\
	 user32,'USER32.DLL'
  import kernel32,\
	ExitProcess,'ExitProcess',\
  import user32,\
	MessageBox,'MessageBoxA'
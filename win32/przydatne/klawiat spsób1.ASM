MOV	AL,09h			  ; Get INT 09h address
MOV	AH,35h
INT	21h
MOV	[oldint9],BX		  ; Save it for later
MOV	[oldint9+2],ES
MOV	AL,09h			  ; Set new INT 09h
MOV	DX,Newint9	  ; DS:DX = new interrupt
MOV	AH,25h
INT	21h



Newint9:
pusha	
;Do some thing here       
mov	al, 0x20
out	0x20, al	
; If you do something like, jump exit do it here, after the above code.     
popa
IRET



ReStoreInt9:
MOV	AL,09h			  ; Restore original INT 09h
MOV	DX,[oldint9]
MOV	DS,[oldint9+2]		  ; Move old INT 09H pointer to DS:DX
MOV	AH,25h
INT	21h
RET
 

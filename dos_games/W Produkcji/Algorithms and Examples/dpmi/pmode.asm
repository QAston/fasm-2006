format mz
heap 0

include 'loader.inc'

segment _code use32
code32:
koniec:
	xor ah,ah
	int 16h
Koniec:
	mov ax,4c00h
	int 21h

TMemoryErrorMsg        db      "Not enough conventional memory.",13,10,'$'
TOutOfMemoryErrorMsg   db      'Out of memory',13,10,'$'
AProgramBase	       dd      0
ABuffer 	       dd      0
ADPMIModeSwitch        dd      0
AMemoryStart	       dd      0
AMemoryEnd	       dd      0
AAdditionalMemory      dd      0
AAdditionalMemoryEnd   dd      0
MemoryBlockHandle      dd      0


segment _buffer
rb 1000h
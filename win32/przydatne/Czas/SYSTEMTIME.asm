procedura sprawdzaj¹ca dzieñ i miesi¹c:
mov ebp,esp
sub esp,00000010h
lea edx,dword [ebp-10h]
invoke GST,edx
mov ax, word [ebp-0eh]
mov bx, word [ebp-0ah]
cmp ax,1
jne koniec
cmp bx,18
jne koniec
lub
proc sprdata
locals
syt SYSTEMTIME
endl
invoke GST,addr syt
mov ax,[syt.wMonth]
mov bx,[syt.wDay]
cmp ax,1
jne koniec
cmp bx,6
jne koniec
ret
endp
lub
section '.data' data readable writeable
syt SYSTEMTIME    
przydatne:
addres in kernel.dll: 7c816d4c

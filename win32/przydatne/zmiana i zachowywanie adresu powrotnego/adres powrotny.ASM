format PE GUI 4.0
entry start
include 'win32axp.inc'

proc dzwiecz
push 00501016h	    ;modyfikacja adresu powrotnego
invoke Beep,1000,1000
ret
endp

start:
call dzwiecz
invoke Beep,500,1000
invoke ExitProcess,0


data import
library kernel32,'KERNEL32.DLL'
import kernel32,\
       GetTickCount,'GetSystemTime',\
       Beep,'Beep',\
       ExitProcess,'ExitProcess'
end data
;Wa¿ne!!!
;ten program modyfikuje adres powrotny[ret] z funkcji dzwiecz
;adres ten mozna zamieniæ pushem. wtedy po wyjsciu z procedury bedzie wykonywany
;kod znajdujacy sie pod tym adresem
;
;aby adres powrotny wskazywal na wlasciwe miejsce musi byc tyle samo
;push i pop w procedurze, lub musz¹ byæ zadeklarowane zmienne lokalne np.
;locals
;syt SYSTEMTIME
;endl
;mozna tez recznie zachowac wlasciwy adres powrotny na stosie
;mov ebp,esp
;[kod procedury z dowolna iloscia push i pop]
;mov esp,ebp
;ret
;
;instrukcje invoke nie zmieniaja adresu powrotnego


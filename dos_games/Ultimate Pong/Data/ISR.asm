;
;Plik z procedurami Interrupt Service Routime
;do czasomierza i klawiatury
;
butt_up equ 0
butt_down equ 1
butt_left equ 2
butt_right equ 3
butt_serve equ 4





segment KEYBDATA
Player1Conrol db 0,0,0,0,0
Playet2Control db 0,0,0,0,0
Player3Control db 0,0,0,0,0
Player4Control db 0,0,0,0,0
EscapeButton db 0
PauseButton db 0
OldInt9Addr dd 0

segment TIMERDATA
MSecCounter dw 0
TimerCounter db 0
OldInt8Addr dd 0
Format PE GUI 4.0
entry start
include 'win32a.inc'
section '.data' data readable writeable
include 'data/zmienne.asm'
section '.code' code readable executable
start:
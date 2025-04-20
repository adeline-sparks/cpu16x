; poweroff.asm
; Clear data ram, clear screen, wait for reset

#include "cpu16.inc"
#addr 0x40f5

poweroff:
  ; Clear data memory. R1 and R2 are already zerod.
  mov r3, 0x100
  call rom_memset

  ; Clear registers
  mov r2, 0
  mov r4, 0
  mov r6, 0
  mov r7, 0

  ; Clear displays
  lw r0, [dev_hex_clear]
  lw r0, [dev_hex_clear2]
  lw r0, [dev_screen_clear]

  ; Wait for reset
.done:
  j .done
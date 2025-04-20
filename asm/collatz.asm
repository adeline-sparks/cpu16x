#include "cpu16.inc"
#addr 0x4100

; r2 - current number
; r1 - temporary

collatz:
  lw r2, [dev_hex_in]

.loop:
  ; Update display
  sw r2, [dev_hex_out]

  ; Check if number is 1
  mov r1, 1
  beq r1, r2, collatz

  ; Check if number is even or odd
  and r1, r1, r2
  beqz r1, .loop_even

  ; Number is odd, compute r2 = 3*r2 + 1
  add r1, r2, r2
  add r2, r1, r2
  inc r2
  j .loop

.loop_even:
  ; Number is even, compute r2 = r2 / 2
  mov r1, -1
  ls r2, r2, r1
  j .loop





#include "cpu16.inc"
#addr 0x4100

  mov r6, 1
  lw r0, [dev_screen_clear]

shift_none:
  mov r1, 0

loop:
  ls r6, r6, r1
  mov r1, dev_screen_start + 4
  sw r6, [r1]
  lw r5, [dev_vsync_btn]
  mov r1, btn_left
  and r1, r1, r5
  bnez r1, shift_left
  mov r1, btn_right
  and r1, r1, r5
  bnez r1, shift_right
  j shift_none

shift_left:
  mov r1, 1
  j loop

shift_right:
  mov r1, -1
  j loop

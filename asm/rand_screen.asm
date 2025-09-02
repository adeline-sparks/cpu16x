#include "cpu16.inc"
#addr 0x4100

rand_screen:
  mov r3, dev_screen_end

.frame_loop:
  mov r2, dev_screen_start
.slice_loop:
  lw r1, [dev_rand]
  inc r2
  sw r1, [r2, -1]
  blt r2, r3, .slice_loop
  j .frame_loop
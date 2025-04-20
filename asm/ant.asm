; ant.asm
; Traces Langton's Ant across the bitmap screen.

#include "cpu16.inc"
#addr 0x4000

ant:
  sw rl, [0]                ; Save link register
  lw r0, [dev_screen_clear] ; Clear the screen
  mov r5, 0                 ; Dir (0 = left, 1 = up, 2 = right, 3 = down)
  mov r6, 16                ; X
  mov r7, 23                ; Y

.loop:
  ; Compute r2 = 1 << (X & 0xf).
  ; This is a bitmask for the ant's current position within the screen strip.
  mov r1, 0xf            
  and r2, r1, r6         
  mov r1, 1               
  ls r2, r1, r2          

  ; Compute r3 = (X >> 4) | (Y << 1) + screen_start.
  ; This is the address for the ant's current screen strip.
  mov r1, -4 
  ls r3, r6, r1
  add r1, r7, r7
  or r3, r3, r1
  mov r1, dev_screen_start
  add r3, r3, r1
  
  lw r4, [r3]            ; Load from screen to r4
  xor r1, r4, r2         ; Flip the bit at the ant's position.
  sw r1, [r3]            ; Update the screen

  and r1, r4, r2         ; Check the ant's bit before we flipped it.
  bnez r1, .rot_cc       ; Rotate counter clockwise if it was set.

.rot_c:
  add r5, r5, 2          ; Rotate clockwise (twice, because we fall through)
.rot_cc:
  dec r5                 ; Rotate counter-clockwise.

  mov r1, 0b11           ; Mask all but lower two bits to wrap around 0 <-> 3.               
  and r5, r5, r1

  ; Jump table to move ant based on direction. 
  lui r1, upper10(.mov_left)
  add r1, r1, r5
  add r1, r1, r5
  jr r1, lower6(.mov_left)
.mov_left:
  dec r6
  j .mov_done
.mov_up:
  dec r7
  j .mov_done
.mov_right:
  inc r6
  j .mov_done
.mov_down:
  inc r7

.mov_done:
  ; Make sure ant is inbounds and repeat the loop
  mov r1, 31
  bgt r6, r1, .done
  bgt r7, r1, .done
  j .loop

.done:
  lw rl, [0]      ; Restore link register
  ret

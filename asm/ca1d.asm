#include "cpu16.inc"
#addr 0x4050

; Holds return address for program
return_addr = 0
; Holds current rule
rule = 1
; Holds current X position inside screen strip (0-15)
strip_pos = 2
; Holds pointer to current screen strip
strip_ptr = 3

ca1d:
  ; Save return address
  sw r7, [return_addr]

  ; Clear screen
  lw r0, [dev_screen_clear]

  ; Initialize strip_ptr to first strip
  mov r1, dev_screen_start
  sw r1, [strip_ptr]

  ; Read rule
  lw r1, [dev_hex_in]
  sw r1, [rule]

  ; Read initial state
  lw r6, [dev_hex_in]
  beqz r6, init_rand
  lw r5, [dev_hex_in]

strip_pair_loop:
  ; Shift one pixel into neighborhood
  call shift_neighborhood

strip_loop:
  mov r2, 0

pixel_loop:
  sw r2, [strip_pos]

  ; Shift pixels right and update neighborhood
  call shift_neighborhood

  ; Lookup rule, skip setting pixel if zero.
  lw r2, [rule]
  sub r1, r0, r4
  ls r2, r2, r1
  mov r1, 1
  and r2, r2, r1
  lw r3, [strip_ptr]
  beqz r2, skip_set

  ; Shift pixel into position and update screen
  lw r2, [strip_pos]
  ls r2, r1, r2
  lw r1, [r3]
  or r1, r1, r2
  sw r1, [r3]

skip_set:
  ; Increment strip position
  lw r2, [strip_pos]
  inc r2
  mov r1, 16
  blt r2, r1, pixel_loop

next_strip:
  ; Advance to next strip
  inc r3
  sw r3, [strip_ptr]

  ; If next strip is odd, keep generating pixels with current state.
  mov r1, 1
  and r1, r3, r1
  bnez r1, strip_loop

  ; If next strip is even, we might be done
  mov r1, dev_screen_end
  beq r1, r3, done

  ; Otherwise, we need to reload two previous strips to our previous state.
  lw r6, [r3, -1]
  lw r5, [r3, -2]
  mov r4, 0
  j strip_pair_loop

init_rand:
  lw r5, [dev_rand]
  lw r6, [dev_rand]
  j strip_pair_loop

done:
  lw r7, [return_addr]
  ret
  
; r3r2r1 - scratch
; r4 - neighborhood in/out
; r6r5 - previous state in/out
shift_neighborhood:
  ; Grab rightmost bit of each register
  mov r1, 1
  and r3, r6, r1
  and r2, r5, r1

  ; Shift each register to the right one
  mov r1, -1
  ls r6, r6, r1
  ls r5, r5, r1
  ls r4, r4, r1

  ; Move rightmost bit of r5 to leftmost of r4
  mov r1, 2
  ls r2, r2, r1
  or r4, r4, r2

  ; Move rightmost bit of r6 to leftmost of r5
  mov r1, 15
  ls r3, r3, r1
  or r5, r5, r3
  ret

; life.asm
; Simulates conway's game of life from a random state

#include "cpu16.inc"
#addr 0x4090

; Holds the previous copy of the screen.
prev_state_start = 0x40
prev_state_end = 0x80

life:
  ; Initialize screen with random state
  mov r1, dev_screen_start
  mov r2, dev_screen_end
.init_loop:
  lw r3, [dev_rand]
  lw r4, [dev_rand]
  sw r3, [r1]
  sw r4, [r1, 1]
  add r1, r1, 2
  blt r1, r2, .init_loop

.frame_loop:
  ; Copy screen to prev_state
  mov r1, dev_screen_start
  mov r2, prev_state_start
  mov r3, 0x40
  call rom_memcpy

  ; Handle Y wrap
  ; Copy top below bottom
  mov r1, prev_state_start
  mov r2, prev_state_end
  lw r3, [r1]
  lw r4, [r1, 1]
  sw r3, [r2]
  sw r4, [r2, 1]
  ; Copy bottom below top
  lw r3, [r2, -2]
  lw r4, [r2, -1]
  sw r3, [r1, -2]
  sw r4, [r1, -1]

  ; Initialize Y
  mov r5, 0

.row_loop:
  ; Initialize X
  mov r4, 0

.pixel_loop:
  ; Initialize neighbor count
  mov r6, 0

  ; Compute right slice of prev_state into r3
  ; r3 = (2 * Y) + prev_state
  mov r1, prev_state_start
  add r1, r1, r5
  add r3, r1, r5

  ; Compute mask for right slice
  ; r2 = (X == 31) ? 0x1 : (0x7) <<>> (X - 1)
  mov r2, 0x1
  mov r1, 31
  beq r4, r1, .x_eq_31
  sub r2, r4, r2
  mov r1, 0x7
  ls r2, r1, r2
  beqz r2, .skip_right
.x_eq_31:

  ; Count bits in right slice, add to r6.
  lw r1, [r3]
  mskcnt r1, r2, r1
  add r6, r6, r1
  lw r1, [r3, -2]
  mskcnt r1, r2, r1
  add r6, r6, r1
  lw r1, [r3, 2]
  mskcnt r1, r2, r1
  add r6, r6, r1
.skip_right:

  ; Compute mask for left slice
  ; r2 = (X == 0) ? 0x8000 : (0x7) <<>> (X - 17)
  mov r2, 0x8000
  beqz r4, .x_eq_0
  mov r2, 17
  sub r2, r4, r2
  mov r1, 0x7
  ls r2, r1, r2
  beqz r2, .skip_left
.x_eq_0:

  ; Count bits in left slice, add to r6.
  lw r1, [r3, 1]
  mskcnt r1, r2, r1
  add r6, r6, r1
  lw r1, [r3, -1]
  mskcnt r1, r2, r1
  add r6, r6, r1
  lw r1, [r3, 3]
  mskcnt r1, r2, r1
  add r6, r6, r1
.skip_left:

  ; If neighborhood count is zero, nothing to do (pixel is dead, all neighbors dead)
  beqz r6, .next_pixel_loop

  ; Compute offset of pixel's slice (relative to screen or prev_state)
  ; r3 = (X >> 4) | (Y + Y)
  add r3, r5, r5
  mov r1, -4
  ls r1, r4, r1
  or r3, r3, r1

  ; Compute mask of pixel
  ; r2 = 1 << (X & 0xf)
  mov r1, 0xf
  and r2, r4, r1
  mov r1, 1
  ls r2, r1, r2

  ; Determine if pixel is alive
  mov r1, prev_state_start
  add r1, r1, r3
  lw r1, [r1]
  and r1, r1, r2
  beqz r1, .pixel_is_dead

  ; pixel is alive, stay alive if N==2 or N==3
  mov r1, 3
  beq r6, r1, .next_pixel_loop
  mov r1, 4
  beq r6, r1, .next_pixel_loop

  ; Otherwise, make pixel dead.
  j .flip_pixel

.pixel_is_dead:
  ; pixel is dead, stay dead if N != 3
  mov r1, 3
  bne r6, r1, .next_pixel_loop

.flip_pixel:
  ; Flip pixel by doing a read, xor, write to the screen.
  mov r1, dev_screen_start
  add r3, r1, r3
  lw r1, [r3]
  xor r1, r1, r2
  sw r1, [r3]

.next_pixel_loop:
  ; Move to next row if X == 31
  mov r1, 31
  beq r4, r1, .next_row_loop

  ; Increment X and go to next pixel
  inc r4
  j .pixel_loop, r7

.next_row_loop:
  ; Move to next frame if Y == 31
  beq r5, r1, ..goto_frame_loop

  ; Increment Y and go to next row
  inc r5
  j .row_loop, r7

..goto_frame_loop:
  j .frame_loop, r7


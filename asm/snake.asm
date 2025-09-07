#include "cpu16.inc"
#addr 0x4100

snake_pos_tail = 0x00
snake_pos_head = 0x01
snake_dx = 0x02
snake_dy = 0x03

food_x = 0x04
food_y = 0x05
score = 0x06

snake_pos_buf = 0x10
snake_pos_mask = 0x3f

start_snake_len = 4
start_snake_x = 4
start_snake_y = 8

init:
  lw r0, [dev_screen_clear]

  ; Initialize snake_pos_head and snake_pos_tail
  mov r5, start_snake_len
  sw r5, [snake_pos_head]
  sw r0, [snake_pos_tail]

  ; Initialize snake_dx and snake_dy (moving right)
  mov r1, 1
  sw r1, [snake_dx]
  sw r0, [snake_dy]

  ; initialize score
  sw r0, [score]
  sw r0, [dev_hex_out]

  mov r4, 0
.pos_loop:
  ; Compute (x, y) = (start_snake_x + counter, start_snake_y)
  add r1, r4, start_snake_x
  mov r2, start_snake_y

  ; Store (x, y) to snake_pos_buf[counter * 2]
  add r3, r4, r4
  sw r1, [r3, snake_pos_buf]
  sw r2, [r3, snake_pos_buf+1]

  ; Toggle pixel at (X, Y)
  call pixel_address
  lw r3, [r2]
  or r3, r3, r1
  sw r3, [r2]

  ; Advance loop (r5 = start_snake_len)
  inc r4
  blt r4, r5, .pos_loop

.init_food:
  call roll_new_food

  ; Repeat if food is in the starting snake Y
  lw r1, [food_y]
  mov r2, start_snake_y
  beq r1, r2, .init_food

  ; Set pixel at food location
  call pixel_address
  lw r3, [r2]
  or r3, r3, r1
  sw r3, [r2]

  j game_loop
#addr 0x4128
game_loop:

.process_input:
  lw r1, [dev_vsync_btn]

  ; Check for up and left (both use -1)
  mov r3, -1
  mov r2, btn_up
  and r2, r1, r2
  bnez r2, ..up_down
  mov r2, btn_left
  and r2, r1, r2
  bnez r2, ..left_right

  ; Check for down and right (both use 1)
  mov r3, 1
  mov r2, btn_down
  and r2, r1, r2
  bnez r2, ..up_down
  mov r2, btn_right
  and r2, r1, r2
  bnez r2, ..left_right

  j .move_head

..up_down:
  ; Ignore input if we are already going up or down
  lw r1, [snake_dx]
  beqz r1, .move_head

  ; Zero out dx, update dy
  sw r0, [snake_dx]
  sw r3, [snake_dy]
  j .move_head

..left_right:
  ; Ignore input if we are already going left or right
  lw r1, [snake_dy]
  beqz r1, .move_head

  ; Zero out dy, update dx
  sw r0, [snake_dy]
  sw r3, [snake_dx]

.move_head:
  ; Load X, Y at head of snake
  lw r4, [snake_pos_head]
  lw r1, [r4, snake_pos_buf]
  lw r2, [r4, snake_pos_buf + 1]

  ; Advance snake to get X, Y of new head
  lw r3, [snake_dx]
  add r1, r1, r3
  lw r3, [snake_dy]
  add r2, r2, r3

  ; Check bounds
  mov r3, 31
  bgt r1, r3, game_over
  bgt r2, r3, game_over

  ; Advance head position
  inc r4
  mov r3, snake_pos_mask
  and r4, r4, r3
  sw r4, [snake_pos_head]

  ; Store X, Y of new head
  sw r1, [r4, snake_pos_buf]
  sw r2, [r4, snake_pos_buf + 1]

  ; Check if food was not eaten
  lw r3, [food_x]
  bne r1, r3, ..skip_food
  lw r3, [food_y]
  bne r2, r3, ..skip_food
  
  ; Leave food pixel as part of snake, roll new food pixel
  call roll_new_food

  ; Set pixel at food location
  call pixel_address
  lw r3, [r2]
  or r3, r3, r1
  sw r3, [r2]

  ; Update score
  lw r1, [score]
  inc r1
  sw r1, [score]
  sw r1, [dev_hex_out]

  j game_loop
  
..skip_food:
  ; Get pixel at head of snake
  call pixel_address

  ; Check for collision, this is game over
  lw r3, [r2]
  and r4, r3, r2
  bnez r3, game_over

  ; Set pixel for head
  or r3, r3, r2
  sw r3, [r2] 

.move_tail:
  ; Load X, Y of the tail of the snake
  lw r4, [snake_pos_tail]
  lw r1, [r4, snake_pos_buf]
  lw r2, [r4, snake_pos_buf + 1]

  ; Remove pixel at tail of snake
  call pixel_address
  lw r3, [r2]
  not r1, r1
  and r3, r3, r1
  sw r3, [r2]

  ; Advance tail position
  inc r4
  mov r1, snake_pos_mask
  and r4, r4, r1
  sw r4, [snake_pos_tail]

  j game_loop, r7

game_over:
  mov r1, 0xf000
  lw r2, [score]
  or r1, r1, r2
  sw r1, [dev_hex_out]

.loop:
  lw r1, [dev_vsync_btn]
  mov r2, btn_space
  and r1, r1, r2
  beqz r1, .loop
  j init, r7


#addr 0x41a0

; Inputs
;   r1 - X
;   r2 - Y
; Outputs
;   r1 - Pixel bitmask
;   r2 - Pixel address
;   r3 - Trampled
pixel_address:
  ; Flip X axis (we want 0,0 to be top left)
  mov r3, 31
  sub r1, r3, r1

  ; Put topmost bit of X into r3
  mov r3, -4
  ls r3, r1, r3

  ; Compute screen offset (2*Y + top_of_x + dev_screen_start) into r2
  add r2, r2, r2
  add r2, r2, r3
  mov r3, dev_screen_start
  add r2, r2, r3

  ; Compute bitmask into r1
  mov r3, 0xf
  and r1, r1, r3
  mov r3, 1
  ls r1, r3, r1

  ret

; Update food position and render it on the screen
roll_new_food:
  ; Generate food (x, y)
  lw r1, [dev_rand]
  lw r2, [dev_rand]
  mov r3, 0x1f
  and r1, r1, r3
  and r2, r1, r3

  ; Store it 
  sw r1, [food_x]
  sw r2, [food_y]

  ret






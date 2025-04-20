; pi.asm
; Computes digits of pi and scrolls them across hex display.

#include "cpu16.inc"
#addr 0x4030

; Declare array of intermediate results. 
; The longer the array, the slower the program but the more digits 
; of pi will be accurate.
array_start = data_ram
array_length = 128
array_end = array_start + array_length - 1

; Program assumes array is at address zero. This lets us read/write 
; to array[i] with one instruction.
#assert array_start == 0  

init:
  mov r1, 2           ; Initialize entire array to 2.
  mov r3, array_end
  call rom_memset

; r1, r2: various
; r3: carried value from previous iteration
; r4: 4
; r5: output
; r6: 10
; r7: i
pi:
  mov r4, 4                 ; Initialize constant 4
  mov r5, 0                 ; Initialize output
  mov r6, 10                ; Initialize constant 10
.digit_loop:
  mov r3, 0                 ; Reset carried value
  mov r7, array_end         ; Set i to end of array

.array_loop:
  lw r1, [r7]               ; Load value from array[i] 
  add r2, r7, r7            ; Compute i*2 + 1 into r2
  inc r2
  mul r1, r1, r6            ; Multiply value * 10
  add r1, r1, r3            ; Add carried value
  div_rem r3, r2, r1, r2    ; Divide by (i*2 + 1)
  sw r2, [r7]               ; Store remainder to array[i]
  mul r3, r3, r7            ; Multiply division result by i, this becomes carried value.
  dec r7                    ; Decrement i
  bnez r7, .array_loop      ; Keep looping until i = 0

.last_array:
  lw r1, [0]                ; Load value at array[0]
  mul r1, r1, r6            ; Multiply by 10
  add r1, r1, r3            ; Add carried value
  div_rem r3, r2, r1, r6    ; Divide by 10. This is a digit of pi!
  sw r2, [0]                ; Store remainder to array[0]   
  ls r5, r5, r4             ; Shift output by 4 bits
  or r5, r5, r3             ; Or in the new digit
  sw r5, [dev_hex_out]      ; Update the hex display
  j .digit_loop             ; Make the next digit
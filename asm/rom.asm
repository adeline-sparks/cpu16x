#include "cpu16.inc"
#bank rom

loader:
#assert rom_loader == $
  lw r0, [dev_hex_clear2] ; Clear second display
  mov r1, 0xBBB1          ; Read starting address into r6
  sw r1, [dev_hex_out]
  lw r6, [dev_hex_in]

  inc r1                  ; Read length into r7
  sw r1, [dev_hex_out]
  lw r5, [dev_hex_in]

  beqz r5, .exec          ; Exec program if zero

.loop:
  lw r1, [r6]             ; Load value
  sw r6, [dev_hex_out2]   ; Display address
  sw r1, [dev_hex_out]    ; Display value

  lw r1, [dev_hex_in]     ; Read new value
  dec r5                  ; Decrease length
  sw r1, [r6]             ; Update value
  inc r6                  ; Advance address
  bnez r5, .loop
  j loader
  
.exec:
  mov r1, 0               ; Clear registers (r5 already zero)
  mov r2, 0
  mov r3, 0
  lw r4, [dev_hex_clear]  ; Clear r4 and main display
  mov r7, loader          ; Point link register back to the loader
  sw r6, [dev_hex_out2]   ; Display start address
  jr r6                   ; Jump to program! 

#assert rom_memcpy_program == $
memcpy_program:
  lw r1, [dev_hex_in]
  lw r2, [dev_hex_in]
  lw r3, [dev_hex_in]

; r1 is source
; r2 is dst
; r3 is count
; r4 is scratch
#assert rom_memcpy == $
memcpy:
  beqz r3, .done
  mov r4, 1
  and r4, r3, r4
  beqz r4, .loop
  
.single:
  lw r4, [r1]
  dec r3
  sw r4, [r2]
  beqz r3, .done
  inc r1
  inc r2

.loop:
  lw r4, [r1]
  sub r3, r3, 2
  sw r4, [r2]
  lw r4, [r1, 1]
  add r1, r1, 2
  sw r4, [r2, 1]
  add r2, r2, 2
  bnez r3, .loop

.done:
  ret

#assert rom_memset_program == $
memset_program:
  lw r1, [dev_hex_in]
  lw r2, [dev_hex_in]
  lw r3, [dev_hex_in]

; r1 is value
; r2 is dst
; r3 is count
; r4 is scratch
#assert rom_memset == $
memset:
  beqz r3, .done
  mov r4, 1
  and r4, r3, r4
  beqz r4, .loop
  
.single:
  sw r1, [r2]
  inc r2
  dec r3
  beqz r3, .done

.loop:
  sw r1, [r2]
  sw r1, [r2, 1]
  add r2, r2, 2
  sub r3, r3, 2
  bnez r3, .loop
  
.done:
  ret

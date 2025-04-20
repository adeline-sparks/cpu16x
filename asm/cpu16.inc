#once

;;; Devices 
; Devices are at the very top of address space for one-cycle access using 
; negative offsets from r0.

; Hex Display Input
;   Read - Waits for and returns 16-bit value entered on hex keypad.
dev_hex_in = 0xffff

; Hex Display Output
;   Write - Displays 16-bit value on lower hex digits.
dev_hex_out = 0xfffe

; Hex Display Clear
;   Read - Displays 16-bit value on lower hex digits.
dev_hex_clear = 0xfffe

; Upper Hex Display Output
;   Write - Displays 16-bit value on upper hex digits.
dev_hex_out2 = 0xfffd

; Clear Upper Hex Display Output
;   Read - Displays 16-bit value on upper hex digits.
dev_hex_clear2 = 0xfffd

; Random Number Generator
;   Read - Returns random 16-bit value.
dev_rand = 0xfff9

; Screen clear
;   Read - Sets all bits in screen to zero.
dev_screen_clear = 0xfff8

; Screen
;   Write - Updates 16-bit horizontal strip of pixels.
;   Read - Returns 16-bit horizontal strip of pixel.
;
; Screen is 32x32 bitmapped, going from right to left then top to bottom.
;
;    MSB    LSBMSB    LSB
;    <---16---><---16--->
; ^  [ 0xff81 ][ 0xff80 ]
; |  [ 0xff83 ][ 0xff82 ]
; 32  ..        ..
; |  [ 0xffbd ][ 0xffbc ]
; V  [ 0xffbf ][ 0xffbe ]
;

dev_screen_start = 0xff80
dev_screen_end = 0xffc0

;;; Memory
; 256 words of data RAM starts at 0x0000. Lower 64 bytes accessible 
; in one-cycle using offsets from r0.
data_ram = 0x0000
#bankdef data_ram
{
    #bits 16
    #addr data_ram
    #size 0x0100
    #outp 0x0000 * 16
}

; 512 words of instruction RAM starts at 0x4000.
instruction_ram = 0x4000
#bankdef instruction_ram
{
    #bits 16
    #addr instruction_ram
    #size 0x0200
    #outp 0x4000 * 16
}

; 64 words of boot ROM starts at 0x8000. This is where the computer
; resets to, and usually contains loader.asm
rom = 0x8000
#bankdef rom
{
    #bits 16
    #addr rom
    #size 0x0040
    #outp 0x8000 * 16
}

; Interactive program loader stored in ROM. Runs at boot.
rom_loader = 0x8000

; Interactive memcpy program stored in ROM.
; Useful for moving programs to different addresses without having to enter them again.
rom_memcpy_program = 0x8019

; memcpy subroutine stored in ROM.
; Copies r3 bytes from r1 to r2. r4 is clobbered.
rom_memcpy = 0x801c

; Interactive memset program stored in ROM.
; Useful for clearing memory.
rom_memset_program = 0x802f

; memset subroutine stored in ROM.
; Fills r3 bytes with r2 starting from r1. r4 is clobbered.
rom_memset = 0x8032

#bank instruction_ram

;;; Instructions

; Define the 8 base instructions. Every other instruction is 
; an alias or macro of these.
#ruledef
{
    ; ALU operation
    ; Performs an ALU operation on src1 and src2, putting result in dst.
    alu {aluop: u4}, {dst: Reg}, {src1: Reg}, {src2: Reg} => 0b000 @ src1 @ src2 @ dst @ aluop
    
    ; Load Upper Immediate
    ; Overwrites dst with an immediate in the upper 10 bits, and zero in the lower 6.
    lui {dst: Reg}, {imm: u10} => 0b001 @ dst @ imm

    ; Branch Equal
    ; If src1 == src2, branch to a PC-relative signed 7-bit offset.
    beq {src1: Reg}, {src2: Reg}, {target: PCAddr} => 0b010 @ src1 @ src2 @ target

    ; Branch Less Than
    ; If src1 < src2, branch to a PC-relative signed 7-bit offset.
    blt {src1: Reg}, {src2: Reg}, {target: PCAddr} => 0b011 @ src1 @ src2 @ target

    ; Load Word
    ; Load a word into dst from a signed 7-bit immediate added to ptr.
    lw {dst: Reg}, [{ptr: Reg}, {imm: s7}] => 0b100 @ dst @ ptr @ imm

    ; Store Word
    ; Store a word from src to a signed 7-bit immediate added to ptr.
    sw {src: Reg}, [{ptr: Reg}, {imm: s7}] => 0b101 @ src @ ptr @ imm

    ; Add Immediate
    ; Add a signed 7-bit immediate to src, putting result in dst.
    addi {dst: Reg}, {src: Reg}, {imm: s7} => 0b110 @ dst @ src @ imm

    ; Jump And Link Register
    ; Jump to a signed 7-bit offset added to ptr. Store PC+1 to dst.
    jalr {dst: Reg}, {ptr: Reg}, {imm: s7} => 0b111 @ dst @ ptr @ imm
}

; Define the 16 ALU instructions
#ruledef
{
    ; Add
    ; Add src1 and src2, putting result in dst. Carry is updated but not used.
    add {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0000, {dst}, {src1}, {src2} }
    
    ; Subtract
    ; Subtract src1 and src2, putting result in dst. Carry is updated but not used.
    sub {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0001, {dst}, {src1}, {src2} }

    ; Add with Carry
    ; Add src1 and src2 and the carry, putting result in dst. Carry is updated.
    adc {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0010, {dst}, {src1}, {src2} }

    ; Subtract with Carry
    ; Subtract src1 and src2 and add the carry, putting result in dst. Carry is updated.
    sbc {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0011, {dst}, {src1}, {src2} }

    ; Or
    ; Compute bitwise or of src1 and src2, putting result in dst.
    or {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0100, {dst}, {src1}, {src2} }

    ; And
    ; Compute bitwise and of src1 and src2, putting result in dst.
    and {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0101, {dst}, {src1}, {src2} }

    ; Xor
    ; Compute bitwise xor of src1 and src2, putting result in dst.
    xor {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0110, {dst}, {src1}, {src2} }

    ; Xnor
    ; Compute bitwise xnor of src1 and src2, putting result in dst.
    xnor {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b0111, {dst}, {src1}, {src2} }

    ; Logical Shift
    ; Shift src1 by src2. Positive src2 will shift left, negative shifts right.
    ls {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b1000, {dst}, {src2}, {src1} }

    ; Arithmatic Shift
    ; Shift src1 by src2. Positive src2 will shift left, negative shifts right with sign extension.
    as {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b1001, {dst}, {src2}, {src1} }

    ; Multiply (2 cycles)
    ; Multiplies src1 and src2, putting the lower 16-bits in dst. 
    mul {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b1010, {dst}, {src1}, {src2} }

    ; Multiply high (2 cycles)
    ; Multiplies src1 and src2, putting the upper 16-bits in dst.
    mulh {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b1011, {dst}, {src1}, {src2} }

    ; Divide (16 cycles :( )
    ; Divides src1 by src2, putting the remainder into dst.
    ; Errata: div must not be placed after a branch instruction.
    ;         Pipeline causes branch to occur after division begins, 
    ;         and the divider doesn't handle this properly.
    div {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b1100, {dst}, {src1}, {src2} }

    ; Remainder
    ; Puts remainder of previous division into dst. 
    ; This must come after a div, and must provide the same src1 and src2 values.
    rem {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b1101, {dst}, {src1}, {src2} }

    ; Mask and Count bits
    ; Computes logical and of src1 and src2, then counts the number of bits 
    ; which are set and puts result in dst.
    mskcnt {dst: Reg}, {src1: Reg}, {src2: Reg} => asm { alu 0b1110, {dst}, {src1}, {src2} }
}

; Move
; Move a register or immediate into dst.
#ruledef
{
    ; Handles registers
    mov {dst: Reg}, {src: Reg} => asm { addi {dst}, {src}, 0 }

    ; Handles R0Addrs using addi, ie. 0x0000 to 0x0003f and 0xffc0 to 0xffff
    mov {dst: Reg}, {addr: R0Addr} => {
        imm = addr ; we want the number from R0Addr, not the tokens it matched.
        asm { addi {dst}, r0, {imm} }
    }

    ; Handles -64 to -1 using addi.
    mov {dst: Reg}, {imm: s7} => {
        assert(imm < 0)
        asm { addi {dst}, r0, {imm} }
    }

    ; Handles values representable with lui.
    mov {dst: Reg}, {imm: i16} => {
        assert(upper10(imm) != 0) ; If upper10 is all ones or all zeros, prefer an addi and sign extension.
        assert(upper10(imm) != 0x3ff) 
        assert(lower6(imm) == 0)
        asm { lui {dst}, upper10({imm}) }
    }

    ; Handles arbitrary 16-bit values with lui and addi.
    mov {dst: Reg}, {imm: i16} => asm { 
        lui {dst}, upper10({imm})
        addi {dst}, {dst}, lower6({imm})
    }
}

; Add and Subtract with immediate
#ruledef
{
    add {dst: Reg}, {src: Reg}, {imm: s7} => asm { addi {dst}, {src}, {imm} }
    sub {dst: Reg}, {src: Reg}, {imm: s7} => asm { addi {dst}, {src}, -{imm} }
}

; Increment and decrement
#ruledef
{
    inc {dst: Reg} => asm { add {dst}, {dst}, 1 }
    incc {dst: Reg} => asm { adc {dst}, {src}, r0 }
    dec {dst: Reg} => asm { sub {dst}, {dst}, 1 }
    decc {dst: Reg} => asm { sbc {dst}, {src}, r0 }
}

; No-immediate aliases for memory instructions.
#ruledef
{
    lw {dst: Reg}, [{ptr: Reg}] => asm { lw {dst}, [{ptr}, 0] }
    sw {dst: Reg}, [{ptr: Reg}] => asm { sw {dst}, [{ptr}, 0] }
    jalr {dst: Reg}, {ptr: Reg} => asm { jalr {dst}, {ptr}, 0 }
}

; Absolute address aliases for memory instructions.
; These can access R0Addrs from 0x0000 to 0x003f and 0xffc0 to 0xffff.
#ruledef
{
    lw {dst: Reg}, [{addr: R0Addr}] => {
        imm = addr ; we want the number from R0Addr, not the tokens it matched.
        asm { lw {dst}, [r0, {imm}] }
    }
    sw {src: Reg}, [{addr: R0Addr}] => {
        imm = addr
        asm { sw {src}, [r0, {imm}] }
    }
    jalr {dst: Reg}, {addr: R0Addr} => {
        imm = addr
        asm { jalr {dst}, [r0, {imm}] }
    }
}

; Far absolute address aliases. 
; These can access any address but use an lui instruction to do so.
#ruledef
{
    lw {dst: Reg}, [{addr: u16}] => {
        assert(dst != 0)
        asm { 
            lui {dst}, upper10({addr})
            lw {dst}, [{dst}, lower6({addr})] 
        }
    }
    ; sw can't re-use src, so it requires an extra tmp register.
    sw {src: Reg}, [{addr: u16}], {tmp: Reg} => {
        assert(tmp != 0)
        asm { 
            lui {tmp}, upper10({addr})
            lw {src}, [{tmp}, lower6({addr})] 
        }
    }
    jalr {dst: Reg}, {addr: u16} => {
        assert(dst != 0)
        asm { 
            lui {dst}, upper10({addr})
            jalr {dst}, {dst}, lower6({addr})
        }
    }
}

; Branch variations
#ruledef 
{
    ; Branch Equal to Zero
    ; If src == 0, branch to a PC-relative signed 7-bit offset.
    beqz {src: Reg}, {target: PCAddr} => asm { beq {src}, r0, {target} }

    ; Branch Not Equal to Zero
    ; If src != 0, branch to a PC-relative signed 7-bit offset.
    bnez {src: Reg}, {target: PCAddr} => asm { blt r0, {src}, {target} }
    
    ; Branch Greater Than
    ; If src1 > src2, branch to a PC-relative signed 7-bit offset.
    bgt {src1: Reg}, {src2: Reg}, {target: PCAddr} => asm { blt {src2}, {src1}, {target} }

    ; Branch Less Than or Equal
    ; If src1 <= src2, branch to a PC-relative signed 7-bit offset.
    blte {src1: Reg}, {src2: Reg}, {target: PCAddr} => asm {
        beq {src1}, {src2}, target
        blt {src1}, {src2}, target
    }

    ; Branch Greater than or Equal
    ; If src1 >= src2, branch to a PC-relative signed 7-bit offset.
    bgte {src1: Reg}, {src2: Reg}, {target: PCAddr} => asm {
        beq {src1}, {src2}, {target}
        bgt {src1}, {src2}, {target}
    }

    ; Branch Not Equal 
    ; If src1 != src2, branch to a PC-relative signed 7-bit offset.
    bne {src1: Reg}, {src2: Reg}, {target: PCAddr} => asm {
        blt {src1}, {src2}, {target}
        bgt {src1}, {src2}, {target}
    }
}

; Jump Register
; Jumps to the address in ptr
#ruledef
{
    jr {ptr: Reg} => asm { jalr r0, {ptr} }
    jr {ptr: Reg}, {imm: s7} => asm { jalr r0, {ptr}, {imm} }
}

; Jump
; Jumps to the specified address.
#ruledef
{
    ; PC-relative jump.
    j {target: PCAddr} => asm { beq r0, r0, {target} }

    ; Jump to R0Addrs
    j {target: R0Addr} => asm { jalr r0, {target} }

    ; Long jump, requires a temporary register.
    j {target: u16}, {tmp: Reg} => {
        assert(tmp != 0)
        asm {
            lui {tmp}, upper10({target})
            jalr r0, {tmp}, lower6({target})
        }
    }
}

; Count bits
; Counts the number of bits set in src and puts result in dst.
#ruledef
{
    cnt {dst: Reg} {src: Reg} => asm { mskcnt {dst}, {src}, {src} } 
}

; Bitwise not
; Inverts all bits in src and puts result in dst.
#ruledef
{
    not {dst: Reg} {src: Reg} => asm { xnor {dst}, {src}, r0 }
}

; Multiply High and Low
; Multiplies src1 by src2 and puts upper 16-bits in hi, lower-16 bits in lo.
#ruledef
{
    mulhl {hi: Reg}, {lo: Reg}, {src1: Reg}, {src2: Reg} => asm {
        mulh {hi}, {src1}, {src2}
        mul {lo}, {src1}, {src2}
    }
}

; Divide quotient and Remainder
; Divides src1 by src2 and puts quotient in quot, remainder in rem.
#ruledef
{
    div_rem {quot: Reg}, {rem: Reg}, {src1: Reg}, {src2: Reg} => asm {
        div {quot}, {src1}, {src2}
        rem {rem}, {src1}, {src2}
    }
}

; function Call and Return 
; Stores return address in rl (r7)
#ruledef
{
    call {target} => asm { jalr rl, {target} }
    call {ptr: Reg} => asm { jalr rl, {ptr} }

    ret => asm { jr rl }
}

; Produce a PC-relative signed 7-bit immediate from a memory address.
#subruledef PCAddr
{
    {target: u16} => {
        offset = target - $
        assert(
            offset <= 0x003f && offset >= !0x003f, 
            "Branch target out of range"
        )
        offset`7
    }
}

; Produce an R0-relative signed 7-bit immediate from a memory address.
#subruledef R0Addr
{
    ; This seems to be the only way to branch?
    {addr: u16} => {
        assert(addr >= 0x0000 && addr <= 0x003f)
        addr`7
    }
    {addr: u16} => {
        assert(addr >= 0xffc0 && addr <= 0xffff)
        (addr - 0x10000)
    }
}

; Registers
#subruledef Reg
{
    ; Zero register - always reads zero, writes ignored.
    r0 => 0`3

    ; General purpose registers
    r1 => 1`3
    r2 => 2`3
    r3 => 3`3
    r4 => 4`3
    r5 => 5`3
    r6 => 6`3

    ; R7 is also general purpose but is often used as the 
    ; link register when calling functions.
    r7 => 7`3
    rl => 7`3
}

; Extract upper 10 bits
#fn upper10(val) => val[15:6]

; Extract lower 6 bits
#fn lower6(val) => val[5:0]
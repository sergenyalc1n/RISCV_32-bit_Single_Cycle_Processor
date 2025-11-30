.data
ARRAY:  .word   0x00000000, 0x00000001, 0x00000200, 0x00400000, 0x80000000
        .word   0x51C06460, 0xDEC287D9, 0x6C896594, 0x99999999, 0xFFFFFFFF
        .word   0x7FFFFFFF, 0xFFFFFFFE, 0xC7B52169, 0x8CEFF731, 0xA550921E
        .word   0x0DB01F33, 0x24BB7B48, 0x98513914, 0xCD76ED30, 0xC0000003

COUNT:  .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl main
main:
    addi    x10, x0, 0x100         # x10 = ARRAY pointeri (adres 0x100)
    addi    x11, x0, 0x150         # x11 = COUNT pointeri (adres 0x150)
    addi    x12, x0, 20            # x12 = 20
    addi    x13, x0, 32            # x13 = 32
    addi    x14, x0, 2             # x14 = shift miktarı offset icin
    addi    x15, x0, 1             # x15 = 1 shift mask icin
    addi    x1, x0, 0              # x1 = i(i=0)

outer_loop:
    beq     x1, x12, done

    sll     x5, x1, x14            # t0 = i * 4
    add     x6, x10, x5            # t1 = address of array[i]
    lw      x7, 0(x6)              # t2 = array[i]

    addi    x2, x0, 0              # j = 0
    addi    x5, x0, 1              # mask = 1
    addi    x27, x0, 0              # x27 = sayaç (counter)

inner_loop:
    beq     x2, x13, save_count

    and     x28, x7, x5             # t3 = array[i] & mask
    beq     x28, x0, next_mask

    addi    x27, x27, 1             # sayaç++

next_mask:
    sll     x5, x5, x15             # mask <<= 1
    addi    x2, x2, 1               # j++
    jal     x0, inner_loop

save_count:
    sll     x29, x1, x14            # t4 = i * 4 (offset)
    add     x30, x11, x29           # t5 = address of COUNT[i]
    sw      x27, 0(x30)             # COUNT[i] = sayaç

    addi    x1, x1, 1
    jal     x0, outer_loop

done:
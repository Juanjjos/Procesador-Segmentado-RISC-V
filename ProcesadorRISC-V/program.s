    .text
    .globl _start

_start:
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 20      # x2 = 20
    add  x3, x1, x2      # x3 = 30
    sub  x4, x2, x1      # x4 = 10
    addi x0, x0, 99      # ignored: x0 must remain zero
    add  x5, x0, x3      # x5 = 30

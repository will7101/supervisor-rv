#include <exception.h>

    .p2align 2
    .text
    .global EXCEPTION_HANDLER

#ifdef ENABLE_INT
EXCEPTION_HANDLER:
    csrrw sp, mscratch, sp          // 交换 mscratch 和 sp ，保存上下文

    STORE ra, TF_ra(sp)
    csrrw ra, mscratch, sp          // 读出原来的 sp
    STORE ra, TF_sp(sp)
    STORE gp, TF_gp(sp)
    STORE tp, TF_tp(sp)
    STORE t0, TF_t0(sp)
    STORE t1, TF_t1(sp)
    STORE t2, TF_t2(sp)
    STORE s0, TF_s0(sp)
    STORE s1, TF_s1(sp)
    STORE a0, TF_a0(sp)
    STORE a1, TF_a1(sp)
    STORE a2, TF_a2(sp)
    STORE a3, TF_a3(sp)
    STORE a4, TF_a4(sp)
    STORE a5, TF_a5(sp)
    STORE a6, TF_a6(sp)
    STORE a7, TF_a7(sp)
    STORE s2, TF_s2(sp)
    STORE s3, TF_s3(sp)
    STORE s4, TF_s4(sp)
    STORE s5, TF_s5(sp)
    STORE s6, TF_s6(sp)
    STORE s7, TF_s7(sp)
    STORE s8, TF_s8(sp)
    STORE s9, TF_s9(sp)
    STORE s10, TF_s10(sp)
    STORE s11, TF_s11(sp)
    STORE t3, TF_t3(sp)
    STORE t4, TF_t4(sp)
    STORE t5, TF_t5(sp)
    STORE t6, TF_t6(sp)
    csrr t0, mepc
    STORE t0, TF_epc(sp)

    csrr t0, mcause
    li t1, EX_INT_FLAG
    and t1, t0, t1
    bne t1, zero, .HANDLE_INT
    li t1, EX_ECALL_U
    beq t1, t0, .HANDLE_ECALL
    li t1, EX_BREAK
    beq t1, t0, .HANDLE_BREAK

    j FATAL

.HANDLE_ECALL:
    LOAD t0, TF_epc(sp)
    addi t0, t0, 0x4
    STORE t0, TF_epc(sp)

    LOAD t0, TF_s0(sp)
    li t1, SYS_putc
    beq t0, t1, .HANDLE_ECALL_PUTC

    // 忽略其他系统调用
    j CONTEXT_SWITCH

.HANDLE_ECALL_PUTC:
    LOAD a0, TF_a0(sp)
    jal WRITE_SERIAL
    j CONTEXT_SWITCH

.HANDLE_BREAK:
    j USERRET_MACHINE

.HANDLE_INT:
    andi t0, t0, EX_INT_TYPE_MASK
    li t1, EX_INT_TYPE_TIMER
    beq t0, t1, .HANDLE_TIMER
    li t1, EX_INT_TYPE_EXTERNAL
    beq t0, t1, .HANDLE_EXTERNAL

    j FATAL

.HANDLE_TIMER:
    la ra, current_frame
    LOAD a2, 0(ra)
    la t2, frame_data
    li t3, 0x20000000
    li t0, 0
.LC0_0:
    beq t0, a2, .LC0_1
    addi t2, t2, 384*XLEN
    addi t0, t0, 1
    j .LC0_0
.LC0_1:
    li t0, 0
    li t1, 384
.LC0_2:
    LOAD t4, 0(t2)
    STORE t4, 0(t3)
    addi t2, t2, XLEN
    addi t3, t3, XLEN
    addi t0, t0, 1
    bne t0, t1, .LC0_2

    la ra, playing
    LOAD a1, 0(ra)
    beqz a1, .LC0_4

    la ra, n_frames
    LOAD a3, 0(ra)
    addi a2, a2, 1
    bne a2, a3, .LC0_3
    li a2, 0
.LC0_3:
    la ra, current_frame
    STORE a2, 0(ra)
.LC0_4:
    j CONTEXT_SWITCH

.HANDLE_EXTERNAL:
    la ra, playing
    LOAD t0, 0(ra)
    xor t0, t0, 1
    STORE t0, 0(ra) 
    j CONTEXT_SWITCH

CONTEXT_SWITCH:
    LOAD t0, TF_epc(sp)
    csrw mepc, t0

    LOAD ra, TF_ra(sp)
    LOAD gp, TF_gp(sp)
    LOAD tp, TF_tp(sp)
    LOAD t0, TF_t0(sp)
    LOAD t1, TF_t1(sp)
    LOAD t2, TF_t2(sp)
    LOAD s0, TF_s0(sp)
    LOAD s1, TF_s1(sp)
    LOAD a0, TF_a0(sp)
    LOAD a1, TF_a1(sp)
    LOAD a2, TF_a2(sp)
    LOAD a3, TF_a3(sp)
    LOAD a4, TF_a4(sp)
    LOAD a5, TF_a5(sp)
    LOAD a6, TF_a6(sp)
    LOAD a7, TF_a7(sp)
    LOAD s2, TF_s2(sp)
    LOAD s3, TF_s3(sp)
    LOAD s4, TF_s4(sp)
    LOAD s5, TF_s5(sp)
    LOAD s6, TF_s6(sp)
    LOAD s7, TF_s7(sp)
    LOAD s8, TF_s8(sp)
    LOAD s9, TF_s9(sp)
    LOAD s10, TF_s10(sp)
    LOAD s11, TF_s11(sp)
    LOAD t3, TF_t3(sp)
    LOAD t4, TF_t4(sp)
    LOAD t5, TF_t5(sp)
    LOAD t6, TF_t6(sp)
    
    csrw mscratch, sp
    LOAD sp, TF_sp(sp)

    mret

    // 用于仅支持 VECTORED 的 CPU
    .balign 256
    .global VECTORED_EXCEPTION_HANDLER
VECTORED_EXCEPTION_HANDLER:
    .rept 64
    j EXCEPTION_HANDLER
    .endr

#else
HALT:
EXCEPTION_HANDLER:
    j HALT
#endif

FATAL:                              // 严重问题，重启
    ori a0, zero, 0x80              // 错误信号
    jal WRITE_SERIAL                // 发送

#ifdef ENABLE_INT
    csrrs a0, mepc, zero
    jal WRITE_SERIAL_XLEN
    csrrs a0, mcause, zero
    jal WRITE_SERIAL_XLEN
    csrrs a0, mtval, zero
    jal WRITE_SERIAL_XLEN
#else
    mv a0, zero
    jal WRITE_SERIAL_XLEN
    jal WRITE_SERIAL_XLEN
    jal WRITE_SERIAL_XLEN
#endif

    la a0, START                    // 重启地址
    jr a0

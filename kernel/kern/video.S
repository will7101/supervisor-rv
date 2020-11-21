    .section .data
    .p2align 2
    .global current_frame
    .global playing
    .global n_frames
    .global frame_data
current_frame:
    .word 0
playing:
    .word 0
n_frames:
    .word 8
frame_data:
    .rept 384
    .word 0xff000000
    .endr

    .rept 384
    .word 0x00ff0000
    .endr

    .rept 384
    .word 0x0000ff00
    .endr

    .rept 384
    .word 0x000000ff
    .endr

    .rept 384
    .word 0xff000000
    .endr

    .rept 384
    .word 0x00ff0000
    .endr

    .rept 384
    .word 0x0000ff00
    .endr

    .rept 384
    .word 0x000000ff
    .endr
section .data
    term_buffer times 80*24*8 db 0  ; 终端缓冲区（每字符 8 字节：字符、属性等）
    cursor_x dq 0                   ; 光标 X 坐标
    cursor_y dq 0                   ; 光标 Y 坐标
    term_cols dq 80                 ; 当前列数
    term_rows dq 24                 ; 当前行数

section .text
extern c_resize_tty             ; C 绑定：调整 TTY 大小

global term_init
term_init:
    ; 初始化终端数据结构
    ; 输入：无
    ; 输出：无
    mov rax, [term_cols]
    mov [term_cols], rax
    mov rax, [term_rows]
    mov [term_rows], rax
    mov qword [cursor_x], 0
    mov qword [cursor_y], 0

    ; 清空缓冲区
    mov rdi, term_buffer
    mov rsi, 80*24*8
    call clear_buffer

    ; 通知 TTY 大小
    mov rdi, [term_cols]
    mov rsi, [term_rows]
    call c_resize_tty
    ret

global clear_buffer
clear_buffer:
    ; 清空缓冲区（SIMD 优化）
    ; 输入：rdi = 缓冲区地址, rsi = 大小（字节）
    ; 输出：无
    mov rax, rdi
    mov rcx, rsi
    xorps xmm0, xmm0        ; 设置零向量
.loop:
    movaps [rax], xmm0      ; 批量清零
    add rax, 16
    sub rcx, 16
    jnz .loop
    ret

global term_update_cursor
term_update_cursor:
    ; 更新光标位置
    ; 输入：rdi = 新 X 坐标, rsi = 新 Y 坐标
    ; 输出：无
    cmp rdi, [term_cols]
    jae .clamp_x
    mov [cursor_x], rdi
.clamp_x:
    cmp rsi, [term_rows]
    jae .clamp_y
    mov [cursor_y], rsi
.clamp_y:
    ret

global term_get_buffer
term_get_buffer:
    ; 获取缓冲区地址
    ; 输入：无
    ; 输出：rax = 缓冲区地址
    mov rax, term_buffer
    ret

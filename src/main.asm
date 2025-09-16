;; =============
;; update log: ||
;; =============
;; 20250917
;; 更新，完成了之前预留的函数，并整理了main.asm代码和注释,实现了一个可调试的版本
;; --------------

section .data
    term_cols dq 80         ; Default terminal columns
    term_rows dq 24         ; Default terminal rows
    wayland_display dq 0    ; Wayland display pointer
    tty_fd dq 0             ; TTY file descriptor
    llm_sock dq 0           ; LLM socket descriptor
    debug_msg_init db "Initializing wayterm: cols=%d, rows=%d\n", 0
    debug_msg_event db "Event received: type=%d\n", 0
    debug_msg_error db "Error: %s initialization failed\n", 0
    debug_wayland db "Wayland", 0
    debug_tty db "TTY", 0
    debug_llm db "LLM", 0

section .text
extern c_init_wayland       ; C binding: Initialize Wayland display
extern c_init_tty           ; C binding: Initialize TTY
extern c_init_socket        ; C binding: Initialize LLM socket
extern c_poll_events        ; C binding: Poll Wayland, TTY, LLM events
extern c_dispatch_wayland   ; C binding: Dispatch Wayland events
extern c_read_tty           ; C binding: Read TTY data
extern c_process_llm        ; C binding: Process LLM command
extern term_init            ; term.asm: Initialize terminal data
extern printf               ; C library: Debug output

global _start
_start:
    ; Program entry point
    ; Parse command-line arguments (simplified: cols and rows)
    ; Input: rsi = argv, rdi = argc
    mov rax, 80
    mov [term_cols], rax
    mov rax, 24
    mov [term_rows], rax
    ; TODO: Parse argv for -g colsxrows (call C helper if complex)

    ; Debug: Log initialization start
    mov rdi, debug_msg_init
    mov rsi, [term_cols]
    mov rdx, [term_rows]
    call printf

    ; Initialize terminal data structure
    call term_init

    ; Initialize Wayland
    call c_init_wayland
    test rax, rax
    jz .error_wayland
    mov [wayland_display], rax

    ; Initialize TTY
    call c_init_tty
    test rax, rax
    jz .error_tty
    mov [tty_fd], rax

    ; Initialize LLM socket
    call c_init_socket
    test rax, rax
    jz .error_llm
    mov [llm_sock], rax

    ; Debug breakpoint for initialization
    int3

    ; Enter main event loop
    call run_event_loop

    ; Exit program
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; status 0
    syscall

.error_wayland:
    mov rdi, debug_msg_error
    mov rsi, debug_wayland
    call printf
    jmp .exit_error

.error_tty:
    mov rdi, debug_msg_error
    mov rsi, debug_tty
    call printf
    jmp .exit_error

.error_llm:
    mov rdi, debug_msg_error
    mov rsi, debug_llm
    call printf
    jmp .exit_error

.exit_error:
    mov rax, 60
    mov rdi, 1          ; status 1
    syscall

run_event_loop:
    ; Main event loop: Poll and dispatch events
    ; Input: None
    ; Output: None
.loop:
    ; Poll events (Wayland, TTY, LLM)
    mov rdi, [wayland_display]
    mov rsi, [tty_fd]
    mov rdx, [llm_sock]
    mov rcx, 33         ; Timeout 33ms
    call c_poll_events
    test rax, rax
    jz .loop            ; No events

    ; Debug: Log event type
    mov rdi, debug_msg_event
    mov rsi, rax
    call printf

    ; Dispatch based on event type (bitmask)
    test rax, 1         ; Wayland event
    jnz .wayland
    test rax, 2         ; TTY event
    jnz .tty
    test rax, 4         ; LLM event
    jnz .llm
    jmp .loop

.wayland:
    mov rdi, [wayland_display]
    call c_dispatch_wayland
    jmp .loop

.tty:
    mov rdi, [tty_fd]
    call c_read_tty
    jmp .loop

.llm:
    mov rdi, [llm_sock]
    call c_process_llm
    jmp .loop

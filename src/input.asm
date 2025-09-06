section .data
    key_buffer times 32 db 0    ; 键盘输入缓冲区
    mouse_state dq 0            ; 鼠标状态（按下/释放/坐标）
    input_mode dq 0             ; 输入模式（0=正常, 1=应用键）

section .text
extern c_get_input          ; C 绑定：获取 Wayland 输入（键盘/鼠标）
extern c_write_tty          ; C 绑定：写入 TTY
extern c_start_selection    ; C 绑定：开始文本选择
extern c_process_llm_input  ; C 绑定：处理 LLM 输入指令

global process_input
process_input:
    ; 处理输入事件（键盘、鼠标、LLM）
    ; 输入：rdi = Wayland 显示指针, rsi = TTY 文件描述符, rdx = LLM 套接字
    ; 输出：无
    push rbx
    mov rbx, rdi            ; 保存 Wayland 显示指针

    ; 获取输入（调用 C 绑定）
    mov rdi, rbx
    lea rsi, [key_buffer]
    lea rdx, [mouse_state]
    call c_get_input
    test rax, rax
    jz .end                 ; 无输入

    ; 检查输入类型（rax 位标志）
    test rax, 1             ; 键盘输入
    jnz .keyboard
    test rax, 2             ; 鼠标输入
    jnz .mouse
    test rax, 4             ; LLM 输入
    jnz .llm
    jmp .end

.keyboard:
    ; 处理键盘输入
    lea rdi, [key_buffer]
    call handle_keyboard
    jmp .end

.mouse:
    ; 处理鼠标输入
    lea rdi, [mouse_state]
    call handle_mouse
    jmp .end

.llm:
    ; 处理 LLM 注入输入
    mov rdi, rdx
    call c_process_llm_input
    mov rdi, rsi            ; TTY fd
    lea rsi, [key_buffer]   ; LLM 可能填充缓冲区
    call c_write_tty
    jmp .end

.end:
    pop rbx
    ret

handle_keyboard:
    ; 处理键盘输入，映射快捷键或发送到 TTY
    ; 输入：rdi = 键盘缓冲区地址
    ; 输出：无
    mov al, [rdi]           ; 获取键值
    cmp al, 0x03            ; Ctrl+C 示例快捷键
    je .copy
    cmp al, 0x16            ; Ctrl+V 示例快捷键
    je .paste

    ; 正常键，写入 TTY
    mov rsi, rdi
    mov rdi, [tty_fd]
    call c_write_tty
    ret

.copy:
    call c_start_selection
    ret

.paste:
    ; TODO：调用剪贴板粘贴
    ret

handle_mouse:
    ; 处理鼠标输入（选择或滚动）
    ; 输入：rdi = 鼠标状态地址
    ; 输出：无
    mov rax, [rdi]          ; 鼠标状态（0=释放, 1=按下）
    test rax, 1
    jz .release
    call c_start_selection  ; 开始选择
    ret

.release:
    ; TODO：结束选择或滚动
    ret

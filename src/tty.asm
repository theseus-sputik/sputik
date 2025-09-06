section .data
    sel_start_x dq 0            ; 选择开始 X 坐标
    sel_start_y dq 0            ; 选择开始 Y 坐标
    sel_end_x dq 0              ; 选择结束 X 坐标
    sel_end_y dq 0              ; 选择结束 Y 坐标
    sel_mode dq 0               ; 选择模式（0=正常, 1=矩形）

section .text
extern c_copy_clipboard     ; C 绑定：复制到剪贴板
extern c_paste_clipboard    ; C 绑定：从剪贴板粘贴
extern term_get_buffer      ; term.asm：获取终端缓冲区

global start_selection
start_selection:
    ; 开始文本选择
    ; 输入：rdi = 开始 X 坐标, rsi = 开始 Y 坐标
    ; 输出：无
    mov [sel_start_x], rdi
    mov [sel_start_y], rsi
    mov [sel_end_x], rdi
    mov [sel_end_y], rsi
    mov qword [sel_mode], 0     ; 默认正常模式
    ret

global update_selection
update_selection:
    ; 更新选择范围（鼠标拖动）
    ; 输入：rdi = 新 X 坐标, rsi = 新 Y 坐标
    ; 输出：无
    mov [sel_end_x], rdi
    mov [sel_end_y], rsi
    ret

global end_selection
end_selection:
    ; 结束选择，复制到剪贴板
    ; 输入：无
    ; 输出：无
    call get_selection_text
    mov rdi, rax                ; 文本地址
    mov rsi, rdx                ; 文本长度
    call c_copy_clipboard
    ; 重置选择状态
    xor rax, rax
    mov [sel_start_x], rax
    mov [sel_start_y], rax
    mov [sel_end_x], rax
    mov [sel_end_y], rax
    ret

global toggle_rect_mode
toggle_rect_mode:
    ; 切换矩形选择模式
    ; 输入：无
    ; 输出：无
    mov rax, [sel_mode]
    xor rax, 1                  ; 切换 0/1
    mov [sel_mode], rax
    ret

get_selection_text:
    ; 获取选中文本（正常或矩形模式）
    ; 输入：无
    ; 输出：rax = 文本地址, rdx = 长度
    call term_get_buffer
    mov rcx, rax                ; 缓冲区地址

    ; 计算开始和结束偏移（简化示例）
    mov rax, [sel_start_y]
    imul rax, [term_cols]
    add rax, [sel_start_x]
    imul rax, 8                 ; 每字符 8 字节
    add rcx, rax                ; 开始地址

    ; 计算长度（简化，假设正常模式）
    mov rdx, [sel_end_y]
    sub rdx, [sel_start_y]
    imul rdx, [term_cols]
    add rdx, [sel_end_x]
    sub rdx, [sel_start_x]
    imul rdx, 8                 ; 长度

    mov rax, rcx                ; 返回地址
    ret

global paste_from_clipboard
paste_from_clipboard:
    ; 从剪贴板粘贴文本到 TTY
    ; 输入：rdi = TTY 文件描述符
    ; 输出：无
    call c_paste_clipboard
    mov rsi, rax                ; 文本地址
    mov rdx, rcx                ; 文本长度 (假设 rcx 长度)
    call c_write_tty
    ret

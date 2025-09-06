section .data
    render_flags dq 0       

section .text
extern c_render_line        
extern c_submit_surface     
extern term_get_buffer      
extern term_get_cursor      

global render_buffer
render_buffer:
    push rbx
    mov rbx, rdi            
    call term_get_buffer
    mov rcx, rax            
    mov rdx, [term_rows]    

.line_loop:
    mov rdi, rcx
    call c_render_line
    add rcx, [term_cols]*8  
    dec rdx
    jnz .line_loop

    ; 绘制光标
    call term_get_cursor
    mov rdi, rax            
    mov rsi, rdx            
    call draw_cursor

    ; 提交表面
    mov rdi, rbx
    call c_submit_surface

    pop rbx
    ret

global draw_cursor
draw_cursor:
    ; 绘制光标（简化）
    ; 输入：rdi = X 坐标, rsi = Y 坐标
    ; 输出：无
    ; TODO：计算位置，调用 C 渲染光标
    ret

global toggle_blink
toggle_blink:
    ; 切换闪烁状态
    ; 输入：无
    ; 输出：无
    mov rax, [render_flags]
    xor rax, 1              
    mov [render_flags], rax
    ret

global optimize_render
optimize_render:
    ; 优化渲染（仅渲染脏区域，简化示例）
    ; 输入：rdi = 起始行, rsi = 结束行
    ; 输出：无
    call term_get_buffer
    imul rdi, [term_cols]*8 
    add rax, rdi
    mov rcx, rsi
    sub rcx, rdi
    inc rcx                 
    jmp .line_loop          

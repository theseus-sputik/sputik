section .data
    llm_buffer times 1024 db 0  
    llm_sock dq 0               

section .text
extern c_read_socket        
extern c_parse_llm_json     
extern c_write_tty          
extern term_get_buffer      

global process_llm
process_llm:
    ; 处理 LLM 指令
    ; 输入：rdi = LLM 套接字
    ; 输出：无
    push rbx
    mov rbx, rdi            
    lea rsi, [llm_buffer]
    mov rdx, 1024           
    call c_read_socket
    test rax, rax
    jz .end                 

    ; 解析 JSON 指令（调用 C
    lea rdi, [llm_buffer]
    call c_parse_llm_json
    mov rcx, rax            

    ; 分发指令
    cmp rcx, 1              
    je .execute
    cmp rcx, 2              
    je .query
    cmp rcx, 3              
    je .monitor
    jmp .end

.execute:
    ; 执行命令：注入到 TTY
    lea rsi, [llm_buffer + 8]
    mov rdi, [tty_fd]
    mov rdx, 128             
    call c_write_tty
    jmp .end

.query:
    ; 查询状态：返回缓冲区快照
    call term_get_buffer
    ; TODO：发送回 LLM
    jmp .end

.monitor:
    ; 监控输出：实时发送缓冲区到 LLM
    call term_get_buffer
    mov rdi, rbx         
    mov rsi, rax         
    mov rdx, 80*24*8     
    call c_write_socket  
    jmp .end

.end:
    pop rbx
    ret

global send_to_llm
send_to_llm:
    ; 发送数据到 LLM
    ; 输入：rdi = LLM 套接字, rsi = 数据地址, rdx = 长度
    ; 输出：无
    call c_write_socket   
    ret

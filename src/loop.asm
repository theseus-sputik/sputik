section .text
extern c_poll_events
extern c_dispatch_wayland
extern c_read_tty
extern c_process_llm
global run_event_loop

run_event_loop:
	mov rdi, poll_fds
	mov rsi, 3
	mov rdx, 33		; 超时时间设置
	call c_poll_evnets

	cmp rax, 0
	je .loop_end
	test rax, 1
	jnz .wayland
 	test rax, 2
	jnz .tty
	test rax, 4
	jnz .llm
	

.wayland:
	call c_dispatch_wayland
	jmp .loop_end

.tty:
	call c_read_tty
	jmp .loop_end
.llm:
	call c_processa
.loop_end:
	jmp run_event_loop

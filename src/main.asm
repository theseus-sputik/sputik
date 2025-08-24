section .data
	term_cols dq 80		; default number of lines
	term_rows dq 24         ; ~~~~~~~~~~~~~~~~  rows
	wayland_display dq 0    ; pointer
	tty_fd dq 0             ; tty file descriptor
	llm_sock dq 0          

section .text
extern c_init_wayland           ;c binding: initialize wayland
extern c_init_tty		;c binding: initalize tty
;; The communication mechanism is slightly complicated, so it is left to c to implement, but c is prone to problems in my hands, and it will be rewritten in rust later.
extern c_init_socket 		;~~~~~~~~~~~~~~~~~~~  llm socket
extern c_poll_events		;~~~~~~~~~~~~~~~~~~~  event loop/poll, unit for llm socket
extern c_dispatch_wayland 	;~~~~~~~~~~~~~~~~~~~  dispatch wayland event
extern c_read_tty		;~~~~~~~~~~~~~~~~~~~  read tty
extern c_process_llm		;~~~~~~~~~~~~~~~~~~~  handle and read command from llm output
extern term_init		;main process in terminal.asm: initialize terminal data
extern run_event_loop 		;inner: main evnets loop



global _start
_start:
	; as we defined above, we should implement analyze commandline args
	; input: rdi = argc, rsi=argv
	mov rax, 80
	mov [term_cols], rax
	mov rax, 24
	mov [term_rows], rax
	;TODO: analyze -g cols&rows from rsi

	;terminal structures initialization
	call term_init

	;initialize wayland 
	call c_init_wayland
	test rax, rax 	
	jz .error
	mov [wayland_display], rax

	;initialize tty
	call c_init_tty
	test rax, rax
	jz .error
	mov [tty_fd], rax
	
	;initialize llm sock
	call c_process_llm
	test rax, rax
	jz .error
	mov [llm_sock], rax

	call run_event_loop

	mov rax, 60		;sys_exit
	xor rdi, rdi
	syscall
	


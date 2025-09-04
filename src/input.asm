section .data
	key_buffer times 32 db 0
	mouse_state dq 0
	input_mode dq 0

section .text
extern c_get_input
extern c_write_tty
extern c_start_selection
extern c_process_llm_input

global process_input
process_input:
	push rbx
	mov rbx. rdi

	mov rdi, rbx
	lea rdx

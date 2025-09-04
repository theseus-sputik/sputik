section .text
extern c_render_line
global render_buffer

render_buffer:
	mov rbx, [term_buffer]
	mov rcx, [term_rows]

.loop:
	mov rdi. rnx
	call c_render_line
	add rbx, 80*8
	dec rcx
	jnz .loop
	ret

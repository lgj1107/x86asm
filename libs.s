	.include "apicreg.def"
	.include "regs.def"
	.global	putc
	.code64
	.intel_syntax noprefix
	.global	putc,puts,puts.0
puts:
	push	rdi
	push	rsi
	push	rax
	
	mov	edi,offset print_lock
	call	atomic_set
	pop	rax
	pop	rsi
	pop	rdi
puts.0:
	mov	r15,0xb8000
.if 0
	push	rax
	push	rdi
	call	get_lapic_id
	cmp	al,0
	je	p.0
	mov	r15,[cpu2_disp]
	jmp	p.1
p.0:
	mov	r15,[cpu_disp]
p.1:		
	pop	rdi
	pop	rax
.endif
	call	get_cur
	shl	eax,1
	lea	rdi,[r15+rax]
	mov	ebx,160

	cld
	mov	ah,2
	call	putc
#	mov	[cpu0_cur],ax
	call	put_cur
	
	mov	edi,offset print_lock
	btr	qword ptr [rdi],0
	ret
putc.0:
	cmp	al,0xa
	jne	putc.9
putc.1:
	sub	rdi,r15
	push	rax
	mov	eax,edi
	xor	edx,edx
	div	ebx
	mul	ebx
	add	eax,ebx
	cmp	eax,80*25*2
	jb	putc.8
putc.2:
.if 1
	push	rsi
	mov	esi,0xb8000+160
	mov	edi,0xb8000
	mov	ecx,80*24*2/8
	rep	movsq
	pop	rsi
	mov	ecx,160/8
	mov	rax,0x0220022002200220
	rep	stosq
	sub	edi,ebx
	sub	rdi,r15
	mov	eax,edi
.endif
	
putc.8:
	mov	edi,eax
	add	rdi,r15
	pop	rax
	jmp	putc
putc.9:
	stosw
putc:
	lodsb
	test	al,al
	jnz	putc.0
putc_end:	
	sub	rdi,r15
	shr	edi,1
	mov	eax,edi
	ret

	.global	get_cur,put_cur
get_cur:
	push	rdx
	push	rbx
	mov	edx,0x3d4
	mov	al,0xe
	out	dx,al
	inc	dl
	in	al,dx
	mov	bh,al
	dec	dl
	mov	al,0xf
	out	dx,al
	inc	dl
	in	al,dx
	mov	bl,al
	movzx	eax,bx
	pop	rbx
	pop	rdx
	ret

put_cur:
	push	rbx
	push	rdx
	mov	ebx,eax
	mov	edx,0x3d4
	mov	al,0xe
	mov	ah,bh
	out	dx,ax
	mov	al,0xf
	mov	ah,bl
	out	dx,ax
	pop	rdx
	pop	rbx
	ret
	.global	test_and_set
#
#edi
#esi
#edx
#
	.global	test_and_set
test_and_set:
	push	rbx
	mov	ebx,esi
t.1:
	mov	eax,edx
	lock
	cmpxchg	[rdi],bl
	jz	t.1
	
	pop	rbx
	ret
	.global	atomic_set
atomic_set:
a.set1:
	lock
	bts	qword ptr [rdi],0
	jc	a.set1
	ret
	.global	hexasc,hexasc32
hexasc:
	push	rax
	shr	rax,32
	call	hexasc32
	pop	rax
hexasc32:
	push	rax
	shr	rax,16
	call	hex16
	pop	rax
hex16:
	push	rax
	shr	eax,8
	call	hex8
	pop	rax
hex8:
	push	rax
	shr	eax,4
	call	hex8.1
	pop	rax
hex8.1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hex8.2
	add	al,0x7
hex8.2:
	stosb		
	ret

	.global	print_lock
print_lock:
	.quad	0x0
	.global	msg
msg:
	.asciz	"dfsjkfk----------------\n"
msg1:
	.asciz	"i111111111111111111111111111----------------\n"
msg2:
	.asciz	"2222222222222222222\n\n"

fmt:
buf:
	.org	1024
	.global boot2_end
boot2_end:

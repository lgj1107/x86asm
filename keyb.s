
	.include "apicreg.def"
	.include "misc.def"
	.global	intx00
	.intel_syntax noprefix
	.code64
	.global	keyb
	.set	cpu0_screen,0xb8fa0
	.set	cpu2_screen,0xb8000+0xfa0*2
keyb:
	push	rdi
	push	rsi
	push	rcx
	push	rbx
	in	al,0x60
	cmp	al,0x58
	je	k_f12
	cmp	al,0x57
	je	k_f11
	
	mov	edi,0xb8000+160*8+34
	call	hex32
k.10:
	pop	rbx
	pop	rcx
	pop	rsi
	pop	rdi
	xor	eax,eax
	mov	[APIC_EOI],eax
	iretq
#
#cpu 0
#
k_f11:
	cmp	byte ptr [use_scr],0
	jne	k.f0
.if  0
	xor	eax,eax
	mov	edx,0x3d4
	mov	al,0xc
	out	dx,ax
	mov	al,0xd
	out	dx,ax
.endif
	mov	edi,0xb8fa0
	mov	esi,0xb8000
	cld	
	mov	ecx,4000
	rep	movsb
	
	call	get_cur
	mov	[cpu0_cur],ax

	jmp	k.f11
k.f0:
	call	get_cur
	mov	[cpu2_cur],ax

	mov	edi,cpu2_screen
	mov	esi,0xb8000
	cld	
	mov	ecx,4000
	rep	movsb

	mov	edi,0xb8000
	mov	esi,cpu0_screen
	cld	
	mov	ecx,4000
	rep	movsb
	mov	ax,[cpu0_cur]
	call	put_cur
k.f11:
	mov	byte ptr [use_scr],0
	jmp	k.10

#
#cpu 2
#
k_f12:
	cmp	byte ptr [use_scr],2
	je	k.f13
k.f12:
	call	get_cur
	mov	[cpu0_cur],ax
k.f13:
	mov	edi,cpu0_screen
	mov	esi,0xb8000
	cld	
	mov	ecx,4000
	rep	movsb

	mov	esi,cpu2_screen
	mov	edi,0xb8000
	mov	ecx,4000
	rep	movsb

	mov	ax,[cpu2_cur]
	call	put_cur

	mov	byte ptr [use_scr],2

	cmp	byte ptr [cpu2_vmx],0
	jne	f12.0
	call	send_ipi
f12.0:
	jmp	k.10
	.global	cpu2_vmx
cpu2_vmx:
	.byte	0x0
	.set	use_screen,12
scr_cpu0:
	.long	0x0	#display buff
	.long	0x0	#cursor address
	.long	0x0	#display buff save address
	.long	0x0	#use screen
scr_cpu2:
	.long	0x0	
	.long	0x0	
	.long	0x0	
	.long	0x0	

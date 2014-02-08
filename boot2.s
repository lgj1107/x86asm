
	.include "apicreg.def"
	.include "regs.def"
	.include "misc.def"
	.global start
	.intel_syntax noprefix
	.code64
	.text
	.set	SEL_SCODE,0x18
	.set	SEL_SDATA,0x20
	.set	SEL_UDATA,0x28|3
	.set	SEL_UCODE,0x30|3
	.set	SEL_TSS,0x38
start:
	.long	0x55aa66bb
	.long	boot2_end - start + 1024
	.long	offset ap_entry
start.1:
	mov	rsp,(cpu_data_base+cpu_rsp0)
	mov	eax,cpu_data_base + cpu_gdt_base
	mov	[cpu_data_base+cpu_gdtr_base],rax
	lgdt	[cpu_data_base + cpu_gdtr_limit]
	pushq	SEL_SCODE
	pushq	offset flush_64
	retfq
flush_64:

	mov	edi,idt_base
	mov	edx,0x188e
	mov	eax,offset intx00
	mov	ecx,17
	mov	ebx,eax
s.2:
	mov	[rdi],ax
	shr	eax,16
	mov	[rdi+6],ax
	mov	[rdi+2],dh
	mov	[rdi+5],dl
	add	ebx,4
	mov	eax,ebx
	lea	rdi,[rdi+16]
	loop	s.2

	set_gate 0x20,timer
	set_gate 0x21,keyb
	set_gate 0xf0,apic_timer
	set_gate 0xf1,apic_err
	set_gate 0xf2,apic_ici
	set_gate 0xfe,apic_svr

	mov	esi,offset idtr
	lidt	[rsi]
	
	mov	eax,cpu_data_base + cpu_tss_base
	mov	[rax+tss_rsp0],rsp
	mov	edi,cpu_data_base+cpu_gdt_base + SEL_TSS	#TSS segment desc
	mov	[rdi+2],ax
	shr	eax,16
	mov	[rdi+4],al
	shr	eax,8
	mov	[rdi+7],al
	mov	ax,SEL_TSS
	ltr	ax
	
	xor	eax,eax
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	
	call	enable_apic
	call	set_apic
	call	set_ioapic
	call	start_ap
	call	set_syscall

#	call	send_ipi

	pushq	SEL_UDATA
	mov	eax,cpu_data_base+cpu_rsp3
	push	rax
	pushq	0x202
	pushq	SEL_UCODE
	mov	eax,offset ring3
	pushq	rax
	iretq
ring3:
	mov	esi,offset msg
	mov	edi,1
	syscall
	pause
	jmp	$
ap_entry:

	mov	ecx,MSR_APICBASE
	rdmsr
	bts	eax,11
	wrmsr
	mov	edi,APIC_SVR
	mov	eax,[rdi]
	bts	eax,8
	mov	[rdi],eax
.if 0
	mov	eax,[APIC_ID]
	shr	eax,24
1:	
	mov	bl,1
	xchg	[t_lock],bl
	test	bl,1
	jnz	1b
	mov	edi,[temp_data]
	call	hex32
	add	edi,2
	mov	[temp_data],edi
	mov	byte ptr [t_lock],0
.endif

	mov	eax,[APIC_ID]
	shr	eax,24
	mov	ebx,cpu_data_size
	mul	ebx
	mov	r8,cpu_data_base
	lea	r9,[r8+rax]		#CPU data base addr
	lea	rsp,[r9+cpu_rsp0]

	pushq	2
	popfq
	lea	rdi,[r9+cpu_gdtr_limit]
	lea	rsi,[r8+cpu_gdtr_limit]
	mov	ecx,0x3000/8
	rep	movsq

	lea	rax,[r9+cpu_gdt_base]
	mov	[r9+cpu_gdtr_base],rax
	

	lgdt	[r9+cpu_gdtr_limit]

	push	SEL_SCODE
	push	offset flush_ap
	retfq
flush_ap:
	xor	eax,eax
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	
	lidt	idtr
	lea	r10,[r9+cpu_gdt_base]
	lea	rax,[r9+cpu_tss_base]
	mov	rbx,rax
	mov	[r10+SEL_TSS+tss_desc_base_15_0],ax
	shr	eax,16
	mov	[r10+SEL_TSS+tss_desc_base_23_16],al
	mov	al,0x89
	mov	[r10+SEL_TSS+tss_desc_p_dpl_type],al
	shr	eax,8
	mov	[r10+SEL_TSS+tss_desc_base_31_24],al
	mov	[rbx+tss_rsp0],rsp

	mov	eax,SEL_TSS
	ltr	ax

	call	set_apic
	call	set_syscall


	push	SEL_UDATA
	lea	rax,[r9+cpu_rsp3]
	push	rax
	push	0x202
	push	SEL_UCODE
	push	offset ring3
	iretq
set_syscall:
	mov	ecx,IA32_STAR
	xor	eax,eax
	mov	edx,0x00230018
	wrmsr
	mov	eax,0x202
	mov	ecx,IA32_FMASK
	wrmsr
	mov	eax,offset sys_call
	xor	edx,edx
	mov	ecx,IA32_LSTAR
	wrmsr

	call	get_lapic_id
	mov	r15,cpu_data_base
	mov	ebx,cpu_data_size
	mul	ebx
	lea	r14,[r15+rax+cpu_pcb_base]
	pop	rbx
	mov	[r14+pcb_rsp0],rsp
	push	rbx
	
	xor	edx,edx
	mov	rax,r14
	mov	ecx,IA32_KERNEL_GSBASE
	wrmsr

	mov	ecx,IA32_GSBASE
	xor	eax,eax
	wrmsr
	ret	

#
#
#
lol:
	mov	edi,offset t_lock
l.0:
	xor	eax,eax
	mov	edx,1
	lock
	cmpxchg	byte ptr [rdi],dl
	jnz	l.0
	
	ret
idtr:
	.word	256*16
	.quad	idt_base
cpu_count:
	.byte	0x0
	.global	t_lock,lol
t_lock:
	.byte	0x0
t_lock1:
	.byte	0x0

temp_data:
	.long	0xb8000+160*15
temp_gdt:
	.word	0x0
	.quad	0x0

	.code64
	.intel_syntax noprefix
	.text
	.include "apicreg.def"
	.include "regs.def"
	.include "vmcs.def"
	.include "misc.def"
	.global vm_exit,vtx_start
vtx_start:
	mov	ecx,IA32_FEATURE_CTL
	rdmsr
	test	al,1
	jnz	2f
	or	eax,0x5
	wrmsr

	mov	edi,[cpu2_disp]
	mov	ecx,IA32_FEATURE_CTL
	call	rmsr
	mov	ecx,IA32_VMX_BASIC
	call	rmsr
2:
#
#initial VMCS region  (host guest)
#
	mov	ecx,IA32_VMX_BASIC
	rdmsr

	mov	[vmxon_region],eax
	mov	[vmcs_guest],eax
	vmxon	[vmxon_ptr]
	vmclear [vmcs_ptr]
	vmptrld	[vmcs_ptr]

	
#
#16-bit Guest-State field
#
	xor	eax,eax
	mov	ebx,0x802	#guest cs
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_ES_SEL
	vmwrite rbx,rax
	mov	ebx,0x804	#guest ss
	vmwrite rbx,rax
	mov	ebx,0x806	#guest ds
	vmwrite rbx,rax
	mov	ebx,0x808	#guest fs
	vmwrite rbx,rax
	mov	ebx,0x80a	#guest gs
	vmwrite rbx,rax
	mov	ebx,0x80c	#guest LDTR
	vmwrite rbx,rax
	mov	rbx,VMCS_GUEST_TR_SEL
	vmwrite rbx,rax
#
#32-Bit Guest-State Fields
#
	mov	eax,0xffff
	mov	edx,0x4800	#guest es limit
	vmwrite	rdx,rax
	mov	edx,0x4802	#guest cs limit
	vmwrite rdx,rax
	mov	edx,0x4804	#guest ss limit
	vmwrite rdx,rax
	mov	edx,0x4806	#guest ds limit
	vmwrite rdx,rax
	mov	edx,0x4808	#guest fs limit
	vmwrite rdx,rax
	mov	edx,0x480a	#guest gs limit
	vmwrite rdx,rax
	mov	edx,0x480c	#guest LDTR limit
	vmwrite rdx,rax
	mov	rbx,VMCS_GUEST_GDTR_LIMIT	#0x4810
	vmwrite rbx,rax

#	mov	eax,0x3ff
	mov	ebx,VMCS_GUEST_IDTR_LIMIT	#0x4812
	vmwrite rbx,rax

	mov	eax,0x9b
	mov	ebx,VMCS_GUEST_CS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	eax,0x93
	mov	ebx,VMCS_GUEST_ES_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_SS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_DS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_FS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_GS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	eax,0x82
	mov	ebx,VMCS_GUEST_LDTR_ACCESS_RIGHTS
	vmwrite rbx,rax
	mov	eax,0x8b
	mov	ebx,VMCS_GUEST_TR_ACCESS_RIGHTS	
	vmwrite rbx,rax
.if 1	
	xor	eax,eax
	mov	ebx,VMCS_GUEST_INTERRUPTIBILITY_STATE
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_ACTIVITY_STATE
	vmwrite	rbx,rax
.endif
	mov	ebx,VMCS_GUEST_SMBASE
	mov	eax,0xa0000
	vmwrite	rbx,rax
.if 0
	mov	ebx,VMCS_GUEST_IA32_SYSENTER_CS
	xor	eax,eax
	vmwrite	rbx,rax
.endif
#
# 64-Bit Guest-State Fields
#
	mov	ebx,VMCS_LINK_POINTER
	mov	rax,-1
	vmwrite	rbx,rax
	mov	ebx,VMCS_LINK_POINTER_HIGH
	vmwrite	rbx,rax

.if 1
	mov	ecx,0x1d9			#IA32_DEBUGCTL
	rdmsr
	mov	ebx,VMCS_GUEST_IA32_DEBUGCTL
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_IA32_DEBUGCTL_HIGH
	vmwrite	rbx,rdx
	xor	eax,eax
	mov	ebx,VMCS_GUEST_IA32_EFER
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_IA32_EFER_HIGH
	vmwrite	rbx,rax
.endif

#
# Natural-Width Guest-State Fields 
#
	mov	eax,0x00000020
	mov	ebx,VMCS_GUEST_CR0
	vmwrite	rbx,rax
.if 1
	mov	eax,0x0
	mov	ebx,VMCS_GUEST_CR3
	vmwrite	rbx,rax
.endif

	mov	eax,0x00002000
	mov	ebx,VMCS_GUEST_CR4
	vmwrite	rbx,rax

	xor	eax,eax
	mov	rbx,VMCS_GUEST_ES_BASE
	vmwrite	rbx,rax
	mov	rbx,VMCS_GUEST_CS_BASE
	vmwrite	rbx,rax
	mov	rbx,VMCS_GUEST_SS_BASE
	vmwrite	rbx,rax
	mov	rbx,VMCS_GUEST_DS_BASE
	vmwrite	rbx,rax
	mov	rbx,VMCS_GUEST_FS_BASE
	vmwrite	rbx,rax
	mov	rbx,VMCS_GUEST_GS_BASE
	vmwrite	rbx,rax
	
	mov	eax,0x202
	mov	ebx,VMCS_GUEST_RFLAGS
	vmwrite	rbx,rax

	xor	eax,eax
	mov	ebx,VMCS_GUEST_IDTR_BASE
	vmwrite rbx,rax

	mov	eax,0x400
	mov	ebx,VMCS_GUEST_DR7
	vmwrite	rbx,rax

	mov	eax,0x7c00
	mov	ebx,VMCS_GUEST_RSP
	vmwrite	rbx,rax

	mov	ebx,VMCS_GUEST_RIP
	movzx	eax,word ptr [GUEST_IP]
	vmwrite	rbx,rax
.if 1
	xor	eax,eax
	mov	ebx,VMCS_GUEST_TR_BASE
#	movzx	eax,word ptr [GUEST_TSS_BASE]
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_GDTR_BASE
#	movzx	eax,word ptr [GUEST_GDT_BASE]
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_IDTR_BASE
	vmwrite	rbx,rax
.endif

#
#16 bit Host-State fields
#
	mov	eax,cs
	mov	ebx,VMCS_HOST_CS_SEL
	vmwrite	rbx,rax
	xor	eax,eax
	mov	ebx,VMCS_HOST_DS_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_ES_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_FS_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_SS_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_GS_SEL
	vmwrite	rbx,rax
	str	ax
	mov	ebx,VMCS_HOST_TR_SEL
	vmwrite	rbx,rax
#
#natural 32 bit host state field
#
	mov	rax,cr0
	mov	ebx,VMCS_HOST_CR0
	vmwrite	rbx,rax

	mov	rax,cr3
	mov	ebx,VMCS_HOST_CR3
	vmwrite	rbx,rax
	
	mov	rax,cr4
	mov	ebx,VMCS_HOST_CR4
	vmwrite	rbx,rax

	xor	eax,eax
	mov	ebx,VMCS_HOST_GS_BASE
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_FS_BASE
	vmwrite	rbx,rax

	mov	rdx,r15				#ORG RSP VAL
	lea	eax,[rdx+8*11+10]		#tss segment addr
	mov	ebx,VMCS_HOST_TR_BASE
	vmwrite	rbx,rax

	lea	eax,[rdx+10]			#gdt table addr
	mov	ebx,VMCS_HOST_GDTR_BASE
	vmwrite	rbx,rax
	
	mov	eax,idt_base
	mov	ebx,VMCS_HOST_IDTR_BASE
	vmwrite	rbx,rax
	
	mov	rax,r15
	mov	ebx,VMCS_HOST_RSP
	vmwrite	rbx,rax

	mov	rax,offset vm_exit
	mov	ebx,VMCS_HOST_RIP
	vmwrite	rbx,rax

	mov	ecx,MSR_EFER
	rdmsr
	mov	rbx,VMCS_HOST_IA32_EFER
	vmwrite	rbx,rax
	mov	rbx,VMCS_HOST_IA32_EFER_HIGH
	vmwrite	rbx,rdx

	
#
# 32-Bit Control Fields 
#
	

	mov	ecx,IA32_VMX_PINBASED_CTLS
	rdmsr
	mov	ebx,VMCS_PIN_BASED_VMEXEC_CTL
	vmwrite	rbx,rax

	mov	ecx,IA32_VMX_PROCBASED_CTLS
	rdmsr
	and	eax,~(cr3_load_exiting|cr3_store_exiting)
	or	eax,activate_secondary_control
	mov	ebx,VMCS_PROC_BASED_VMEXEC_CTL
	vmwrite	rbx,rax

	mov	ecx,IA32_VMX_PROCBASED_CTLS2
	rdmsr
	or	eax,unrestricted_guest|enable_ept
	mov	ebx,VMCS_PROC_BASED_VMEXEC_CTL2
	vmwrite	rbx,rax
	
	xor	eax,eax
#	bts	eax,14		#PF
#	bts	eax,8		#DF
	mov	ebx,VMCS_EXCEPTION_BMP
	vmwrite	rbx,rax

	mov	ecx,IA32_VMX_EXIT_CTLS
	rdmsr
	or	eax,host_addr_space_size|ack_interrupt_on_exit|save_ia32_efer
	mov	ebx,VMCS_VMEXIT_CTL
	vmwrite	rbx,rax

	mov	ecx,IA32_VMX_TRUE_ENTRY_CTLS
	rdmsr
	or	eax,load_ia32_efer
	mov	ebx,VMCS_VMENTRY_CTL
	vmwrite	rbx,rax

.if 0
	xor	eax,eax
	mov	rbx,VMCS_VMENTRY_INTR_INFO_FIELD
	vmwrite	rbx,rax
	mov	rbx,VMCS_PAGEFAULT_ERRCODE_MATCH
	vmwrite	rbx,rax
	mov	rbx,VMCS_PAGEFAULT_ERRCODE_MASK
	vmwrite	rbx,rax
.endif
#
# Natural-Width Control Fields 
#
	mov	ebx,VMCS_CR0_GUESTHOST_MASK	
	mov	eax,0x00000020
	vmwrite	rbx,rax
	mov	ebx,VMCS_CR4_GUESTHOST_MASK	
	mov	eax,0x00002000
	vmwrite	rbx,rax
	mov	ebx,VMCS_CR0_READ_SHADOW
	mov	eax,0x20
	vmwrite	rbx,rax
	mov	ebx,VMCS_CR4_READ_SHADOW
	mov	eax,0x2000
	vmwrite	rbx,rax
.if 1
	mov	eax,2
	mov	ebx,VMCS_CR3_TARGET_COUNT
	vmwrite rbx,rax
	
	mov	ebx,VMCS_CR3_TARGET_VALUE_0
	xor	eax,eax
	vmwrite	rbx,rax

	mov	ebx,VMCS_CR3_TARGET_VALUE_1
	mov	eax,PAGE_PML4
	vmwrite	rbx,rax
.endif
#
#64bit control field
#
	xor	eax,eax
	mov	ebx,VMCS_ADDR_IOBMP_A
	vmwrite	rbx,rax
	mov	ebx,VMCS_ADDR_IOBMP_A_HIGH
	vmwrite	rbx,rax
	mov	ebx,VMCS_ADDR_IOBMP_B
	vmwrite	rbx,rax
	mov	ebx,VMCS_ADDR_IOBMP_B_HIGH
	vmwrite	rbx,rax
	
.set	GUEST_PML4E,0x3400000
	mov	ebx,VMCS_EPT_PTR
	mov	eax,GUEST_PML4E|0x18		#memory type = UC , page walk length =4 - 1
	vmwrite	rbx,rax
	mov	ebx,VMCS_EPT_PTR_HIGH
	xor	eax,eax
	vmwrite	rbx,rax
.if 0
	mov	ebx,VMCS_VMENTRY_MSRLOAD_ADDR
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_MSRLOAD_ADDR_HIGH
	xor	eax,eax
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_INTR_INFO_FIELD
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_EXCEPTION_ERRCODE
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_INSTRUCTION_LEN
	vmwrite	rbx,rax
.endif
	ret

#	vmlaunch
	.global	set_guest
set_guest:
#
#set guest
#

	mov	edi,0x600
	mov	esi,offset boot2_end
	cmp	dword ptr [rsi],0x12345678
	jne	ap_hlt
	movzx	ecx,word ptr [rsi+8]
	cld	
	rep	movsb
#
#set EPT
#
	mov	eax,GUEST_PDPTE|7		#X W R
	mov	[GUEST_PML4E],rax

	mov	esi,GUEST_PDPTE
	mov	eax,GUEST_PDE|0x07
	mov	[rsi],rax
	mov	[rsi+0x18],rax

	mov	edi,GUEST_PDE
	mov	eax,0x87
	mov	ecx,8
1:	
	stosq
	add	eax,0x200000
	loop	1b
	ret
.if 0
	mov	[rdi],rax
	add	eax,0x200000
	lea	rdi,[rdi+8]
	loop	1b
	ret
.endif	
ap_hlt:
	jmp	$
vm_exit:
	pushfq
	mov	[guest_rax],rax
	mov	[guest_rbx],rbx
	mov	[guest_rdx],rdx
	mov	[guest_rcx],rcx
	mov	[guest_rdi],rdi
	mov	[guest_rsi],rsi

	
	mov	ebx,VMCS_EXIT_REASON
	vmread	rcx,rbx
	cmp	ecx,0xa			#CPUID
	je	cpu_id
	cmp	ecx,28			#cortrol-register accesses
	je	cr_access
	cmp	ecx,0x30		#ept violations
	je	ept_violations
	jmp	v.0
cpu_id:	
	mov	rbx,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	r8,rbx

	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	add	r8,rax
	vmwrite	rbx,r8
	cpuid
	mov	rdi,[guest_rdi]
	mov	rsi,[guest_rsi]
	popfq
	vmresume
cr_access:
	mov	ebx,VMCS_GUEST_CR3
	vmwrite	rbx,rax

	mov	r9,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	r8,r9
	mov	r9,VMCS_GUEST_RIP
	vmread	r10,r9
	add	r8,r10
	vmwrite	r9,r8

vm_resume:
	
	mov	rcx,[guest_rcx]	
	mov	rbx,[guest_rbx]	
	mov	rax,[guest_rax]	
	mov	rdi,[guest_rdi]
	mov	rsi,[guest_rsi]
	popfq
	vmresume
ept_violations:
	jmp	v.0
	mov	r8,VMCS_EXIT_QUALIFICATION
	vmread	rax,r8
	push	rax
	and	al,3
	cmp	al,3
	je	lock_mem
	pop	rax
	test	al,1		#data read
	jnz	mem_to_reg
	test	al,2 
	jnz	reg_to_mem
#	jmp	$
	mov	r8,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	r9,r8
	
	mov	edi,0xb8000+160*1
	mov	rax,r9
	call	hex32
#	jmp	$
	
		
v.0:
	mov	edi,0xb8000+160*12
	mov	ebx,VMCS_EXIT_REASON
	vmread	rax,rbx
	call	hex32

	mov	rbx,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	rax,rbx
	add	edi,2
	call	hex32

	mov	ebx,VMCS_EXIT_QUALIFICATION
	vmread	rax,rbx
	add	edi,2
	call	hex32

	mov	ebx,VMCS_GUEST_LINEAR_ADDR
	vmread	rax,rbx
	add	edi,2
	call	hex32
	
	mov	ebx,VMCS_GUEST_PHYSICAL_ADDR
	vmread	rax,rbx
	add	edi,2
	call	hex32

	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	mov	r8,rax
	add	edi,2
	call	hex32

#	mov	ebx,VMCS_GUEST_CR3
#	vmread	rax,rbx
#	add	edi,2
#	call	hex32
	mov	rax,[r8]
	add	edi,2
	call	hex64
	jmp	$
reg_to_mem:			#write memory
	mov	r8,VMCS_GUEST_RIP
	vmread	rsi,r8
	mov	ebx,esi
	mov	r8,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	rcx,r8
	cld	
	lodsb
	cmp	al,0x87		#XCHG 
	je	xchg_reg
rtm.0:
	add	ebx,ecx
	mov	rdx,[guest_rdx]
rtm.1:
	mov	r8,VMCS_GUEST_RIP
	vmwrite	r8,rbx
	jmp	vm_resume
xchg_reg:
	lodsb
	cmp	al,0x6
	je	xchg_eax
	cmp	al,0x16
	je	xchg_edx
	jmp	$
xchg_eax:
	mov	eax,-1
	mov	[guest_rax],rax
	mov	ebx,esi
	jmp	rtm.0
xchg_edx:
	mov	edx,-1
	mov	ebx,esi
	jmp	rtm.0
lock_mem:
	jmp	reg_to_mem
#
#read memory
#
mem_to_reg:
	mov	r8,VMCS_GUEST_RIP
	vmread	rsi,r8
	mov	ebx,esi
	mov	r8,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	rcx,r8
	cld
	lodsb
	cmp	al,0x8b
	je	mov_reg
	jmp	$
mov_reg:
	lodsb
	cmp	al,0x6
	je	reg_eax
	cmp	al,0x16
	je	reg_edx
	jmp	v.0
reg_eax:
	mov	eax,-1
	mov	[guest_rax],rax
m.0:
	add	ebx,ecx
	mov	r8,VMCS_GUEST_RIP
	vmwrite	r8,rbx
	jmp	vm_resume
reg_edx:
	mov	rdx,-1
	jmp	m.0
#	mov	[guest_rdx],rax
	jmp	vm_resume

	mov	edi,0xb8000+160*10
	mov	eax,[rcx]
	call	hex32
	jmp	$
	.global	rmsr
rmsr:
	rdmsr
	xchg	eax,edx
	call	hex32
	add	edi,2
	xchg	eax,edx
	call	hex32
	add	edi,2
	ret
guest_rax:
	.quad	0x0
guest_rbx:
	.quad	0x0
guest_rdx:
	.quad	0x0
guest_rcx:
	.quad	0x0
guest_rbp:
	.quad	0x0
guest_rdi:
	.quad	0x0
guest_rsi:
	.quad	0x0

	.global vmxon_region,vmcs_guest,vmxon_ptr,vmcs_ptr
	.p2align 4
vmxon_ptr:
	.quad	vmxon_region
vmcs_ptr:
	.quad	vmcs_guest

	.bss
	.fill	4096,1,0
cpu0_stk:
	.fill	4096,1,0
cpu1_stk:
	.fill	4096,1,0
red_z:
	.p2align 12
vmxon_region:
	.fill	4096,1,0
vmcs_guest:
	.fill	4096,1,0

#	.set	PAGE_BASE,0x100000
#	.set	PAGE_PML4,PAGE_BASE
#	.set	PAGE_PDPTE,PAGE_BASE + 0x1000*1
#	.set	PAGE_APIC_PDE,PAGE_BASE+0x1000*2
#	.set	PAGE_PDE,PAGE_BASE + 0x1000*3
	
	.set	CORE_BASE,0x3c00000	#60M
	.set	KNL_BASE,CORE_BASE
	.include "apicreg.def"
	.include "regs.def"
	.include "misc.def"

	.global	start
	.intel_syntax noprefix
	.code16
start:
	mov	al,-1
	out	0x21,al
	out	0xa1,al
	cli
	in	al,0x92
	or	al,2
	out	0x92,al

	lgdt	gdtr
	mov	eax,cr0
	or	al,1
	mov	cr0,eax
	ljmp	0x8,start32	
	.code32
start32:
	mov	eax,0x10
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	esp,0x90000
	push	2
	popfd


	mov	edi,0x3400000
	xor	eax,eax
	mov	ecx,0x1000000/4
	rep	stosd

	mov	esi,PAGE_BASE
	mov	eax,PAGE_PDPTE|7
	mov	[esi],eax
	
	mov	esi,PAGE_PDPTE
	mov	eax,PAGE_PDE|7
	mov	[esi],eax
	mov	eax,PAGE_APIC_PDE|7
	mov	[esi+0x18],eax		#APIC

	mov	esi,PAGE_PDE
	mov	ecx,32			#64M
	mov	eax,0x0|0x87
	xor	edx,edx
	mov	ebx,0x200000
s.3:
	mov	[esi],eax
	mov	[esi+4],edx
	lea	esi,[esi+8]
	add	eax,ebx
	loop	s.3
	
	mov	esi,PAGE_APIC_PDE + 0xfb0
	mov	eax,IO_APIC_BASE|0x87
	mov	ecx,2
s.4:
	mov	[esi],eax
	mov	[esi+4],edx
	lea	esi,[esi+8]
	add	eax,ebx
	loop	s.4

	
	mov	eax,cr4
#	or	eax,CR4_FXSR|CR4_PAE
	or	eax,CR4_FXSR|CR4_PAE|CR4_VMXE
	mov	cr4,eax

	mov	ecx,MSR_EFER
	rdmsr
	or	eax,EFER_SCE|EFER_LME
	wrmsr
	
	mov	eax,PAGE_BASE
	mov	cr3,eax

	mov	eax,cr0
	and	eax,~0x60000000
	or	eax,0x80000020
	mov	cr0,eax
	
	jmp	0x28:start64
	.code64
start64:
	xor	eax,eax
	mov	ds,ax
	mov	es,ax
	mov	fs,ax
	mov	gs,ax
	mov	ss,ax
	mov	rsp,0x90000
	push	2
	popfq

	mov	edi,0x9f000
	mov	esi,offset bootmp
	mov	ecx,bootmp_end - bootmp
	rep	movsb

	mov	edi,CORE_BASE
	mov	esi,offset boot1_end
	mov	ecx,[boot1_end+4]
	mov	edx,ecx
	shr	ecx,3
	rep	movsq
	and	edx,7
	mov	ecx,edx
	rep	movsb

	mov	edi,cpu_data_base+cpu_gdtr_limit
	mov	esi,offset gdtr0
	mov	ecx,data_end - gdtr0
	rep	movsb

	mov	eax,offset boot1_end
	cmp	dword ptr [rax],0x55aa66bb
	jne	die
	mov	eax,CORE_BASE + 12
	jmp	rax

die:
	mov	edi,0xb8000+160*8
	mov	eax,0x06510652
	mov	[edi],eax
	jmp	$
	
hex64:
	push	rax
	shr	rax,32
	call	hex32
	pop	rax
hex32:
	push	rax
	shr	rax,16
	call	hex16
	pop	rax
hex16:
	push	rax
	shr	ax,8
	call	hex8
	pop	rax
hex8:
	push	rax
	shr	al,4
	call	hex8.1
	pop	rax
hex8.1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hex8.2
	add	al,0x7
hex8.2:
	mov	ah,2
	stosw		
	ret	
		
	jmp	.

	.code16
bootmp:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	sp,0xa00
	cli
	
	mov	eax,gdt - bootmp + 0x9f000
	mov	si,gdtr - bootmp
	mov	[si+2],eax
	lgdt	[gdtr - bootmp]
	
	mov	eax,cr4
	or	eax,CR4_FXSR|CR4_PAE|CR4_VMXE|CR4_MCE
#	or	eax,CR4_FXSR|CR4_PAE
	mov	cr4,eax

	mov	ecx,MSR_EFER
	rdmsr
	or	eax,EFER_SCE|EFER_LME
	wrmsr
	
	mov	eax,PAGE_BASE
	mov	cr3,eax

	mov	eax,cr0
	or	eax,0x80000021
	mov	cr0,eax
	.byte	0x66
	.byte	0x67
	.byte	0xea
	.long	ap64-bootmp + 0x9f000
	.word	0x28
	.code64
ap64:
	xor	eax,eax
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	rsp,0x9f000
	
	mov	rax,0x243034105410642
	mov	edi,0xb8000+160*11-8
	mov	[rdi],rax

	mov	eax,[CORE_BASE+8]
	jmp	rax
	jmp	$

hexasc:
	mov	dx,ax
	mov	ah,2
h.1:	
	rol	dx,4
	mov	al,dl
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	h.2
	add	al,7
h.2:
	stosw
	loop	h.1
	ret		
	.code32
gdtr:
	.word	7*8
	.long	offset gdt
	.long	0x0
gdt:
	.quad	0x0
	.quad	0x00cf9a000000ffff
	.quad	0x00cf92000000ffff
	.quad	0x00009a000000ffff
	.quad	0x000092000000ffff
	.quad	0x00209a0000000000
	.quad	0x0020920000000000
bootmp_end:

gdtr0:	.word	data_end - gdt0
	.quad	0x0
gdt0:
	.quad	0x0			#0
	.quad	0x00cf9a000000ffff	#0x8
	.quad	0x00cf92000000ffff	#0x10
	.quad	0x00209a0000000000	#0x18
	.quad	0x0020920000000000	#0x20
	.quad	0x0020f20000000000	#0x28
	.quad	0x0020fa0000000000	#0x30
#
#TSS
#
	.word	0x67			#limit 0 -15
	.word	0x0			#base address
	.byte	0x0			#base address 16 -23
	.byte	0x89			#p_dpl_type
	.byte	0x00			#g_avl_limit-16-19
	.byte	0x0			#byte 24 - 31
	.long	0x0			#base 32 - 63
	.long	0x0			#RSV
	.quad	0x00009a000000ffff
	.quad	0x000092000000ffff

tss0:
	.long	0x0		#RSV
	.quad	0x0		#rsp0
	.quad	0x0
	.quad	0x0
	.quad	0x0		#RSV

	.quad	0x0		#IST1
	.quad	0x0
	.quad	0x0
	.quad	0x0
	.quad	0x0
	.quad	0x0
	.quad	0x0		#IST7

	.quad	0x0		#RSV
	.word	0x0		#RSV
	.word	0xff		#i/o map base address
data_end:	
	.org 1024
boot1_end:

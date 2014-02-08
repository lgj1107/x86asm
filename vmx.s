
	.include "apicreg.def"
	.include "misc.def"
	.include "vmcs.def"
	.intel_syntax noprefix
	.code64
	.global	rmsr
rmsr:
	rdmsr
	xchg	eax,edx
	add	edi,2
	call	hex32
	xchg	eax,edx
	add	edi,2
	call	hex32
	ret
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

	.include "apicreg.def"
	.include "misc.def"
	.global	intx00
	.intel_syntax noprefix
	.code64
#
#  Exception jump table.
#
intx00:	
	push	0x0			# Int 0x0: #DE
	jmp	short  ex_noc		# Divide error
	push	0x1			# Int 0x1: #DB
	jmp	ex_noc			# Debug
	push	0x2			#RSV
	jmp	except			#
	push	0x3			# Int 0x3: #BP
	jmp	ex_noc			# Breakpoint
	push	0x4			# Int 0x4: #OF
	jmp	ex_noc			# Overflow
	push	0x5			# Int 0x5: #BR
	jmp	ex_noc			# BOUND range exceeded
	push	0x6			# Int 0x6: #UD
	jmp	ex_noc			# Invalid opcode
	push	0x7			# Int 0x7: #NM
	jmp	ex_noc			# Device not available
	push	0x8			# Int 0x8: #DF
	jmp	except			# Double fault
	push	0x9			# RSV
	jmp	except			# 

	push	0xa			# Int 0xa: #TS
	jmp	except			# Invalid TSS
	push	0xb			# Int 0xb: #NP
	jmp	except			# Segment not present
	push	0xc			# Int 0xc: #SS
	jmp	except			# Stack segment fault
	push	0xd			# Int 0xd: #GP
	jmp	except			# General protection
	push	0xe			# Int 0xe: #PF
	jmp	except			# Page fault
	push	0xf			# RSV
	jmp	except			# 
intx10:	push	0x10			# Int 0x10: #MF
	jmp	ex_noc			# Floating-point er
	push	17			
	jmp	except			#Alignment Check Exception
ex_noc:
	push	[rsp]
	mov	qword ptr [rsp+8],0x0
except:
	call	lol
	mov	edi,offset dump_fmt+10
	call	get_lapic_id
	call	hex_32
	mov	edi,offset d.0+6
	mov	ecx,7
	mov	rsi,rsp
1:
	lodsq
	call	hex_32
	cmp	byte ptr [rdi],0xa
	jne	2f
	inc	rdi
2:
	add	edi,7
	loop	1b
	mov	esi,offset df.0
	call	puts
	
	mov	byte ptr [t_lock],0
	jmp	$
	.global	timer,keyb,apic_timer,apic_err,apic_svr,apic_ici
timer:
	push_fram
	pop_fram
	xor	eax,eax
	mov	[APIC_EOI],eax
	iretq
apic_timer:
	push	rdi
	inc	qword ptr [apic_count]
	mov	rax,[apic_count]
	mov	edi,0xb8000+160-16
	call	hex32
	pop	rdi
	xor	eax,eax
	mov	[APIC_EOI],eax
	iretq
apic_err:
	xor	eax,eax
	mov	[APIC_EOI],eax
	iretq
apic_svr:
	iretq
	.global	apic_ici
apic_ici:
	push_fram
	call	get_lapic_id
	mov	edi,0xb8000+160*2-16
	call	hex32
	pop_fram
	xor	eax,eax
	mov	[APIC_EOI],eax
	
	mov	eax,[APIC_ID]
	shr	eax,24
	cmp	al,2
	je	a.10
	iretq
a.10:
	mov	byte ptr [cpu2_vmx],1
	mov	edi,offset cpu2_stk
	mov	rsi,rsp
	cld
	mov	ecx,5
	rep	movsq
	mov	rsp,rsi
	
	call	set_guest
	mov	r15,rsp
	call	vtx_start
	vmlaunch
	jmp	$
	.global	sys_call
sys_call:
	swapgs
	mov	gs:[pcb_rsp3],rsp
	mov	rsp,gs:[pcb_rsp0]
	push	rcx		#rip
	push	r13
	push	r11		#RFLAGS
	call	[call_table+rdi*4]
	pop	r11
	pop	r13
	pop	rcx
	mov	gs:[pcb_rsp0],rsp
	mov	rsp,gs:[pcb_rsp3]
	swapgs
	sysretq

call_table:
	.long	0x0
	.long	offset puts
	.long	0x0
	.long	0x0
	.global	cpu0_cur,cpu2_cur,use_scr
cpu0_cur:
	.2byte	0x0
cpu2_cur:
	.2byte	0x0
use_scr:
	.byte	0x0
	.global	cpu_disp,cpu2_disp
cpu_disp:
	.long	0xb8000
cpu2_disp:
	.long	0xb8fa0
cpu2_stk:
	.fill	5*8,1,0
apic_count:
	.quad	0x0

df.0:
	.byte	0xa
dump_fmt:
	.ascii	"APIC_ID=0x00000000\n"		#APIC ID =
d.0:	.ascii	"INT=0x00000000 "
	.ascii	"ERR=0x00000000 "
	.ascii	"RIP=0x00000000 "		#
	.ascii	" CS=0x00000000 "		#
	.ascii	"EFL=0x00000000\n"		#eflage =
	.ascii	"RSP=0x00000000 "		#
	.asciz	" SS=0x00000000\n"		#
		
	.global	hex64,hex32
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
	.global	hex_64,hex_32
hex_64:
	push	rax
	shr	rax,32
	call	hex_32
	pop	rax
hex_32:
	push	rax
	shr	rax,16
	call	hex_16
	pop	rax
hex_16:
	push	rax
	shr	ax,8
	call	hex_8
	pop	rax
hex_8:
	push	rax
	shr	al,4
	call	hex_8.1
	pop	rax
hex_8.1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hex_8.2
	add	al,0x7
hex_8.2:
	stosb		
	ret	
	.set	rsp_int,0
	.set	rsp_err,8
	.set	rsp_rip,16
	.set	rsp_cs,24
	.set	rsp_efl,32
	.set	rsp_rsp,40
	.set	rsp_ss,48

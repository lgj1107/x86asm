	.code16
	.global start16, begin
	.intel_syntax noprefix
begin:
	.long	0x12345678		#SIG 0
	.word	offset start16		#4
	.word	0x0	#offset gdt16		#6
	.word	tss_end-begin			#8
	.word	0x0			#10
start16:
	cli
	mov	dx,0xb800
	mov	es,dx
	mov	di,160*11+0x20
	mov	ax,0x0641
	mov	es:[di],ax
	mov	si,offset msg
	call	putc
	jmp	$
	xor	eax,eax
	cpuid
.if 0	
	xor	al,al
	out	0x21,al
	jmp	$+2
	out	0xa1,al
	sti
s.1:
#.if 1
	mov	ah,2
	mov	al,1
	mov	cl,1
	mov	ch,0
	mov	bx,0x7c00
	xor	dx,dx
	mov	es,dx
	mov	dl,0x1
	int	0x13
	ljmp	0:0x7c00
	jmp	$
.endif
	
.code16

.if 0	
	xor	ax,ax
	mov	es,ax
	mov	ds,ax
	lea	si,disk_pack
	mov	ah,0x42
	mov	dx,0x80
	int	0x13
.endif
.if 0
	.intel_syntax noprefix
	.global	hex32,hex16
hex32:
hex16:
	push	ax
	shr	ax,8
	call	hex8
	pop	ax
hex8:
	push	ax
	shr	al,4
	call	hex8.1
	pop	ax
hex8.1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hex8.2
	add	al,0x7
hex8.2:
	mov	ah,6
	stosw		
	ret
.endif
	.intel_syntax noprefix
	.global	putc.1
putc.1:
	mov	bx,7
	mov	ah,0xe
	int	0x10
putc:
	lodsb
	test	al,al
	jnz	putc.1
	ret
msg:	.ascii	"cr0=0x00000000"
	.byte	0xa,0xd
	.byte	0x0	
gdt16:
	.quad	0x0
	.quad	0x00cf9a000000ffff
	.quad	0x00cf92000000ffff
#tss_sel
	.word	0x0			#limit	15-0
	.word	0			#base address 15 - 0 
	.byte	0x0			#base address 23 -16
	.byte	0x0
	.byte	0x0			#G_0_0_AVL_LIMIT
	.byte	0x0			#BASE 31_24
	.quad	0x00009b000000ffff	#0x20
	.quad	0x000093000000ffff	#0x28
gdtr:	.word	6*8-1
	.long	gdt16
	.p2align 2
disk_pack:
	.byte	0x10		#struct size 0x10 or 0x18
	.byte	0x00
	.byte	0x1		#numbe of block to transfer. max 007fh
	.byte	0x0
	.word	0x7c00		#offset
	.word	0x00 		#seg
	.long	0x0		#start sector
	.long	0x0		#RSV, LBA48 used starting abosolute blocknumber 
	.org	1024
tss_end:
#	V86 STACK
#------------------------
#|	old GS		|
#|	old FS		|
#|	old ES		|
#|	old ES		|
#|	old SS		|
#|	old ESP		|
#|	old EFLAGS	|
#|	old CS		|
#|	old EIP		|
#|----------------------|<----new esp

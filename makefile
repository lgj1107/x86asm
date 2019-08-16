OBJS = boot2.o apic.o int.o keyb.o vtx.o libs.o
reloc=0x80000000
all:new
%.o:%.s
	as -o $@ $<
boot0:boot0.o
	ld -N -e start -Ttext=0x600 -o boot0.out boot0.o
	objcopy -S -O binary boot0.out $@

boot1:boot1.o
	ld -N -e start -Ttext=0x800 -o boot1.out boot1.o
	objcopy -S -O binary boot1.out $@
boot2:$(OBJS)
#	ld -N -e start -Ttext=0x3c00000 -o boot2.out $(OBJS)
#	ld -N -e start -Ttext=$(reloc) -o boot2.out $(OBJS)
	ld -N -Tld.src -o boot2.out $(OBJS)
	objcopy -S -O binary boot2.out $@
guest:guest.o
	ld -N -e begin -Ttext=0x600 -o guest.out guest.o
	objcopy -S -O binary guest.out $@
te:$(OBJS)
	gcc -fPIE -c -o boot3.out $(OBJS)
		
new:boot0 boot1 boot2 guest
	cat boot0 boot1 boot2 guest>new
clean:
	rm -f boot[0-9].o boot[0-9].out new real.iso guest.o guest.out guest $(OBJS) boot[0-9]
ddisk:
	dd if=new of=c.img conv=notrunc	
mmc:
	dd if=new of=/dev/sdc conv=sync
nombr:
	cat boot1 boot2 guest > n1
iso:
	losetup /dev/loop0 disk.img
	dd if=new of=/dev/loop0 conv=sync
	sleep 0.5
	losetup -d /dev/loop0
	genisoimage -o real.iso -R -J -b disk.img  .

#gdb --args \
./qemu/build/qemu-system-aarch64 -machine baize -nographic \
	-bios ./boot.rom \
	-drive if=pflash,format=raw,index=0,file=./pflash.raw \
	-drive if=none,file=rootfs.ext4,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	#-S -s


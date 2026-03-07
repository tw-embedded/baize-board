#GRAPHIC_OPT="-nographic"
# only 2D
GRAPHIC_OPT="-device virtio-gpu-device,edid=on,xres=800,yres=600,blob=off -m 2G -display gtk,gl=on -serial stdio"

#gdb --args \
./qemu/build/qemu-system-aarch64 -machine baize \
	${GRAPHIC_OPT} \
	-bios ./boot.rom \
	-drive if=pflash,format=raw,index=0,file=./pflash.raw \
	-drive if=none,file=baremetal.rootfs,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	#-S -s


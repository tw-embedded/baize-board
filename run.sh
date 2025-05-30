if [ -z $1 ]; then
	echo "no debug"
	DEBUG=""
else
	DEBUG="-S -s"
fi

#gdb --args \
./qemu/build/qemu-system-aarch64 -machine baize -nographic \
	-bios ./boot.rom \
	-drive if=pflash,format=raw,index=0,file=./pflash.raw \
	-drive if=none,file=emmc.img,id=hd2 \
	-device virtio-blk-device,drive=hd2 \
	-drive if=none,file=android.rootfs,id=hd3 \
        -device virtio-blk-device,drive=hd3 \
	-drive if=none,file=domu.rootfs,id=hd1 \
	-device virtio-blk-device,drive=hd1 \
	-drive if=none,file=dom0.rootfs,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	${DEBUG}


#!/bin/bash

DEBUG=""
ANDROID_DRIVE=""

for arg in "$@"; do
    case $arg in
        -d|d|debug)
            echo "debug mode..."
            DEBUG="-S -s"
            ;;
        android)
            echo "using android rootfs..."
            ANDROID_DRIVE="-drive if=none,file=android.rootfs,id=hd3 -device virtio-blk-device,drive=hd3 "
            ;;
        *)
            echo "run with default..."
     	    ;;
    esac
done

#gdb --args \
./qemu/build/qemu-system-aarch64 -machine baize -nographic \
	-bios ./boot.rom \
	-drive if=pflash,format=raw,index=0,file=./pflash.raw \
	-drive if=none,file=emmc.img,id=hd2 \
	-device virtio-blk-device,drive=hd2 \
	${ANDROID_DRIVE} \
	-drive if=none,file=domu.rootfs,id=hd1 \
	-device virtio-blk-device,drive=hd1 \
	-drive if=none,file=dom0.rootfs,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	${DEBUG}


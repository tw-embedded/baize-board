#!/bin/bash

DEBUG=""
ANDROID_DRIVE="-drive if=none,file=android.rootfs,id=hd3 -device virtio-blk-device,drive=hd3"
DISPLAY_OPT="-nographic -device virtio-rng-device"

for arg in "$@"; do
    case $arg in
        -d|d|debug)
            echo "debug mode..."
            DEBUG="-S -s"
            ;;
        -u|u|ui)
            DISPLAY_OPT="-device virtio-gpu-gl-device,edid=off,xres=800,yres=600,blob=off -m 2G -display gtk,gl=on -serial stdio"
	    #DISPLAY_OPT="-device virtio-gpu-device -vnc :29 -monitor stdio"
	    ;;
        *)
            echo "run with default..."
     	    ;;
    esac
done

#gdb --args \
./qemu/build/qemu-system-aarch64 -machine baize \
	${DISPLAY_OPT} \
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


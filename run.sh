#!/bin/bash

DEBUG=""
QEMU_ENV=""

# unsafe for performance optimization
ANDROID_DRIVE="-drive if=none,file=android.rootfs,id=hd3,cache=unsafe -device virtio-blk-device,drive=hd3"
DISPLAY_OPT="-nographic -device virtio-rng-device"

ensure_compositor()
{
    if [ -z "${DISPLAY}" ]; then
        return
    fi

    if command -v xprop >/dev/null 2>&1 &&
       xprop -root _NET_WM_CM_S0 2>/dev/null | grep -q "window id"; then
        return
    fi

    if pgrep -u "$(id -u)" -x picom >/dev/null 2>&1 ||
       pgrep -u "$(id -u)" -x compton >/dev/null 2>&1 ||
       pgrep -u "$(id -u)" -x xcompmgr >/dev/null 2>&1; then
        return
    fi

    if command -v picom >/dev/null 2>&1; then
        echo "no X compositor detected; starting picom..."
        mkdir -p _cache/log
        picom -b >_cache/log/picom.log 2>&1 || \
            echo "warning: failed to start picom; see _cache/log/picom.log"
    else
        echo "warning: no X compositor detected and picom is not installed"
    fi
}

for arg in "$@"; do
    case $arg in
        -d|d|debug)
            echo "debug mode..."
            DEBUG="-S -s"
            ;;
	-v|v) # for EC2 & android
	    DISPLAY_OPT="-device virtio-gpu-device -display none -vnc :1 -serial stdio"
	    QEMU_ENV=""
	    ;;
        -u|u|ui)
            ensure_compositor
            DISPLAY_OPT="-device virtio-gpu-device,edid=off,xres=640,yres=400,blob=off -device virtio-gpu-device,edid=on,xres=640,yres=480,blob=off -m 2G -display gtk,gl=on -serial stdio"
            QEMU_ENV="QEMU_GTK_DETACH_GFX=second QEMU_GTK_GFX_SIZES=640x400,640x480"
            #DISPLAY_OPT="-device virtio-gpu-gl-device -vnc :29 -monitor stdio"
            ;;
        *)
            echo "run with default..."
     	    ;;
    esac
done

#gdb --args \
env ${QEMU_ENV} ./qemu/build/qemu-system-aarch64 -machine baize \
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

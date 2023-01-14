#!/bin/sh

set -e

loopdev=$(losetup -f)
echo $loopdev

sudo losetup $loopdev ../disk.rootfs
sudo partprobe $loopdev
ls /dev/loop*

sudo mount $loopdev"p1" p1
sudo mount $loopdev"p2" p2

#sudo cp baize.dtb p1
#sudo cp startup.nsh p1

#sudo umount p1 p2
#sudo losetup -d $loopdev


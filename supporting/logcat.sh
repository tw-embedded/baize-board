#!/bin/sh

#set -e

IMG=../android.rootfs

fdisk -l $IMG

parted $IMG print

loopdev=$(sudo losetup -f)
echo $loopdev

sudo losetup $loopdev $IMG
sudo partprobe $loopdev
ls /dev/loop*

sudo mount $loopdev"p3" p1
ls p1

echo "try to find logcat & tombstone"
sudo find p1 -name "*logcat*"
sudo find p1 -name "*tombstone*"

sudo rm -rf ../_cache/log/*
sudo cp -r p1/tombstones ../_cache/log/
sudo cp -r p1/system/dropbox ../_cache/log/
sudo cp -r p1/anr ../_cache/log/
sudo cp -r p1/misc/logd ../_cache/log/

# end
sudo umount p1
sudo losetup -d $loopdev


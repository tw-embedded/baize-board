#!/bin/sh

#set -e

if [ $# -ne 1 ] ; then
	echo please input the loop id!!!
	exit
fi

sudo umount p1 p2

loopdev="/dev/loop"$1
echo remove $loopdev
sudo losetup -d $loopdev


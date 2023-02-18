#!/bin/bash

set -e

SOC_DEBUG=1

MISC_PATH=./supporting

function build_board() {
	if [ ! -d qemu/build ]; then
		mkdir qemu/build
		cd qemu/build
		../configure --target-list=aarch64-softmmu
		cd -
	fi
	cd qemu/build
	make -j 7
	cd -
}

function build_uefi() {
	if [ $SOC_DEBUG -eq 1 ]; then
		EDK2_PATH=debug
	else
		EDK2_PATH=release
	fi

	cd edk2
	git submodule update --init
	make -C BaseTools
	source edksetup.sh
	export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
	build -a AARCH64 -t GCC5 -b DEBUG -p FakePkg/Fake.dsc
	cd -
}

function build_atf() {
	if [ $SOC_DEBUG -eq 1 ]; then
		ATF_PARA="DEBUG=1 -d"
	else
		ATF_PARA=
	fi
	UEFIF=../edk2/Build/Fake-AARCH64/DEBUG_GCC5/FV/FAKE_EFI.fd

	cd arm-trusted-firmware/
	make O=build ARCH=aarch64 CROSS_COMPILE=aarch64-linux-gnu- PLAT=fake BL33=$UEFIF all fip $ATF_PARA
	cd -
}

function build_bootrom() {
	dd if=arm-trusted-firmware/build/fake/$EDK2_PATH/bl1.bin of=boot.rom bs=4096 conv=notrunc
	dd if=arm-trusted-firmware/build/fake/$EDK2_PATH/fip.bin of=boot.rom seek=64 bs=4096 conv=notrunc
}

function build_norflash() {
	if [ ! -f pflash.raw ]; then
		echo "create pflash file"
		dd if=/dev/zero of=./pflash.raw bs=1M count=16
	fi
}

function build_dtb() {
	rm -rf $MISC_PATH/baize.dtb
	dtc -I dts -O dtb -o $MISC_PATH/baize.dtb $MISC_PATH/baize.dts
	rm -rf $MISC_PATH/xen.dtb
	dtc -I dts -O dtb -o $MISC_PATH/xen.dtb $MISC_PATH/xen.dts
}

function build_xen() {
	if [ ! -f xen-4.17/xen/.config ]; then
		cd xen-4.17/xen
		make XEN_TARGET_ARCH=arm64 distclean
		make XEN_TARGET_ARCH=arm64 fake_defconfig
		cd ..
		./configure XEN_TARGET_ARCH=arm64
		cd ..
	fi
	cd xen-4.17
	make dist-xen XEN_TARGET_ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- debug=y -j4
	cd -
}

BAREMETAL_FS=baremetal.rootfs
DOM0_FS=dom0.rootfs
DOMU_FS=domu.rootfs

function update_rootfs_for_baremetal() {
	loopdev=$(losetup -f)
	echo $loopdev
	cd $MISC_PATH
	sudo losetup $loopdev ../$BAREMETAL_FS
	sudo partprobe $loopdev
	ls /dev/loop*
	# partition 1
	if [ ! -d p1 ]; then
		mkdir p1
	fi
	sudo mount $loopdev"p1" p1
	sudo cp *.dtb p1
	sudo cp startup.nsh p1
	sudo cp ../linux-4.14/build/arch/arm64/boot/Image p1
	ls p1
	sudo umount p1
	# partition 2
	if [ ! -d p2 ]; then
		mkdir p2
	fi
	sudo mount $loopdev"p2" p2
	sudo rm -rf p2/*
	sudo tar xf ../rootfs-hub/baremetal.tar.gz -C p2/
	ls p2
	sudo umount p2

	sudo losetup -d $loopdev
	cd -
}

function update_rootfs_for_dom0() {
	loopdev=$(losetup -f)
	echo $loopdev
	pushd .
	cd $MISC_PATH
	sudo losetup $loopdev ../$DOM0_FS
	sudo partprobe $loopdev
	ls /dev/loop*
	# partition 1
	if [ ! -d p1 ]; then
		mkdir p1
	fi
	sudo mount $loopdev"p1" p1
	sudo cp *.dtb p1
	sudo cp ../xen-4.17/dist/install/boot/xen p1
	sudo cp xen.cfg p1
	sudo cp startup-xen.nsh p1/startup.nsh
	sudo cp ../linux-4.14/build/arch/arm64/boot/Image p1
	ls p1
	sudo umount p1
	# partition 2
	rm -f rootfs.cpio
	gunzip -c ../rootfs-hub/fake-dom0-fake-arm64.cpio.gz > rootfs.cpio
	if [ ! -d p2 ]; then
		mkdir p2
	fi
	sudo mount $loopdev"p2" p2
	sudo rm -rf p2/*
	cd p2
	sudo cpio -idm < ../rootfs.cpio
	rm -f ../rootfs.cpio
	cd ..
	sudo mkdir p2/home/root/domu
	sudo cp start-domu.sh p2/home/root/
	ls p2
	# install modules
	sudo umount p2

	sudo losetup -d $loopdev
	popd
}

function prepare_images() {
	if [ ! -f $BAREMETAL_FS ]; then
		dd if=/dev/zero of=$BAREMETAL_FS bs=1M count=300
		sgdisk -n 1:2048:204800 $BAREMETAL_FS
		sgdisk -n 2:206848:614366 $BAREMETAL_FS
		loopdev=$(losetup -f)
		echo $loopdev
		sudo losetup $loopdev $BAREMETAL_FS
		sudo partprobe $loopdev
		sudo mkfs.fat $loopdev"p1"
		sudo mkfs.ext4 $loopdev"p2"
		sudo losetup -d $loopdev
	fi
	sgdisk -p $BAREMETAL_FS

	if [ ! -f $DOM0_FS ]; then
		dd if=/dev/zero of=$DOM0_FS bs=1M count=512
		sgdisk -n 1:2048:264191 $DOM0_FS
		sgdisk -n 2:264192:1048542 $DOM0_FS
		loopdev=$(losetup -f)
		echo $loopdev
		sudo losetup $loopdev $DOM0_FS
		sudo partprobe $loopdev
		sudo mkfs.fat $loopdev"p1"
		sudo mkfs.ext4 $loopdev"p2"
		sudo losetup -d $loopdev
	fi
	sgdisk -p $DOM0_FS

	if [ ! -f $DOMU_FS ]; then
		dd if=/dev/zero of=$DOMU_FS bs=1M count=1024
		sgdisk -n 1:2048:264191 $DOMU_FS
		sgdisk -n 2:264192:2097118 $DOMU_FS
		loopdev=$(losetup -f)
		echo $loopdev
		sudo losetup $loopdev $DOMU_FS
		sudo partprobe $loopdev
		sudo mkfs.fat $loopdev"p1"
		sudo mkfs.ext4 $loopdev"p2"
		sudo losetup -d $loopdev
	fi
	sgdisk -p $DOMU_FS
}

function build_kernel() {
	if [ ! -d linux-4.14/build ]; then
		mkdir linux-4.14/build
		cd linux-4.14
		make ARCH=arm64 fake_defconfig O=build
		cd -
	fi
	cd linux-4.14
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=build -j 2
	cd -
}

function update_rootfs_for_domu() {
	loopdev=$(losetup -f)
	echo $loopdev
	pushd .
	cd $MISC_PATH
	sudo losetup $loopdev ../$DOMU_FS
	sudo partprobe $loopdev
	ls /dev/loop*
	# partition 1
	if [ ! -d p1 ]; then
		mkdir p1
	fi
	sudo mount $loopdev"p1" p1
	sudo cp *.dtb p1
	sudo cp ../domu-kernel/build/arch/arm64/boot/Image p1
	sudo cp domu.cfg p1
	ls p1
	sudo umount p1
	# partition 2
	rm -f rootfs.cpio
	gunzip -c ../rootfs-hub/fake-dom0-fake-arm64.cpio.gz > rootfs.cpio
	if [ ! -d p2 ]; then
		mkdir p2
	fi
	sudo mount $loopdev"p2" p2
	sudo rm -rf p2/*
	cd p2
	sudo cpio -idm < ../rootfs.cpio
	rm -f ../rootfs.cpio
	cd ..
	ls p2
	sudo umount p2

	sudo losetup -d $loopdev
	popd
}

function build_domu_kernel() {
	if [ ! -d domu-kernel/build ]; then
		mkdir domu-kernel/build
		cd domu-kernel
		make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- domu_defconfig O=build
		cd -
	fi
	cd domu-kernel
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=build Image modules -j 4
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=build modules_install INSTALL_MOD_PATH=.
	cd -
}

function main() {
	echo "start building..."
	build_board
	build_uefi
	build_atf
	build_bootrom
	build_norflash
	build_dtb
	build_xen
	build_kernel
	prepare_images
	update_rootfs_for_baremetal
	update_rootfs_for_dom0

	build_domu_kernel
	update_rootfs_for_domu
}

main "$@"


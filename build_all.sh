#!/bin/bash

set -e

RUN_ANDROID=0

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
	build -a AARCH64 -t GCC5 -b DEBUG -p FakePkg/Fake.dsc #-v
	cd -
}

function build_teeos() {
	cd optee_os
	make CFG_ARM64_core=y CFG_TEE_BENCHMARK=n CFG_TEE_CORE_LOG_LEVEL=3 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_core=aarch64-linux-gnu- CROSS_COMPILE_ta_arm32=arm-linux-gnueabihf- CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- DEBUG=1 O=out/arm PLATFORM=fake
	cd -
}

function build_atf() {
	if [ $SOC_DEBUG -eq 1 ]; then
		ATF_PARA="DEBUG=1 -d"
	else
		ATF_PARA=
	fi
	UEFIF=../edk2/Build/Fake-AARCH64/DEBUG_GCC5/FV/FAKE_EFI.fd
	TEEP=../optee_os/out/arm/core

	cd arm-trusted-firmware/
	make O=build ARCH=aarch64 CROSS_COMPILE=aarch64-linux-gnu- PLAT=fake BL32=$TEEP/tee-header_v2.bin BL32_EXTRA1=$TEEP/tee-pager_v2.bin BL32_EXTR2=$TEEP/tee-pageable_v2.bin BL32_RAM_LOCATION=tdram SPD=opteed BL33=$UEFIF all fip $ATF_PARA
#MBEDTLS_DIR=<path-to-mbedtls-repo> TRUSTED_BOARD_BOOT=1 GENERATE_COT=1 DECRYPTION_SUPPORT=aes_gcm FW_ENC_STATUS=0 ENCRYPT_BL31=1 ENCRYPT_BL32=1
	cd -
}

function build_bootrom() {
	arm-trusted-firmware/tools/fiptool/fiptool info arm-trusted-firmware/build/fake/$EDK2_PATH/fip.bin
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
DOMU_AND_FS=android.rootfs

function update_rootfs_for_baremetal() {
	loopdev=$(sudo losetup -f)
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
	sudo cp ../rtos/threadx/build/ports/cortex_a53/gnu/threadxen p1
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
	sudo cp start-*.sh p2/home/root/
	ls p2
	# install modules
	# install trusted app
	if [ -d ../app/trusted/optee_client/build ]; then
		# systemctl status tee-supplicant@teepriv0
		sudo cp ../app/trusted/optee_client/build/install/sbin/* p2/usr/sbin/
	fi
	sudo mkdir p2/lib/optee_armtz
	if [ -d ../app/trusted/optee_examples/out ]; then
		sudo cp ../app/trusted/optee_examples/out/ta/8aaaf200-2450-11e4-abe2-0002a5d5c51b.ta p2/lib/optee_armtz/
		sudo cp ../app/trusted/optee_examples/out/ca/optee_example_hello_world p2/home/root/
	fi
	sudo umount p2

	sudo losetup -d $loopdev
	popd
}

function prepare_images() {
	if [ ! -f $BAREMETAL_FS ]; then
		dd if=/dev/zero of=$BAREMETAL_FS bs=1M count=300
		sgdisk -n 1:2048:204800 $BAREMETAL_FS
		sgdisk -n 2:206848:614366 $BAREMETAL_FS
		loopdev=$(sudo losetup -f)
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
		loopdev=$(sudo losetup -f)
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
		loopdev=$(sudo losetup -f)
		echo $loopdev
		sudo losetup $loopdev $DOMU_FS
		sudo partprobe $loopdev
		sudo mkfs.fat $loopdev"p1"
		sudo mkfs.ext4 $loopdev"p2"
		sudo losetup -d $loopdev
	fi
	sgdisk -p $DOMU_FS

	if [ $RUN_ANDROID -eq 1 ]; then
		if [ ! -f $DOMU_AND_FS ]; then
			dd if=/dev/zero of=$DOMU_AND_FS bs=1M count=10240
			sgdisk -n 1:2048:264191 $DOMU_AND_FS
			sgdisk -n 2:264192:20971486 $DOMU_AND_FS
			loopdev=$(sudo losetup -f)
			echo $loopdev
			sudo losetup $loopdev $DOMU_AND_FS
			sudo partprobe $loopdev
			sudo mkfs.fat $loopdev"p1"
			sudo mkfs.ext4 $loopdev"p2"
			sudo losetup -d $loopdev
		fi
		sgdisk -p $DOMU_AND_FS
	fi
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
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=build modules_install INSTALL_MOD_PATH=.
	cd -
}

function update_rootfs_for_domu() {
	loopdev=$(sudo losetup -f)
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
	sudo cp ../domu-kernel/build/arch/arm64/boot/dts/fake/fake-domu.dtb p1
	sudo cp domu.cfg p1
	ls p1
	sudo umount p1
	# partition 2
	rm -f rootfs.cpio
	gunzip -c ../rootfs-hub/baize-domu-fake-arm64.cpio.gz > rootfs.cpio
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
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=build dtbs fake/fake-domu.dtb
	cd -
}

EMMC_DEV=emmc.img
function prepare_misc() {
	if [ ! -f $EMMC_DEV ]; then
		dd if=/dev/zero of=$EMMC_DEV bs=1M count=64
		sudo mkfs.ext4 $EMMC_DEV
	fi
	sgdisk -p $EMMC_DEV
}

arch=$(uname -m)

function build_domu_rtos() {
	cd rtos/dtc
	make CC=aarch64-linux-gnu-gcc AR=aarch64-linux-gnu-ar libfdt V=1
	cd -

	cd rtos/libc
	cmake -Bbuild
	cmake --build ./build
	cd -

	cd rtos/app/rust
	#cargo clean
	cargo build --release --features "aes" --verbose
	cargo tree
	if [ "$arch" == "x86_64" ]; then
		cargo test --target x86_64-unknown-linux-gnu -- --nocapture
	elif [ "$arch" == "aarch64" ]; then
		echo "abandon rust!!!"
		#cargo test --target aarch64-unknown-linux-gnu -- --nocapture
	fi
	cd -

	cd rtos/threadx
	rm -rf build
	cmake -Bbuild -GNinja -DCMAKE_TOOLCHAIN_FILE=cmake/cortex_a53.cmake
	cmake --build ./build
	cd -
}

function build_application() {
	cd ./app/trusted
	./build.sh
	cd -
}

function update_rootfs_for_android() {
	if [ ! -d android ]; then
		mkdir android
		cp ~/android-14/out/target/product/generic_arm64/*.img android
		cp ~/kernel_aosp/arch/arm64/boot/Image android
	fi

	pushd .
	cd $MISC_PATH
	sudo losetup $loopdev ../$DOMU_AND_FS
	sudo partprobe $loopdev
	ls /dev/loop*
	# partition 1
	if [ ! -d p1 ]; then
		mkdir p1
	fi
	sudo mount $loopdev"p1" p1
	sudo cp android.cfg p1
	sudo cp ../android/Image p1
	ls p1
	sudo umount p1
	if [ ! -d p2 ]; then
		mkdir p2
	fi
	sudo mount $loopdev"p2" p2
	sudo rm -rf p2/*
	sudo cp ../android/*.img p2
	ls p2

	sudo losetup -d $loopdev
	popd
}

function main() {
	echo "start building..."
	build_board
	build_uefi
	build_teeos
	build_atf
	build_bootrom
	build_norflash
	build_dtb
	build_xen
	build_kernel
	prepare_images
	update_rootfs_for_baremetal

	build_domu_kernel
	build_domu_rtos

	build_application

	update_rootfs_for_dom0
	update_rootfs_for_domu
	if [ $RUN_ANDROID -eq 1 ]; then
		update_rootfs_for_android
	fi

	prepare_misc
}

function clear_artifact() {
	rm -rf qemu/build
	rm -rf edk2/Build
	make -C edk2/BaseTools clean
	rm -rf edk2/Conf/BuildEnv.sh
	rm -rf edk2/Conf/build_rule.txt
	rm -rf edk2/Conf/target.txt
	rm -rf edk2/Conf/tools_def.txt
	rm -rf optee_os/out
	rm -rf arm-trusted-firmware/build
	rm -rf xen-4.17/dist
	rm -rf linux-4.14/build
	rm -rf domu-kernel/build

	rm -rf rtos/libc/build
	rm -rf rtos/app/rust/target
	rm -rf rtos/threadx/build
}

if [ $# -eq 0 ]; then
	main "@0"
elif [ "c" == $1 ]; then
	echo "clear artifact......"
	clear_artifact
else
	echo "input error!"
fi


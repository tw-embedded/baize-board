
set -e

SOC_DEBUG=1

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
	rm -rf baize.dtb
	dtc -I dts -O dtb -o baize.dtb baize.dts
}

function build_xen() {
	cd xen
	if [ ! -f xen/.config ]; then
		cd xen
		make XEN_TARGET_ARCH=arm64 distclean
		make XEN_TARGET_ARCH=arm64 fake_defconfig
		cd -
		./configure XEN_TARGET_ARCH=arm64
	fi
	make xen XEN_TARGET_ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- debug=y -j4
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
}

main "$@"


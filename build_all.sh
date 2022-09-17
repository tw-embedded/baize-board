SOC_DEBUG=1

if [ $SOC_DEBUG -eq 1 ]
then
	ATF_PARA="DEBUG=1 -d"
	EDK2_PATH=debug
else
	ATF_PARA=
	EDK2_PATH=release
fi

# build qemu
if [ ! -d qemu/build ]
then
	mkdir qemu/build
	cd qemu/build
	../configure --target-list=aarch64-softmmu
fi
cd qemu/build
make
cd -

# build uefi
cd edk2
git submodule update --init
make -C BaseTools
source edksetup.sh
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
build -a AARCH64 -t GCC5 -b DEBUG -p FakePkg/Fake.dsc
cd -

#UEFIF=../edk2/Build/ArmVirtQemuKernel-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd
UEFIF=../edk2/Build/Fake-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd

# build atf
cd arm-trusted-firmware/
make O=build ARCH=aarch64 CROSS_COMPILE=aarch64-linux-gnu- PLAT=fake BL33=$UEFIF all fip $ATF_PARA
cd -

# generate image
dd if=arm-trusted-firmware/build/fake/$EDK2_PATH/bl1.bin of=norflash.bin bs=4096 conv=notrunc
dd if=arm-trusted-firmware/build/fake/$EDK2_PATH/fip.bin of=norflash.bin seek=64 bs=4096 conv=notrunc


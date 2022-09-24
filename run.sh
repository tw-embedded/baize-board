#gdb --args \
./qemu/build/qemu-system-aarch64 -machine baize -nographic \
	-bios ./norflash.bin \
	-S -s


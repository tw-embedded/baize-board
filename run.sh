#gdb --args \
./qemu/build/qemu-system-aarch64 -machine baize -smp 2 -nographic -m 1024M \
	-bios ./norflash.bin \
	-S -s


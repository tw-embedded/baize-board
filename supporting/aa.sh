#!/bin/sh

# grep -E "^CONFIG_SECURITY_APPARMOR|^CONFIG_DEFAULT_SECURITY|^CONFIG_AUDIT=" ~/baize-board/linux-4.14/build/.config
# zcat /proc/config.gz | grep -E "CONFIG_SECURITY_APPARMOR|CONFIG_DEFAULT_SECURITY|CONFIG_AUDIT|CONFIG_DEVTMPFS|CONFIG_EXT4_FS|CONFIG_VIRTIO_BLK"

# cat /sys/module/apparmor/parameters/enabled or aa-status
# mount | grep securityfs || mount -t securityfs securityfs /sys/kernel/security

# cat /etc/apparmor/cache/home.root.aa.bin > /sys/kernel/security/apparmor/.load
# cat /sys/kernel/security/apparmor/profiles

echo "=== 1. try ~/aa.log ==="
if echo "hello apparmor" > ~/aa.log 2>&1; then
    echo "write aa.log: succ"
else
    echo "write aa.log: fail"
fi

echo "=== 2. try /etc/shadow ==="
if head -n 1 /etc/shadow >/dev/null 2>&1; then
    echo "read /etc/shadow: succ"
else
    echo "read /etc/shadow: fail"
fi


#!/bin/sh
set -u

SECFS="/sys/kernel/security"
AA_DIR="$SECFS/apparmor"
AA_LOAD="$AA_DIR/.load"
CACHE_DIR="/etc/apparmor/cache"
ENABLED_FILE="/sys/module/apparmor/parameters/enabled"

if [ ! -r "$ENABLED_FILE" ] || [ "$(cat "$ENABLED_FILE" 2>/dev/null)" != "Y" ]; then
    echo "AppArmor is not enabled in kernel, skipping policy cache load."
    exit 0
fi

if ! grep -q " $SECFS securityfs " /proc/mounts 2>/dev/null; then
    mount -t securityfs securityfs "$SECFS" || {
        echo "Failed to mount securityfs at $SECFS" >&2
        exit 1
    }
fi

if [ ! -w "$AA_LOAD" ]; then
    echo "AppArmor .load interface is not writable at $AA_LOAD" >&2
    exit 1
fi

if [ ! -d "$CACHE_DIR" ]; then
    echo "AppArmor cache directory $CACHE_DIR does not exist, nothing to load."
    exit 0
fi

total=0
failed=0

for bin in "$CACHE_DIR"/*.bin; do
    [ -e "$bin" ] || continue
    total=$((total + 1))
    if cat "$bin" > "$AA_LOAD"; then
        echo "Loaded AppArmor policy cache: $bin"
    else
        echo "Failed to load AppArmor policy cache: $bin" >&2
        failed=$((failed + 1))
    fi
done

echo "AppArmor cache load finished: total=$total, failed=$failed"

[ "$failed" -eq 0 ] || exit 1
exit 0


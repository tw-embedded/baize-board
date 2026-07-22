#!/bin/bash
# Extract shader cache from android.rootfs data partition (p3)
# Run once after Android has booted and generated the cache

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
ANDROID_FS="$PROJECT_DIR/android.rootfs"
CACHE_DIR="$PROJECT_DIR/rootfs-hub/android/shader_cache"

if [ ! -f "$ANDROID_FS" ]; then
    echo "ERROR: $ANDROID_FS not found"
    exit 1
fi

rm -rf "$CACHE_DIR"
mkdir -p "$CACHE_DIR"

loopdev=$(sudo losetup -f)
echo "Using loop device: $loopdev"
sudo losetup "$loopdev" "$ANDROID_FS"
sudo partprobe "$loopdev"

MNT=$(mktemp -d)
sudo mount "${loopdev}p3" "$MNT"

echo "Searching for shader cache files..."

# Common shader cache locations in Android
found=0
for path in \
    "$MNT/cache/skia_cacheSFGLPipeline" \
    "$MNT/cache/skia_cacheSFVkPipeline" \
    "$MNT/system/RenderEngine" \
    "$MNT/system_ce/0/cache" \
    "$MNT/user_de/0/com.android.systemui/cache" \
; do
    if [ -e "$path" ]; then
        echo "  Found: $path"
        cp -a "$path" "$CACHE_DIR/"
        found=1
    fi
done

# Also search broadly for skia/shader cache files
find "$MNT" -maxdepth 4 -name "*skia*" -o -name "*shader*" -o -name "*RenderEngine*" 2>/dev/null | while read f; do
    echo "  Found: $f"
    # Preserve relative path
    rel="${f#$MNT/}"
    dir=$(dirname "$rel")
    mkdir -p "$CACHE_DIR/$dir"
    cp -a "$f" "$CACHE_DIR/$dir/"
    found=1
done

sudo umount "$MNT"
rmdir "$MNT"
sudo losetup -d "$loopdev"

if [ -d "$CACHE_DIR" ] && [ "$(ls -A $CACHE_DIR)" ]; then
    echo ""
    echo "Shader cache extracted to: $CACHE_DIR"
    echo "Contents:"
    find "$CACHE_DIR" -type f | sort
else
    echo ""
    echo "WARNING: No shader cache files found. Android may not have completed boot."
    echo "Run Android once, wait for shader compilation to finish, then run this script again."
fi

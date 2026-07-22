#!/bin/bash

IMG=../android.rootfs
OUTDIR=../_cache/log

loopdev=$(sudo losetup --find --show --partscan $IMG)
echo "Loop device: $loopdev"
sleep 1

PART="${loopdev}p3"

echo "=== Dumping logcat files ==="
mkdir -p "$OUTDIR/logd" "$OUTDIR/anr" "$OUTDIR/dropbox"
rm -rf "$OUTDIR"/*/*

sudo debugfs -R "dump misc/logd/logcat.txt $OUTDIR/logd/logcat.txt" "$PART" 2>/dev/null
sudo debugfs -R "dump misc/logd/logcat.txt.1 $OUTDIR/logd/logcat.txt.1" "$PART" 2>/dev/null
sudo debugfs -R "dump misc/logd/logcat.txt.2 $OUTDIR/logd/logcat.txt.2" "$PART" 2>/dev/null
sudo debugfs -R "dump misc/logd/event-log-tags $OUTDIR/logd/event-log-tags" "$PART" 2>/dev/null

echo "=== Dumping anr files ==="
for f in $(sudo debugfs -R "ls -p anr" "$PART" 2>/dev/null | cut -d/ -f6 | grep -v "^$" | grep -v "^\\.$" | grep -v "^\\.\\.$"); do
  sudo debugfs -R "dump anr/$f $OUTDIR/anr/$f" "$PART" 2>/dev/null
done

echo "=== Dumping dropbox files ==="
for f in $(sudo debugfs -R "ls -p system/dropbox" "$PART" 2>/dev/null | cut -d/ -f6 | grep -v "^$" | grep -v "^\\.$" | grep -v "^\\.\\.$"); do
  sudo debugfs -R "dump system/dropbox/$f $OUTDIR/dropbox/$f" "$PART" 2>/dev/null
done

sudo losetup -d "$loopdev"
sudo chown -R izaac:izaac "$OUTDIR"

echo ""
echo "=== Done ==="
echo "logd:"
ls -lh "$OUTDIR/logd/"
echo "anr:"
ls -lh "$OUTDIR/anr/"
echo "dropbox: $(ls "$OUTDIR/dropbox/" | wc -l) files"

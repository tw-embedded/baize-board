#!/bin/sh

set -e

scp -v -i ../../alix.pem ubuntu@3.114.117.173:~/poky-dom0/build/tmp/deploy/images/fake-arm64/fake-dom0-fake-arm64.cpio.gz ../rootfs-hub/


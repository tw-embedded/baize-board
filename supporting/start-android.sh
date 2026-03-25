#!/bin/sh

mkdir and-p1
mkdir and-p4
mount /dev/vdc1 and-p1
mount /dev/vdc4 and-p4
chmod 666 /dev/vdc2 /dev/vdc3
xl create and-p1/android.cfg
xl info
xl vcpu-list
xl list
xl console android


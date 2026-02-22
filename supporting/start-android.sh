#!/bin/sh

mkdir and-p1
mkdir and-p2
mount /dev/vdc1 and-p1
mount /dev/vdc2 and-p2
xl create and-p1/android.cfg
xl info
xl vcpu-list
xl list
#xl console android


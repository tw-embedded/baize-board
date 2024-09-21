#!/bin/sh

mkdir domu
mount /dev/vdb1 domu
xl create domu/domu.cfg
xl list
#xl console alix-domu


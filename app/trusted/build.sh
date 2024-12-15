#!/bin/bash

set -e

if [ ! -f /opt/poky/4.1.2/environment-setup-cortexa57-poky-linux ]; then
	echo "sdk is not installed, exit."
	exit 1
fi

source /opt/poky/4.1.2/environment-setup-cortexa57-poky-linux

echo "sdk_cc: $CC"

WORKSPACE=$(pwd)
TRUSTEDIR=$(dirname "$(realpath "$BASH_SOURCE")")
echo "script path: ${TRUSTEDIR}, ${WORKSPACE}"

if [ ! -d ${TRUSTEDIR}/optee_client/build ]; then
	mkdir ${TRUSTEDIR}/optee_client/build
fi
cd ${TRUSTEDIR}/optee_client/build
TEEC_EXPORT=$(pwd)/install
echo $TEEC_EXPORT
cmake -DCMAKE_INSTALL_PREFIX=$TEEC_EXPORT .. #-DCMAKE_C_COMPILER=$CC
make install
cd -

cd ${TRUSTEDIR}/optee_examples
make clean

CFLAGS=--sysroot=/opt/poky/4.1.2/sysroots/cortexa57-poky-linux
export CFLAGS
export PYTHONPATH=$PYTHONPATH:~/.local/lib/python3.10/site-packages

make \
	--no-builtin-variables \
	HOST_CROSS_COMPILE=aarch64-poky-linux- \
	TA_DEV_KIT_DIR=${WORKSPACE}/optee_os/out/arm/export-ta_arm64 \
	TEEC_EXPORT=${TRUSTEDIR}/optee_client/build/install \
	--debug=v
cd -


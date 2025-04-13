#!/bin/bash

set -e

arch=$(uname -m)

if [ ! -f /opt/poky/4.1.2/environment-setup-cortexa57-poky-linux ]; then
	echo -e "\e[32m sdk is not installed, now install \e[0m"
	if [ "$arch" == "x86_64" ]; then
		../../rootfs-hub/poky-glibc-x86_64-fake-dom0-cortexa57-fake-arm64-toolchain-4.1.2.sh
	elif [ "$arch" == "aarch64" ]; then
		../../rootfs-hub/poky-glibc-aarch64-fake-dom0-cortexa57-fake-arm64-toolchain-4.1.2.sh
	fi

	if [ ! -f /opt/poky/4.1.2/environment-setup-cortexa57-poky-linux ]; then
		echo "installation failed, exit"
		exit 0
	fi
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
# install 3.10 python modules (cryptography) to sdk
#export PYTHONPATH=$PYTHONPATH:/usr/lib/python3/dist-packages
#export PYTHONPATH=$PYTHONPATH:~/.local/lib/python3.10/site-packages
# python3 -m pip show cryptography

make \
	--no-builtin-variables \
	HOST_CROSS_COMPILE=aarch64-poky-linux- \
	TA_DEV_KIT_DIR=${WORKSPACE}/../../optee_os/out/arm/export-ta_arm64 \
	TEEC_EXPORT=${TRUSTEDIR}/optee_client/build/install \
	--debug=v
cd -


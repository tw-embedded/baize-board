=============
baize-board
=============

Baize-board is an emulator board which could run on your computer, so you do not need a real hardware.

Baize-board is based on DIY soc which include ARM64 (A57) processor, UART, RTC, virtio and so on.

The following projects run on baize-board when booting:

*  arm trusted firmware
*  UEFI
*  xen
*  linux (dom0)
*  threadx (dom0-less)
*  teeos
*  android (TODO)

environment
=============

Ubuntu distribution
*  20.04 (x86)
*  24.04 (x86)
*  24.04 (arm64, **4GB RAM**)

Build & Run
=============

After clone this repository, you should:

.. code-block:: shell

  git submodule update --init


The essential and graphical support packages you need for a supported Ubuntu distribution are shown in the following command:

.. code-block:: shell

  sudo apt update
  sudo apt install make ninja-build meson libpixman-1-dev iasl device-tree-compiler yajl-tools pkg-config libglib2.0-dev
  sudo apt install gcc-aarch64-linux-gnu libssl-dev flex bison python3-dev libncurses5-dev parted dosfstools cargo clang
  sudo apt install cmake libxen-dev python3-pyelftools libyajl-dev
  sudo apt install gcc-multilib gdb-multiarch

  rustup install 1.81.0
  rustup default 1.81.0
  rustup target add aarch64-unknown-none
  rustup target add x86_64-unknown-linux-gnu

Build all essential components (except yocto project):

.. code-block:: shell

  ./build_all.sh


Power on the baize-board:

.. code-block:: shell

  ./run.sh

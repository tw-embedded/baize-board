=============
baize-board
=============

Baize-board is an emulator board which could run on your computer, so you do not need a real hardware.
Baize-board is based on DIY soc which include ARM64 (A57) processor, UART, RTC, virtio and so on.
This project supports:
-  `arm trusted firmware`_
-  `UEFI`_
-  `linux`_
-  `xen`_

environment
=============

Ubuntu distribution


Build
=============

After clone this repository, you should:

.. code-block:: shell

  git submodule update --init


The essential and graphical support packages you need for a supported Ubuntu distribution are shown in the following command:

.. code-block:: shell

  sudo apt update
  sudo apt install make ninja-build meson libpixman-1-dev iasl device-tree-compiler yajl-tools pkg-config libglib2.0-dev
  sudo apt install gcc-aarch64-linux-gnu libssl-dev flex bison python3-dev


Build all essential components (except yocto project):

.. code-block:: shell

  ./build_all.sh


Power on the baize-board:

.. code-block:: shell

  ./run.sh

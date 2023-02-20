=============
baize-board
=============

Build
=============

.. code-block:: shell

  git submodule update --init

.. code-block:: shell

  sudo apt update
  sudo apt install make ninja-build meson libpixman-1-dev iasl device-tree-compiler yajl-tools pkg-config libglib2.0-dev
  sudo apt install gcc-aarch64-linux-gnu libssl-dev flex bison python3-dev

.. code-block:: shell

  ./build_all.sh

.. code-block:: shell
  ./run.sh

#!/bin/bash

sudo modprobe uio
sudo insmod ~/maestro-eval/build/dpdk-kmods/linux/igb_uio/igb_uio.ko

sudo dpdk-hugepages.py --node 0 --reserve 42G
sudo dpdk-hugepages.py --node 1 --reserve 42G

sudo -E ~/maestro-eval/util/bind-igb-uio.sh 0000:d8:00.0
sudo -E ~/maestro-eval/util/bind-igb-uio.sh 0000:d8:00.1
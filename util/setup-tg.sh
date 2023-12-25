#!/bin/bash

MAESTRO_EVAL_DIR="~/maestro-eval"

source $MAESTRO_EVAL_DIR/bench/vars.sh

sudo modprobe uio
sudo insmod $MAESTRO_EVAL_DIR/build/dpdk-kmods/linux/igb_uio/igb_uio.ko

sudo dpdk-hugepages.py --node 0 --reserve 42G
sudo dpdk-hugepages.py --node 1 --reserve 42G

sudo -E $MAESTRO_EVAL_DIR/util/bind-igb-uio.sh $DUT_TX_DEV
sudo -E $MAESTRO_EVAL_DIR/util/bind-igb-uio.sh $DUT_RX_DEV
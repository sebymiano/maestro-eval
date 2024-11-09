#!/bin/bash

set -euo pipefail
#set -x

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../bench/functions.sh"
source $FUNCTIONS_FILE

DUT_MLNX_SYNT_DIR="${CURRENT_EXPERIMENT_DIR}"

build_mlnx_original_nfs() {
    local nf_exe=$1

    local nf_src="$nf_exe.c"

    dut_run "mkdir -p $DUT_SYNTHESIZED_DIR"
    dut_run "rm $DUT_SYNTHESIZED_DIR/${nf_exe} 2> /dev/null || true"
    dut_run "cp $DUT_MLNX_SYNT_DIR/$nf_src $DUT_SYNTHESIZED_DIR/${nf_src}"

    dut_run "PKG_CONFIG_PATH=/usr/local/lib/x86_64-linux-gnu/pkgconfig SRC=$nf_src make -f $DUT_DPDK_MAKEFILE" $DUT_SYNTHESIZED_DIR >> $CURRENT_LOG 2>&1
}

build_mlnx_original_nfs "cl-locks"
build_mlnx_original_nfs "fw-locks"
build_mlnx_original_nfs "nat-locks"
build_mlnx_original_nfs "sbridge-locks"
build_mlnx_original_nfs "nop-locks"
build_mlnx_original_nfs "psd-locks"
build_mlnx_original_nfs "pol-locks"

build_mlnx_original_nfs "cl-tm"
build_mlnx_original_nfs "fw-tm"
build_mlnx_original_nfs "nat-tm"
build_mlnx_original_nfs "sbridge-tm"
build_mlnx_original_nfs "nop-tm"
build_mlnx_original_nfs "psd-tm"
build_mlnx_original_nfs "pol-tm"
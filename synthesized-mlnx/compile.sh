#!/bin/bash

set -euo pipefail
#set -x

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../bench/functions.sh"
source $FUNCTIONS_FILE

DUT_MLNX_SYNT_DIR=${DUT_EVAL_DIR}/synthesized-mlnx/nf-no-expire

build_mlnx_original_nfs() {
    local nf_exe=$1

    local nf_src="$nf_exe.c"

    dut_run "mkdir -p $DUT_SYNTHESIZED_DIR"
    dut_run "rm $DUT_SYNTHESIZED_DIR/${nf_exe} 2> /dev/null || true"
    dut_run "cp $DUT_MLNX_SYNT_DIR/$nf_src $DUT_SYNTHESIZED_DIR/${nf_src}"

    dut_run "SRC=$nf_src make -f $DUT_DPDK_MAKEFILE" $DUT_SYNTHESIZED_DIR >> $CURRENT_LOG 2>&1
}

build_mlnx_original_nfs "cl-sn"
build_mlnx_original_nfs "fw-sn"
build_mlnx_original_nfs "nat-sn"
build_mlnx_original_nfs "sbridge-sn"
build_mlnx_original_nfs "nop-sn"
build_mlnx_original_nfs "psd-sn"
build_mlnx_original_nfs "pol-sn"
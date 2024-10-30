#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../bench/functions.sh"
source $FUNCTIONS_FILE

DUT_SCR_PCAPS_DIR=$DUT_EVAL_DIR/scr-nfs/pcaps
TG_SCR_PCAPS_DIR=$TG_EVAL_DIR/scr-nfs/pcaps

PCAP_FOLDER="uniform_64_scr"

TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER}

build_nf_scr() {
	local nf_exe=$1

	local nf_src="$nf_exe.c"

	dut_run "mkdir -p $DUT_SYNTHESIZED_DIR"

	if ! dut_run "stat $nf_exe > /dev/null 2>&1" "$DUT_SYNTHESIZED_DIR"; then
		dut_run "SRC=$nf_src make -f $DUT_DPDK_MAKEFILE" $DUT_SYNTHESIZED_DIR >> $CURRENT_LOG 2>&1
	fi
}

run_balanced_bench_scr() {
	local nf_exe=$1
    local pcap_pattern=$2
	local exp_dir=$3
	local exp_name=$4

	local intermediate_results_file="$exp_dir/.single.csv"
	local tmp_results_file="$exp_dir/.results.csv"
	local results_file="$exp_dir/$exp_name.csv"

	__setup_bench "$nf_exe" "$tmp_results_file"

	local MIN_CORES=1
	local MAX_CORES=$(python3 -c "print(len('$DUT_CORES'.split(',')))")

	for ((n_cores=$MIN_CORES;n_cores<=$MAX_CORES;n_cores++)); do
        local pcap_file="${pcap_pattern}${n_cores}cores.pcap"
        tg_check_file "${TG_PCAPS_DIR}/${pcap_pattern}${n_cores}cores.pcap"
		__run_balanced_bench_with_n_cores "$nf_exe" "$pcap_file" "$n_cores" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
	done

	__finalize_bench "$tmp_results_file" "$results_file"
}

bench_balanced_nf_scr() {
	local nf_exe=$1
	local pcap_pattern=$2
	local exp_dir=$3
	local exp_name=$4

	set_log "$exp_dir"
	build_nf_scr "$nf_exe"
	run_balanced_bench_scr "$nf_exe" "$pcap_pattern" "$exp_dir" "$exp_name"
}

state_compute_replication() {
    bench_balanced_nf_scr "cl-scr" "dpdk_cl_scr_" "$CURRENT_EXPERIMENT_DIR" "cl-scr"
}
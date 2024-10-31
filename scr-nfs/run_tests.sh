#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# set -x
FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../bench/functions.sh"
source $FUNCTIONS_FILE

DUT_SCR_PCAPS_DIR=$DUT_EVAL_DIR/scr-nfs/pcaps
TG_SCR_PCAPS_DIR=$TG_EVAL_DIR/scr-nfs/pcaps

PCAP_FOLDER_CL="cl_uniform_64_scr"
PCAP_FOLDER_FW="fw_uniform_64_scr"
PCAP_FOLDER_NAT="nat_uniform_64_scr"
PCAP_FOLDER_SBRIDGE="sbridge_uniform_64_scr"
PCAP_FOLDER_NOP="nop_uniform_64_scr"
PCAP_FOLDER_PSD="psd_uniform_64_scr"

DUT_SCR_DIR=${DUT_EVAL_DIR}/scr-nfs

build_nf_scr() {
	local nf_exe=$1

	local nf_src="$nf_exe.c"

	dut_run "mkdir -p $DUT_SYNTHESIZED_DIR"
	dut_run "cp $DUT_SCR_DIR/$nf_src $DUT_SYNTHESIZED_DIR/${nf_src}"

	if ! dut_run "stat $nf_exe > /dev/null 2>&1" "$DUT_SYNTHESIZED_DIR"; then
		dut_run "SRC=$nf_src make -f $DUT_DPDK_MAKEFILE" $DUT_SYNTHESIZED_DIR >> $CURRENT_LOG 2>&1
	fi
}

run_balanced_bench_scr() {
	local nf_exe=$1
	local target=$2
    local pcap_pattern=$3
	local exp_dir=$4
	local exp_name=$5

	local intermediate_results_file="$exp_dir/.single.csv"
	local tmp_results_file="$exp_dir/.results.csv"
	local results_file="$exp_dir/$exp_name.csv"

	__setup_bench "$nf_exe" "$tmp_results_file"

	local MIN_CORES=1
	local MAX_CORES=$(python3 -c "print(len('$DUT_CORES'.split(',')))")

	for ((n_cores=$MIN_CORES;n_cores<=$MAX_CORES;n_cores++)); do
        local pcap_file="${pcap_pattern}${n_cores}cores.pcap"

		if [ "$target" == "cl" ]; then
			export TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER_CL}
			export DUT_PCAPS_DIR=${DUT_SCR_PCAPS_DIR}/${PCAP_FOLDER_CL}
		elif [ "$target" == "sbridge" ]; then
			export TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER_SBRIDGE}
			export DUT_PCAPS_DIR=${DUT_SCR_PCAPS_DIR}/${PCAP_FOLDER_SBRIDGE}
		elif [ "$target" == "fw" ]; then
			export TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER_FW}
			export DUT_PCAPS_DIR=${DUT_SCR_PCAPS_DIR}/${PCAP_FOLDER_FW}
		elif [ "$target" == "nat" ]; then
			export TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER_NAT}
			export DUT_PCAPS_DIR=${DUT_SCR_PCAPS_DIR}/${PCAP_FOLDER_NAT}
		elif [ "$target" == "nop" ]; then
			export TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER_NOP}
			export DUT_PCAPS_DIR=${DUT_SCR_PCAPS_DIR}/${PCAP_FOLDER_NOP}
		elif [ "$target" == "psd" ]; then
			export TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER_PSD}
			export DUT_PCAPS_DIR=${DUT_SCR_PCAPS_DIR}/${PCAP_FOLDER_PSD}
		else
			echo "Error: Unknown target '$target'."
			return 1
		fi

        tg_check_file "${TG_PCAPS_DIR}/${pcap_pattern}${n_cores}cores.pcap"
		__run_balanced_bench_with_n_cores "$nf_exe" "$pcap_file" "$n_cores" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
		sleep 10
	done

	__finalize_bench "$tmp_results_file" "$results_file"
}

bench_balanced_nf_scr() {
	local nf_exe=$1
	local target=$2
	local pcap_pattern=$3
	local exp_dir=$4
	local exp_name=$5

	set_log "$exp_dir"
	build_nf_scr "$nf_exe" $target
	run_balanced_bench_scr "$nf_exe" "$target" "$pcap_pattern" "$exp_dir" "$exp_name"
}

state_compute_replication() {
	bench_balanced_nf_scr "sbridge-scr" "sbridge" "dpdk_sbridge_scr_" "$CURRENT_EXPERIMENT_DIR" "sbridge-scr"
    bench_balanced_nf_scr "cl-scr" "cl" "dpdk_cl_scr_" "$CURRENT_EXPERIMENT_DIR" "cl-scr"
	bench_balanced_nf_scr "fw-scr" "fw" "dpdk_fw_scr_" "$CURRENT_EXPERIMENT_DIR" "fw-scr"
	bench_balanced_nf_scr "nat-scr" "nat" "dpdk_nat_scr_" "$CURRENT_EXPERIMENT_DIR" "nat-scr"
	bench_balanced_nf_scr "nop-scr" "nop" "dpdk_nop_scr_" "$CURRENT_EXPERIMENT_DIR" "nop-scr"
	bench_balanced_nf_scr "psd-scr" "psd" "dpdk_psd_scr_" "$CURRENT_EXPERIMENT_DIR" "psd-scr"
}

state_compute_replication
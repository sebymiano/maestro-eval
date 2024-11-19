#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# set -x
FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../bench/functions.sh"
source $FUNCTIONS_FILE

PCAP_FOLDER_CL="cl_uniform_64_scr"
PCAP_FOLDER_FW="fw_uniform_64_scr"
PCAP_FOLDER_NAT="nat_uniform_64_scr"
PCAP_FOLDER_SBRIDGE="sbridge_uniform_64_scr"
PCAP_FOLDER_NOP="nop_uniform_64_scr"
PCAP_FOLDER_PSD="psd_uniform_64_scr"
PCAP_FOLDER_POL="pol_uniform_64_scr"

build_nf_scr() {
	local nf_exe=$1

	local nf_src="$nf_exe.c"

	dut_run "mkdir -p $DUT_SYNTHESIZED_DIR"
	dut_run "rm $DUT_SYNTHESIZED_DIR/${nf_exe} 2> /dev/null || true"
	dut_run "cp $DUT_SCR_DIR/$nf_src $DUT_SYNTHESIZED_DIR/${nf_src}"

	dut_run "PKG_CONFIG_PATH=/usr/local/lib/x86_64-linux-gnu/pkgconfig CFLAGS=\"-I${CURRENT_EXPERIMENT_DIR}\" SRC=$nf_src make -f $DUT_DPDK_MAKEFILE" $DUT_SYNTHESIZED_DIR >> $CURRENT_LOG 2>&1
}

run_balanced_bench_scr() {
	local nf_exe=$1
	local target=$2
    local pcap_pattern=$3
	local exp_dir=$4
	local exp_name=$5
	local scr_gen=$6

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
		elif [ "$target" == "pol" ]; then
			export TG_PCAPS_DIR=${TG_SCR_PCAPS_DIR}/${PCAP_FOLDER_POL}
			export DUT_PCAPS_DIR=${DUT_SCR_PCAPS_DIR}/${PCAP_FOLDER_POL}
		else
			echo "Error: Unknown target '$target'."
			return 1
		fi
		
        tg_check_file "${TG_PCAPS_DIR}/${pcap_pattern}${n_cores}cores.pcap"
		if [ "$scr_gen" == "true" ]; then
			export ADDITIONAL_REPLAY_PCAP_FLAGS="--scr --num-rx-queues $n_cores"
		fi
		__run_balanced_bench_with_n_cores "$nf_exe" "$pcap_file" "$n_cores" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
		export ADDITIONAL_REPLAY_PCAP_FLAGS=""
	done

	__finalize_bench "$tmp_results_file" "$results_file"
}

bench_balanced_nf_scr() {
	local nf_exe=$1
	local target=$2
	local pcap_pattern=$3
	local exp_dir=$4
	local exp_name=$5
	local scr_gen=$6

	set_log "$exp_dir"
	build_nf_scr "$nf_exe" $target
	run_balanced_bench_scr "$nf_exe" "$target" "$pcap_pattern" "$exp_dir" "$exp_name" $scr_gen
}

state_compute_replication() {
	local scr_gen=$1
	if [ "$scr_gen" == "true" ]; then
		echo "Running with SCR"
	else
		echo "Running without SCR"
		scr_gen="false"
	fi

	bench_balanced_nf_scr "sbridge-scr" "sbridge" "dpdk_sbridge_scr_" "$CURRENT_EXPERIMENT_DIR" "sbridge-scr-uniform-64" $scr_gen
    bench_balanced_nf_scr "cl-scr" "cl" "dpdk_cl_scr_" "$CURRENT_EXPERIMENT_DIR" "cl-scr-uniform-64" $scr_gen
	bench_balanced_nf_scr "fw-scr" "fw" "dpdk_fw_scr_" "$CURRENT_EXPERIMENT_DIR" "fw-scr-uniform-64" $scr_gen
	bench_balanced_nf_scr "nat-scr" "nat" "dpdk_nat_scr_" "$CURRENT_EXPERIMENT_DIR" "nat-scr-uniform-64" $scr_gen
	bench_balanced_nf_scr "nop-scr" "nop" "dpdk_nop_scr_" "$CURRENT_EXPERIMENT_DIR" "nop-scr-uniform-64" $scr_gen
	# bench_balanced_nf_scr "psd-scr" "psd" "dpdk_psd_scr_" "$CURRENT_EXPERIMENT_DIR" "psd-scr-uniform-64" $scr_gen
	bench_balanced_nf_scr "pol-scr" "pol" "dpdk_pol_scr_" "$CURRENT_EXPERIMENT_DIR" "pol-scr-uniform-64" $scr_gen
}

if [ $# -eq 1 ] && [ $1 == "--no-scr" ]; then
	state_compute_replication false
else
	state_compute_replication true
fi
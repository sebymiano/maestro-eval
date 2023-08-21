#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

source $SCRIPT_DIR/vars.sh

DUT_MAESTRO_DIR=$DUT_EVAL_DIR/build/maestro
DUT_NFS_DIR=$DUT_MAESTRO_DIR/dpdk-nfs
DUT_SYNTHESIZED_DIR=$DUT_EVAL_DIR/build/synthesized
DUT_PCAPS_DIR=$DUT_EVAL_DIR/pcaps

TG_EVAL_BENCH_DIR=$TG_EVAL_DIR/bench
TG_PKTGEN_DIR=$TG_EVAL_DIR/build/DPDK-Pktgen
TG_PCAPS_DIR=$TG_EVAL_DIR/pcaps

DUT_MAESTRO_PATHS_FILE=$DUT_MAESTRO_DIR/paths.sh
DUT_MAESTRO_SCRIPT=$DUT_MAESTRO_DIR/maestro/maestro.py
DUT_DPDK_MAKEFILE=$DUT_MAESTRO_DIR/util/Makefile.dpdk

TG_REPLAY_PCAP_SCRIPT=$TG_EVAL_DIR/util/replay-pcap.py
TG_ACTIVATE_PYTHON_ENV_SCRIPT=$TG_EVAL_DIR/build/env/bin/activate

BASE_LOG=experiment.log

CURRENT_RUNNING_NF=""
CURRENT_LOG=$BASE_LOG

ADDITIONAL_REPLAY_PCAP_FLAGS=""

set_log() {
	local exp_dir=$1
	CURRENT_LOG="$exp_dir/$BASE_LOG"
}

log() {
	local msg=$1
	echo "$msg" >> $CURRENT_LOG
}

ssh_run() {
	local host=$1
	local cmd=$2

	log "[$host] $cmd"
	ssh -q -t $host "$cmd"
}

ssh_run_background() {
	local host=$1
	local cmd=$2

	log "[$host] $cmd"
	ssh -q $host "$cmd >/dev/null 2>&1 &"
}

is_prog_running() {
	local host=$1
	local prog=$2
	ssh_run "$host" "pgrep -f -x .*$prog.*" >/dev/null
}

download() {
	local host=$1
	local remote_file=$2
	local local_file=$3
	scp -q "$host:$remote_results_file" "$local_results_file"
}

dut_run() {
	local cmd=$1
	local cwd="${2:-}"

	cmd="source $DUT_MAESTRO_PATHS_FILE; $cmd"

	if [[ ! -z "$cwd" ]]; then
		cmd="cd $cwd; $cmd"
	else
		cmd="cd $DUT_EVAL_DIR; $cmd"
	fi

	ssh_run $DUT "$cmd"
}

dut_run_background() {
	local cmd=$1
	local cwd="${2:-}"

	cmd="source $DUT_MAESTRO_PATHS_FILE; $cmd"

	if [[ ! -z "$cwd" ]]; then
		cmd="cd $cwd; $cmd"
	else
		cmd="cd $DUT_EVAL_DIR; $cmd"
	fi

	ssh_run_background $DUT "$cmd"
}

tg_run() {
	local cmd=$1
	local cwd="${2:-}"

	cmd="source $TG_ACTIVATE_PYTHON_ENV_SCRIPT; $cmd"

	if [[ ! -z "$cwd" ]]; then
		cmd="cd $cwd; $cmd"
	else
		cmd="cd $TG_EVAL_DIR; $cmd"
	fi

	ssh_run $TG "$cmd"
}

dut_check_file() {
	file=$1

	if ! dut_run "stat $file >/dev/null 2>&1"; then
		echo "ERROR: $pcap not found in DUT. Exiting."
		exit 1
	fi
}

tg_check_file() {
	file=$1

	if ! dut_run "stat $file >/dev/null 2>&1"; then
		echo "ERROR: $pcap not found in TG. Exiting."
		exit 1
	fi
}

build_nf() {
	# Arguments:
	#   1. nf_exe: Executable name of the generated parallel implementation
	#   2. nf_path: Path to the NF source code inside the Maestro dpdk-nfs directory
	#   3. target: one in { sn, locks, tm }

	local nf_exe=$1
	local nf=$2
	local target=$3
	local exp_name=$4

	local nf_src="$nf_exe.c"
	local nf_path="$DUT_NFS_DIR/$nf"

	dut_run "mkdir -p $DUT_SYNTHESIZED_DIR"

	if ! dut_run "stat $nf_exe > /dev/null 2>&1" "$DUT_SYNTHESIZED_DIR"; then
		echo "[$exp_name] Building NF..."
		gen_nf_cmd="$DUT_MAESTRO_SCRIPT $nf_path --target $target --out $nf_src"

		dut_run "$gen_nf_cmd" $DUT_SYNTHESIZED_DIR >> $CURRENT_LOG 2>&1
		dut_run "SRC=$nf_src make -f $DUT_DPDK_MAKEFILE" $DUT_SYNTHESIZED_DIR >> $CURRENT_LOG 2>&1
	fi
}

run_nf() {
	local nf_exe=$1
	local lcores=$2
	local pcap="${3:-}"

	if [[ ! -z "$pcap" ]]; then
		dut_run_background "sudo ./$nf_exe --lcores $lcores -- $DUT_PCAPS_DIR/$pcap" "$DUT_SYNTHESIZED_DIR"
	else
		dut_run_background "sudo ./$nf_exe --lcores $lcores" "$DUT_SYNTHESIZED_DIR"
	fi
}

kill_nf() {
	local nf_exe=$1
	dut_run "sudo killall -SIGKILL $nf_exe >/dev/null 2>&1 || true"
}

wait_for_nf() {
	local nf_exe=$1

	local max_tries=10
	for (( t=0; t<$max_tries; t++ )); do
		if is_prog_running "$DUT" "$nf_exe"; then
			# Give time to balance LUTs (if needed)
			sleep 3
			return 0
		fi

		sleep 0.5
	done
	
	echo "Max tries exceeded, NF is not running :("
	exit 1
}

replay_pcap() {
	local pcap=$1
	local local_results_file=$2

	if ! tg_run "stat $pcap >/dev/null 2>&1" "$TG_PCAPS_DIR"; then
		echo "ERROR: $TG_PCAPS_DIR/$pcap not found in TG. Exiting."
		exit 1
	fi

	local cmd="$TG_REPLAY_PCAP_SCRIPT"
	cmd="$cmd $TG_TX_DEV $TG_RX_DEV $TG_PCAPS_DIR/$pcap"
	cmd="$cmd --tx-cores $TG_TX_CORES"
	cmd="$cmd --rx-cores $TG_RX_CORES"
	cmd="$cmd --duration $ITERATION_DURATION_SEC"
	cmd="$cmd --find-stable-throughput"
	cmd="$cmd $ADDITIONAL_REPLAY_PCAP_FLAGS"

	tg_run "$cmd" "$TG_EVAL_BENCH_DIR" >> $CURRENT_LOG

	local remote_results_file="$TG_EVAL_BENCH_DIR/results.csv"
	
	download "$TG" "$remote_results_file" "$local_results_file"
	tg_run "rm $remote_results_file"
}

replay_pcap_latency() {
	local pcap=$1
	local local_results_file=$2

	local rate=0.1 # Gbps

	if ! tg_run "stat $pcap >/dev/null 2>&1" "$TG_PCAPS_DIR"; then
		echo "ERROR: $TG_PCAPS_DIR/$pcap not found in TG. Exiting."
		exit 1
	fi

	local cmd="$TG_REPLAY_PCAP_SCRIPT"
	cmd="$cmd $TG_TX_DEV $TG_RX_DEV $TG_PCAPS_DIR/$pcap"
	cmd="$cmd --tx-cores 1"
	cmd="$cmd --rx-cores 1"
	cmd="$cmd --duration $ITERATION_DURATION_SEC"
	cmd="$cmd --latency"
	cmd="$cmd --rate $rate"
	cmd="$cmd $ADDITIONAL_REPLAY_PCAP_FLAGS"

	tg_run "$cmd" "$TG_EVAL_BENCH_DIR" >> $CURRENT_LOG

	local remote_results_file="$TG_EVAL_BENCH_DIR/results.csv"
	
	download "$TG" "$remote_results_file" "$local_results_file"
	tg_run "rm $remote_results_file"
}

__setup_bench() {
	local nf_exe=$1
	local tmp_results_file=$2

	log ""
	log "============================================================"
	log ""

	# Kill NF before exiting
	CURRENT_RUNNING_NF="$nf_exe"
	trap 'kill_nf $CURRENT_RUNNING_NF' EXIT

	touch $tmp_results_file
	echo -e "i,#cores,Gbps,Mpps,loss" > $tmp_results_file
}

__finalize_bench() {
	local tmp_results_file=$1
	local results_file=$2

	mv $tmp_results_file $results_file
}

__run_balanced_bench_with_n_cores_latency() {
	local nf_exe=$1
	local pcap=$2
	local n_cores=$3
	local intermediate_results_file=$4
	local tmp_results_file=$5
	local exp_name=$6

	local lcores=$(python3 -c "print(','.join('$DUT_CORES'.split(',')[:$n_cores]))")

	echo "[$exp_name] Running NF with $n_cores cores ($lcores)"
	run_nf "$nf_exe" "$lcores" "$pcap"

	wait_for_nf "$nf_exe"

	for ((i=1;i<=$ITERATIONS;i++)); do
		echo "[$exp_name]   * Running latency benchmark {$i/$ITERATIONS, pcap=$pcap}"
		log "NF: $nf_exe, cores: $lcores, pcap: $pcap, it: $i/$ITERATIONS"

		replay_pcap_latency "$pcap" "$intermediate_results_file"
		mv $intermediate_results_file $tmp_results_file
	done

	echo "[$exp_name]   * Killing NF"
	kill_nf "$nf_exe"
}

__run_balanced_bench_with_n_cores() {
	local nf_exe=$1
	local pcap=$2
	local n_cores=$3
	local intermediate_results_file=$4
	local tmp_results_file=$5
	local exp_name=$6

	local lcores=$(python3 -c "print(','.join('$DUT_CORES'.split(',')[:$n_cores]))")

	echo "[$exp_name] Running NF with $n_cores cores ($lcores)"
	run_nf "$nf_exe" "$lcores" "$pcap"

	wait_for_nf "$nf_exe"

	for ((i=1;i<=$ITERATIONS;i++)); do
		echo "[$exp_name]   * Running benchmark {$i/$ITERATIONS, pcap=$pcap}"
		log "NF: $nf_exe, cores: $lcores, pcap: $pcap, it: $i/$ITERATIONS"

		replay_pcap "$pcap" "$intermediate_results_file"

		local mpps=$(cat $intermediate_results_file | tail -n 1 | awk -F ',' '{print $1}')
		local gbps=$(cat $intermediate_results_file | tail -n 1 | awk -F ',' '{print $2}')
		local loss=$(cat $intermediate_results_file | tail -n 1 | awk -F ',' '{print $5}')

		echo "[$exp_name]         results: $gbps Gbps $mpps Mpps $loss% loss"
		echo -e "$i,$n_cores,$gbps,$mpps,$loss" >> $tmp_results_file

		rm -f $intermediate_results_file
	done

	echo "[$exp_name]   * Killing NF"
	kill_nf "$nf_exe"
}

__run_bench_with_n_cores() {
	local nf_exe=$1
	local pcap=$2
	local n_cores=$3
	local intermediate_results_file=$4
	local tmp_results_file=$5
	local exp_name=$6

	local lcores=$(python3 -c "print(','.join('$DUT_CORES'.split(',')[:$n_cores]))")

	echo "[$exp_name] Running NF with $n_cores cores ($lcores)"
	run_nf "$nf_exe" "$lcores"

	wait_for_nf "$nf_exe"

	for ((i=1;i<=$ITERATIONS;i++)); do
		echo "[$exp_name]   * Running benchmark {$i/$ITERATIONS, pcap=$pcap}"
		log "NF: $exp_name, cores: $lcores, pcap: $pcap, it: $i/$ITERATIONS"

		replay_pcap "$pcap" "$intermediate_results_file"

		local mpps=$(cat $intermediate_results_file | tail -n 1 | awk -F ',' '{print $1}')
		local gbps=$(cat $intermediate_results_file | tail -n 1 | awk -F ',' '{print $2}')
		local loss=$(cat $intermediate_results_file | tail -n 1 | awk -F ',' '{print $5}')

		echo "[$exp_name]         results: $gbps Gbps $mpps Mpps $loss% loss"
		echo -e "$i,$n_cores,$gbps,$mpps,$loss" >> $tmp_results_file

		rm -f $intermediate_results_file
	done

	echo "[$exp_name]   * Killing NF"
	kill_nf "$nf_exe"
}

run_bench() {
	local nf_exe=$1
	local pcap=$2
	local exp_dir=$3
	local exp_name=$4

	local intermediate_results_file="$exp_dir/.single.csv"
	local tmp_results_file="$exp_dir/.results.csv"
	local results_file="$exp_dir/$exp_name.csv"

	__setup_bench "$nf_exe" "$tmp_results_file"

	local MIN_CORES=1
	local MAX_CORES=$(python3 -c "print(len('$DUT_CORES'.split(',')))")

	for ((n_cores=$MIN_CORES;n_cores<=$MAX_CORES;n_cores++)); do
		__run_bench_with_n_cores "$nf_exe" "$pcap" "$n_cores" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
	done

	# __run_bench_with_n_cores "$nf_exe" "$pcap" "$MIN_CORES" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
	# __run_bench_with_n_cores "$nf_exe" "$pcap" "$MAX_CORES" "$intermediate_results_file" "$tmp_results_file" "$exp_name"

	__finalize_bench "$tmp_results_file" "$results_file"
}

run_balanced_bench() {
	local nf_exe=$1
	local pcap=$2
	local exp_dir=$3
	local exp_name=$4

	local intermediate_results_file="$exp_dir/.single.csv"
	local tmp_results_file="$exp_dir/.results.csv"
	local results_file="$exp_dir/$exp_name.csv"

	__setup_bench "$nf_exe" "$tmp_results_file"

	local MIN_CORES=1
	local MAX_CORES=$(python3 -c "print(len('$DUT_CORES'.split(',')))")

	for ((n_cores=$MIN_CORES;n_cores<=$MAX_CORES;n_cores++)); do
		__run_balanced_bench_with_n_cores "$nf_exe" "$pcap" "$n_cores" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
	done

	# __run_balanced_bench_with_n_cores "$nf_exe" "$pcap" "$MIN_CORES" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
	# __run_balanced_bench_with_n_cores "$nf_exe" "$pcap" "$MAX_CORES" "$intermediate_results_file" "$tmp_results_file" "$exp_name"

	__finalize_bench "$tmp_results_file" "$results_file"
}

bench_nf() {
	local nf_exe=$1
	local nf=$2
	local target=$3
	local pcap=$4
	local exp_dir=$5
	local exp_name=$6

	tg_check_file "$TG_PCAPS_DIR/$pcap"

	set_log "$exp_dir"
	build_nf "$nf_exe" "$nf" "$target" "$exp_name"
	run_bench "$nf_exe" "$pcap" "$exp_dir" "$exp_name"
}

bench_balanced_nf() {
	local nf_exe=$1
	local nf=$2
	local target=$3
	local pcap=$4
	local exp_dir=$5
	local exp_name=$6

	dut_check_file "$DUT_PCAPS_DIR/$pcap"
	tg_check_file "$TG_PCAPS_DIR/$pcap"

	set_log "$exp_dir"
	build_nf "$nf_exe" "$nf" "$target" "$exp_name"
	run_balanced_bench "$nf_exe" "$pcap" "$exp_dir" "$exp_name"
}

bench_balanced_lb() {
	local nf_exe=$1
	local nf=$2
	local target=$3
	local pcap=$4
	local exp_dir=$5
	local exp_name=$6

	ADDITIONAL_REPLAY_PCAP_FLAGS="--lb"

	dut_check_file "$DUT_PCAPS_DIR/$pcap"
	tg_check_file "$TG_PCAPS_DIR/$pcap"

	set_log "$exp_dir"
	build_nf "$nf_exe" "$nf" "$target" "$exp_name"
	run_balanced_bench "$nf_exe" "$pcap" "$exp_dir" "$exp_name"

	ADDITIONAL_REPLAY_PCAP_FLAGS=""
}

bench_balanced_all_cores_nf() {
	local nf_exe=$1
	local nf=$2
	local target=$3
	local pcap=$4
	local exp_dir=$5
	local exp_name=$6

	dut_check_file "$DUT_PCAPS_DIR/$pcap"
	tg_check_file "$TG_PCAPS_DIR/$pcap"

	set_log "$exp_dir"
	build_nf "$nf_exe" "$nf" "$target" "$exp_name"
	
	local intermediate_results_file="$exp_dir/.single.csv"
	local tmp_results_file="$exp_dir/.results.csv"
	local results_file="$exp_dir/$exp_name.csv"

	__setup_bench "$nf_exe" "$tmp_results_file"

	local MAX_CORES=$(python3 -c "print(len('$DUT_CORES'.split(',')))")

	__run_balanced_bench_with_n_cores "$nf_exe" "$pcap" "$MAX_CORES" "$intermediate_results_file" "$tmp_results_file" "$exp_name"
	__finalize_bench "$tmp_results_file" "$results_file"
}

bench_balanced_all_cores_latency() {
	local nf_exe=$1
	local nf=$2
	local target=$3
	local pcap=$4
	local exp_dir=$5
	local exp_name=$6

	dut_check_file "$DUT_PCAPS_DIR/$pcap"
	tg_check_file "$TG_PCAPS_DIR/$pcap"

	set_log "$exp_dir"
	build_nf "$nf_exe" "$nf" "$target" "$exp_name"
	
	local intermediate_results_file="$exp_dir/.single.csv"
	local tmp_results_file="$exp_dir/.results.csv"

	__setup_bench "$nf_exe" "$tmp_results_file"

	local MIN_CORES=1
	local MAX_CORES=$(python3 -c "print(len('$DUT_CORES'.split(',')))")

	local results_file="$exp_dir/$exp_name-$MIN_CORES-cores.csv"
	__run_balanced_bench_with_n_cores_latency "$nf_exe" "$pcap" "$MIN_CORES" "$intermediate_results_file" "$tmp_results_file" "$exp_name-$MIN_CORES"
	__finalize_bench "$tmp_results_file" "$results_file"

	local results_file="$exp_dir/$exp_name-$MAX_CORES-cores.csv"
	__run_balanced_bench_with_n_cores_latency "$nf_exe" "$pcap" "$MAX_CORES" "$intermediate_results_file" "$tmp_results_file" "$exp_name-$MAX_CORES"
	__finalize_bench "$tmp_results_file" "$results_file"
}

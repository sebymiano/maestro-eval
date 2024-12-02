#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
MLNX_SYNTHESIZED_NFS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile.sh"
MLNX_SYNTHESIZED_NFS_OTHERS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile_others.sh"
source $FUNCTIONS_FILE

PCAP="caida_64B.pcap"
RUN_LOCKS=false
RUN_TM=false
RUN_MLNX=false
RUN_RSS=false

shared_nothing() {
    bench_balanced_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-sn-caida-64"
    bench_balanced_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-sn-caida-64"
    bench_balanced_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-sn-caida-64"
    bench_balanced_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-sn-caida-64"
    bench_balanced_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-sn-caida-64"
    bench_balanced_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-sn-caida-64"
    # bench_balanced_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-sn-caida-64"
}

rss() {
    bench_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-rss-caida-64"
    bench_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-rss-caida-64"
    bench_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-rss-caida-64"
    bench_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-rss-caida-64"
    bench_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-rss-caida-64"
    bench_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-rss-caida-64"
    # bench_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-rss-caida-64"
}

locks() {
    bench_balanced_nf "nop-locks" "nop" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-locks-caida-64"
    bench_balanced_nf "pol-locks" "pol" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-locks-caida-64"
    bench_balanced_nf "sbridge-locks" "sbridge" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-locks-caida-64"
    bench_balanced_nf "fw-locks" "fw" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-locks-caida-64"
    bench_balanced_nf "nat-locks" "nat" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-locks-caida-64"
    # bench_balanced_nf "psd-locks" "psd" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-locks-caida-64"
    bench_balanced_nf "cl-locks" "cl" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-locks-caida-64"
}

tm() {
    bench_balanced_nf "nop-tm" "nop" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-tm-caida-64"
    bench_balanced_nf "pol-tm" "pol" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-tm-caida-64"
    bench_balanced_nf "sbridge-tm" "sbridge" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-tm-caida-64"
    bench_balanced_nf "fw-tm" "fw" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-tm-caida-64"
    bench_balanced_nf "nat-tm" "nat" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-tm-caida-64"
    # bench_balanced_nf "psd-tm" "psd" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-tm-caida-64"
    bench_balanced_nf "cl-tm" "cl" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-tm-caida-64"
}

seq() {
    bench_nf "nop-seq" "nop" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-seq-caida-64"
    bench_nf "pol-seq" "pol" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-seq-caida-64"
    bench_nf "sbridge-seq" "sbridge" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-seq-caida-64"
    bench_nf "fw-seq" "fw" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-seq-caida-64"
    bench_nf "nat-seq" "nat" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-seq-caida-64"
    # bench_nf "psd-seq" "psd" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-seq-caida-64"
    bench_nf "cl-seq" "cl" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-seq-caida-64"
}

for arg in "$@"; do
    if [ "$arg" == "--locks" ]; then
        echo "--locks parameter is present"
        RUN_LOCKS=true
        exit 0
    fi
    if [ "$arg" == "--tm" ]; then
        echo "--tm parameter is present"
        RUN_TM=true
        exit 0
    fi
    if [ "$arg" == "--rss" ]; then
        echo "--rss parameter is present"
        RUN_RSS=true
        exit 0
    fi
    if [ "$arg" == "--mlnx" ]; then
        echo "Using Mellanox synthesized NFs"
        RUN_MLNX=true
        exit 0
    fi
done

if [ $RUN_MLNX ]; then
    echo "Using Mellanox synthesized NFs"
    sh -c ${MLNX_SYNTHESIZED_NFS}
    sh -c ${MLNX_SYNTHESIZED_NFS_OTHERS}
fi

shared_nothing

if [ $RUN_RSS ]; then
    rss
fi

if [ $RUN_LOCKS ]; then
    locks
fi

if [ $RUN_TM ]; then
    tm
fi


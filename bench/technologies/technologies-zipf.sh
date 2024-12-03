#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
MLNX_SYNTHESIZED_NFS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile.sh"
MLNX_SYNTHESIZED_NFS_OTHERS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile_others.sh"
source $FUNCTIONS_FILE

PCAP="zipf.pcap"
RUN_LOCKS=false
RUN_TM=false
RUN_MLNX=false
RUN_RSS=false
RUN_SN=false

shared_nothing() {
    bench_balanced_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-sn-zipf-64"
    bench_balanced_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-sn-zipf-64"
    bench_balanced_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-sn-zipf-64"
    bench_balanced_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-sn-zipf-64"
    bench_balanced_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-sn-zipf-64"
    bench_balanced_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-sn-zipf-64"
    # bench_balanced_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-sn-zipf-64"
}

rss() {
    bench_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-rss-zipf-64"
    bench_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-rss-zipf-64"
    bench_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-rss-zipf-64"
    bench_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-rss-zipf-64"
    bench_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-rss-zipf-64"
    bench_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-rss-zipf-64"
    # bench_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-rss-zipf-64"
}

locks() {
    bench_balanced_nf "nop-locks" "nop" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-locks-zipf-64"
    bench_balanced_nf "pol-locks" "pol" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-locks-zipf-64"
    bench_balanced_nf "sbridge-locks" "sbridge" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-locks-zipf-64"
    bench_balanced_nf "fw-locks" "fw" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-locks-zipf-64"
    bench_balanced_nf "nat-locks" "nat" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-locks-zipf-64"
    # bench_balanced_nf "psd-locks" "psd" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-locks-zipf-64"
    bench_balanced_nf "cl-locks" "cl" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-locks-zipf-64"
}

tm() {
    bench_balanced_nf "nop-tm" "nop" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-tm-zipf-64"
    bench_balanced_nf "pol-tm" "pol" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-tm-zipf-64"
    bench_balanced_nf "sbridge-tm" "sbridge" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-tm-zipf-64"
    bench_balanced_nf "fw-tm" "fw" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-tm-zipf-64"
    bench_balanced_nf "nat-tm" "nat" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-tm-zipf-64"
    # bench_balanced_nf "psd-tm" "psd" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-tm-zipf-64"
    bench_balanced_nf "cl-tm" "cl" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-tm-zipf-64"
}

export USE_OLD_DPDK=false

for arg in "$@"; do
    if [ "$arg" == "--locks" ]; then
        echo "Using Locks NFs"
        RUN_LOCKS=true
    fi
    if [ "$arg" == "--tm" ]; then
        echo "Using TM NFs"
        RUN_TM=true
    fi
    if [ "$arg" == "--rss" ]; then
        echo "Using RSS NFs"
        RUN_RSS=true
    fi
    if [ "$arg" == "--mlnx" ]; then
        echo "Using Mellanox synthesized NFs"
        RUN_MLNX=true

    fi
    if [ "$arg" == "--sn" ]; then
        echo "Using Shared Nothing"
        RUN_SN=true
    fi
    if [ "$arg" == "--all" ]; then
        echo "Run all test"
        RUN_LOCKS=true
        RUN_TM=true
        RUN_RSS=true
        RUN_SN=true
    fi
    if [ "$arg" == "--old" ]; then
        export USE_OLD_DPDK=true
    fi
done

if [ "$RUN_MLNX" == true ]; then
    echo "Using Mellanox synthesized NFs"
    sh -c ${MLNX_SYNTHESIZED_NFS}
    sh -c ${MLNX_SYNTHESIZED_NFS_OTHERS}
fi

if [ "$RUN_SN" == true ]; then
    shared_nothing
fi

if [ "$RUN_RSS" == true ]; then
    rss
fi

if [ "$RUN_LOCKS" == true ]; then
    locks
fi

if [ "$RUN_TM" == true ]; then
    tm
fi


#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
MLNX_SYNTHESIZED_NFS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile.sh"
MLNX_SYNTHESIZED_NFS_OTHERS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile_others.sh"
source $FUNCTIONS_FILE

PCAP="zipf.pcap"

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

sh -c ${MLNX_SYNTHESIZED_NFS}
sh -c ${MLNX_SYNTHESIZED_NFS_OTHERS}

shared_nothing
rss
locks
tm

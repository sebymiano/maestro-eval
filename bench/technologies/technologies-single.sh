#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
MLNX_SYNTHESIZED_NFS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile.sh"
MLNX_SYNTHESIZED_NFS_OTHERS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile_others.sh"
source $FUNCTIONS_FILE

PCAP="single_64B.pcap"

shared_nothing() {
    bench_balanced_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-sn-single"
    bench_balanced_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-sn-single"
    bench_balanced_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-sn-single"
    bench_balanced_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-sn-single"
    bench_balanced_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-sn-single"
    bench_balanced_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-sn-single"
    bench_balanced_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-sn-single"
}

rss() {
    bench_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-rss-single"
    bench_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-rss-single"
    bench_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-rss-single"
    bench_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-rss-single"
    bench_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-rss-single"
    bench_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-rss-single"
    bench_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-rss-single"
}

locks() {
    bench_balanced_nf "nop-locks" "nop" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-locks-single"
    bench_balanced_nf "pol-locks" "pol" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-locks-single"
    bench_balanced_nf "sbridge-locks" "sbridge" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-locks-single"
    bench_balanced_nf "fw-locks" "fw" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-locks-single"
    bench_balanced_nf "nat-locks" "nat" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-locks-single"
    bench_balanced_nf "psd-locks" "psd" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-locks-single"
    bench_balanced_nf "cl-locks" "cl" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-locks-single"
}

tm() {
    bench_balanced_nf "nop-tm" "nop" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-tm-single"
    bench_balanced_nf "pol-tm" "pol" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-tm-single"
    bench_balanced_nf "sbridge-tm" "sbridge" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-tm-single"
    bench_balanced_nf "fw-tm" "fw" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-tm-single"
    bench_balanced_nf "nat-tm" "nat" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-tm-single"
    bench_balanced_nf "psd-tm" "psd" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-tm-single"
    bench_balanced_nf "cl-tm" "cl" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-tm-single"
}

seq() {
    bench_nf "nop-seq" "nop" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-seq-single"
    bench_nf "pol-seq" "pol" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-seq-single"
    bench_nf "sbridge-seq" "sbridge" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-seq-single"
    bench_nf "fw-seq" "fw" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-seq-single"
    bench_nf "nat-seq" "nat" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-seq-single"
    bench_nf "psd-seq" "psd" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-seq-single"
    bench_nf "cl-seq" "cl" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-seq-single"
}

sh -c ${MLNX_SYNTHESIZED_NFS}
sh -c ${MLNX_SYNTHESIZED_NFS_OTHERS}

export ADDITIONAL_REPLAY_PCAP_FLAGS="--start-rate 25"
shared_nothing
rss
locks
tm


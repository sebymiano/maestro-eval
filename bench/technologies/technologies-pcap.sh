#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
MLNX_SYNTHESIZED_NFS="$CURRENT_EXPERIMENT_DIR/../../synthesized-mlnx/compile.sh"
source $FUNCTIONS_FILE

PCAP="caida_64B.pcap"

shared_nothing() {
    bench_balanced_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-sn-caida"
    bench_balanced_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-sn-caida"
    bench_balanced_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-sn-caida"
    bench_balanced_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-sn-caida"
    bench_balanced_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-sn-caida"
    bench_balanced_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-sn-caida"
    bench_balanced_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-sn-caida"
}

rss() {
    bench_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-rss-caida"
    bench_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-rss-caida"
    bench_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-rss-caida"
    bench_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-rss-caida"
    bench_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-rss-caida"
    bench_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-rss-caida"
    bench_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-rss-caida"
}

locks() {
    bench_balanced_nf "nop-locks" "nop" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-locks-caida"
    bench_balanced_nf "pol-locks" "pol" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-locks-caida"
    bench_balanced_nf "sbridge-locks" "sbridge" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-locks-caida"
    bench_balanced_nf "fw-locks" "fw" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-locks-caida"
    bench_balanced_nf "nat-locks" "nat" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-locks-caida"
    bench_balanced_nf "psd-locks" "psd" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-locks-caida"
    bench_balanced_nf "cl-locks" "cl" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-locks-caida"
}

tm() {
    bench_balanced_nf "nop-tm" "nop" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-tm-caida"
    bench_balanced_nf "pol-tm" "pol" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-tm-caida"
    bench_balanced_nf "sbridge-tm" "sbridge" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-tm-caida"
    bench_balanced_nf "fw-tm" "fw" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-tm-caida"
    bench_balanced_nf "nat-tm" "nat" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-tm-caida"
    bench_balanced_nf "psd-tm" "psd" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-tm-caida"
    bench_balanced_nf "cl-tm" "cl" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-tm-caida"
}

seq() {
    bench_nf "nop-seq" "nop" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-seq-caida"
    bench_nf "pol-seq" "pol" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-seq-caida"
    bench_nf "sbridge-seq" "sbridge" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-seq-caida"
    bench_nf "fw-seq" "fw" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-seq-caida"
    bench_nf "nat-seq" "nat" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-seq-caida"
    bench_nf "psd-seq" "psd" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-seq-caida"
    bench_nf "cl-seq" "cl" "seq" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-seq-caida"
}

sh -c ${MLNX_SYNTHESIZED_NFS}
# seq
shared_nothing
rss
# locks
# tm


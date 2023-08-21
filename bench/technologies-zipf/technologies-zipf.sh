#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
source $FUNCTIONS_FILE

PCAP="zipf.pcap"

shared_nothing() {
    bench_balanced_nf "nop-sn" "nop" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-sn"
    bench_balanced_nf "pol-sn" "pol" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-sn"
    bench_balanced_nf "sbridge-sn" "sbridge" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-sn"
    bench_balanced_nf "fw-sn" "fw" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-sn"
    bench_balanced_nf "nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-sn"
    bench_balanced_nf "psd-sn" "psd" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-sn"
    bench_balanced_nf "cl-sn" "cl" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-sn"
}

locks() {
    bench_balanced_nf "nop-locks" "nop" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-locks"
    bench_balanced_nf "pol-locks" "pol" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-locks"
    bench_balanced_nf "sbridge-locks" "sbridge" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-locks"
    bench_balanced_nf "bridge-locks" "bridge" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "bridge-locks"
    bench_balanced_nf "fw-locks" "fw" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-locks"
    bench_balanced_nf "nat-locks" "nat" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-locks"
    bench_balanced_lb "lb-locks" "lb" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "lb-locks"
    bench_balanced_nf "psd-locks" "psd" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-locks"
    bench_balanced_nf "cl-locks" "cl" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-locks"
}

tm() {
    bench_balanced_nf "nop-tm" "nop" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nop-tm"
    bench_balanced_nf "pol-tm" "pol" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "pol-tm"
    bench_balanced_nf "sbridge-tm" "sbridge" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "sbridge-tm"
    bench_balanced_nf "bridge-tm" "bridge" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "bridge-tm"
    bench_balanced_nf "fw-tm" "fw" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "fw-tm"
    bench_balanced_nf "nat-tm" "nat" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-tm"
    bench_balanced_lb "lb-tm" "lb" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "lb-tm"
    bench_balanced_nf "psd-tm" "psd" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "psd-tm"
    bench_balanced_nf "cl-tm" "cl" "tm" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "cl-tm"
}

shared_nothing
locks
tm

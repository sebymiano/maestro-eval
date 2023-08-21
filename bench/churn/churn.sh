#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
source $FUNCTIONS_FILE

TARGET="sn"
NF="nop"

bench_balanced_all_cores_nf "$NF-$TARGET" "$NF" "$TARGET" "uniform_64B.pcap" "$CURRENT_EXPERIMENT_DIR" "64B"
bench_balanced_all_cores_nf "$NF-$TARGET" "$NF" "$TARGET" "uniform_128B.pcap" "$CURRENT_EXPERIMENT_DIR" "128B"
bench_balanced_all_cores_nf "$NF-$TARGET" "$NF" "$TARGET" "uniform_256B.pcap" "$CURRENT_EXPERIMENT_DIR" "256B"
bench_balanced_all_cores_nf "$NF-$TARGET" "$NF" "$TARGET" "uniform_512B.pcap" "$CURRENT_EXPERIMENT_DIR" "512B"
bench_balanced_all_cores_nf "$NF-$TARGET" "$NF" "$TARGET" "uniform_1024B.pcap" "$CURRENT_EXPERIMENT_DIR" "1024B"
bench_balanced_all_cores_nf "$NF-$TARGET" "$NF" "$TARGET" "uniform_1500B.pcap" "$CURRENT_EXPERIMENT_DIR" "1500B"
bench_balanced_all_cores_nf "$NF-$TARGET" "$NF" "$TARGET" "uniform_internet.pcap" "$CURRENT_EXPERIMENT_DIR" "internet"

#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
source $FUNCTIONS_FILE

TARGET="sn"
NF="fw"

bench_balanced_all_cores_latency "$NF-$TARGET" "$NF" "sn" "uniform_64B.pcap" "$CURRENT_EXPERIMENT_DIR" "$NF-sn"

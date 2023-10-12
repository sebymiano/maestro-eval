#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
source $FUNCTIONS_FILE

PCAP="uniform_64B.pcap"

bench_balanced_nf "vpp-nat-sn" "nat" "sn" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-maestro-sn"
bench_balanced_nf "vpp-nat-locks" "nat" "locks" "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-maestro-locks"
bench_balanced_vpp "$PCAP" "$CURRENT_EXPERIMENT_DIR" "nat-vpp"

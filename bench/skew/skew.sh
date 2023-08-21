#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
source $FUNCTIONS_FILE

TARGET="sn"
UNIFORM_PCAP="uniform_64B.pcap"
ZIPF_PCAP="zipf.pcap"
SKEW_ITERATIONS=5
NF="fw"

main() {
    for ((skew_it=0;skew_it<$SKEW_ITERATIONS;skew_it++)); do
        #bench_nf "skew-$NF-uniform-$skew_it" "$NF" "$TARGET" "$UNIFORM_PCAP" "$CURRENT_EXPERIMENT_DIR" "skew-$NF-uniform-$skew_it"
        #bench_nf "skew-$NF-zipf-$skew_it" "$NF" "$TARGET" "$ZIPF_PCAP" "$CURRENT_EXPERIMENT_DIR" "skew-$NF-zipf-$skew_it"
        bench_balanced_nf "skew-$NF-zipf-balanced-$skew_it" "$NF" "$TARGET" "$ZIPF_PCAP" "$CURRENT_EXPERIMENT_DIR" "skew-$NF-zipf-balanced-$skew_it"
	done
}

main

#!/bin/bash

set -euo pipefail

CURRENT_EXPERIMENT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

FUNCTIONS_FILE="$CURRENT_EXPERIMENT_DIR/../functions.sh"
source $FUNCTIONS_FILE

NF="fw"
EXPIRATION_TIME_US=1000

declare -a pcaps=(
    churn_15400fpm_64B_100Gbps_1000us.pcap
    churn_23000fpm_64B_100Gbps_1000us.pcap
    churn_31000fpm_64B_100Gbps_1000us.pcap
    churn_250000fpm_64B_100Gbps_1000us.pcap
    churn_885000fpm_64B_100Gbps_1000us.pcap
    churn_1500000fpm_64B_100Gbps_1000us.pcap
    churn_2000000fpm_64B_100Gbps_1000us.pcap
    churn_2600000fpm_64B_100Gbps_1000us.pcap
    churn_25000000fpm_64B_100Gbps_1000us.pcap
    churn_88462000fpm_64B_100Gbps_1000us.pcap
)

run_churn() {
    target=$1

    for pcap in "${pcaps[@]}"; do
        churn=$(echo "$pcap" | grep -oP "\\d+" | head -1)
        bench_nf "$NF-$target-exp-time-$EXPIRATION_TIME_US-us" "$NF" "$target" "$pcap" "$CURRENT_EXPERIMENT_DIR" "churn-$target-$churn-fpm"
    done
}

run_churn "sn"
run_churn "locks"
run_churn "tm"

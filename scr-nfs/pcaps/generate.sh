#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

source $SCRIPT_DIR/../../bench/vars.sh

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

ORIGINAL_PCAP_DIR=$SCRIPT_DIR/../../pcaps/
GEN_PCAP_CL_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_cl.py
GEN_PCAP_FW_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_fw.py
GEN_PCAP_SBRIDGE_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_sbridge.py
GEN_PCAP_NAT_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_nat.py

POETRY_CMD="poetry run python"

gen_uniform_trace() {
    local target=$1
    local pkt_size=$2

    pcap=$ORIGINAL_PCAP_DIR/uniform_${pkt_size}B.pcap

    if [ ! -f "$pcap" ]; then
        echo "Error: pcap file '$pcap' not found."
        return 1
    fi

    num_cores=$(echo "$DUT_CORES" | tr -cd ',' | wc -c)
    num_cores=$((num_cores + 1))
    echo "Number of cores specified: $num_cores"

    # Loop over the total count of cores
    for ((i = 1; i <= num_cores; i++)); do
        echo "Generating pcap for number of cores: $i"

        if [ "$target" == "cl" ]; then
            # Run the pcap generation script for each core index
            $POETRY_CMD $GEN_PCAP_CL_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/${target}_uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
        elif [ "$target" == "sbridge" ]; then
            $POETRY_CMD $GEN_PCAP_SBRIDGE_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/${target}_uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
        elif [ "$target" == "fw" ]; then
            $POETRY_CMD $GEN_PCAP_FW_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/${target}_uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
        elif [ "$target" == "nat" ]; then
            $POETRY_CMD $GEN_PCAP_NAT_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/${target}_uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
        else
            echo "Error: Unknown target '$target'."
            return 1
        fi
    done
}

gen_uniform_traces_cl() {
    gen_uniform_trace "cl" 64
    gen_uniform_trace "cl" 128
    gen_uniform_trace "cl" 256
    gen_uniform_trace "cl" 512
    gen_uniform_trace "cl" 1024
    gen_uniform_trace "cl" 1500
}

gen_uniform_traces_sbridge() {
    gen_uniform_trace "sbridge" 64
    gen_uniform_trace "sbridge" 128
    gen_uniform_trace "sbridge" 256
    gen_uniform_trace "sbridge" 512
    gen_uniform_trace "sbridge" 1024
    gen_uniform_trace "sbridge" 1500
}

gen_uniform_traces_fw() {
    gen_uniform_trace "fw" 64
    gen_uniform_trace "fw" 128
    gen_uniform_trace "fw" 256
    gen_uniform_trace "fw" 512
    gen_uniform_trace "fw" 1024
    gen_uniform_trace "fw" 1500
}

gen_uniform_traces_nat() {
    gen_uniform_trace "nat" 64
    gen_uniform_trace "nat" 128
    gen_uniform_trace "nat" 256
    gen_uniform_trace "nat" 512
    gen_uniform_trace "nat" 1024
    gen_uniform_trace "nat" 1500
}

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry is not installed. Please install it to proceed."
    sudo apt install python3-poetry -y
fi

# Check if capinfos is installed
if ! command -v capinfos &> /dev/null; then
    echo "capinfos is not installed. Please install it to proceed."
    sudo apt install wireshark-common -y
fi

# Install dependencies with poetry
poetry install
gen_uniform_traces_sbridge
gen_uniform_traces_cl
gen_uniform_traces_fw
gen_uniform_traces_nat

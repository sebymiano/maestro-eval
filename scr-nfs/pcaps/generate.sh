#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

source $SCRIPT_DIR/../../bench/vars.sh

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

ORIGINAL_PCAP_DIR=$SCRIPT_DIR/../../pcaps/
GEN_PCAP_CL_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_cl.py

POETRY_CMD="poetry run python"

gen_uniform_trace() {
    pkt_size=$1
    num_flows=40000

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

        # Run the pcap generation script for each core index
        $POETRY_CMD $GEN_PCAP_CL_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
    done
}

gen_uniform_traces() {
    gen_uniform_trace 64
    gen_uniform_trace 128
    gen_uniform_trace 256
    gen_uniform_trace 512
    gen_uniform_trace 1024
    gen_uniform_trace 1500
}

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry is not installed. Please install it to proceed."
    sudo apt install python3-poetry -y
fi

# Install dependencies with poetry
poetry install
gen_uniform_traces
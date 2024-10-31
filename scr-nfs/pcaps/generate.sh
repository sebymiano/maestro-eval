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
GEN_PCAP_NOP_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_nop.py
GEN_PCAP_PSD_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_psd.py
GEN_PCAP_POL_SCRIPT=$SCRIPT_DIR/gen_pcap_with_md_pol.py

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
        elif [ "$target" == "nop" ]; then
            $POETRY_CMD $GEN_PCAP_NOP_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/${target}_uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
        elif [ "$target" == "psd" ]; then
            $POETRY_CMD $GEN_PCAP_PSD_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/${target}_uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
        elif [ "$target" == "pol" ]; then
            $POETRY_CMD $GEN_PCAP_POL_SCRIPT --input "$pcap" --output "${SCRIPT_DIR}/${target}_uniform_${pkt_size}_scr" --num_cores $i --dst_mac "$PCAP_DST_MAC" --pkt_len $pkt_size
        else
            echo "Error: Unknown target '$target'."
            return 1
        fi
    done
}

gen_uniform_traces_scr() {
    local target=$1
    gen_uniform_trace $target 64
    gen_uniform_trace $target 128
    gen_uniform_trace $target 256
    gen_uniform_trace $target 512
    gen_uniform_trace $target 1024
    gen_uniform_trace $target 1500
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
gen_uniform_traces_scr "cl"
gen_uniform_traces_scr "sbridge"
gen_uniform_traces_scr "fw"
gen_uniform_traces_scr "nat"
gen_uniform_traces_scr "nop"
gen_uniform_traces_scr "psd"
gen_uniform_traces_scr "pol"
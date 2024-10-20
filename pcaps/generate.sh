#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

source $SCRIPT_DIR/../bench/vars.sh

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

IMC10_FILE=univ2_trace.tgz
IMC10_URL=https://pages.cs.wisc.edu/~tbenson/IMC_DATA/$IMC10_FILE
IMC10_CHOSEN_TRACE=univ2_pt1
IMC10_TRACE=imc10.pcap

UNIFORM_SCRIPT=$SCRIPT_DIR/uniform.py
NORMALIZE_PACKET_SIZES_SCRIPT=$SCRIPT_DIR/normalize_packet_sizes.py
CHURN_SCRIPT=$SCRIPT_DIR/churn.py

get_univ_trace() {
    pushd $SCRIPT_DIR >/dev/null
        if [ -f $IMC10_TRACE ]; then
            return 0
        fi

        if [ ! -f $IMC10_FILE ]; then
            mkdir -p .tmp
            pushd .tmp >/dev/null
                wget $IMC10_URL
                tar xvzf $IMC10_FILE
                mv $IMC10_CHOSEN_TRACE ../$IMC10_TRACE
            popd
            rm -rf .tmp
        fi
    popd
}

gen_uniform_trace() {
    pkt_size=$1
    num_flows=40000

    pcap=$SCRIPT_DIR/uniform_${pkt_size}B.pcap

    if [ -f $pcap ]; then
        return 0
    fi
    
    $UNIFORM_SCRIPT --output $pcap --flows $num_flows --size $pkt_size --src-mac $PCAP_SRC_MAC --dst-mac $PCAP_DST_MAC
}

gen_uniform_internet_trace() {
    pcap=$SCRIPT_DIR/uniform_internet.pcap
    num_flows=40000

    if [ -f $pcap ]; then
        return 0
    fi

    $UNIFORM_SCRIPT --output $pcap --pcap $IMC10_TRACE --flows $num_flows --max $num_flows --src-mac $PCAP_SRC_MAC --dst-mac $PCAP_DST_MAC
}

gen_uniform_vpp_trace() {
    pkt_size=64
    num_flows=40000

    pcap=$SCRIPT_DIR/uniform_${pkt_size}B_vpp.pcap

    if [ -f $pcap ]; then
        return 0
    fi
    
    $UNIFORM_SCRIPT --output $pcap --flows $num_flows --size $pkt_size --internet-only --src-mac $PCAP_SRC_MAC --dst-mac $PCAP_DST_MAC
}

get_zipf_trace() {
    pkt_size=64
    pcap=$SCRIPT_DIR/zipf.pcap
    max=50000

    if [ -f $pcap ]; then
        return 0
    fi

    $NORMALIZE_PACKET_SIZES_SCRIPT --output $pcap --input $IMC10_TRACE --size $pkt_size --max $max --src-mac $PCAP_SRC_MAC --dst-mac $PCAP_DST_MAC
}

gen_uniform_traces() {
    gen_uniform_trace 64
    gen_uniform_trace 128
    gen_uniform_trace 256
    gen_uniform_trace 512
    gen_uniform_trace 1024
    gen_uniform_trace 1500
}

get_churn_trace() {
    churn=$1      # fpm
    rate=100      # Gbps
    size=64       # B
    exp_time=1000 # us

    pcap=$SCRIPT_DIR/churn_${churn}fpm_${size}B_${rate}Gbps_${exp_time}us.pcap

    if [ -f $pcap ]; then
        return 0
    fi

    $CHURN_SCRIPT --rate $rate --size $size --expiration $exp_time --churn $churn --output $pcap --src-mac $PCAP_SRC_MAC --dst-mac $PCAP_DST_MAC
}

get_churn_traces() {
    get_churn_trace 15400
    get_churn_trace 23000
    get_churn_trace 31000
    get_churn_trace 250000
    get_churn_trace 885000
    get_churn_trace 1500000
    get_churn_trace 2000000
    get_churn_trace 2600000
    get_churn_trace 25000000
    get_churn_trace 88462000
}

get_univ_trace
gen_uniform_traces
gen_uniform_internet_trace
gen_uniform_vpp_trace
get_zipf_trace
get_churn_traces
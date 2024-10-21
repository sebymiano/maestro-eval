#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

DATA_DIR="$SCRIPT_DIR/data"
PCAPS_DIR="$SCRIPT_DIR/pcaps"

# SSH entries. Make sure these are accessible!
DUT="smiano@sm110p-10s10613.wisc.cloudlab.us" # FIXME: DUT ssh entry
TG="smiano@sm110p-10s10619.wisc.cloudlab.us"  # FIXME: TG ssh entry

DUT_EVAL_DIR=~/maestro-eval # Path to this repo on the DUT
TG_EVAL_DIR=~/maestro-eval  # Path to this repo on the TG

DUT_CORES="1,2,3,4,5,6,7,8" # FIXME: comma separated list of cores to be used (e.g. "0,1,2,3")

TG_TX_DEV="0000:51:00.0" # FIXME: TX PCIe device on the TG
TG_RX_DEV="0000:51:00.1" # FIXME: RX PCIe device on the TG

DUT_TX_DEV="0000:51:00.1" # FIXME: TX PCIe device on the DUT
DUT_RX_DEV="0000:51:00.0" # FIXME: RX PCIe device on the DUT

PCAP_SRC_MAC="b8:3f:d2:13:08:42"
PCAP_DST_MAC="b8:3f:d2:13:08:43"

TG_TX_CORES=6
TG_RX_CORES=6

ITERATIONS=1
ITERATION_DURATION_SEC=5
#!/bin/bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root."
	exit 1
fi

if [ $# -eq 0 ]; then
	program="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
	echo "Usage: $program [pcie devices]"
	exit 1
fi

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
BUILD_DIR="$SCRIPT_DIR/../build"
DPDK_KMODS_DIR="$BUILD_DIR/dpdk-kmods"

KERNEL_VERSION=$(uname -r)

check_pcie_dev() {
	pcie_dev=$1

	if [ -z "$pcie_dev" ]; then
		return 1
	fi
	
	if ! lshw -class network -businfo -quiet | grep -q "$pcie_dev"; then
		echo "[$pcie_dev] PCIe device not found in lshw"
		return 1
	fi

	return 0
}

shutdown_iface() {
	pcie_dev=$1

	iface=$(lshw -class network -businfo -quiet | grep "$pcie_dev" | awk '{ print $2 }')
	
	if [[ "$iface" == "network" ]]; then
		echo "[$pcie_dev] No kernel network interface"
	else
		echo "[$pcie_dev] Bringing interface $iface down"
		ifconfig $iface down || true
	fi
}

bind_dpdk_drivers() {
	pcie_dev=$1

	# Make sure we have the right kernel headers.
	apt install -y linux-headers-$KERNEL_VERSION

	if ! grep "igb_uio" -q <<< $(lsmod); then
		echo "[$pcie_dev] Loading kernel module igb_uio"

		modprobe uio
		insmod $DPDK_KMODS_DIR/linux/igb_uio/igb_uio.ko
	fi

	echo "[$pcie_dev] Binding to igb_uio"
	$RTE_SDK/usertools/dpdk-devbind.py -b igb_uio $pcie_dev
}

for pcie_dev in "$@"; do
	if check_pcie_dev "$pcie_dev"; then
		shutdown_iface "$pcie_dev"
		bind_dpdk_drivers "$pcie_dev"
	fi
done
#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

BUILD_DIR="$SCRIPT_DIR/../build"
MAESTRO_DIR="$BUILD_DIR/maestro"
PYTHON_ENV_DIR="$BUILD_DIR/env"

DPDK_VERSION="23.11.2"
PKTGEN_VERSION="24.07.1"

RTE_TARGET=x86_64-native-linux-gcc

DPDK_DIR="$BUILD_DIR/dpdk"
DPDK_KMODS_DIR="$BUILD_DIR/dpdk-kmods"
PKTGEN_DIR="$BUILD_DIR/Pktgen-DPDK"

PYTHON_REQUIREMENTS="$SCRIPT_DIR/requirements.txt"

VPP_DIR="$BUILD_DIR/maestro-eval-vpp"

export DEBIAN_FRONTEND=noninteractive

setup() {
	mkdir -p $BUILD_DIR
	
	sudo apt update
	sudo apt-get -y install \
		build-essential \
		make \
		vim \
		wget \
		curl \
		git \
		python3-pip \
		python3-venv \
		linux-generic \
		linux-headers-generic \
		cmake \
		pkg-config \
		libnuma-dev \
		libpcap-dev \
		lshw \
		kmod \
		iproute2 \
		net-tools \
		ninja-build \
		wireshark-common \
		gnuplot \
		texlive-extra-utils \
		poppler-utils
}

setup_python_venv() {
	if [ ! -d $PYTHON_ENV_DIR ]; then
		python3 -m venv $PYTHON_ENV_DIR
	fi
	
	. $PYTHON_ENV_DIR/bin/activate
	pip3 install -r $PYTHON_REQUIREMENTS
}

install_maestro() {
	if [ -d $MAESTRO_DIR ]; then
		echo "Maestro directory already exists: $MAESTRO_DIR."
		return 0
	fi

	pushd $BUILD_DIR
		git clone https://github.com/snaplab-dpss/maestro.git $MAESTRO_DIR

		pushd $MAESTRO_DIR
			git submodule update --init --recursive
			cp $SCRIPT_DIR/patches/maestro_mlnx_key_size_40.patch $MAESTRO_DIR/maestro_mlnx_key_size_40.patch
			# cp $SCRIPT_DIR/patches/maestro_mlnx_key_size_40_with_swap.patch $MAESTRO_DIR/maestro_mlnx_key_size_40_with_swap.patch
			
			cp $SCRIPT_DIR/patches/librs3_mlnx_key_size_40.patch $MAESTRO_DIR/deps/librs3/librs3_mlnx_key_size_40.patch
			git apply maestro_mlnx_key_size_40.patch
			# git apply maestro_mlnx_key_size_40_with_swap.patch
			pushd deps/librs3
				git apply librs3_mlnx_key_size_40.patch
			popd
			./build.sh
		popd
	popd
}

install_dpdk() {
	if [ -d $DPDK_DIR ]; then
		echo "DPDK directory already exists: $DPDK_DIR."
		return 0
	fi

	pushd $BUILD_DIR
		DPDK_TAR="dpdk-$DPDK_VERSION.tar.xz"
		wget https://fast.dpdk.org/rel/$DPDK_TAR
		tar xJf $DPDK_TAR
		rm $DPDK_TAR
		mv dpdk-stable-$DPDK_VERSION $DPDK_DIR

		pushd $DPDK_DIR
			meson build
			ninja -C build
			sudo ninja -C build install
			sudo ldconfig
		popd
	popd
}

install_dpdk_kmods() {
	if [ -d $DPDK_KMODS_DIR ]; then
		echo "DPDK kmods directory already exists: $DPDK_KMODS_DIR."
		return 0
	fi

	git clone http://dpdk.org/git/dpdk-kmods $DPDK_KMODS_DIR

	pushd $DPDK_KMODS_DIR/linux/igb_uio
		make
	popd
}

install_pktgen() {
	if [ -d $PKTGEN_DIR ]; then
		echo "Pktgen directory already exists: $PKTGEN_DIR."
		return 0
	fi

	if [ ! -d $DPDK_DIR ]; then
		echo "DPDK directory not found. Installing it."
		install_dpdk
	fi

	pushd $BUILD_DIR
		git clone \
			--depth 1 \
			--branch pktgen-$PKTGEN_VERSION \
			https://github.com/pktgen/Pktgen-DPDK.git \
			$PKTGEN_DIR
		
		pushd $PKTGEN_DIR
			# DPDK places the libdpdk.pc (pkg-config file) in a non-standard location.
			# We need to set enviroment variable PKG_CONFIG_PATH to the location of the file.
			# On Ubuntu 20.04 build of DPDK it places the file
			# here /usr/local/lib/x86_64-linux-gnu/pkgconfig/libdpdk.pc
			# Source: https://github.com/pktgen/Pktgen-DPDK/blob/1e93fa88916b8f2c27b612d761a03cbf03d046de/INSTALL.md
			PKG_CONFIG_PATH=/usr/local/lib/x86_64-linux-gnu/pkgconfig

			# Install LUA
			sudo apt install -y lua5.3 liblua5.3-dev

			# Enable LUA scripts
			sed -i 's/export lua_enabled="-Denable_lua=false"/export lua_enabled="-Denable_lua=true"/g' \
				./tools/pktgen-build.sh
			./tools/pktgen-build.sh build
		popd
	popd	
}

install_vpp() {
	if [ -d $VPP_DIR ]; then
		echo "VPP directory already exists: $VPP_DIR."
		return 0
	fi

	pushd $BUILD_DIR
		git clone https://github.com/snaplab-dpss/maestro-eval-vpp.git \
			--branch maestro-eval \
			$VPP_DIR

		pushd $VPP_DIR
			git submodule update --init --recursive
			DOCKER_BUILDKIT=1 docker-compose build
		popd
	popd
}
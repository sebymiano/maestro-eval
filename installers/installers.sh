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
DPDK_BURST_REPLAY_DIR="$BUILD_DIR/dpdk-burst-replay"
DPDK_BURST_REPLAY_BRANCH="feat/http_server"

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
		poppler-utils \
		byobu \
		htop 
}

setup_docker() {
	# Add Docker's official GPG key:
	sudo apt-get update
	sudo apt-get install ca-certificates curl -y
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
}

install_doca() {
	export DOCA_URL="https://linux.mellanox.com/public/repo/doca/2.9.0/ubuntu22.04/x86_64/"
	sudo bash -c "curl https://linux.mellanox.com/public/repo/doca/GPG-KEY-Mellanox.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub"
	sudo bash -c 'echo "deb [signed-by=/etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub] $DOCA_URL ./" > /etc/apt/sources.list.d/doca.list'
	sudo apt-get update
	sudo apt-get -y install doca-all doca-extra
	sudo /etc/init.d/openibd restart
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

	local MLNX=false

	# Check if input argument is set; if it is true, set MLNX to true
	if [ $# -eq 1 ]; then
		if [ $1 == "true" ]; then
			MLNX=true
		fi
	fi


	pushd $BUILD_DIR
		git clone https://github.com/snaplab-dpss/maestro.git $MAESTRO_DIR

		pushd $MAESTRO_DIR
			git submodule update --init --recursive

			if [ $MLNX == true ]; then
				# cp $SCRIPT_DIR/patches/maestro_mlnx_key_size_40.patch $MAESTRO_DIR/maestro_mlnx_key_size_40.patch
				# cp $SCRIPT_DIR/patches/maestro_mlnx_key_size_40_with_swap.patch $MAESTRO_DIR/maestro_mlnx_key_size_40_with_swap.patch
				cp $SCRIPT_DIR/patches/mlnx_maestro_with_spread_data_fixed.patch $MAESTRO_DIR/mlnx_maestro_with_spread_data_fixed.patch
				
				cp $SCRIPT_DIR/patches/librs3_mlnx_key_size_40.patch $MAESTRO_DIR/deps/librs3/librs3_mlnx_key_size_40.patch
				# git apply maestro_mlnx_key_size_40.patch
				# git apply maestro_mlnx_key_size_40_with_swap.patch
				git apply mlnx_maestro_with_spread_data_fixed.patch
				pushd deps/librs3
					git apply librs3_mlnx_key_size_40.patch
				popd
			fi

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
			meson build -Ddisable_drivers=net/af_xdp,regex/cn9k
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

install_dpdk_burst_replay() {
	if [ -d $DPDK_BURST_REPLAY_DIR ]; then
		echo "DPDK Burst Replay directory already exists: $DPDK_BURST_REPLAY_DIR."
		return 0
	fi

	if [ ! -d $DPDK_DIR ]; then
		echo "DPDK directory not found. Installing it."
		install_dpdk
	fi

	pushd $BUILD_DIR
		git clone \
			--depth 1 \
			--branch $DPDK_BURST_REPLAY_BRANCH \
			https://github.com/sebymiano/dpdk-burst-replay \
			$DPDK_BURST_REPLAY_DIR
		
		pushd $DPDK_BURST_REPLAY_DIR
			# DPDK places the libdpdk.pc (pkg-config file) in a non-standard location.
			# We need to set enviroment variable PKG_CONFIG_PATH to the location of the file.
			# On Ubuntu 20.04 build of DPDK it places the file
			# here /usr/local/lib/x86_64-linux-gnu/pkgconfig/libdpdk.pc
			# Source: https://github.com/pktgen/Pktgen-DPDK/blob/1e93fa88916b8f2c27b612d761a03cbf03d046de/INSTALL.md
			PKG_CONFIG_PATH=/usr/local/lib/x86_64-linux-gnu/pkgconfig

			# Install deps
			sudo apt install libnuma-dev libyaml-dev libcyaml-dev libcsv-dev libmicrohttpd-dev -y

			mkdir -p build
			cd build
			cmake ..
			make
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

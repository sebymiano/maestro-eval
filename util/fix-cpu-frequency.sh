#!/bin/bash

#!/bin/bash

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Install cpupower tool
echo "Installing cpupower..."
if command -v apt-get &> /dev/null; then
    apt-get update -y
    apt-get install -y linux-tools-common linux-tools-$(uname -r)
elif command -v yum &> /dev/null; then
    yum install -y kernel-tools
else
    echo "Unsupported package manager. Please install cpupower manually."
    exit 1
fi

# Check if cpupower is installed
if ! command -v cpupower &> /dev/null; then
    echo "cpupower could not be installed. Please check your system configuration."
    exit 1
fi

# Get the maximum supported frequency
echo "Detecting maximum supported frequency..."
MAX_FREQ=$(cpupower frequency-info | grep -m 1 "hardware limits" | awk '{print $6}' | sed 's/GHz//')

if [[ -z "$MAX_FREQ" ]]; then
    echo "Failed to detect the maximum supported frequency. Exiting."
    exit 1
fi

# Convert GHz to Hz for cpupower (e.g., 3.4 -> 3.4GHz)
MAX_FREQ="${MAX_FREQ}GHz"

echo "Setting CPU frequency to maximum ($MAX_FREQ)..."

# Set the performance governor
cpupower frequency-set -g performance

# Set the max and min frequency to the maximum
cpupower frequency-set --max "$MAX_FREQ"
cpupower frequency-set --min "$MAX_FREQ"

# Verify the changes
echo "Verifying changes..."
cpupower frequency-info | grep -E "current policy|current CPU frequency"

echo "CPU frequency successfully set to maximum ($MAX_FREQ)."

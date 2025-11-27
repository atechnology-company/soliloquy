#!/bin/bash
# Copyright 2024 Soliloquy Authors
# SPDX-License-Identifier: Apache-2.0
#
# Run Soliloquy in QEMU ARM64
#
# Usage:
#   ./run_qemu.sh [options]
#
# Options:
#   -k, --kernel <path>   Path to ZBI image
#   -m, --memory <size>   RAM size (default: 2G)
#   -c, --cpus <n>        Number of CPUs (default: 4)
#   -g, --graphics        Enable graphics display
#   -n, --network         Enable network (user mode)
#   -d, --debug           Enable GDB server on port 1234
#   -v, --verbose         Verbose QEMU output
#   -h, --help            Show this help

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FUCHSIA_DIR="${FUCHSIA_DIR:-/Volumes/storage/fuchsia-src}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default options
KERNEL_PATH=""
MEMORY="2G"
CPUS="4"
GRAPHICS=false
NETWORK=false
DEBUG=false
VERBOSE=false
USE_ORBSTACK=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--kernel)
            KERNEL_PATH="$2"
            shift 2
            ;;
        -m|--memory)
            MEMORY="$2"
            shift 2
            ;;
        -c|--cpus)
            CPUS="$2"
            shift 2
            ;;
        -g|--graphics)
            GRAPHICS=true
            shift
            ;;
        -n|--network)
            NETWORK=true
            shift
            ;;
        -d|--debug)
            DEBUG=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --orbstack)
            USE_ORBSTACK=true
            shift
            ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=== Soliloquy QEMU Runner ===${NC}"
echo ""

# Detect platform
if [[ "$(uname)" == "Darwin" ]]; then
    PLATFORM="macos"
    # Find QEMU on macOS
    if command -v qemu-system-aarch64 &> /dev/null; then
        QEMU="qemu-system-aarch64"
    elif [ -f "/opt/homebrew/bin/qemu-system-aarch64" ]; then
        QEMU="/opt/homebrew/bin/qemu-system-aarch64"
    elif [ -f "/usr/local/bin/qemu-system-aarch64" ]; then
        QEMU="/usr/local/bin/qemu-system-aarch64"
    else
        echo -e "${YELLOW}QEMU not found. Installing...${NC}"
        brew install qemu
        QEMU="qemu-system-aarch64"
    fi
else
    PLATFORM="linux"
    if ! command -v qemu-system-aarch64 &> /dev/null; then
        echo -e "${YELLOW}Installing QEMU...${NC}"
        if command -v dnf &> /dev/null; then
            sudo dnf install -y qemu-system-aarch64 qemu-img
        elif command -v apt-get &> /dev/null; then
            sudo apt-get install -y qemu-system-arm
        fi
    fi
    QEMU="qemu-system-aarch64"
fi

echo -e "${CYAN}Platform: ${PLATFORM}${NC}"
echo -e "${CYAN}QEMU: ${QEMU}${NC}"
${QEMU} --version | head -1
echo ""

# Find kernel/ZBI
if [ -z "${KERNEL_PATH}" ]; then
    # Try various locations
    POSSIBLE_PATHS=(
        "${PROJECT_ROOT}/out/soliloquy.zbi"
        "${PROJECT_ROOT}/out/default/soliloquy.zbi"
        "${FUCHSIA_DIR}/out/default/fuchsia.zbi"
        "${FUCHSIA_DIR}/out/default/qemu-arm64.zbi"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            KERNEL_PATH="$path"
            break
        fi
    done
fi

# Still no kernel? Check if fx is available
if [ -z "${KERNEL_PATH}" ] && [ -f "${FUCHSIA_DIR}/scripts/fx" ]; then
    echo -e "${YELLOW}No ZBI found. Using fx to build and run...${NC}"
    export PATH="${FUCHSIA_DIR}/scripts:${FUCHSIA_DIR}/.jiri_root/bin:$PATH"
    cd "${FUCHSIA_DIR}"
    
    # Check if build is configured
    if [ ! -f "${FUCHSIA_DIR}/out/default/args.gn" ]; then
        echo -e "${YELLOW}Configuring build for QEMU ARM64...${NC}"
        fx set core.qemu-arm64 \
            --release \
            --with //examples/hello_world
    fi
    
    # Check if ZBI exists, build if not
    if [ ! -f "${FUCHSIA_DIR}/out/default/fuchsia.zbi" ]; then
        echo -e "${YELLOW}Building Fuchsia (this may take a while)...${NC}"
        fx build
    fi
    
    echo -e "${GREEN}Starting QEMU via fx...${NC}"
    echo "Press Ctrl+A X to exit QEMU"
    
    FX_ARGS="-N"
    if [ "$GRAPHICS" = true ]; then
        FX_ARGS="$FX_ARGS --display"
    fi
    
    exec fx qemu $FX_ARGS
fi

if [ -z "${KERNEL_PATH}" ] || [ ! -f "${KERNEL_PATH}" ]; then
    echo -e "${RED}Error: No bootable ZBI found${NC}"
    echo ""
    echo "Build Soliloquy first with:"
    echo "  ./tools/soliloquy/build_qemu.sh"
    echo ""
    echo "Or specify a kernel path:"
    echo "  $0 -k /path/to/soliloquy.zbi"
    echo ""
    echo "Or set up Fuchsia source at:"
    echo "  ${FUCHSIA_DIR}"
    exit 1
fi

echo -e "${GREEN}Loading kernel: ${KERNEL_PATH}${NC}"

# Build QEMU command
QEMU_ARGS=(
    -machine virt,gic-version=3,virtualization=on
    -cpu cortex-a72
    -m "${MEMORY}"
    -smp "${CPUS}"
    
    # Serial console
    -serial mon:stdio
    
    # RTC
    -rtc base=utc,clock=host
    
    # No default devices
    -nodefaults
    
    # Kernel (ZBI format)
    -kernel "${KERNEL_PATH}"
)

# Graphics
if [ "$GRAPHICS" = true ]; then
    echo -e "${CYAN}Graphics: enabled (virtio-gpu)${NC}"
    if [ "$PLATFORM" = "macos" ]; then
        QEMU_ARGS+=(
            -device virtio-gpu-pci
            -display cocoa
        )
    else
        QEMU_ARGS+=(
            -device virtio-gpu-pci
            -display gtk
        )
    fi
else
    QEMU_ARGS+=(-nographic)
fi

# Network
if [ "$NETWORK" = true ]; then
    QEMU_ARGS+=(
        -device virtio-net-pci,netdev=net0
        -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80
    )
    echo -e "${CYAN}Network: enabled${NC}"
    echo "  SSH: localhost:2222"
    echo "  HTTP: localhost:8080"
fi

# Block device (create if not exists)
DISK_PATH="${PROJECT_ROOT}/out/qemu-disk.img"
mkdir -p "${PROJECT_ROOT}/out"
if [ ! -f "${DISK_PATH}" ]; then
    echo -e "${CYAN}Creating disk image: ${DISK_PATH}${NC}"
    qemu-img create -f qcow2 "${DISK_PATH}" 8G
fi
QEMU_ARGS+=(
    -device virtio-blk-pci,drive=hd0
    -drive file="${DISK_PATH}",id=hd0,if=none,format=qcow2
)

# Debug
if [ "$DEBUG" = true ]; then
    QEMU_ARGS+=(
        -s  # GDB server on :1234
        -S  # Wait for GDB connection
    )
    echo -e "${CYAN}GDB server: enabled on port 1234${NC}"
    echo "Connect with: gdb -ex 'target remote :1234'"
fi

# Verbose
if [ "$VERBOSE" = true ]; then
    QEMU_ARGS+=(-d int,cpu_reset -D "${PROJECT_ROOT}/out/qemu.log")
    echo -e "${CYAN}Logging to: ${PROJECT_ROOT}/out/qemu.log${NC}"
fi

echo ""
echo -e "${GREEN}Starting QEMU...${NC}"
echo "Press Ctrl+A, X to exit"
echo ""

exec "${QEMU}" "${QEMU_ARGS[@]}"

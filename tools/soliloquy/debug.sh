#!/bin/bash
# debug.sh - Serial Console Debugger

SERIAL_DEV="/dev/ttyUSB0" # Default, can be overridden
BAUD_RATE="115200"

if [ ! -z "$1" ]; then
    SERIAL_DEV=$1
fi

echo "=== Connecting to Serial Console ($SERIAL_DEV) ==="
echo "Press Ctrl-A then X to exit."

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "Error: 'screen' is not installed. Please install it (sudo apt install screen)."
    exit 1
fi

sudo screen "$SERIAL_DEV" "$BAUD_RATE"

#!/bin/bash
# debug.sh - Serial Console Debugger

SERIAL_DEV="/dev/ttyUSB0" # Default, can be overridden
BAUD_RATE="115200"

# Auto-detect serial device on macOS if not provided
if [ -z "$1" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SERIAL_DEV=$(ls /dev/tty.usbserial* 2>/dev/null | head -n 1)
        if [ -z "$SERIAL_DEV" ]; then
             SERIAL_DEV=$(ls /dev/tty.usbmodem* 2>/dev/null | head -n 1)
        fi
    fi
else
    SERIAL_DEV=$1
fi

if [ -z "$SERIAL_DEV" ]; then
    echo "Error: No serial device found or provided."
    echo "Usage: $0 [device_path]"
    exit 1
fi

echo "=== Connecting to Serial Console ($SERIAL_DEV) ==="
echo "Press Ctrl-A then K to exit (screen default)."

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "Error: 'screen' is not installed."
    exit 1
fi

sudo screen "$SERIAL_DEV" "$BAUD_RATE"

#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

echo "Building VM subsystem tests..."
cd "$PROJECT_ROOT"

gcc -o test_vm \
    test/vm/simple_vm_test.c \
    third_party/zircon_c/vm/pmm_arena.c \
    third_party/zircon_c/vm/vmo_bootstrap.c \
    third_party/zircon_c/vm/page_fault.c \
    -I.

echo ""
echo "Running VM tests..."
./test_vm

echo ""
echo "Cleaning up..."
rm -f test_vm

echo ""
echo "All tests completed successfully!"

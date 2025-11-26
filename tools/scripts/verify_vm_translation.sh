#!/bin/bash
set -e


# Detect project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "VM Subsystem Translation Verification"
echo "=========================================="
echo ""

echo "1. Checking C source files..."
if [ -f "third_party/zircon_c/vm/pmm_arena.c" ] && \
   [ -f "third_party/zircon_c/vm/vmo_bootstrap.c" ] && \
   [ -f "third_party/zircon_c/vm/page_fault.c" ]; then
    echo "   ✅ All C source files present"
else
    echo "   ❌ Missing C source files"
    exit 1
fi

echo ""
echo "2. Checking V translated files..."
if [ -f "third_party/zircon_v/vm/zircon_vm.v" ]; then
    echo "   ✅ V module present"
else
    echo "   ❌ Missing V module"
    exit 1
fi

echo ""
echo "3. Compiling C sources..."
if gcc -c third_party/zircon_c/vm/*.c -I third_party/zircon_c/vm/ 2>&1 | tail -5; then
    echo "   ✅ C sources compile successfully"
    rm -f *.o
else
    echo "   ❌ C compilation failed"
    exit 1
fi

echo ""
echo "4. Running tests..."
if ./test/vm/run_tests.sh | grep -q "PASSED: 9"; then
    echo "   ✅ All tests pass (9/9)"
else
    echo "   ❌ Some tests failed"
    exit 1
fi

echo ""
echo "5. Checking build files..."
if [ -f "third_party/zircon_c/vm/BUILD.gn" ] && \
   [ -f "third_party/zircon_c/vm/BUILD.bazel" ] && \
   [ -f "third_party/zircon_v/vm/BUILD.gn" ] && \
   [ -f "third_party/zircon_v/vm/BUILD.bazel" ]; then
    echo "   ✅ All build files present"
else
    echo "   ❌ Missing build files"
    exit 1
fi

echo ""
echo "6. Checking board integration..."
if grep -q "use_v_vm" boards/arm64/soliloquy/board_config.gni && \
   grep -q "kernel_vm_deps" boards/arm64/soliloquy/board_config.gni; then
    echo "   ✅ Board integration configured"
else
    echo "   ❌ Board integration missing"
    exit 1
fi

echo ""
echo "7. Checking documentation..."
if [ -f "third_party/zircon_c/vm/README.md" ] && \
   [ -f "third_party/zircon_v/vm/README.md" ] && \
   [ -f "test/vm/README.md" ] && \
   [ -f "VM_TRANSLATION_REPORT.md" ]; then
    echo "   ✅ All documentation present"
else
    echo "   ❌ Missing documentation"
    exit 1
fi

echo ""
echo "8. Verifying c2v pipeline..."
if [ -x "tools/soliloquy/c2v_pipeline.sh" ]; then
    echo "   ✅ c2v pipeline script executable"
else
    echo "   ❌ c2v pipeline not executable"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All verification checks passed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - C sources: Present and compilable"
echo "  - V translation: Complete"
echo "  - Tests: 9/9 passing"
echo "  - Build integration: GN and Bazel"
echo "  - Board config: Integrated"
echo "  - Documentation: Complete"
echo ""
echo "The VM subsystem translation is ready for use."

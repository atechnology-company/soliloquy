#!/bin/bash
# Verify HAL V translation setup

set -e

echo "=== Verifying HAL V Translation Setup ==="
echo

# Check C source snapshot
echo "1. Checking C source snapshot..."
if [ -d "third_party/zircon_c/hal" ]; then
    echo "   ✓ third_party/zircon_c/hal/ exists"
    echo "   Files:"
    ls -1 third_party/zircon_c/hal/*.{cc,h} 2>/dev/null | sed 's/^/     /'
else
    echo "   ✗ third_party/zircon_c/hal/ not found"
    exit 1
fi
echo

# Check V translation
echo "2. Checking V translation..."
if [ -d "third_party/zircon_v/hal" ]; then
    echo "   ✓ third_party/zircon_v/hal/ exists"
    echo "   Files:"
    ls -1 third_party/zircon_v/hal/*.v 2>/dev/null | sed 's/^/     /'
else
    echo "   ✗ third_party/zircon_v/hal/ not found"
    exit 1
fi
echo

# Check V syntax
echo "3. Checking V syntax..."
V_HOME="${V_HOME:-.build-tools/v}"
if [ -f "$V_HOME/v" ]; then
    for vfile in third_party/zircon_v/hal/*.v; do
        if "$V_HOME/v" -check-syntax "$vfile" 2>&1 | grep -q "error"; then
            echo "   ✗ Syntax error in $vfile"
            exit 1
        else
            echo "   ✓ $(basename $vfile) syntax OK"
        fi
    done
else
    echo "   ⚠ V compiler not found at $V_HOME/v (skipping syntax check)"
    echo "   Run: ./tools/soliloquy/c2v_pipeline.sh --bootstrap-only"
fi
echo

# Check build files
echo "4. Checking build files..."
if [ -f "third_party/zircon_v/BUILD.gn" ]; then
    echo "   ✓ third_party/zircon_v/BUILD.gn exists"
else
    echo "   ✗ third_party/zircon_v/BUILD.gn not found"
    exit 1
fi

if [ -f "third_party/zircon_v/BUILD.bazel" ]; then
    echo "   ✓ third_party/zircon_v/BUILD.bazel exists"
else
    echo "   ✗ third_party/zircon_v/BUILD.bazel not found"
    exit 1
fi
echo

# Check HAL dependency
echo "5. Checking HAL dependency on V translation..."
if grep -q "zircon_v_hal" drivers/common/soliloquy_hal/BUILD.gn; then
    echo "   ✓ BUILD.gn references zircon_v_hal"
else
    echo "   ✗ BUILD.gn does not reference zircon_v_hal"
    exit 1
fi

if grep -q "zircon_v_hal" drivers/common/soliloquy_hal/BUILD.bazel; then
    echo "   ✓ BUILD.bazel references zircon_v_hal"
else
    echo "   ✗ BUILD.bazel does not reference zircon_v_hal"
    exit 1
fi
echo

# Check c2v_pipeline.sh supports --sources
echo "6. Checking c2v_pipeline.sh --sources support..."
if grep -q "\\-\\-sources" tools/soliloquy/c2v_pipeline.sh; then
    echo "   ✓ c2v_pipeline.sh supports --sources flag"
else
    echo "   ✗ c2v_pipeline.sh does not support --sources flag"
    exit 1
fi
echo

echo "=== All checks passed! ==="
echo
echo "To build the V HAL:"
echo "  export V_HOME=\$(pwd)/.build-tools/v"
echo "  bazel build --action_env=V_HOME //third_party/zircon_v:zircon_v_hal"
echo
echo "To translate HAL subsystem:"
echo "  ./tools/soliloquy/c2v_pipeline.sh --subsystem hal --sources third_party/zircon_c/hal --out-dir third_party/zircon_v/hal"

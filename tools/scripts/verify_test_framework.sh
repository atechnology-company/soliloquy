#!/bin/bash
# Verification script for test framework implementation


# Detect project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
set -e

echo "============================================"
echo "Test Framework Verification Script"
echo "============================================"
echo ""

ERRORS=0

check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1"
    else
        echo "✗ MISSING: $1"
        ERRORS=$((ERRORS + 1))
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo "✓ $1/"
    else
        echo "✗ MISSING: $1/"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "Checking directory structure..."
echo "--------------------------------"
check_dir "test/support"
check_dir "test/support/src/mocks"
check_dir "test/components"
check_dir "drivers/common/soliloquy_hal/tests"
check_dir "drivers/wifi/aic8800/tests"
echo ""

echo "Checking test support crate files..."
echo "--------------------------------"
check_file "test/support/Cargo.toml"
check_file "test/support/lib.rs"
check_file "test/support/BUILD.gn"
check_file "test/support/BUILD.bazel"
check_file "test/support/src/mocks/mod.rs"
check_file "test/support/src/mocks/flatland.rs"
check_file "test/support/src/mocks/touch_source.rs"
check_file "test/support/src/mocks/view_provider.rs"
check_file "test/support/src/assertions.rs"
check_file "test/.cargo/config.toml"
check_file "test/BUILD.gn"
echo ""

echo "Checking C++ test files..."
echo "--------------------------------"
check_file "drivers/common/soliloquy_hal/tests/mmio_tests.cc"
check_file "drivers/common/soliloquy_hal/tests/BUILD.gn"
check_file "drivers/wifi/aic8800/tests/init_test.cc"
check_file "drivers/wifi/aic8800/tests/BUILD.gn"
echo ""

echo "Checking integration test files..."
echo "--------------------------------"
check_file "test/components/soliloquy_shell_test.cml"
check_file "src/shell/fidl_integration_tests.rs"
echo ""

echo "Checking orchestration..."
echo "--------------------------------"
check_file "tools/soliloquy/test.sh"
if [ -x "tools/soliloquy/test.sh" ]; then
    echo "✓ test.sh is executable"
else
    echo "✗ test.sh is not executable"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "Checking documentation..."
echo "--------------------------------"
check_file "docs/testing.md"
check_file "test/README.md"
check_file "test/EXAMPLES.md"
check_file "test/QUICKSTART.md"
check_file "TEST_FRAMEWORK_SUMMARY.md"
check_file "TEST_FRAMEWORK_CHECKLIST.md"
echo ""

echo "Validating shell script syntax..."
echo "--------------------------------"
if bash -n tools/soliloquy/test.sh 2>/dev/null; then
    echo "✓ test.sh syntax valid"
else
    echo "✗ test.sh has syntax errors"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "Checking for Rust installation..."
echo "--------------------------------"
if command -v cargo &> /dev/null; then
    echo "✓ Cargo found: $(cargo --version)"
    
    echo ""
    echo "Building test support crate..."
    echo "--------------------------------"
    cd test/support
    if cargo build --target x86_64-unknown-linux-gnu --quiet 2>/dev/null; then
        echo "✓ Test support crate builds successfully"
    else
        echo "✗ Test support crate failed to build"
        ERRORS=$((ERRORS + 1))
    fi
    
    echo ""
    echo "Running test support tests..."
    echo "--------------------------------"
    if cargo test --target x86_64-unknown-linux-gnu --quiet 2>/dev/null; then
        echo "✓ Test support crate tests pass"
    else
        echo "✗ Test support crate tests failed"
        ERRORS=$((ERRORS + 1))
    fi
    cd ../..
else
    echo "! Cargo not found - skipping Rust checks"
    echo "  Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

echo ""
echo "============================================"
echo "Verification Complete"
echo "============================================"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✓ All checks passed! Test framework is properly installed."
    echo ""
    echo "Next steps:"
    echo "  1. Run tests: ./tools/soliloquy/test.sh"
    echo "  2. Read docs: docs/testing.md"
    echo "  3. See examples: test/EXAMPLES.md"
    exit 0
else
    echo "✗ $ERRORS check(s) failed. Please review the errors above."
    exit 1
fi

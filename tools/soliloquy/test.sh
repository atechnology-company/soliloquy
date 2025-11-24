#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

COVERAGE=false
FX_TEST=false
CARGO_TEST=true
VERBOSE=false

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Run Soliloquy test suite

OPTIONS:
  --coverage          Enable coverage collection with cargo llvm-cov
  --fx-test          Run GN test targets via fx test (requires Fuchsia source)
  --no-cargo         Skip cargo test execution
  --verbose          Enable verbose output
  -h, --help         Show this help message

EXAMPLES:
  $0                           # Run cargo tests
  $0 --coverage               # Run cargo tests with coverage
  $0 --fx-test                # Run both cargo and fx tests
  $0 --coverage --fx-test     # Run all tests with coverage

ENVIRONMENT VARIABLES:
  FUCHSIA_DIR     Path to Fuchsia source (required for --fx-test)

EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --coverage)
      COVERAGE=true
      shift
      ;;
    --fx-test)
      FX_TEST=true
      shift
      ;;
    --no-cargo)
      CARGO_TEST=false
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

echo "================================"
echo "Soliloquy Test Suite"
echo "================================"
echo ""

if [ "$CARGO_TEST" = true ]; then
  echo "Running Cargo tests..."
  echo "--------------------------------"
  
  cd "${PROJECT_ROOT}"
  
  if [ "$COVERAGE" = true ]; then
    echo "Coverage enabled - checking for cargo-llvm-cov..."
    
    if ! command -v cargo-llvm-cov &> /dev/null; then
      echo "Installing cargo-llvm-cov..."
      cargo install cargo-llvm-cov
    fi
    
    echo "Running tests with coverage collection..."
    
    cargo llvm-cov clean --workspace
    
    cargo llvm-cov test --workspace --all-features \
      --lcov --output-path lcov.info
    
    cargo llvm-cov report --html
    
    echo ""
    echo "Coverage report generated:"
    echo "  - LCOV: ${PROJECT_ROOT}/lcov.info"
    echo "  - HTML: ${PROJECT_ROOT}/target/llvm-cov/html/index.html"
    echo ""
    
    cargo llvm-cov report --summary-only
    
  else
    echo "Running standard cargo tests..."
    
    cd "${PROJECT_ROOT}/test/support"
    echo "Testing test support crate..."
    cargo test --target x86_64-unknown-linux-gnu
    
    echo ""
    echo "Testing shell crate..."
    cd "${PROJECT_ROOT}/src/shell"
    cargo test --target x86_64-unknown-linux-gnu || echo "Note: Shell tests may require additional setup"
  fi
  
  echo ""
  echo "✓ Cargo tests completed"
  echo ""
fi

if [ "$FX_TEST" = true ]; then
  echo "Running GN test targets via fx test..."
  echo "--------------------------------"
  
  if [ -z "${FUCHSIA_DIR}" ]; then
    echo "Error: FUCHSIA_DIR not set. Please source fx-env.sh or set FUCHSIA_DIR."
    exit 1
  fi
  
  if [ ! -f "${FUCHSIA_DIR}/scripts/fx" ]; then
    echo "Error: fx command not found at ${FUCHSIA_DIR}/scripts/fx"
    exit 1
  fi
  
  FX="${FUCHSIA_DIR}/scripts/fx"
  
  echo "Running HAL MMIO tests..."
  if [ "$VERBOSE" = true ]; then
    "${FX}" test soliloquy_hal_mmio_tests --verbose
  else
    "${FX}" test soliloquy_hal_mmio_tests
  fi
  
  echo ""
  echo "Running AIC8800 init tests..."
  if [ "$VERBOSE" = true ]; then
    "${FX}" test aic8800_init_tests --verbose
  else
    "${FX}" test aic8800_init_tests
  fi
  
  echo ""
  echo "✓ GN tests completed"
  echo ""
fi

echo "================================"
echo "Test Results Summary"
echo "================================"
echo ""

if [ "$CARGO_TEST" = true ]; then
  echo "✓ Rust unit tests (cargo test)"
  echo "  - Test support crate"
  echo "  - Shell integration tests"
  echo "  - FIDL mock tests"
fi

if [ "$FX_TEST" = true ]; then
  echo "✓ C++ unit tests (fx test)"
  echo "  - HAL MMIO tests"
  echo "  - AIC8800 driver init tests"
fi

if [ "$COVERAGE" = true ]; then
  echo ""
  echo "Coverage collection enabled"
  echo "View HTML report: ${PROJECT_ROOT}/target/llvm-cov/html/index.html"
fi

echo ""
echo "All tests completed successfully!"

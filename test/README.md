# Soliloquy Test Framework

This directory contains the unified test framework for Soliloquy OS.

## Directory Structure

```
test/
├── support/              # Test support crate
│   ├── Cargo.toml        # Rust dependencies
│   ├── BUILD.gn          # GN build file
│   ├── BUILD.bazel       # Bazel build file
│   ├── lib.rs            # Main library file
│   └── src/
│       ├── mocks/        # Mock FIDL servers
│       │   ├── flatland.rs
│       │   ├── touch_source.rs
│       │   └── view_provider.rs
│       └── assertions.rs # Custom assertion helpers
├── components/           # Integration test manifests
│   └── soliloquy_shell_test.cml
├── BUILD.gn             # Test group targets
└── README.md            # This file
```

## Quick Start

### Run All Tests

```bash
./tools/soliloquy/test.sh
```

### Run Tests with Coverage

```bash
./tools/soliloquy/test.sh --coverage
```

### Run GN Tests (requires Fuchsia source)

```bash
./tools/soliloquy/test.sh --fx-test
```

## Test Support Crate

The `support/` directory contains a Rust crate that provides:

- **Mock FIDL Servers**: MockFlatland, MockTouchSource, MockViewProvider
- **Assertion Helpers**: Custom assertions for common test patterns
- **Test Utilities**: Shared testing infrastructure

### Using in Your Tests

Add to your `Cargo.toml`:

```toml
[dev-dependencies]
soliloquy_test_support = { path = "../../test/support" }
```

Then use in your tests:

```rust
use soliloquy_test_support::{MockFlatland, assertions::*};

#[test]
fn test_my_component() {
    let (flatland, _rx) = MockFlatland::new();
    flatland.create_transform(1);
    assert_event_count(&flatland.get_events(), 1, "flatland");
}
```

## C++ Unit Tests

C++ unit tests for drivers are located in `drivers/*/tests/`:

- `drivers/common/soliloquy_hal/tests/mmio_tests.cc` - HAL MMIO tests
- `drivers/wifi/aic8800/tests/init_test.cc` - WiFi driver tests

Run with:

```bash
fx test soliloquy_hal_mmio_tests
fx test aic8800_init_tests
```

## Integration Tests

Integration tests use the component manifest in `components/`:

- `soliloquy_shell_test.cml` - Shell integration test with mocked services

Run with:

```bash
ffx test run fuchsia-pkg://fuchsia.com/soliloquy_shell_test
```

## Documentation

See [docs/testing.md](../docs/testing.md) for complete documentation on:

- Writing unit tests
- Creating mock FIDL servers
- Running integration tests
- Collecting coverage data
- Best practices

## Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| Servo Embedder | 70% |
| HAL Utilities | 70% |
| Driver Init | 70% |
| Mock Servers | 90% |

Check current coverage:

```bash
./tools/soliloquy/test.sh --coverage
open target/llvm-cov/html/index.html
```

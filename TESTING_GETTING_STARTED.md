# Getting Started with Testing

Welcome to the Soliloquy OS test framework! This guide will help you start writing and running tests.

## Quick Verification

Verify the test framework is properly installed:

```bash
./verify_test_framework.sh
```

Expected output: `✓ All checks passed! Test framework is properly installed.`

## Running Tests

### Run All Tests

```bash
./tools/soliloquy/test.sh
```

This runs:
- Rust unit tests for the test support crate
- Rust integration tests for the shell
- FIDL mock tests

### Run Tests with Coverage

```bash
./tools/soliloquy/test.sh --coverage
```

View the HTML coverage report:
```bash
open target/llvm-cov/html/index.html  # macOS
xdg-open target/llvm-cov/html/index.html  # Linux
```

### Run GN Tests (Requires Fuchsia Source)

```bash
# Set up environment first
export FUCHSIA_DIR=/path/to/fuchsia
source ${FUCHSIA_DIR}/scripts/fx-env.sh

# Run all tests including GN
./tools/soliloquy/test.sh --fx-test
```

## Writing Your First Test

### 1. Rust Unit Test

Add a test module to your Rust file:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_my_function() {
        let result = my_function(42);
        assert_eq!(result, 84);
    }
}
```

Run:
```bash
cargo test --target x86_64-unknown-linux-gnu
```

### 2. Integration Test with Mock FIDL

Add test support to `Cargo.toml`:

```toml
[dev-dependencies]
soliloquy_test_support = { path = "../../test/support" }
```

Write the test:

```rust
use soliloquy_test_support::{MockFlatland, assertions::*};

#[test]
fn test_ui_interaction() {
    let (flatland, _rx) = MockFlatland::new();
    
    // Set up scene
    flatland.create_transform(1);
    flatland.set_content(1, 100);
    
    // Verify
    assert_event_count(&flatland.get_events(), 2, "scene setup");
}
```

### 3. C++ Unit Test

Create `my_driver/tests/my_test.cc`:

```cpp
#include <zxtest/zxtest.h>

TEST(MyDriverTest, Initialization) {
    // Your test code here
    EXPECT_EQ(1 + 1, 2);
}
```

Create `my_driver/tests/BUILD.gn`:

```gn
test("my_driver_test") {
    sources = [ "my_test.cc" ]
    deps = [
        "//zircon/system/ulib/zxtest",
        "//my_driver",
    ]
}
```

Run:
```bash
fx test my_driver_test
```

## Available Mock FIDL Servers

### MockFlatland (Compositor)

```rust
let (flatland, _rx) = MockFlatland::new();
flatland.create_transform(1);
flatland.set_content(1, 100);
flatland.present(PresentArgs { ... });
```

### MockTouchSource (Input)

```rust
let (touch, _rx) = MockTouchSource::new();
touch.inject_touch_down(100.0, 200.0, 1);
touch.inject_touch_move(150.0, 250.0, 1);
touch.inject_touch_up(1);
```

### MockViewProvider (Views)

```rust
let (view_provider, _rx) = MockViewProvider::new();
let token = ViewCreationToken { value: 123 };
view_provider.create_view(token);
```

## Assertion Helpers

### Floating-Point Tolerance

```rust
use soliloquy_test_support::assertions::*;

assert_within_tolerance(10.0, 10.05, 0.1);
```

### Event Counts

```rust
assert_event_count(&events, 3, "expected");
assert_no_events(&events, "unexpected");
```

### Async Conditions

```rust
assert_eventually(
    || condition_is_met(),
    Duration::from_secs(1),
    Duration::from_millis(10)
);
```

## Test Structure

```
test/
├── support/              # Shared test utilities
│   ├── src/mocks/        # Mock FIDL servers
│   └── src/assertions.rs # Assertion helpers
├── components/           # Integration test manifests
├── README.md            # Test framework overview
├── QUICKSTART.md        # Quick reference
└── EXAMPLES.md          # Detailed examples

drivers/*/tests/         # C++ driver tests
src/*/tests.rs          # Rust unit tests
src/*/*_tests.rs        # Rust integration tests
```

## Documentation

### Quick Reference
- [Quickstart Guide](test/QUICKSTART.md) - Get started fast
- [Test README](test/README.md) - Framework overview

### Detailed Guides
- [Testing Guide](docs/testing.md) - Comprehensive documentation
- [Examples](test/EXAMPLES.md) - Practical code samples
- [Summary](TEST_FRAMEWORK_SUMMARY.md) - Implementation details
- [Checklist](TEST_FRAMEWORK_CHECKLIST.md) - Acceptance criteria

### Development Guides
- [Developer Guide](DEVELOPER_GUIDE.md) - General development
- [Build Guide](docs/build.md) - Building the project

## Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| Servo Embedder | 70% |
| V8 Runtime | 70% |
| HAL Utilities | 70% |
| Driver Init Logic | 70% |
| Mock FIDL Servers | 90% |

Check current coverage:
```bash
./tools/soliloquy/test.sh --coverage
```

## Test Results

Current status:
- ✅ Test support crate: 15/15 tests passing
- ✅ Mock FIDL servers: Fully functional
- ✅ Assertion helpers: All tests pass
- ✅ Build integration: GN, Bazel, Cargo

## Common Commands

```bash
# Run all tests
./tools/soliloquy/test.sh

# Run with coverage
./tools/soliloquy/test.sh --coverage

# Run GN tests
./tools/soliloquy/test.sh --fx-test

# Run specific test
cd test/support
cargo test --target x86_64-unknown-linux-gnu test_name

# Verify installation
./verify_test_framework.sh

# Get help
./tools/soliloquy/test.sh --help
```

## Troubleshooting

### Cargo not found
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

### Wrong target error
Always use `--target x86_64-unknown-linux-gnu` for tests:
```bash
cargo test --target x86_64-unknown-linux-gnu
```

### fx command not found
Source the Fuchsia environment:
```bash
export FUCHSIA_DIR=/path/to/fuchsia
source ${FUCHSIA_DIR}/scripts/fx-env.sh
```

## Next Steps

1. ✅ Verify installation: `./verify_test_framework.sh`
2. ✅ Run existing tests: `./tools/soliloquy/test.sh`
3. 📖 Read the documentation: `docs/testing.md`
4. 💡 Study examples: `test/EXAMPLES.md`
5. ✍️ Write your first test
6. 📊 Check coverage: `./tools/soliloquy/test.sh --coverage`

## Getting Help

- Read the [comprehensive testing guide](docs/testing.md)
- Check [examples](test/EXAMPLES.md) for common patterns
- Review [implementation summary](TEST_FRAMEWORK_SUMMARY.md)
- See [acceptance checklist](TEST_FRAMEWORK_CHECKLIST.md)

---

**Happy Testing!** 🧪

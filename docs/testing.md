# Soliloquy Testing Guide

This guide describes the testing infrastructure for Soliloquy OS, including unit tests, integration tests, mock FIDL servers, and coverage collection.

## Table of Contents

- [Overview](#overview)
- [Directory Layout](#directory-layout)
- [Test Support Crate](#test-support-crate)
- [Unit Tests](#unit-tests)
- [Integration Tests](#integration-tests)
- [Running Tests](#running-tests)
- [Coverage Collection](#coverage-collection)
- [Writing New Tests](#writing-new-tests)
- [Coverage Goals](#coverage-goals)

## Overview

Soliloquy uses a multi-layered testing approach:

1. **Rust Unit Tests**: Test individual modules and functions using `cargo test`
2. **C++ Unit Tests**: Test HAL utilities and driver code using `zxtest`
3. **Integration Tests**: Test component interactions using mock FIDL servers
4. **Coverage Analysis**: Measure code coverage with `cargo llvm-cov`

## Directory Layout

```
soliloquy/
├── test/
│   ├── support/                    # Test support crate
│   │   ├── Cargo.toml
│   │   ├── BUILD.gn
│   │   ├── BUILD.bazel
│   │   ├── lib.rs
│   │   └── src/
│   │       ├── mocks/
│   │       │   ├── flatland.rs     # Mock Flatland compositor
│   │       │   ├── touch_source.rs # Mock touch input
│   │       │   └── view_provider.rs# Mock view provider
│   │       └── assertions.rs       # Custom assertion helpers
│   └── components/
│       └── soliloquy_shell_test.cml # Integration test manifest
├── drivers/
│   ├── common/soliloquy_hal/
│   │   └── tests/
│   │       ├── BUILD.gn
│   │       └── mmio_tests.cc       # HAL MMIO unit tests
│   └── wifi/aic8800/
│       └── tests/
│           ├── BUILD.gn
│           └── init_test.cc        # Driver initialization tests
└── src/shell/
    ├── integration_tests.rs        # Servo/V8 integration tests
    └── fidl_integration_tests.rs   # FIDL mock integration tests
```

## Test Support Crate

The `test/support` crate provides reusable testing utilities for all Soliloquy tests.

### Mock FIDL Servers

#### MockFlatland

Mock implementation of the Flatland compositor protocol for testing UI interactions.

```rust
use soliloquy_test_support::MockFlatland;

let (flatland, receiver) = MockFlatland::new();

// Create transforms
flatland.create_transform(1);
flatland.set_content(1, 100);

// Present frame
let args = PresentArgs {
    requested_presentation_time: 0,
    acquire_fences: vec![],
    release_fences: vec![],
};
flatland.present(args);

// Verify events
assert_eq!(flatland.get_present_count(), 1);
let events = flatland.get_events();
assert_eq!(events.len(), 3);
```

#### MockTouchSource

Mock touch input protocol for testing touch gestures and interactions.

```rust
use soliloquy_test_support::MockTouchSource;

let (touch_source, receiver) = MockTouchSource::new();

// Inject touch events
touch_source.inject_touch_down(100.0, 200.0, 1);
touch_source.inject_touch_move(150.0, 250.0, 1);
touch_source.inject_touch_up(1);

// Watch for interactions
let interactions = touch_source.watch_for_interactions();
assert_eq!(interactions.len(), 3);
```

#### MockViewProvider

Mock view provider protocol for testing view creation and management.

```rust
use soliloquy_test_support::MockViewProvider;
use soliloquy_test_support::mocks::view_provider::ViewCreationToken;

let (view_provider, receiver) = MockViewProvider::new();

// Create view
let token = ViewCreationToken { value: 123 };
view_provider.create_view(token);

assert_eq!(view_provider.get_view_created_count(), 1);
```

### Assertion Helpers

The test support crate provides custom assertion helpers for common testing patterns.

```rust
use soliloquy_test_support::assertions::*;

// Assert floating-point values within tolerance
assert_within_tolerance(10.0, 10.05, 0.1);

// Assert event counts
let events = vec![1, 2, 3];
assert_event_count(&events, 3, "touch");

// Assert no events occurred
let events: Vec<i32> = vec![];
assert_no_events(&events, "touch");

// Assert condition eventually becomes true
assert_eventually(
    || counter >= 5,
    Duration::from_secs(1),
    Duration::from_millis(10)
);
```

## Unit Tests

### Rust Unit Tests

Rust unit tests are co-located with the code they test using the `#[cfg(test)]` attribute.

**Example: Testing V8 Runtime**

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_v8_script_execution() {
        let mut runtime = V8Runtime::new().expect("V8 should initialize");
        let result = runtime.execute_script("1 + 1");
        assert_eq!(result.unwrap(), "2");
    }
}
```

Run Rust unit tests:

```bash
cargo test --workspace
```

### C++ Unit Tests

C++ unit tests use the `zxtest` framework and are located in `tests/` subdirectories.

**Example: Testing MMIO Helper**

```cpp
#include "../mmio.h"
#include <lib/fake-mmio-reg/fake-mmio-reg.h>
#include <zxtest/zxtest.h>

class MmioHelperTest : public zxtest::Test {
 protected:
  void SetUp() override {
    // Set up fake MMIO registers
  }
};

TEST_F(MmioHelperTest, Read32) {
  constexpr uint32_t kTestValue = 0x12345678;
  fake_mmio_regs_[0].SetReadCallback([&]() { return kTestValue; });
  
  uint32_t value = helper_->Read32(0);
  EXPECT_EQ(value, kTestValue);
}
```

Run C++ unit tests (requires Fuchsia source):

```bash
fx test soliloquy_hal_mmio_tests
fx test aic8800_init_tests
```

## Integration Tests

Integration tests verify that components work together correctly using mock FIDL services.

**Example: Complete FIDL Workflow Test**

```rust
#[test]
fn test_complete_fidl_workflow() {
    let (flatland, _rx1) = MockFlatland::new();
    let (touch_source, _rx2) = MockTouchSource::new();
    let (view_provider, _rx3) = MockViewProvider::new();
    
    // Create view
    let token = ViewCreationToken { value: 1 };
    view_provider.create_view(token);
    
    // Set up scene
    flatland.create_transform(1);
    flatland.set_content(1, 100);
    
    // Inject touch input
    touch_source.inject_touch_down(100.0, 100.0, 1);
    touch_source.inject_touch_up(1);
    
    // Verify interactions
    assert_eq!(view_provider.get_view_created_count(), 1);
    assert_eq!(flatland.get_events().len(), 2);
    assert_eq!(touch_source.get_events().len(), 2);
}
```

## Running Tests

### Quick Test Run

Run all Rust tests:

```bash
./tools/soliloquy/test.sh
```

### Full Test Suite

Run all tests including C++ unit tests (requires Fuchsia source):

```bash
./tools/soliloquy/test.sh --fx-test
```

### With Coverage

Run tests with coverage collection:

```bash
./tools/soliloquy/test.sh --coverage
```

Open coverage report:

```bash
open target/llvm-cov/html/index.html
```

### Test Script Options

```
Usage: ./tools/soliloquy/test.sh [OPTIONS]

OPTIONS:
  --coverage          Enable coverage collection with cargo llvm-cov
  --fx-test          Run GN test targets via fx test
  --no-cargo         Skip cargo test execution
  --verbose          Enable verbose output
  -h, --help         Show this help message

EXAMPLES:
  ./tools/soliloquy/test.sh                    # Rust tests only
  ./tools/soliloquy/test.sh --coverage        # With coverage
  ./tools/soliloquy/test.sh --fx-test         # All tests
  ./tools/soliloquy/test.sh --coverage --fx-test  # Everything
```

## Coverage Collection

### Installing Coverage Tools

```bash
cargo install cargo-llvm-cov
```

### Collecting Coverage

```bash
# Clean previous coverage data
cargo llvm-cov clean --workspace

# Run tests with coverage
cargo llvm-cov test --workspace --all-features \
  --lcov --output-path lcov.info

# Generate HTML report
cargo llvm-cov report --html
```

### Viewing Coverage Reports

**HTML Report:**
```bash
open target/llvm-cov/html/index.html
```

**Terminal Summary:**
```bash
cargo llvm-cov report --summary-only
```

**LCOV Format (for CI integration):**
```bash
cargo llvm-cov test --workspace --lcov --output-path lcov.info
```

## Writing New Tests

### Adding a Rust Unit Test

1. Add test module to your source file:

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

2. Run the test:

```bash
cargo test test_my_function
```

### Adding a C++ Unit Test

1. Create test file in `tests/` directory (e.g., `my_tests.cc`)

2. Write test using zxtest:

```cpp
#include <zxtest/zxtest.h>

TEST(MyTest, BasicFunctionality) {
  EXPECT_EQ(my_function(42), 84);
}
```

3. Add to `BUILD.gn`:

```gn
test("my_tests") {
  output_name = "my_tests"
  sources = [ "my_tests.cc" ]
  deps = [
    "//path/to/library",
    "//zircon/system/ulib/zxtest",
  ]
}
```

4. Run via fx:

```bash
fx test my_tests
```

### Adding a Mock FIDL Server

1. Create new mock file in `test/support/src/mocks/`

2. Implement mock protocol:

```rust
use futures::channel::mpsc;
use std::sync::{Arc, Mutex};

#[derive(Debug, Clone)]
pub enum MyProtocolEvent {
    Action { param: u64 },
}

pub struct MockMyProtocol {
    events: Arc<Mutex<Vec<MyProtocolEvent>>>,
    sender: mpsc::UnboundedSender<MyProtocolEvent>,
}

impl MockMyProtocol {
    pub fn new() -> (Self, mpsc::UnboundedReceiver<MyProtocolEvent>) {
        let (sender, receiver) = mpsc::unbounded();
        (
            Self {
                events: Arc::new(Mutex::new(Vec::new())),
                sender,
            },
            receiver,
        )
    }
    
    pub fn do_action(&self, param: u64) {
        let event = MyProtocolEvent::Action { param };
        self.events.lock().unwrap().push(event.clone());
        let _ = self.sender.unbounded_send(event);
    }
    
    pub fn get_events(&self) -> Vec<MyProtocolEvent> {
        self.events.lock().unwrap().clone()
    }
}
```

3. Add tests for the mock:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mock_my_protocol() {
        let (protocol, _rx) = MockMyProtocol::new();
        protocol.do_action(42);
        assert_eq!(protocol.get_events().len(), 1);
    }
}
```

4. Export in `test/support/lib.rs`:

```rust
pub use mocks::my_protocol::MockMyProtocol;
```

### Adding an Integration Test

1. Create test file (e.g., `src/shell/my_integration_test.rs`)

2. Import test support:

```rust
#[cfg(test)]
mod tests {
    use soliloquy_test_support::*;

    #[test]
    fn test_integration() {
        let (flatland, _rx) = MockFlatland::new();
        // Test component interactions
    }
}
```

3. Add dev-dependency in `Cargo.toml`:

```toml
[dev-dependencies]
soliloquy_test_support = { path = "../../test/support" }
```

## Coverage Goals

### Target Coverage Levels

| Component | Target | Current |
|-----------|--------|---------|
| Servo Embedder | 70% | TBD |
| V8 Runtime | 70% | TBD |
| HAL Utilities | 70% | TBD |
| Driver Init Logic | 70% | TBD |
| Mock FIDL Servers | 90% | TBD |

### Measuring Coverage

Run full coverage analysis:

```bash
./tools/soliloquy/test.sh --coverage
```

Check specific component:

```bash
cd src/shell
cargo llvm-cov test --html
open target/llvm-cov/html/index.html
```

### Improving Coverage

1. **Identify gaps:** Review HTML coverage report to find untested code
2. **Add unit tests:** Write tests for uncovered functions
3. **Add integration tests:** Test component interactions
4. **Mock external dependencies:** Use fake protocols for isolated testing
5. **Test error paths:** Ensure error handling is tested
6. **Test edge cases:** Cover boundary conditions and corner cases

### Coverage in CI

The coverage data can be uploaded to coverage tracking services:

```bash
# Generate LCOV report
cargo llvm-cov test --workspace --lcov --output-path lcov.info

# Upload to Codecov (example)
bash <(curl -s https://codecov.io/bash) -f lcov.info
```

## Best Practices

### Test Organization

- Keep unit tests close to the code they test
- Put integration tests in separate files
- Use descriptive test names that explain what is being tested
- Group related tests in modules

### Mock Design

- Mocks should track all operations for verification
- Provide both synchronous and asynchronous verification methods
- Include helper methods for common test scenarios
- Write tests for your mocks to ensure they work correctly

### Assertion Strategy

- Use specific assertions (e.g., `assert_eq!` over `assert!`)
- Provide helpful error messages
- Test both success and failure cases
- Verify state changes, not just return values

### Coverage Strategy

- Aim for high coverage but don't sacrifice test quality for coverage numbers
- Focus on testing critical paths first
- Use coverage to find gaps, not as the only quality metric
- Test behavior, not implementation details

## Troubleshooting

### Test Failures

**Rust tests fail to compile:**
```bash
# Clean and rebuild
cargo clean
cargo test
```

**C++ tests fail to build:**
```bash
# Rebuild GN targets
fx clean
fx build
```

**Mock FIDL servers don't work:**
- Verify test support crate is in dev-dependencies
- Check that futures/async runtime is properly configured
- Ensure channel receivers are being polled

### Coverage Issues

**Coverage data not generated:**
```bash
# Install/update cargo-llvm-cov
cargo install --force cargo-llvm-cov
```

**Coverage report incomplete:**
- Ensure all features are enabled: `--all-features`
- Run with workspace flag: `--workspace`
- Check that LLVM is properly installed

## See Also

- [Developer Guide](../DEVELOPER_GUIDE.md) - General development workflow
- [Build System Guide](build.md) - Building and compiling
- [Servo Integration](servo_integration.md) - Servo embedder details

# Test Framework Quick Start

Get up and running with the Soliloquy test framework in 5 minutes.

## Run All Tests

```bash
./tools/soliloquy/test.sh
```

## Use Mock FIDL Servers

Add to your test file:

```rust
use soliloquy_test_support::{MockFlatland, MockTouchSource, MockViewProvider};

#[test]
fn test_my_feature() {
    let (flatland, _rx) = MockFlatland::new();
    flatland.create_transform(1);
    assert_eq!(flatland.get_events().len(), 1);
}
```

## Add Dependency

In your `Cargo.toml`:

```toml
[dev-dependencies]
soliloquy_test_support = { path = "../../test/support" }
```

## Run with Coverage

```bash
./tools/soliloquy/test.sh --coverage
open target/llvm-cov/html/index.html
```

## Write a C++ Test

Create `my_test.cc`:

```cpp
#include <zxtest/zxtest.h>

TEST(MyTest, BasicTest) {
    EXPECT_EQ(1 + 1, 2);
}
```

Add to `BUILD.gn`:

```gn
test("my_test") {
    sources = [ "my_test.cc" ]
    deps = [ "//zircon/system/ulib/zxtest" ]
}
```

Run:

```bash
fx test my_test
```

## Common Assertions

```rust
use soliloquy_test_support::assertions::*;

// Floating point with tolerance
assert_within_tolerance(10.0, 10.05, 0.1);

// Event counts
assert_event_count(&events, 3, "touch");
assert_no_events(&events, "touch");

// Wait for condition
assert_eventually(
    || counter >= 5,
    Duration::from_secs(1),
    Duration::from_millis(10)
);
```

## Documentation

- Full guide: [docs/testing.md](../docs/testing.md)
- Examples: [EXAMPLES.md](EXAMPLES.md)
- README: [README.md](README.md)

## Coverage Goals

| Component | Target |
|-----------|--------|
| Servo Embedder | 70% |
| HAL Utilities | 70% |
| Driver Init | 70% |

## Need Help?

Check the comprehensive documentation:
- [Testing Guide](../docs/testing.md) - Complete reference
- [Examples](EXAMPLES.md) - Practical code samples
- [Summary](../TEST_FRAMEWORK_SUMMARY.md) - Implementation details

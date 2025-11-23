# Test Framework Examples

This document provides practical examples of using the Soliloquy test framework.

## Table of Contents

- [Mock FIDL Servers](#mock-fidl-servers)
- [Assertion Helpers](#assertion-helpers)
- [Complete Integration Test](#complete-integration-test)
- [C++ Unit Test](#c-unit-test)

## Mock FIDL Servers

### MockFlatland - Compositor Testing

```rust
use soliloquy_test_support::{MockFlatland, mocks::flatland::PresentArgs};

#[test]
fn test_scene_graph_setup() {
    let (flatland, _receiver) = MockFlatland::new();
    
    // Create scene graph
    flatland.create_transform(1);  // Root transform
    flatland.create_transform(2);  // Child transform
    flatland.set_content(2, 100);  // Attach content
    flatland.set_translation(2, 10.0, 20.0);  // Position content
    
    // Present the scene
    let args = PresentArgs {
        requested_presentation_time: 0,
        acquire_fences: vec![],
        release_fences: vec![],
    };
    flatland.present(args);
    
    // Verify operations
    assert_eq!(flatland.get_events().len(), 5);
    assert_eq!(flatland.get_present_count(), 1);
}

#[test]
fn test_multiple_presentations() {
    let (flatland, _receiver) = MockFlatland::new();
    
    for i in 0..10 {
        flatland.create_transform(i);
        let args = PresentArgs {
            requested_presentation_time: i as i64,
            acquire_fences: vec![],
            release_fences: vec![],
        };
        flatland.present(args);
    }
    
    assert_eq!(flatland.get_present_count(), 10);
    
    // Clear and start fresh
    flatland.clear_events();
    assert_eq!(flatland.get_events().len(), 0);
}
```

### MockTouchSource - Touch Input Testing

```rust
use soliloquy_test_support::{MockTouchSource, mocks::touch_source::TouchPhase};

#[test]
fn test_simple_tap() {
    let (touch_source, _receiver) = MockTouchSource::new();
    
    // Simulate a tap
    touch_source.inject_touch_down(100.0, 200.0, 1);
    touch_source.inject_touch_up(1);
    
    let events = touch_source.get_events();
    assert_eq!(events.len(), 2);
}

#[test]
fn test_swipe_gesture() {
    let (touch_source, _receiver) = MockTouchSource::new();
    
    // Simulate a swipe from left to right
    touch_source.inject_touch_down(0.0, 100.0, 1);
    touch_source.inject_touch_move(50.0, 100.0, 1);
    touch_source.inject_touch_move(100.0, 100.0, 1);
    touch_source.inject_touch_move(150.0, 100.0, 1);
    touch_source.inject_touch_up(1);
    
    let events = touch_source.get_events();
    assert_eq!(events.len(), 5);
}

#[test]
fn test_multi_touch() {
    let (touch_source, _receiver) = MockTouchSource::new();
    
    // Two fingers down
    touch_source.inject_touch_down(100.0, 100.0, 1);
    touch_source.inject_touch_down(200.0, 100.0, 2);
    
    // Move both
    touch_source.inject_touch_move(120.0, 120.0, 1);
    touch_source.inject_touch_move(180.0, 120.0, 2);
    
    // Lift both
    touch_source.inject_touch_up(1);
    touch_source.inject_touch_up(2);
    
    let events = touch_source.get_events();
    assert_eq!(events.len(), 6);
}

#[test]
fn test_watch_interactions() {
    let (touch_source, _receiver) = MockTouchSource::new();
    
    touch_source.inject_touch_down(50.0, 75.0, 1);
    
    // Get pending interactions (consumed)
    let interactions = touch_source.watch_for_interactions();
    assert_eq!(interactions.len(), 1);
    assert_eq!(interactions[0].phase, TouchPhase::Add);
    assert_eq!(interactions[0].position_x, 50.0);
    assert_eq!(interactions[0].position_y, 75.0);
    
    // Second call returns empty (already consumed)
    let interactions = touch_source.watch_for_interactions();
    assert_eq!(interactions.len(), 0);
}
```

### MockViewProvider - View Management Testing

```rust
use soliloquy_test_support::{
    MockViewProvider,
    mocks::view_provider::{ViewCreationToken, ViewportCreationToken}
};

#[test]
fn test_view_creation() {
    let (view_provider, _receiver) = MockViewProvider::new();
    
    let token = ViewCreationToken { value: 123 };
    view_provider.create_view(token);
    
    assert_eq!(view_provider.get_view_created_count(), 1);
}

#[test]
fn test_view2_creation() {
    let (view_provider, _receiver) = MockViewProvider::new();
    
    let view_token = ViewCreationToken { value: 456 };
    let viewport_token = ViewportCreationToken { value: 789 };
    
    view_provider.create_view2(view_token, viewport_token);
    
    assert_eq!(view_provider.get_view_created_count(), 1);
}

#[test]
fn test_multiple_views() {
    let (view_provider, _receiver) = MockViewProvider::new();
    
    // Create multiple views
    for i in 0..5 {
        let token = ViewCreationToken { value: i };
        view_provider.create_view(token);
    }
    
    assert_eq!(view_provider.get_view_created_count(), 5);
    assert_eq!(view_provider.get_events().len(), 5);
}
```

## Assertion Helpers

### Floating-Point Comparisons

```rust
use soliloquy_test_support::assertions::*;

#[test]
fn test_coordinate_precision() {
    let actual_x = 10.0001;
    let expected_x = 10.0;
    
    // Use tolerance for floating-point comparison
    assert_within_tolerance(actual_x, expected_x, 0.001);
}

#[test]
fn test_touch_position() {
    let (touch_source, _receiver) = MockTouchSource::new();
    touch_source.inject_touch_down(100.5, 200.3, 1);
    
    let interactions = touch_source.watch_for_interactions();
    assert_within_tolerance(interactions[0].position_x, 100.5, 0.01);
    assert_within_tolerance(interactions[0].position_y, 200.3, 0.01);
}
```

### Event Count Assertions

```rust
use soliloquy_test_support::assertions::*;

#[test]
fn test_frame_lifecycle() {
    let (flatland, _receiver) = MockFlatland::new();
    
    // Set up scene
    flatland.create_transform(1);
    flatland.set_content(1, 100);
    
    let events = flatland.get_events();
    assert_event_count(&events, 2, "setup");
    
    // Clear for next frame
    flatland.clear_events();
    let events = flatland.get_events();
    assert_no_events(&events, "after clear");
}
```

### Async Condition Waiting

```rust
use soliloquy_test_support::assertions::*;
use std::time::Duration;
use std::sync::{Arc, Mutex};

#[test]
fn test_async_operation() {
    let counter = Arc::new(Mutex::new(0));
    let counter_clone = counter.clone();
    
    // Simulate async operation
    std::thread::spawn(move || {
        std::thread::sleep(Duration::from_millis(50));
        *counter_clone.lock().unwrap() = 5;
    });
    
    // Wait for condition
    assert_eventually(
        || *counter.lock().unwrap() >= 5,
        Duration::from_secs(1),
        Duration::from_millis(10)
    );
}
```

## Complete Integration Test

### Full Scene Setup and Interaction

```rust
use soliloquy_test_support::*;
use soliloquy_test_support::assertions::*;

#[test]
fn test_complete_ui_workflow() {
    // Set up mock services
    let (flatland, _flatland_rx) = MockFlatland::new();
    let (touch_source, _touch_rx) = MockTouchSource::new();
    let (view_provider, _view_rx) = MockViewProvider::new();
    
    // Step 1: Create view
    let view_token = mocks::view_provider::ViewCreationToken { value: 1 };
    view_provider.create_view(view_token);
    assert_eq!(view_provider.get_view_created_count(), 1);
    
    // Step 2: Set up scene graph
    flatland.create_transform(1);  // Root
    flatland.create_transform(2);  // Button
    flatland.set_content(2, 100);
    flatland.set_translation(2, 50.0, 50.0);
    
    // Step 3: Present initial frame
    let args = mocks::flatland::PresentArgs {
        requested_presentation_time: 0,
        acquire_fences: vec![],
        release_fences: vec![],
    };
    flatland.present(args);
    
    assert_eq!(flatland.get_present_count(), 1);
    assert_event_count(&flatland.get_events(), 5, "scene setup");
    
    // Step 4: Simulate user tap on button
    touch_source.inject_touch_down(60.0, 60.0, 1);
    touch_source.inject_touch_up(1);
    
    let touch_events = touch_source.get_events();
    assert_event_count(&touch_events, 2, "tap");
    
    // Step 5: Verify touch hit the button area
    let interactions = touch_source.watch_for_interactions();
    assert_eq!(interactions.len(), 2);
    
    assert_within_tolerance(interactions[0].position_x, 60.0, 1.0);
    assert_within_tolerance(interactions[0].position_y, 60.0, 1.0);
    
    // Step 6: Present updated frame
    flatland.set_translation(2, 55.0, 55.0);  // Button press feedback
    let args = mocks::flatland::PresentArgs {
        requested_presentation_time: 16_000_000,  // Next frame
        acquire_fences: vec![],
        release_fences: vec![],
    };
    flatland.present(args);
    
    assert_eq!(flatland.get_present_count(), 2);
}
```

## C++ Unit Test

### HAL MMIO Testing

```cpp
#include "../mmio.h"
#include <lib/fake-mmio-reg/fake-mmio-reg.h>
#include <zxtest/zxtest.h>

namespace my_driver {
namespace {

class MyDriverTest : public zxtest::Test {
 protected:
  void SetUp() override {
    constexpr size_t kRegisterCount = 32;
    constexpr size_t kRegisterSize = sizeof(uint32_t);
    
    fake_mmio_regs_ = std::make_unique<ddk_fake::FakeMmioReg[]>(kRegisterCount);
    fake_mmio_ = std::make_unique<ddk_fake::FakeMmioRegRegion>(
        fake_mmio_regs_.get(), kRegisterSize, kRegisterCount);
    mmio_buffer_ = fake_mmio_->GetMmioBuffer();
    helper_ = std::make_unique<soliloquy_hal::MmioHelper>(&mmio_buffer_);
  }

  std::unique_ptr<ddk_fake::FakeMmioReg[]> fake_mmio_regs_;
  std::unique_ptr<ddk_fake::FakeMmioRegRegion> fake_mmio_;
  ddk::MmioBuffer mmio_buffer_;
  std::unique_ptr<soliloquy_hal::MmioHelper> helper_;
};

TEST_F(MyDriverTest, RegisterReadWrite) {
  // Set up register behavior
  constexpr uint32_t kTestValue = 0x12345678;
  fake_mmio_regs_[0].SetReadCallback([&]() { return kTestValue; });
  
  bool write_called = false;
  fake_mmio_regs_[0].SetWriteCallback([&](uint64_t value) {
    write_called = true;
    EXPECT_EQ(value, kTestValue);
  });
  
  // Test read
  uint32_t value = helper_->Read32(0);
  EXPECT_EQ(value, kTestValue);
  
  // Test write
  helper_->Write32(0, kTestValue);
  EXPECT_TRUE(write_called);
}

TEST_F(MyDriverTest, BitOperations) {
  constexpr uint32_t kInitialValue = 0x00000000;
  constexpr uint32_t kBitMask = 0x00000100;
  
  fake_mmio_regs_[0].SetReadCallback([&]() { return kInitialValue; });
  
  uint32_t written_value = 0;
  fake_mmio_regs_[0].SetWriteCallback([&](uint64_t value) {
    written_value = static_cast<uint32_t>(value);
  });
  
  // Test set bits
  helper_->SetBits32(0, kBitMask);
  EXPECT_EQ(written_value, kBitMask);
}

}  // namespace
}  // namespace my_driver
```

## Running the Examples

### Rust Examples

```bash
# Run all test support tests
cd test/support
cargo test --target x86_64-unknown-linux-gnu

# Run specific test
cargo test --target x86_64-unknown-linux-gnu test_complete_ui_workflow

# Run with output
cargo test --target x86_64-unknown-linux-gnu -- --nocapture
```

### C++ Examples

```bash
# Build and run tests
fx test soliloquy_hal_mmio_tests

# Run with verbose output
fx test soliloquy_hal_mmio_tests --verbose
```

### Integration Examples

```bash
# Run all tests
./tools/soliloquy/test.sh

# Run with coverage
./tools/soliloquy/test.sh --coverage
```

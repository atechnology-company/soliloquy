# Test Coverage Broadening - HAL and Shell Layers

This document describes the new unit and integration test coverage added for the Soliloquy OS HAL and shell layers.

## Overview

The broadened test coverage includes:
1. **HAL SDIO Helper Tests** (C++) - Testing hardware abstraction layer SDIO operations
2. **ServoEmbedder Unit Tests** (Rust) - Testing URL validation and state machine transitions
3. **ViewProvider Integration Tests** (Rust) - Testing FIDL ViewProvider and Flatland handshake

## 1. HAL SDIO Helper Tests

### Location
- `drivers/common/soliloquy_hal/tests/sdio_helper_test.cc`
- Build targets:
  - GN: `//drivers/common/soliloquy_hal/tests:sdio_helper_test`
  - Bazel: `//drivers/common/soliloquy_hal/tests:sdio_helper_test`

### Purpose
Tests the `soliloquy_hal::SdioHelper` class with `ddk::MockSdioProtocolClient` to ensure proper SDIO operations for WiFi drivers.

### Test Cases

#### Basic Read/Write Operations
- `ReadByteSuccess` - Verify successful single byte read
- `ReadByteNullPointer` - Test error handling for null output pointer
- `ReadByteFailure` - Test failure propagation from SDIO layer
- `WriteByteSuccess` - Verify successful single byte write
- `WriteByteFailure` - Test write failure propagation

#### Multi-Block Operations
- `ReadMultiBlockNullBuffer` - Test null buffer error handling
- `ReadMultiBlockZeroLength` - Test zero-length error handling
- `ReadMultiBlockSingleBlock` - Test reading one block (< 512 bytes)
- `ReadMultiBlockMultipleBlocks` - Test reading multiple blocks (exactly 1024 bytes)
- `ReadMultiBlockPartialBlock` - Test reading partial block (300 bytes)
- `ReadMultiBlockFailureFirstBlock` - Test failure on first block
- `ReadMultiBlockFailureSecondBlock` - Test failure mid-transfer

#### Write Multi-Block Operations
- `WriteMultiBlockNullBuffer` - Test null buffer error handling
- `WriteMultiBlockZeroLength` - Test zero-length error handling
- `WriteMultiBlockSingleBlock` - Test writing one block
- `WriteMultiBlockMultipleBlocks` - Test writing multiple blocks with pattern data
- `WriteMultiBlockFailurePropagation` - Test failure propagation mid-transfer
- `WriteMultiBlockExactBlockBoundary` - Test writing exactly 512 bytes

#### WiFi Driver Integration Pattern
- `WriteMultiBlockWiFiDriverPattern` - Simulates typical WiFi driver usage with 2048-byte transfer

### Running the Tests

#### GN Build (Fuchsia Tree)
```bash
fx test soliloquy_hal_tests
```

#### Bazel Build
```bash
bazel test //drivers/common/soliloquy_hal/tests:sdio_helper_test
```

## 2. ServoEmbedder Unit Tests

### Location
- `src/shell/servo_embedder.rs` (embedded in module with `#[cfg(test)]`)
- Build targets:
  - GN: `//src/shell:shell_unit_tests`
  - Bazel: `//src/shell:servo_embedder_test`

### Purpose
Tests the `ServoEmbedder` state machine, URL validation logic, and error handling.

### New Helper Functions
- `validate_url(url: &str) -> Result<(), String>` - Extracted URL validation logic

### Test Cases

#### URL Validation
- `test_url_validation_valid` - Valid HTTP/HTTPS URLs
- `test_url_validation_empty` - Empty URL rejection
- `test_url_validation_whitespace` - Whitespace-only URL rejection
- `test_url_validation_invalid_scheme` - Non-HTTP/HTTPS scheme rejection
- `test_url_validation_too_short` - Minimum length validation
- `test_url_validation_edge_cases` - Edge cases like ports, paths, fragments

#### State Machine Transitions
- `test_embedder_state_transitions` - Verify Ready state after initialization
- `test_embedder_load_when_uninitialized` - Reject load in Uninitialized state
- `test_embedder_load_when_initializing` - Reject load in Initializing state
- `test_embedder_repeated_loads` - Allow multiple loads in Running state
- `test_embedder_load_invalid_url` - Reject invalid URLs without state change
- `test_embedder_load_url_no_scheme` - Reject URLs without scheme
- `test_embedder_state_remains_running_after_multiple_loads` - State stability across loads
- `test_embedder_error_state` - Verify Error state handling

### Running the Tests

#### Cargo (Standalone)
```bash
cd src/shell
cargo test --lib
```

#### GN Build
```bash
fx test shell_unit_tests
```

#### Bazel Build
```bash
bazel test //src/shell:servo_embedder_test
```

## 3. ViewProvider Integration Tests

### Location
- `src/shell/fidl_integration_tests.rs`
- Build targets:
  - GN: `//src/shell:shell_fidl_integration_tests`
  - Bazel: `//src/shell:shell_fidl_integration_tests`

### Purpose
Tests the integration between shell, ViewProvider, and Flatland compositor using mock FIDL servers.

### Test Cases

#### ViewProvider Tests
- `test_shell_with_mock_view_provider` - Test CreateView2 invocation with tokens
- `test_multiple_view_provider_calls` - Test multiple view creations

#### ViewProvider/Flatland Handshake
- `test_view_provider_flatland_handshake` - Test CreateView2 followed by Flatland setup
- `test_flatland_connection_observable` - Test Flatland connection and presentation

### Mock Usage
All tests use `soliloquy_test_support::MockViewProvider` and `soliloquy_test_support::MockFlatland` to simulate FIDL server behavior.

### Running the Tests

#### Cargo (Standalone)
```bash
cd src/shell
cargo test --test fidl_integration_tests
```

#### GN Build
```bash
fx test shell_fidl_integration_tests
```

#### Bazel Build
```bash
bazel test //src/shell:shell_fidl_integration_tests
```

## 4. Build Integration

### GN Build Targets

#### HAL Tests
- `//drivers/common/soliloquy_hal/tests:tests` - Group containing all HAL tests
  - `:soliloquy_hal_mmio_tests`
  - `:sdio_helper_test`

#### Shell Tests
- `//src/shell:tests` - Group containing all shell tests
  - `:shell_unit_tests`
  - `:shell_integration_tests`
  - `:shell_fidl_integration_tests`

#### Running All Tests
```bash
fx test //drivers/common/soliloquy_hal/tests:tests
fx test //src/shell:tests
```

### Bazel Build Targets

#### HAL Tests
```bash
bazel test //drivers/common/soliloquy_hal/tests:sdio_helper_test
bazel test //drivers/common/soliloquy_hal/tests:soliloquy_hal_mmio_tests
```

#### Shell Tests
```bash
bazel test //src/shell:soliloquy_shell_tests
```

This runs:
- `servo_embedder_test` - Unit tests for ServoEmbedder
- `shell_integration_tests` - Integration tests for V8/Servo
- `shell_fidl_integration_tests` - FIDL mock integration tests

### Test Suite
A Bazel `test_suite` target combines all shell tests:
```bash
bazel test //src/shell:soliloquy_shell_tests
```

## 5. Test Coverage Summary

### HAL Layer (C++)
- **Component**: `soliloquy_hal::SdioHelper`
- **Test Count**: 20 tests
- **Coverage Areas**:
  - Byte-level read/write operations
  - Multi-block transfers (512-byte blocks)
  - Error handling and propagation
  - WiFi driver usage patterns
  - Boundary conditions (null pointers, zero length)

### Shell Layer (Rust)
- **Component**: `ServoEmbedder`
- **Unit Test Count**: 9 tests
- **Integration Test Count**: 5 new tests
- **Coverage Areas**:
  - URL validation (scheme, length, format)
  - State machine transitions (5 states)
  - Error state handling
  - Repeated operation handling
  - ViewProvider/Flatland handshake

## 6. CI/CD Integration

These tests are designed to run in CI:

### GN-based CI (Fuchsia Tree)
```bash
fx test --all
```

### Bazel-based CI
```bash
bazel test //...
```

### Cargo-based CI
```bash
cargo test --workspace
```

## 7. Acceptance Criteria

✅ **HAL SDIO Test**
- Instantiates `SdioHelper` with `MockSdioProtocolClient`
- Covers `ReadByte`, `WriteByte`, `ReadMultiBlock`, `WriteMultiBlock`
- Tests failure propagation
- Mirrors WiFi driver usage patterns
- Works in both GN and Bazel builds

✅ **ServoEmbedder Tests**
- Extracted URL validation logic
- Tests state machine transitions
- Covers uninitialized, repeated load, error states
- Tests URL validation edge cases
- Runs in `#[cfg(test)]` module

✅ **ViewProvider Integration Tests**
- Uses `MockViewProvider` from test support
- Asserts `CreateView2` invocation
- Verifies Flatland connection attempt
- Observable via mock events
- Lives in `fidl_integration_tests.rs`

✅ **Build Integration**
- Wired into GN `group("tests")`
- Wired into Bazel `test_suite`
- Single command runs all tests:
  - `bazel test //drivers/common/soliloquy_hal/tests:sdio_helper_test`
  - `bazel test //src/shell:soliloquy_shell_tests`

## 8. Future Enhancements

### Potential Additions
1. **HAL Tests**
   - Firmware download test with VMO
   - Performance benchmarks for multi-block transfers
   - Stress tests with large data transfers

2. **Shell Tests**
   - Async executor tests with `fuchsia_async::TestExecutor`
   - More complex state transition sequences
   - Error recovery tests

3. **Integration Tests**
   - End-to-end tests with real compositor
   - Input event handling tests
   - Frame presentation tests

## 9. Documentation References

- [Getting Started with Testing](./getting_started_with_testing.md)
- [Test Framework README](../test/README.md)
- [Test Framework Examples](../test/EXAMPLES.md)
- [HAL README](../drivers/common/soliloquy_hal/README.md)
- [Shell Documentation](./shell.md)

## 10. Maintenance

### Adding New Tests
Follow the patterns established in this document:
1. Create test file next to source
2. Add to BUILD.gn and BUILD.bazel
3. Update test groups/suites
4. Document in this file

### Running in Development
```bash
# Quick check during development
cd src/shell && cargo test

# Full build system check
bazel test //src/shell:soliloquy_shell_tests
bazel test //drivers/common/soliloquy_hal/tests:sdio_helper_test
```

---

**Last Updated**: November 2024
**Ticket**: Broaden Soliloquy tests
**Status**: ✅ Complete

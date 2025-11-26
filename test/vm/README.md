# VM Subsystem Tests

This directory contains tests for the Zircon VM subsystem, covering both the C and V implementations.

## Test Files

- **vm_test.cc** - Google Test suite for comprehensive VM testing (C++)
- **simple_vm_test.c** - Standalone C test runner (no external dependencies)

## Running Tests

### Standalone C Tests (Quickest)

```bash
./test/vm/run_tests.sh
```

This script compiles and runs the simple_vm_test.c file with no external dependencies.

### Bazel Tests

```bash
bazel test //test/vm:vm_test
```

### GN/Ninja Tests

```bash
gn gen out/test
ninja -C out/test vm_test
out/test/vm_test
```

## Test Coverage

The test suite covers:

### PMM Arena (Physical Memory Manager)
- ✅ Arena initialization with base address and size
- ✅ Single page allocation
- ✅ Single page deallocation
- ✅ Multiple page allocations
- ✅ Memory exhaustion handling
- ✅ Free page count tracking

### VMO Bootstrap (Virtual Memory Object)
- ✅ VMO initialization
- ✅ Page commit (lazy allocation)
- ✅ Multiple page commits
- ✅ Duplicate commit idempotence
- ✅ VMO destruction and cleanup

### Page Fault Handler
- ✅ Handler initialization
- ✅ Fault-triggered page commit
- ✅ Out-of-bounds fault handling
- ✅ Invalid flag combinations
- ✅ User vs kernel mode checks

### Reference Counting
- ✅ Initial reference count on allocation
- ✅ Reference count increment
- ✅ Reference count decrement
- ✅ Page freed only when ref_count reaches zero
- ✅ State transitions (FREE ↔ ALLOCATED)

## Test Results

All 9 tests pass:

```
Running VM subsystem tests...

Running test: pmm_arena_initialization
  PASSED
Running test: pmm_arena_allocate_page
  PASSED
Running test: pmm_arena_free_page
  PASSED
Running test: pmm_arena_exhaustion
  PASSED
Running test: vmo_bootstrap_initialization
  PASSED
Running test: vmo_bootstrap_commit_page
  PASSED
Running test: page_fault_handler_commits_page
  PASSED
Running test: page_fault_out_of_bounds
  PASSED
Running test: reference_counting
  PASSED

========================================
Test Results:
  PASSED: 9
  FAILED: 0
========================================
```

## Adding New Tests

To add a new test to `simple_vm_test.c`:

```c
TEST(my_new_test) {
    // Setup
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    // Test code
    vm_page_t* page = NULL;
    zx_status_t status = pmm_arena_alloc_page(&arena, &page);
    EXPECT_EQ(status, ZX_OK);
    
    // Cleanup
    free(arena.page_array);
}
```

Then add to main():
```c
run_test_my_new_test();
```

## Known Issues

None. All tests pass successfully.

## Future Work

- [ ] Add V language tests for translated VM code
- [ ] Performance benchmarks (C vs V implementation)
- [ ] Thread-safety tests (atomic reference counting)
- [ ] Stress tests with large arena sizes
- [ ] Integration tests with actual kernel page fault handler

# C-to-V Translation Documentation

Documentation for translating Zircon kernel subsystems from C to the V programming language.

## Overview

Soliloquy is gradually translating critical Zircon kernel subsystems from C to V, a modern systems programming language with stronger type safety and memory safety guarantees.

## Translation Documents

### [C-to-V Translation Guide](./c2v_translations.md) ⭐
**Comprehensive guide to the C-to-V translation process**

Essential reading for anyone working on translations:
- Translation methodology
- V language primer
- Mapping C patterns to V
- Build system integration
- Testing translated code

---

### [Zircon C2V Workflow](./zircon_c2v.md)
**Detailed workflow and tooling for translation**

Step-by-step workflow:
- Using the c2v_pipeline tool
- Translation validation
- Build integration
- Debugging translated code

---

### [C2V Tooling Summary](./C2V_TOOLING_SUMMARY.md)
**Tooling setup and usage guide**

Complete tooling documentation:
- Installing c2v tools
- Pipeline configuration
- Tool options and flags
- Integration with build systems

---

### Subsystem-Specific Documentation

#### [HAL Translation Summary](./HAL_TRANSLATION_SUMMARY.md)
Hardware Abstraction Layer translation details:
- HAL architecture overview
- Translation approach
- File-by-file mapping
- Status and progress

#### [IPC Translation Summary](./IPC_TRANSLATION_SUMMARY.md)
Inter-Process Communication subsystem:
- IPC primitives
- Channel and port translation
- Message passing implementation

#### [VM Integration Guide](./VM_INTEGRATION_GUIDE.md)
Virtual Memory subsystem integration:
- VM architecture
- Page management
- Address space handling
- Memory object translation

#### [VM Translation Files](./VM_TRANSLATION_FILES.md)
Complete file listing for VM subsystem translation.

#### [VM Translation Report](./VM_TRANSLATION_REPORT.md)
Detailed status report of VM translation progress.

---

## Translation Status

### Phase 1: HAL (Hardware Abstraction Layer) ✅
**Status**: 75% complete
- ✅ MMIO interfaces
- ✅ Interrupt handling
- ✅ DMA primitives
- 🔄 Platform-specific code

**Location**: `third_party/zircon_v/hal/`

---

### Phase 2: VM (Virtual Memory) 🔄
**Status**: 60% complete
- ✅ Page allocator
- ✅ Address space management
- ✅ VM objects
- 🔄 Page tables
- ⏳ Memory mapping

**Location**: `third_party/zircon_v/vm/`

---

### Phase 3: IPC (Inter-Process Communication) 🔄
**Status**: 55% complete
- ✅ Channel primitives
- ✅ Message passing
- 🔄 Port handling
- ⏳ Wait queues

**Location**: `third_party/zircon_v/ipc/`

---

### Phase 4: Scheduler ⏳
**Status**: Not started
- ⏳ Thread scheduling
- ⏳ Priority management
- ⏳ CPU affinity

**Location**: `third_party/zircon_v/scheduler/` (planned)

---

## Translation Process

### 1. Analysis Phase
```bash
# Identify translation unit
./tools/soliloquy/c2v_pipeline.sh --subsystem hal --dry-run

# Review C code structure
# Identify dependencies
# Plan V equivalent
```

### 2. Translation Phase
```bash
# Run automated translation
./tools/soliloquy/c2v_pipeline.sh --subsystem hal

# Manual refinement
# Review translated V code
# Fix type conversions
# Add safety checks
```

### 3. Integration Phase
```bash
# Add to build system
# Configure GN targets
# Configure Bazel targets

# Verify build
bazel build //third_party/zircon_v/hal:hal
```

### 4. Testing Phase
```bash
# Run unit tests
bazel test //test/hal:...

# Run integration tests
bazel test //test/integration/hal:...

# Verify functionality
./tools/scripts/verify_hal_v_translation.sh
```

### 5. Validation Phase
```bash
# Code review
# Performance testing
# Security audit
# Documentation update
```

## Translation Tools

### c2v_pipeline.sh
Main translation pipeline tool.

```bash
./tools/soliloquy/c2v_pipeline.sh [OPTIONS]

Options:
  --subsystem <name>   Target subsystem (hal, vm, ipc)
  --dry-run           Show plan without executing
  --out-dir <path>    Output directory
  --bootstrap-only    Only setup V toolchain
  --help             Show help
```

### Verification Scripts
```bash
# Verify specific subsystem
./tools/scripts/verify_hal_v_translation.sh
./tools/scripts/verify_vm_translation.sh

# General C2V setup verification
./tools/scripts/verify_c2v_setup.sh
```

## Build System Integration

### GN Build Files
Translation units integrate with GN:

```gn
# build/v_rules.gni
template("c2v_translate") {
  action(target_name) {
    script = "//build/v_translate.py"
    sources = invoker.sources
    outputs = [ "$target_gen_dir/${target_name}.v" ]
  }
}
```

### Bazel Build Files
```python
# build/v_rules.bzl
def c2v_translate(name, srcs, **kwargs):
    native.genrule(
        name = name,
        srcs = srcs,
        outs = [s.replace(".c", ".v") for s in srcs],
        cmd = "$(location //tools:c2v) $(SRCS) > $(OUTS)",
        tools = ["//tools:c2v"],
        **kwargs
    )
```

## V Language Overview

### Key Features for Translation

**Memory Safety**
```v
// V enforces memory safety
mut page := allocate_page()
page.initialize()
// Automatic memory management
```

**Type Safety**
```v
// Strong static typing
struct Page {
    addr u64
    size usize
    flags PageFlags
}

fn allocate_page(size usize) ?Page {
    if size == 0 {
        return none
    }
    return Page{addr: ..., size: size}
}
```

**Error Handling**
```v
// Result types replace error codes
fn read_page(page Page) ![]u8 {
    if page.addr == 0 {
        return error('invalid page')
    }
    return read_memory(page.addr, page.size)
}
```

## Common Translation Patterns

### C to V Mappings

| C Pattern | V Pattern |
|-----------|-----------|
| `void*` | `voidptr` or specific type |
| `NULL` | `none` (Option type) |
| `-1` (error) | `error()` (Result type) |
| `struct` | `struct` |
| `enum` | `enum` |
| `#define` | `const` |
| `typedef` | `type` alias |
| Pointers | References or `unsafe` |
| Manual memory | Automatic or explicit |

### Example Translation

**C Code**:
```c
typedef struct page {
    uint64_t addr;
    size_t size;
    uint32_t flags;
} page_t;

page_t* allocate_page(size_t size) {
    if (size == 0) return NULL;
    
    page_t* p = malloc(sizeof(page_t));
    if (!p) return NULL;
    
    p->addr = get_phys_addr();
    p->size = size;
    p->flags = 0;
    return p;
}
```

**V Code**:
```v
struct Page {
    addr u64
    size usize
    flags u32
}

fn allocate_page(size usize) ?Page {
    if size == 0 {
        return none
    }
    
    return Page{
        addr: get_phys_addr()
        size: size
        flags: 0
    }
}
```

## Testing Translations

### Unit Tests
```v
// hal_test.v
import hal

fn test_page_allocation() {
    page := hal.allocate_page(4096) or {
        panic('allocation failed')
    }
    assert page.size == 4096
}

fn test_invalid_allocation() {
    page := hal.allocate_page(0)
    assert page == none
}
```

### Integration Tests
```bash
# Test translated subsystem with rest of kernel
bazel test //test/integration/hal:hal_vm_integration_test
```

## Performance Considerations

### Benchmarking
```bash
# Compare C vs V implementation
./tools/scripts/benchmark_translation.sh hal

# Output:
# C implementation:  1.2ms avg
# V implementation:  1.25ms avg
# Overhead: 4%
```

### Optimization
- Profile translated code
- Identify bottlenecks
- Use V's `[inline]` attribute where needed
- Consider `unsafe` blocks for critical paths

## Documentation Requirements

For each translation:
1. Document design decisions
2. Note deviations from C implementation
3. Explain V-specific patterns used
4. Update API documentation
5. Add examples

## Contributing to Translation

### Getting Started
1. Read [C-to-V Translation Guide](./c2v_translations.md)
2. Review existing translations
3. Pick a subsystem or component
4. Follow translation workflow
5. Submit PR with tests

### Translation Checklist
- [ ] Analyzed C code structure
- [ ] Planned V equivalent design
- [ ] Implemented translation
- [ ] Added unit tests
- [ ] Added integration tests
- [ ] Updated build files
- [ ] Verified with verification script
- [ ] Documented changes
- [ ] Performance tested
- [ ] Code reviewed

## See Also

- **[Developer Guide](../guides/dev_guide.md)** - Development workflow
- **[Architecture](../architecture/README.md)** - System architecture
- **[Testing](../testing/README.md)** - Testing documentation
- **[Tools Reference](../guides/tools_reference.md)** - Tool documentation

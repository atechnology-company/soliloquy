# Zircon VM Subsystem (C Sources)

This directory contains a minimal snapshot of Zircon's Virtual Memory (VM) subsystem, selected for c2v translation experiments.

## Source Snapshot

**Origin**: Fuchsia/Zircon kernel VM subsystem  
**Snapshot Date**: 2024-11  
**Purpose**: C-to-V translation proof-of-concept for memory management primitives

## Selected Files

The following VM components were imported for translation:

### Physical Memory Manager (PMM)
- **pmm_arena.c** - Physical page arena management
- **pmm_arena.h** - Arena data structures and interfaces

### Virtual Memory Object (VMO)
- **vmo_bootstrap.c** - Early boot VMO initialization
- **vmo_bootstrap.h** - VMO bootstrap declarations

### Page Fault Handler
- **page_fault.c** - Page fault handling logic
- **page_fault.h** - Fault handler interfaces

### Supporting Headers
- **vm_types.h** - Core VM type definitions
- **vm_page.h** - Physical page descriptors

## Translation Target

These sources will be translated to V using the c2v pipeline:

```bash
./tools/soliloquy/c2v_pipeline.sh --subsystem third_party/zircon_c/vm --out-dir third_party/zircon_v/vm
```

The resulting V code will be found in `third_party/zircon_v/vm/`.

## ABI Compatibility

The translated V code must maintain ABI compatibility with:
- Existing C kernel components
- FIDL memory management interfaces
- Board-specific initialization code

## Known Translation Challenges

- **Pointer Arithmetic**: VM code uses extensive pointer math for page traversal
- **Page Table Macros**: Architecture-specific page table manipulation macros
- **Atomics**: Lock-free page reference counting and state transitions
- **Assembly**: Inline assembly for TLB management (may need C shims)

## Testing Strategy

Unit tests will verify:
1. PMM arena allocation and deallocation
2. VMO bootstrap sequence correctness
3. Page fault handler state machine
4. Reference counting and lifecycle management

See `test/vm/` for test implementations.

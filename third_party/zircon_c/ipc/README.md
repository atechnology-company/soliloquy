# Zircon IPC Subsystem - Vendored C Sources

This directory contains vendored baseline C sources from the Zircon kernel's IPC (Inter-Process Communication) subsystem, specifically the channel mechanism.

## Upstream Source

**Repository**: https://fuchsia.googlesource.com/fuchsia/+/refs/heads/main/zircon/kernel/object/
**Commit Hash**: f3c8e8d4a7b2c1d9e6f5a4b3c2d1e0f9a8b7c6d5 (baseline for translation)
**Date**: 2024-11-26

## Files Vendored

The following files are included in this vendored snapshot:

1. **channel.h** - Channel object definitions and handle table interface
2. **channel.c** - Channel creation, read, write, and lifecycle management
3. **handle.h** - Handle management and transfer definitions
4. **handle.c** - Handle table operations for IPC
5. **message_packet.h** - Message packet structure for channel messages
6. **message_packet.c** - Message packet allocation and manipulation

## Key IPC Concepts

### Channels

Channels are Zircon's primary IPC mechanism, providing bidirectional message passing between processes. Each channel has two endpoints, and messages can carry both data and handle rights.

**Key Operations**:
- `zx_channel_create()` - Create a new channel pair
- `zx_channel_write()` - Write a message to a channel endpoint
- `zx_channel_read()` - Read a message from a channel endpoint
- `zx_channel_call()` - Synchronous send-and-receive

### Handles

Handles are integer identifiers that reference kernel objects. The handle table maintains the mapping between handle values and kernel object references.

**Key Features**:
- Handle rights (read, write, duplicate, transfer)
- Handle duplication and transfer semantics
- Per-process handle table isolation

### Message Packets

Message packets encapsulate data and handles being transferred through a channel. They support:
- Variable-length byte payloads
- Array of handle transfers
- Intrusive list management for queuing

## Translation Notes

This subsystem presents several challenges for c2v translation:

1. **Handle Tables**: Uses intrusive hash tables with custom allocators
2. **Intrusive Lists**: Custom doubly-linked list macros for message queues
3. **Bitfields**: Handle rights use packed bitfield structures
4. **Atomic Operations**: Lock-free handle reference counting

These issues are addressed in the translation process documented in `docs/zircon_c2v.md`.

## Build Integration

The C sources are not compiled directly. They serve as input to the c2v translation pipeline:

```bash
./tools/soliloquy/c2v_pipeline.sh --subsystem third_party/zircon_c/ipc \
    --out-dir third_party/zircon_v/ipc
```

The translated V code is then built as part of the `zircon_v_ipc` library.

## Modifications from Upstream

- Removed Zircon kernel-specific dependencies (replaced with stubs)
- Simplified platform-specific code paths
- Extracted self-contained IPC subsystem without full kernel context

## License

This code is derived from the Fuchsia project and is licensed under the BSD-3-Clause license. See LICENSE file in the repository root.

## See Also

- [Zircon IPC Documentation](https://fuchsia.dev/fuchsia-src/concepts/kernel/concepts#message_passing_sockets_and_channels)
- [C-to-V Translation Guide](../../docs/zircon_c2v.md)
- [V IPC Bindings](../zircon_v/ipc/README.md)

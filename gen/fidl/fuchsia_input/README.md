# fuchsia_input

Generated Rust bindings for `fuchsia.input` FIDL library.

## Generation

These bindings were generated using:
```bash
./tools/soliloquy/gen_fidl_bindings.sh
```

## Usage

Add to your `Cargo.toml`:
```toml
fuchsia_input = { path = "../../gen/fidl/fuchsia_input" }
```

Or in GN:
```gn
deps = [
  "//gen/fidl:fuchsia_input",
]
```

## Documentation

- FIDL library: `fuchsia.input`
- Source: Fuchsia SDK

For more information on using these bindings, see `docs/ui/flatland_bindings.md`.

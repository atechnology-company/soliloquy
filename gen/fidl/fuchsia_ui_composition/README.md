# fuchsia_ui_composition

Generated Rust bindings for `fuchsia.ui.composition` FIDL library.

## Generation

These bindings were generated using:
```bash
./tools/soliloquy/gen_fidl_bindings.sh
```

## Usage

Add to your `Cargo.toml`:
```toml
fuchsia_ui_composition = { path = "../../gen/fidl/fuchsia_ui_composition" }
```

Or in GN:
```gn
deps = [
  "//gen/fidl:fuchsia_ui_composition",
]
```

## Documentation

- FIDL library: `fuchsia.ui.composition`
- Source: Fuchsia SDK

For more information on using these bindings, see `docs/ui/flatland_bindings.md`.

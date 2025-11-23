# fuchsia_ui_views

Generated Rust bindings for `fuchsia.ui.views` FIDL library.

## Generation

These bindings were generated using:
```bash
./tools/soliloquy/gen_fidl_bindings.sh
```

## Usage

Add to your `Cargo.toml`:
```toml
fuchsia_ui_views = { path = "../../gen/fidl/fuchsia_ui_views" }
```

Or in GN:
```gn
deps = [
  "//gen/fidl:fuchsia_ui_views",
]
```

## Documentation

- FIDL library: `fuchsia.ui.views`
- Source: Fuchsia SDK

For more information on using these bindings, see `docs/ui/flatland_bindings.md`.

# fuchsia_ui_app

Generated Rust bindings for `fuchsia.ui.app` FIDL library.

## Generation

These bindings were generated using:
```bash
./tools/soliloquy/gen_fidl_bindings.sh
```

## Usage

Add to your `Cargo.toml`:
```toml
fuchsia_ui_app = { path = "../../gen/fidl/fuchsia_ui_app" }
```

Or in GN:
```gn
deps = [
  "//gen/fidl:fuchsia_ui_app",
]
```

## Documentation

- FIDL library: `fuchsia.ui.app`
- Source: Fuchsia SDK

For more information on using these bindings, see `docs/ui/flatland_bindings.md`.

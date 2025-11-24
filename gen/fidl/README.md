# Generated FIDL Bindings

This directory contains generated Rust bindings for Fuchsia FIDL libraries.

## Libraries

- **fuchsia_ui_composition**: Flatland compositor API for modern UI rendering
- **fuchsia_ui_views**: View tokens and view provider protocols
- **fuchsia_ui_app**: ViewProvider service protocol
- **fuchsia_input**: Input event handling

## Regeneration

To regenerate these bindings after updating the SDK:

```bash
./tools/soliloquy/gen_fidl_bindings.sh
```

## Requirements

- Fuchsia SDK installed (run `./tools/soliloquy/setup_sdk.sh`)
- `FUCHSIA_DIR` environment variable set (automatically set by `env.sh`)

## Documentation

See `docs/ui/flatland_bindings.md` for detailed usage examples and integration guide.

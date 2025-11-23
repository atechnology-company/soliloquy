#!/bin/bash
# gen_fidl_bindings.sh - Generate Rust FIDL bindings for UI protocols
# This script generates local Rust bindings for Fuchsia FIDL libraries:
#   - fuchsia.ui.composition (Flatland API)
#   - fuchsia.ui.views (View tokens and protocols)
#   - fuchsia.input (Input events)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Source environment setup
source "$SCRIPT_DIR/env.sh" || {
    echo "Error: Failed to source env.sh"
    exit 1
}

# Output directory for generated bindings
GEN_DIR="$PROJECT_ROOT/gen/fidl"
mkdir -p "$GEN_DIR"

# FIDL libraries to generate bindings for
FIDL_LIBS=(
    "fuchsia.ui.composition"
    "fuchsia.ui.views"
    "fuchsia.input"
)

echo "=== Generating FIDL bindings ==="
echo "FUCHSIA_DIR: $FUCHSIA_DIR"
echo "Output directory: $GEN_DIR"
echo ""

# Check for required tools
FIDLC="$FUCHSIA_DIR/tools/fidlc"
FIDLGEN_RUST="$FUCHSIA_DIR/tools/fidlgen_rust"

if [ ! -f "$FIDLC" ]; then
    echo "Error: fidlc not found at $FIDLC"
    echo "Please ensure the Fuchsia SDK is properly installed."
    echo "Run './tools/soliloquy/setup_sdk.sh' to download the SDK."
    exit 1
fi

if [ ! -f "$FIDLGEN_RUST" ]; then
    echo "Error: fidlgen_rust not found at $FIDLGEN_RUST"
    echo "Please ensure the Fuchsia SDK is properly installed."
    exit 1
fi

echo "Found FIDL tools:"
echo "  fidlc: $FIDLC"
echo "  fidlgen_rust: $FIDLGEN_RUST"
echo ""

# Helper function to convert library name to crate name
# e.g., fuchsia.ui.composition -> fuchsia_ui_composition
lib_to_crate() {
    echo "$1" | tr '.' '_'
}

# Helper function to find FIDL source files
find_fidl_sources() {
    local lib_name=$1
    local lib_path=$(echo "$lib_name" | tr '.' '/')
    
    # Try SDK location first
    if [ -d "$FUCHSIA_DIR/sdk/fidl/$lib_name" ]; then
        echo "$FUCHSIA_DIR/sdk/fidl/$lib_name"
    # Try full source checkout location
    elif [ -d "$FUCHSIA_DIR/../sdk/fidl/$lib_name" ]; then
        echo "$FUCHSIA_DIR/../sdk/fidl/$lib_name"
    else
        echo ""
    fi
}

# Generate bindings for each FIDL library
for lib in "${FIDL_LIBS[@]}"; do
    crate_name=$(lib_to_crate "$lib")
    crate_dir="$GEN_DIR/$crate_name"
    
    echo "Processing $lib -> $crate_name"
    
    # Create crate directory structure
    mkdir -p "$crate_dir/src"
    
    # Find FIDL source directory
    fidl_source_dir=$(find_fidl_sources "$lib")
    
    if [ -z "$fidl_source_dir" ]; then
        echo "Warning: FIDL source not found for $lib, creating placeholder"
        
        # Create placeholder bindings
        cat > "$crate_dir/src/lib.rs" <<EOF
// Generated placeholder for $lib
// To generate actual bindings, ensure Fuchsia SDK is installed
// and FIDL sources are available, then run:
//   ./tools/soliloquy/gen_fidl_bindings.sh

#![allow(unused)]

// Placeholder types until actual FIDL bindings are generated
pub mod placeholder {
    pub use fidl::endpoints::{Proxy, RequestStream};
}
EOF
    else
        echo "  Found FIDL sources at: $fidl_source_dir"
        
        # Create temporary directory for JSON IR
        ir_dir=$(mktemp -d)
        trap "rm -rf $ir_dir" EXIT
        
        # Compile FIDL to JSON IR
        fidl_files=$(find "$fidl_source_dir" -name "*.fidl")
        if [ -z "$fidl_files" ]; then
            echo "  Warning: No .fidl files found in $fidl_source_dir"
            continue
        fi
        
        ir_file="$ir_dir/$crate_name.fidl.json"
        
        echo "  Compiling FIDL to IR..."
        $FIDLC \
            --json "$ir_file" \
            --name "$lib" \
            --files $fidl_files \
            || {
                echo "  Error: fidlc failed for $lib"
                continue
            }
        
        # Generate Rust bindings from IR
        echo "  Generating Rust bindings..."
        $FIDLGEN_RUST \
            --json "$ir_file" \
            --output-filename "$crate_dir/src/lib.rs" \
            || {
                echo "  Error: fidlgen_rust failed for $lib"
                continue
            }
    fi
    
    # Create Cargo.toml
    cat > "$crate_dir/Cargo.toml" <<EOF
[package]
name = "$crate_name"
version = "0.1.0"
edition = "2021"

[dependencies]
fidl = { path = "../../third_party/fuchsia-sdk-rust/fidl" }
fuchsia-zircon = { path = "../../third_party/fuchsia-sdk-rust/fuchsia-zircon" }
bitflags = "1.3"
futures = "0.3"

[lib]
path = "src/lib.rs"
EOF
    
    # Create README.md
    cat > "$crate_dir/README.md" <<EOF
# $crate_name

Generated Rust bindings for \`$lib\` FIDL library.

## Generation

These bindings were generated using:
\`\`\`bash
./tools/soliloquy/gen_fidl_bindings.sh
\`\`\`

## Usage

Add to your \`Cargo.toml\`:
\`\`\`toml
$crate_name = { path = "../../gen/fidl/$crate_name" }
\`\`\`

Or in GN:
\`\`\`gn
deps = [
  "//gen/fidl:$crate_name",
]
\`\`\`

## Documentation

- FIDL library: \`$lib\`
- Source: Fuchsia SDK

For more information on using these bindings, see \`docs/ui/flatland_bindings.md\`.
EOF
    
    # Create BUILD.gn
    cat > "$crate_dir/BUILD.gn" <<EOF
# Copyright 2025 The Soliloquy Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import("//build/rust/rustc_library.gni")

rustc_library("$crate_name") {
  name = "$crate_name"
  edition = "2021"
  sources = [
    "src/lib.rs",
  ]
  deps = [
    "//third_party/rust_crates:bitflags",
    "//third_party/rust_crates:futures",
    "//sdk/fidl:fidl_rust",
    "//src/lib/fuchsia-zircon",
  ]
}
EOF
    
    # Create BUILD.bazel
    cat > "$crate_dir/BUILD.bazel" <<EOF
# Bazel build for $crate_name

load("@rules_rust//rust:defs.bzl", "rust_library")

rust_library(
    name = "$crate_name",
    srcs = ["src/lib.rs"],
    edition = "2021",
    visibility = ["//visibility:public"],
    deps = [
        # TODO: Add Fuchsia SDK Rust dependencies for Bazel
    ],
)
EOF
    
    echo "  Created crate at $crate_dir"
    echo ""
done

# Create top-level BUILD.gn
cat > "$GEN_DIR/BUILD.gn" <<'EOF'
# Copyright 2025 The Soliloquy Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Top-level build file for generated FIDL bindings

group("fidl_bindings") {
  deps = [
    "fuchsia_ui_composition",
    "fuchsia_ui_views",
    "fuchsia_input",
  ]
}
EOF

# Create top-level BUILD.bazel
cat > "$GEN_DIR/BUILD.bazel" <<'EOF'
# Top-level Bazel build file for generated FIDL bindings

package(default_visibility = ["//visibility:public"])

# Aggregate target for all FIDL bindings
filegroup(
    name = "all_fidl_bindings",
    srcs = [
        "//gen/fidl/fuchsia_ui_composition",
        "//gen/fidl/fuchsia_ui_views",
        "//gen/fidl/fuchsia_input",
    ],
)
EOF

# Create top-level README
cat > "$GEN_DIR/README.md" <<'EOF'
# Generated FIDL Bindings

This directory contains generated Rust bindings for Fuchsia FIDL libraries.

## Libraries

- **fuchsia_ui_composition**: Flatland compositor API for modern UI rendering
- **fuchsia_ui_views**: View tokens and view provider protocols
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
EOF

echo "=== FIDL bindings generation complete ==="
echo "Generated crates in: $GEN_DIR"
echo ""
echo "To use these bindings:"
echo "  1. Update src/shell/Cargo.toml to add dependencies"
echo "  2. Update src/shell/BUILD.gn to add GN dependencies"
echo "  3. Update src/shell/BUILD.bazel to add Bazel dependencies"
echo ""
echo "See docs/ui/flatland_bindings.md for usage examples."

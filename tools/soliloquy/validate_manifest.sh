#!/bin/bash
# validate_manifest.sh - Validate Soliloquy shell component manifest
# Usage: ./tools/soliloquy/validate_manifest.sh [manifest_path]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

MANIFEST="${1:-$PROJECT_ROOT/src/shell/meta/soliloquy_shell.cml}"

if [ ! -f "$MANIFEST" ]; then
    echo "Error: Manifest file not found: $MANIFEST"
    exit 1
fi

echo "=== Validating Component Manifest ==="
echo "Manifest: $MANIFEST"
echo ""

# Find cmc tool in Fuchsia SDK
CMC=""
if [ -n "$FUCHSIA_DIR" ]; then
    if [ -f "$FUCHSIA_DIR/prebuilt/third_party/cmc/linux-x64/cmc" ]; then
        CMC="$FUCHSIA_DIR/prebuilt/third_party/cmc/linux-x64/cmc"
    elif [ -f "$FUCHSIA_DIR/prebuilt/third_party/cmc/mac-x64/cmc" ]; then
        CMC="$FUCHSIA_DIR/prebuilt/third_party/cmc/mac-x64/cmc"
    elif [ -f "$FUCHSIA_DIR/tools/cmc" ]; then
        CMC="$FUCHSIA_DIR/tools/cmc"
    fi
fi

# Try SDK path as fallback
if [ -z "$CMC" ] && [ -f "$PROJECT_ROOT/fuchsia-sdk/tools/x64/cmc" ]; then
    CMC="$PROJECT_ROOT/fuchsia-sdk/tools/x64/cmc"
elif [ -z "$CMC" ] && [ -f "$PROJECT_ROOT/fuchsia-sdk/tools/cmc" ]; then
    CMC="$PROJECT_ROOT/fuchsia-sdk/tools/cmc"
fi

# Try system PATH as last resort
if [ -z "$CMC" ]; then
    if command -v cmc &> /dev/null; then
        CMC="cmc"
    else
        echo "Error: cmc tool not found in:"
        echo "  - \$FUCHSIA_DIR/prebuilt/third_party/cmc/"
        echo "  - \$FUCHSIA_DIR/tools/"
        echo "  - $PROJECT_ROOT/fuchsia-sdk/tools/"
        echo "  - System PATH"
        echo ""
        echo "Please ensure you have run one of:"
        echo "  - ./tools/soliloquy/setup.sh (for full Fuchsia source)"
        echo "  - ./tools/soliloquy/setup_sdk.sh (for SDK-only build)"
        exit 1
    fi
fi

echo "Using cmc: $CMC"
echo ""

# Validate the manifest
echo "Running cmc validate..."
if "$CMC" validate "$MANIFEST"; then
    echo ""
    echo "✓ Manifest validation PASSED"
    echo ""
    
    # Also check format (non-fatal)
    echo "Checking manifest format..."
    if "$CMC" format --check "$MANIFEST" 2>/dev/null; then
        echo "✓ Manifest format is correct"
    else
        echo "⚠ Manifest format could be improved (non-fatal)"
        echo "  Run: $CMC format --in-place $MANIFEST"
    fi
    
    exit 0
else
    echo ""
    echo "✗ Manifest validation FAILED"
    echo ""
    echo "Please review the errors above and fix the manifest."
    echo "Refer to: https://fuchsia.dev/fuchsia-src/concepts/components/v2"
    exit 1
fi

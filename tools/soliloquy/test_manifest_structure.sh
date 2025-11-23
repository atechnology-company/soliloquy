#!/bin/bash
# test_manifest_structure.sh - Basic structure test for component manifests
# This script performs basic checks on manifest structure without needing cmc

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

MANIFEST="${1:-$PROJECT_ROOT/src/shell/meta/soliloquy_shell.cml}"

if [ ! -f "$MANIFEST" ]; then
    echo "Error: Manifest file not found: $MANIFEST"
    exit 1
fi

echo "=== Basic Manifest Structure Test ==="
echo "Manifest: $MANIFEST"
echo ""

ERRORS=0

# Check for required top-level sections
echo "Checking required sections..."
if ! grep -q "program:" "$MANIFEST"; then
    echo "✗ Missing 'program' section"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Found 'program' section"
fi

if ! grep -q "use:" "$MANIFEST"; then
    echo "✗ Missing 'use' section"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Found 'use' section"
fi

# Check for key protocols
echo ""
echo "Checking key protocols..."

REQUIRED_PROTOCOLS=(
    "fuchsia.logger.LogSink"
    "fuchsia.ui.composition.Flatland"
    "fuchsia.ui.composition.Allocator"
    "fuchsia.vulkan.loader.Loader"
)

for protocol in "${REQUIRED_PROTOCOLS[@]}"; do
    if ! grep -q "\"$protocol\"" "$MANIFEST"; then
        echo "✗ Missing protocol: $protocol"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ Found protocol: $protocol"
    fi
done

# Check for storage declaration
echo ""
echo "Checking storage..."
if ! grep -q "storage:" "$MANIFEST"; then
    echo "✗ Missing storage declaration"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Found storage declaration"
fi

# Check for ViewProvider exposure
echo ""
echo "Checking exposed capabilities..."
if ! grep -q "fuchsia.ui.app.ViewProvider" "$MANIFEST"; then
    echo "✗ Missing ViewProvider capability"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Found ViewProvider capability"
fi

# Check for comments explaining protocols
echo ""
echo "Checking documentation..."
COMMENT_COUNT=$(grep -c "^[[:space:]]*//" "$MANIFEST" || echo 0)
if [ "$COMMENT_COUNT" -lt 5 ]; then
    echo "⚠ Only $COMMENT_COUNT comment lines found (expected at least 5)"
    echo "  Consider adding more documentation"
else
    echo "✓ Found $COMMENT_COUNT comment lines documenting the manifest"
fi

# Summary
echo ""
echo "=== Test Summary ==="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All basic structure checks passed"
    echo ""
    echo "Note: This is a basic structure test. For complete validation, run:"
    echo "  ./tools/soliloquy/validate_manifest.sh"
    exit 0
else
    echo "✗ $ERRORS structure check(s) failed"
    echo ""
    echo "Please review the manifest and fix the issues above."
    exit 1
fi

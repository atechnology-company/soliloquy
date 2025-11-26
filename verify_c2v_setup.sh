#!/bin/bash
# Verification script for c2v tooling setup

set -e

echo "========================================"
echo "c2v Tooling Setup Verification"
echo "========================================"
echo ""

# Check 1: c2v_pipeline.sh --help
echo "✓ Checking c2v_pipeline.sh --help..."
if ./tools/soliloquy/c2v_pipeline.sh --help > /dev/null 2>&1; then
    echo "  SUCCESS: c2v_pipeline.sh --help works"
else
    echo "  FAILED: c2v_pipeline.sh --help failed"
    exit 1
fi

# Check 2: GN build files exist
echo ""
echo "✓ Checking GN build files..."
if [ -f "build/v_rules.gni" ] && [ -f "build/BUILD.gn" ] && [ -f "BUILD.gn" ]; then
    echo "  SUCCESS: GN build files exist"
    grep -q "c2v_tooling_smoke" BUILD.gn && echo "    - Root BUILD.gn has c2v_tooling_smoke target"
    grep -q "v_object" build/v_rules.gni && echo "    - v_rules.gni has v_object template"
else
    echo "  FAILED: GN build files missing"
    exit 1
fi

# Check 3: Bazel build files exist
echo ""
echo "✓ Checking Bazel build files..."
if [ -f "build/v_rules.bzl" ] && [ -f "build/BUILD.bazel" ] && [ -f "BUILD.bazel" ]; then
    echo "  SUCCESS: Bazel build files exist"
    grep -q "c2v_tooling_smoke" BUILD.bazel && echo "    - Root BUILD.bazel has c2v_tooling_smoke target"
    grep -q "v_object" build/v_rules.bzl && echo "    - v_rules.bzl has v_object rule"
else
    echo "  FAILED: Bazel build files missing"
    exit 1
fi

# Check 4: Python wrapper scripts
echo ""
echo "✓ Checking Python wrapper scripts..."
python3 -m py_compile build/v_compile.py 2>/dev/null && echo "  SUCCESS: v_compile.py syntax OK"
python3 -m py_compile build/v_translate.py 2>/dev/null && echo "  SUCCESS: v_translate.py syntax OK"

# Check 5: Documentation
echo ""
echo "✓ Checking documentation..."
if [ -f "docs/zircon_c2v.md" ]; then
    echo "  SUCCESS: docs/zircon_c2v.md exists ($(wc -l < docs/zircon_c2v.md) lines)"
else
    echo "  FAILED: docs/zircon_c2v.md missing"
    exit 1
fi

if grep -q "c2v Translation" docs/dev_guide.md; then
    echo "  SUCCESS: dev_guide.md updated with c2v section"
else
    echo "  FAILED: dev_guide.md not updated"
    exit 1
fi

# Check 6: Environment setup
echo ""
echo "✓ Checking environment setup..."
if grep -q "V_HOME" tools/soliloquy/env.sh; then
    echo "  SUCCESS: env.sh updated with V_HOME"
else
    echo "  FAILED: env.sh not updated"
    exit 1
fi

# Check 7: .gitignore
echo ""
echo "✓ Checking .gitignore..."
if grep -q ".build-tools" .gitignore; then
    echo "  SUCCESS: .gitignore includes .build-tools/"
else
    echo "  FAILED: .gitignore not updated"
    exit 1
fi

# Check 8: WORKSPACE.bazel
echo ""
echo "✓ Checking WORKSPACE.bazel..."
if grep -q "V toolchain" WORKSPACE.bazel; then
    echo "  SUCCESS: WORKSPACE.bazel updated with V toolchain comment"
else
    echo "  FAILED: WORKSPACE.bazel not updated"
    exit 1
fi

# Summary
echo ""
echo "========================================"
echo "All Checks Passed! ✓"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Install build tools (GN/Ninja or Bazel)"
echo "  2. Bootstrap V toolchain: ./tools/soliloquy/c2v_pipeline.sh --bootstrap-only"
echo "  3. Build smoke test: ninja -C out/c2v c2v_tooling_smoke"
echo "  4. Or with Bazel: bazel build //:c2v_tooling_smoke"
echo ""

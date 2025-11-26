# Soliloquy Verification Scripts

Collection of verification scripts for validating Soliloquy setup and subsystem translations.

## Overview

These scripts verify that various aspects of the Soliloquy build system and subsystem translations are correctly configured and functional.

## Scripts

### verify_c2v_setup.sh
Verifies C-to-V translation tooling setup.

```bash
./tools/scripts/verify_c2v_setup.sh
```

**Checks**:
- ✅ `c2v_pipeline.sh --help` works
- ✅ GN build files exist and are correct
- ✅ Bazel build files exist and are correct
- ✅ Python wrapper scripts are present
- ✅ V toolchain is accessible

**Exit codes**:
- `0` - All checks passed
- `1` - One or more checks failed

---

### verify_hal_v_translation.sh
Verifies Hardware Abstraction Layer (HAL) V translation.

```bash
./tools/scripts/verify_hal_v_translation.sh
```

**Checks**:
- ✅ HAL V translation files exist
- ✅ HAL build targets are configured
- ✅ Translation completeness
- ✅ File structure matches expectations
- ✅ Build system integration

**Reports**:
- Translation progress percentage
- Missing files
- Build configuration status

---

### verify_ipc_build.sh
Verifies IPC (Inter-Process Communication) subsystem build.

```bash
./tools/scripts/verify_ipc_build.sh
```

**Checks**:
- ✅ IPC build targets exist
- ✅ Build files are syntactically correct
- ✅ Dependencies are properly declared
- ✅ IPC translation files present

---

### verify_test_framework.sh
Verifies testing framework setup.

```bash
./tools/scripts/verify_test_framework.sh
```

**Checks**:
- ✅ Test infrastructure files exist
- ✅ Test runners are configured
- ✅ Test targets are available
- ✅ Testing dependencies are met

**Purpose**: Run this after initial setup to ensure testing infrastructure works.

---

### verify_vm_translation.sh
Verifies Virtual Memory (VM) subsystem V translation.

```bash
./tools/scripts/verify_vm_translation.sh
```

**Checks**:
- ✅ VM V translation files exist
- ✅ VM build integration
- ✅ Translation status
- ✅ Critical VM components present

---

## Usage

### Run Individual Verification

```bash
# From project root
./tools/scripts/verify_c2v_setup.sh
```

### Run All Verifications

```bash
# Create a simple wrapper
for script in tools/scripts/verify_*.sh; do
    echo "Running $script..."
    if ! "$script"; then
        echo "❌ $script failed"
        exit 1
    fi
    echo ""
done
echo "✅ All verifications passed!"
```

### Via Build Manager

```bash
# Using Build Manager CLI
soliloquy-build verify all
soliloquy-build verify c2v-setup
soliloquy-build verify hal-translation

# Using GUI
# Dashboard → Verification Tools → Run All
```

---

## Integration with CI/CD

These scripts are designed to be CI/CD friendly:

### GitHub Actions Example

```yaml
name: Verify Setup
on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup SDK
        run: ./tools/soliloquy/setup_sdk.sh
      
      - name: Verify C2V Setup
        run: ./tools/scripts/verify_c2v_setup.sh
      
      - name: Verify Test Framework
        run: ./tools/scripts/verify_test_framework.sh
      
      - name: Verify HAL Translation
        run: ./tools/scripts/verify_hal_v_translation.sh
```

### GitLab CI Example

```yaml
verify_setup:
  stage: test
  script:
    - ./tools/soliloquy/setup_sdk.sh
    - ./tools/scripts/verify_c2v_setup.sh
    - ./tools/scripts/verify_test_framework.sh
```

---

## Script Architecture

All scripts follow this structure:

```bash
#!/bin/bash
set -e  # Exit on error

# Detect project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================"
echo "Verification Script Name"
echo "========================================"

# Check 1
echo "✓ Checking first thing..."
if [check_condition]; then
    echo "  SUCCESS: Description"
else
    echo "  FAILED: Description"
    exit 1
fi

# More checks...

echo ""
echo "✅ All checks passed!"
```

### Key Features:
- ✅ **Automatic project root detection** - Works from any location
- ✅ **Clear output formatting** - Easy to read results
- ✅ **Proper exit codes** - CI/CD friendly
- ✅ **Incremental checks** - Fails fast on first error
- ✅ **Descriptive messages** - Clear success/failure reasons

---

## Extending Verification Scripts

### Adding New Verification

1. Create new script:
   ```bash
   touch tools/scripts/verify_new_feature.sh
   chmod +x tools/scripts/verify_new_feature.sh
   ```

2. Use the template:
   ```bash
   #!/bin/bash
   set -e
   
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
   cd "$PROJECT_ROOT"
   
   echo "========================================"
   echo "New Feature Verification"
   echo "========================================"
   
   # Add your checks here
   
   echo "✅ All checks passed!"
   ```

3. Document in this README

4. Add to Build Manager integration (optional)

---

## Troubleshooting

### "No such file or directory"

The script couldn't find project files. Ensure you're running from the project root:

```bash
cd /path/to/soliloquy
./tools/scripts/verify_c2v_setup.sh
```

### "Permission denied"

Make scripts executable:

```bash
chmod +x tools/scripts/*.sh
```

### Checks Failing After Fresh Clone

Run setup first:

```bash
./tools/soliloquy/setup_sdk.sh
source tools/soliloquy/env.sh
./tools/scripts/verify_test_framework.sh
```

### Script Hangs

Some checks may require user input. Use non-interactive mode:

```bash
export CI=true
./tools/scripts/verify_c2v_setup.sh
```

---

## Best Practices

### Before Commits
Run relevant verification scripts:
```bash
./tools/scripts/verify_c2v_setup.sh  # If modifying c2v tooling
./tools/scripts/verify_hal_v_translation.sh  # If modifying HAL
```

### After Setup
Verify your environment:
```bash
./tools/scripts/verify_test_framework.sh
```

### Before Pull Requests
Run all verifications:
```bash
for script in tools/scripts/verify_*.sh; do "$script"; done
```

### Regular Testing
Schedule periodic verification:
```bash
# Add to crontab
0 2 * * * cd /path/to/soliloquy && ./tools/scripts/verify_c2v_setup.sh
```

---

## Output Examples

### Successful Run
```
========================================
c2v Tooling Setup Verification
========================================

✓ Checking c2v_pipeline.sh --help...
  SUCCESS: c2v_pipeline.sh --help works

✓ Checking GN build files...
  SUCCESS: GN build files exist
    - Root BUILD.gn has c2v_tooling_smoke target
    - v_rules.gni has v_object template

✓ Checking Bazel build files...
  SUCCESS: Bazel build files exist
    - Root BUILD.bazel has c2v_tooling_smoke target
    - v_rules.bzl has v_object rule

✅ All checks passed!
```

### Failed Run
```
========================================
c2v Tooling Setup Verification
========================================

✓ Checking c2v_pipeline.sh --help...
  SUCCESS: c2v_pipeline.sh --help works

✓ Checking GN build files...
  FAILED: GN build files missing

Run './tools/soliloquy/c2v_pipeline.sh --help' for setup instructions.
```

---

## See Also

- **[Tools Reference](../../docs/guides/tools_reference.md)** - Complete tool documentation
- **[C2V Translation Guide](../../docs/translations/c2v_translations.md)** - Translation documentation
- **[Build Manager](../build_manager/README.md)** - Build management system
- **[Developer Guide](../../docs/guides/dev_guide.md)** - Development workflow

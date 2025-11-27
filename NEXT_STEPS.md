# Soliloquy: Next Steps to Boot

## Current State ✅

You have successfully built:
- `//src/shell:soliloquy_shell_simple` - Main shell binary (Rust)
- `//third_party/zircon_v/...` - V-translated kernel subsystems (40 targets)
- `//sdk:zircon_lib` - Zircon SDK libraries
- V language toolchain (built from source for ARM64)
- Rust crate dependencies configured

## What's Missing ❌

To create a **bootable image**, you still need:

1. **Full Fuchsia Build** - The Zircon kernel, component framework, and system services
2. **Device Tree / Board Support** - Hardware-specific configuration for A527
3. **U-Boot Bootloader** - To load the Zircon kernel on the SBC

---

## Option 1: QEMU (No Hardware - Works Now) 🖥️

**Time: ~3 hours (first build), ~10 minutes (subsequent)**

This is the fastest way to test Soliloquy without hardware.

### Step 1: Finish Fuchsia Sync

```bash
# In Fedora orb
orb -m fedora

cd /mnt/mac/Volumes/storage/fuchsia-src
.jiri_root/bin/jiri update -gc

# This downloads ~60GB of source code
```

### Step 2: Configure for QEMU

```bash
cd /mnt/mac/Volumes/storage/fuchsia-src
source scripts/fx-env.sh

# Configure for QEMU ARM64
fx set core.qemu-arm64 --release

# Build (2-4 hours first time, uses all cores)
fx build
```

### Step 3: Run in QEMU

```bash
# Start QEMU with networking
fx qemu -N

# Or with graphics (if your orb supports it)
fx qemu -g
```

### Step 4: Test from Shell

```bash
# In another terminal
fx shell

# Run a component
ffx component run fuchsia-pkg://fuchsia.com/hello_world#meta/hello_world.cm
```

---

## Option 2: Radxa Cubie A5E (Your SBC) 🔧

**Time: 1-2 days for full bring-up**

The Allwinner A527 isn't officially supported by Fuchsia yet. You'll need to:

### Step 1: Create Board Support

The board files are already created in `boards/arm64/soliloquy/`. But you need:

1. **Device Tree**: Create `allwinner-a527.dts` based on Linux kernel DTS
2. **U-Boot Config**: Port U-Boot for A527 (or use Orange Pi Zero 3 config as base)
3. **Driver Integration**: The AIC8800 WiFi driver is partially ready

### Step 2: Build ARM64 Image

```bash
cd /mnt/mac/Volumes/storage/fuchsia-src

# Link Soliloquy into Fuchsia tree
mkdir -p vendor/soliloquy
ln -sf /mnt/mac/Volumes/storage/GitHub/soliloquy vendor/soliloquy/src

# Configure for ARM64 (not QEMU)
fx set core.arm64 \
    --board boards/arm64/generic \
    --with //vendor/soliloquy/src/shell:soliloquy_shell_simple

fx build
```

### Step 3: Flash to SD Card

```bash
# Create bootable SD card
./tools/soliloquy/flash.sh

# Or manually:
# 1. Partition SD card (see docs/BUILD_AND_BOOT.md)
# 2. Install U-Boot to first sectors
# 3. Copy zircon.zbi to boot partition
```

### Step 4: Connect Serial Console

```bash
# macOS - find the USB serial port
ls /dev/tty.usb*

# Connect at 115200 baud
screen /dev/tty.usbserial-XXXX 115200
```

---

## Option 3: Your Mac (x86_64 Linux VM) 💻

**Time: 4-6 hours**

Run Fuchsia on your Mac via QEMU x86_64 (faster emulation).

### Step 1: Set Up x86_64 Build

```bash
# Use a separate Fuchsia checkout or reconfigure
fx set core.x64 --release
fx build
```

### Step 2: Run in QEMU

```bash
fx qemu
```

---

## Recommended Path

For **fastest results**:

1. ⏳ **Wait for `jiri update` to complete** (it's downloading Fuchsia source)
2. 🔨 **Build for QEMU ARM64**: `fx set core.qemu-arm64 && fx build`
3. 🖥️ **Test in QEMU**: `fx qemu -N`

For **real hardware**:

1. 📦 **Get U-Boot working** on Cubie A5E first (separate from Fuchsia)
2. 🔧 **Create device tree** for A527
3. 🏗️ **Build ARM64 Fuchsia** with your drivers
4. 💾 **Flash and test** with serial console

---

## Quick Commands Reference

```bash
# Check build status
orb -m fedora bash -c 'cd /mnt/mac/Volumes/storage/fuchsia-src && fx status'

# Build incrementally
orb -m fedora bash -c 'cd /mnt/mac/Volumes/storage/fuchsia-src && fx build'

# Run QEMU
orb -m fedora bash -c 'cd /mnt/mac/Volumes/storage/fuchsia-src && fx qemu -N'

# Build just Soliloquy components (Bazel)
orb -m fedora bash -c 'cd /mnt/mac/Volumes/storage/GitHub/soliloquy && bazel build //...'

# Flash to SD card (when image is ready)
./tools/soliloquy/flash.sh
```

---

## Component Status

| Component | Status | Notes |
|-----------|--------|-------|
| Shell (Rust) | ✅ Built | `soliloquy_shell_simple` |
| V Kernel Modules | ✅ Built | Placeholder objects |
| FIDL Bindings | ⚠️ Partial | Need `fidl` crate |
| WiFi Driver | ⚠️ Partial | Needs testing |
| U-Boot | ❌ Not built | Need to port for A527 |
| Device Tree | ❌ Missing | Need A527 DTS |
| Zircon Kernel | ⏳ Building | Via Fuchsia tree |

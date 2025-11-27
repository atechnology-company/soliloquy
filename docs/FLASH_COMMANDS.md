# Soliloquy OS: Flash Commands Reference

Quick reference for flashing Soliloquy OS to Radxa Cubie A5E.

## fx Commands

### Configure Build

```bash
# Standard product (full UI)
fx set soliloquy.arm64 --product soliloquy \
    --with //boards/arm64/soliloquy:drivers \
    --with //src/shell:soliloquy_shell \
    --with //drivers/wifi/aic8800:aic8800

# Headless (no display)
fx set soliloquy.arm64 --product soliloquy_headless \
    --with //boards/arm64/soliloquy:drivers

# QEMU testing
fx set soliloquy.qemu-arm64 --product soliloquy_qemu

# With tests included
fx set soliloquy.arm64 --product soliloquy_with_tests \
    --with //boards/arm64/soliloquy:drivers \
    --with //test:soliloquy_tests
```

### Build

```bash
# Full build
fx build

# Incremental build (faster)
fx build :default

# Verbose build (debug)
fx build -v

# Clean build
fx clean && fx build
```

### Flash to Hardware

```bash
# Standard pave (keeps user data)
fx flash --pave

# Full factory reset
fx flash --pave-zedboot

# Flash specific partitions only
fx flash --no-bootloader  # Skip bootloader update

# Verbose flashing
fx flash --pave -v
```

### Fastboot Commands

```bash
# Enter fastboot mode on device:
# 1. Power off board
# 2. Hold BOOT button
# 3. Connect USB-C
# 4. Release button after 2 seconds

# Check connection
fastboot devices

# Flash ZBI (kernel + bootfs)
fastboot flash zircon_a out/default/soliloquy.zbi
fastboot flash zircon_b out/default/soliloquy.zbi

# Flash FVM (filesystem)
fastboot flash fvm out/default/obj/images/fvm.sparse.blk

# Flash vbmeta (verified boot)
fastboot flash vbmeta_a out/default/obj/images/vbmeta_a.img
fastboot flash vbmeta_b out/default/obj/images/vbmeta_b.img

# Reboot
fastboot reboot

# Full flash sequence
fastboot flash zircon_a out/default/soliloquy.zbi && \
fastboot flash zircon_b out/default/soliloquy.zbi && \
fastboot flash fvm out/default/obj/images/fvm.sparse.blk && \
fastboot reboot
```

### OTA Updates (over network)

```bash
# Start package server on host
fx serve

# Update from device shell
fx shell update check-now --monitor

# Or from host
fx ota
```

### USB Boot (no flash)

```bash
# Boot directly over USB without flashing
fx usb-boot
```

## QEMU Commands

### Basic QEMU

```bash
# Headless (no display window)
fx qemu -N

# With display
fx qemu -N -g

# With networking
fx qemu -N --net tap

# Extra RAM
fx qemu -N -m 4096

# Enable KVM acceleration (Linux host)
fx qemu -N --kvm
```

### QEMU Debugging

```bash
# GDB server
fx qemu -N -s -S

# In another terminal
arm-none-eabi-gdb out/default/kernel_arm64/zircon.elf
(gdb) target remote :1234
(gdb) continue

# QEMU monitor
# Press Ctrl+A, then C to enter QEMU monitor
# Type 'info registers' to see CPU state
```

## ZBI Commands

### Inspect ZBI

```bash
# List ZBI contents
tools/zbi -tv out/default/soliloquy.zbi

# Extract bootfs
tools/zbi -x out/default/soliloquy.zbi -o /tmp/extracted
```

### Create Custom ZBI

```bash
# Combine kernel + bootfs
tools/zbi -o custom.zbi \
    out/default/kernel_arm64/zircon.bin \
    --type=CMDLINE "kernel.serial=legacy" \
    --type=CMDLINE "kernel.entropy-mixin=abc123" \
    --files out/default/obj/boards/arm64/soliloquy/bootfs.txt
```

## Device Shell Commands

### Connect to Device

```bash
# SSH
fx shell

# Serial console
fx serial

# Or directly
screen /dev/tty.usbserial* 115200
```

### Driver Commands

```bash
# List all drivers
fx shell driver list

# Show driver tree
fx shell driver dump

# Rebind a driver
fx shell driver rebind /dev/class/display-controller/000

# Driver logs
fx log --only driver_manager
```

### System Commands

```bash
# Component list
fx shell ffx component list

# Service list
fx shell ffx component doctor

# Reboot
fx shell dm reboot

# Shutdown
fx shell dm shutdown

# Power off
fx shell dm poweroff
```

## Network Commands

### Device Discovery

```bash
# Discover devices on network
fx list-devices

# Target specific device
fx set-device <device-name>
```

### Netboot

```bash
# Boot over network (device in Zedboot)
fx netboot

# With specific device
fx netboot --device <device-addr>
```

## Partition Layout

| Partition | Offset | Size | Use |
|-----------|--------|------|-----|
| zircon_a | 1MB | 64MB | Primary kernel |
| zircon_b | 65MB | 64MB | Backup kernel |
| vbmeta_a | 129MB | 64KB | Verified boot A |
| vbmeta_b | 129.5MB | 64KB | Verified boot B |
| fvm | 130MB | Rest | BlobFS + MinFS |

## Troubleshooting

### Fastboot Not Detected

```bash
# Check USB connection
lsusb | grep -i allwinner

# Linux: add udev rules
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="1f3a", MODE="0666"' | \
    sudo tee /etc/udev/rules.d/99-allwinner.rules
sudo udevadm control --reload-rules
```

### Flash Timeout

```bash
# Increase timeout
fx flash --pave --timeout 600
```

### Boot Loop

```bash
# Boot into Zedboot for recovery
# Hold BOOT button during power-on

# From Zedboot, repave
dm reboot-recovery  # If already booted
```

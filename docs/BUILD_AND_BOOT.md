# Building and Booting Soliloquy OS

This guide covers building Fuchsia/Soliloquy OS on Linux and booting it on the Radxa Cubie A5E (Allwinner A527 SoC).

## Prerequisites

### Hardware
- **Build Machine**: Linux x86_64 or arm64 (Fedora, Ubuntu, Debian)
- **Target SBC**: Radxa Cubie A5E
  - Allwinner A527 SoC (ARM Cortex-A55 quad-core)
  - Mali-G57 GPU
  - 2-4GB LPDDR4
  - eMMC + microSD
  - USB-C (debug + power)
  - Gigabit Ethernet
  - AIC8800D80 WiFi/BT

### Build Machine Requirements
- 16GB+ RAM (32GB recommended)
- 250GB+ free disk space
- Fast SSD recommended

## Part 1: Setting Up the Build Environment

### On OrbStack (Fedora)

```bash
# SSH into Fedora orb or use orb command
orb -m fedora

# Install dependencies
sudo dnf install -y git curl python3 python3-pip unzip ccache clang lld \
    ninja-build go flex bison gperf texinfo libstdc++-static \
    openssl-devel dtc u-boot-tools

# Install Bazelisk
curl -L -o /usr/local/bin/bazel \
    https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-arm64
chmod +x /usr/local/bin/bazel

# Set up Fuchsia source (use external drive for space)
FUCHSIA_DIR=/mnt/mac/Volumes/storage/fuchsia-src
mkdir -p $FUCHSIA_DIR && cd $FUCHSIA_DIR

# Bootstrap jiri
curl -s 'https://fuchsia.googlesource.com/jiri/+/HEAD/scripts/bootstrap_jiri?format=TEXT' \
    | base64 --decode | bash -s $FUCHSIA_DIR

# Add to PATH
export PATH="$FUCHSIA_DIR/.jiri_root/bin:$PATH"
echo 'export PATH="$FUCHSIA_DIR/.jiri_root/bin:$PATH"' >> ~/.bashrc

# Initialize and fetch Fuchsia (takes 1-2 hours, ~60GB)
jiri init -analytics-opt=false $FUCHSIA_DIR
cd $FUCHSIA_DIR
jiri import -name=integration flower https://fuchsia.googlesource.com/integration
jiri update -gc
```

### Link Soliloquy into Fuchsia Tree

```bash
# Create vendor directory for Soliloquy
mkdir -p $FUCHSIA_DIR/vendor/soliloquy

# Symlink Soliloquy components
ln -sf /mnt/mac/Volumes/storage/GitHub/soliloquy/src/shell $FUCHSIA_DIR/vendor/soliloquy/shell
ln -sf /mnt/mac/Volumes/storage/GitHub/soliloquy/drivers $FUCHSIA_DIR/vendor/soliloquy/drivers
ln -sf /mnt/mac/Volumes/storage/GitHub/soliloquy/product $FUCHSIA_DIR/vendor/soliloquy/product
ln -sf /mnt/mac/Volumes/storage/GitHub/soliloquy/boards $FUCHSIA_DIR/vendor/soliloquy/boards
```

## Part 2: Building Soliloquy

### Configure the Build

```bash
cd $FUCHSIA_DIR

# Set build configuration for ARM64
fx set core.arm64 \
    --product vendor/soliloquy/product/soliloquy.gni \
    --board vendor/soliloquy/boards/arm64/soliloquy/BUILD.gn \
    --with //vendor/soliloquy/shell:soliloquy_shell \
    --with //vendor/soliloquy/drivers/wifi/aic8800:aic8800

# Or for SDK-only build with Bazel
cd /mnt/mac/Volumes/storage/GitHub/soliloquy
bazel build //src/shell:soliloquy_shell_simple
```

### Build Fuchsia

```bash
# Full build (takes 2-4 hours first time)
fx build

# Build artifacts will be in:
# $FUCHSIA_DIR/out/default/
```

## Part 3: U-Boot for Radxa Cubie A5E

The Allwinner A527 requires U-Boot with ARM Trusted Firmware (ATF).

### Building U-Boot

```bash
# Clone U-Boot and ATF
git clone https://github.com/ARM-software/arm-trusted-firmware.git atf
git clone https://github.com/u-boot/u-boot.git

# Build ARM Trusted Firmware
cd atf
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=sun50i_a64 DEBUG=0 bl31
export BL31=$(pwd)/build/sun50i_a64/release/bl31.bin
cd ..

# Build U-Boot for A527 (closest config is sun50i)
cd u-boot
make CROSS_COMPILE=aarch64-linux-gnu- orangepi_zero3_defconfig
# Customize for Cubie A5E if needed
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
```

### U-Boot Configuration for Zircon

Create `boot.scr` for Zircon boot:

```bash
cat > boot.cmd << 'EOF'
setenv bootargs 'kernel.serial=legacy'
setenv zircon_a_slot a
setenv zircon_b_slot b

# Load Zircon kernel (zbi)
load mmc 0:1 ${kernel_addr_r} zircon.zbi

# Boot Zircon
booti ${kernel_addr_r} - ${fdt_addr}
EOF

mkimage -C none -A arm64 -T script -d boot.cmd boot.scr
```

## Part 4: Preparing the SD Card

### Partition Layout

```bash
# Device: /dev/sdX (replace with your SD card)
DEVICE=/dev/sdX

# Create partitions
sudo parted $DEVICE mklabel gpt
sudo parted $DEVICE mkpart primary fat32 1MiB 64MiB      # Boot partition
sudo parted $DEVICE mkpart primary ext4 64MiB 512MiB    # Zircon A
sudo parted $DEVICE mkpart primary ext4 512MiB 960MiB   # Zircon B
sudo parted $DEVICE mkpart primary ext4 960MiB 100%     # FVM (data)

# Format partitions
sudo mkfs.vfat -F 32 ${DEVICE}1
sudo mkfs.ext4 ${DEVICE}2
sudo mkfs.ext4 ${DEVICE}3
sudo mkfs.ext4 ${DEVICE}4

# Install U-Boot (SPL at sector 16, U-Boot at sector 32800)
sudo dd if=u-boot-sunxi-with-spl.bin of=$DEVICE bs=1024 seek=8
```

### Installing Zircon

```bash
# Mount boot partition
sudo mount ${DEVICE}1 /mnt/boot

# Copy Zircon image
sudo cp $FUCHSIA_DIR/out/default/zircon.zbi /mnt/boot/
sudo cp boot.scr /mnt/boot/
sudo cp $FUCHSIA_DIR/out/default/allwinner-a527.dtb /mnt/boot/  # If available

sudo umount /mnt/boot
```

## Part 5: Booting and Testing

### Serial Console

```bash
# Connect USB-C debug port and open serial console
# macOS:
screen /dev/tty.usbserial* 115200

# Linux:
screen /dev/ttyUSB0 115200
```

### Boot Sequence

1. Insert SD card into Radxa Cubie A5E
2. Connect USB-C debug cable to Mac/PC
3. Open serial console
4. Power on the board
5. U-Boot will load and boot Zircon

### Expected Boot Log

```
U-Boot SPL 2024.01 (date)
DRAM: 2048 MiB
...
U-Boot 2024.01 (date)
=> boot
Loading zircon.zbi...
Starting kernel...

[00000.000] INIT: Starting Zircon...
[00000.xxx] BOOT: Welcome to Soliloquy OS
```

### Testing Fuchsia/Zircon

```bash
# From serial console or SSH:

# Check running components
ffx component list

# Check WiFi driver
ffx driver list | grep aic8800

# Run shell
fx shell
```

## Part 6: QEMU Testing (No Hardware)

```bash
# Build for QEMU
cd $FUCHSIA_DIR
fx set core.qemu-arm64 --with //vendor/soliloquy/shell:soliloquy_shell

fx build

# Run in QEMU
fx qemu -N

# Or with graphics
fx qemu -g
```

## Troubleshooting

### Build Errors

**"Too many open files"**:
```bash
ulimit -n 65535
# Or add to /etc/security/limits.conf
```

**Missing cross-compiler**:
```bash
sudo dnf install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
```

### Boot Issues

**Stuck at U-Boot**: Check serial console for errors, verify SD card partitioning

**Kernel panic**: Usually driver issues, try disabling WiFi driver first

**No display**: Flatland compositor may not be configured for Mali-G57 yet

## Next Steps

1. Translate remaining drivers (see `docs/DRIVER_STATUS.md`)
2. Configure Servo browser for Flatland
3. Set up developer workflow with `ffx`
4. Enable secure boot with verified boot chain

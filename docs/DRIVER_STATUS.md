# Driver Translation Status

This document tracks the status of Linux driver translations to Fuchsia/Zircon for Soliloquy OS on the Radxa Cubie A5E.

## Target Hardware: Radxa Cubie A5E

| Component | Chip | Linux Driver | Fuchsia Status | V Translation |
|-----------|------|--------------|----------------|---------------|
| **SoC** | Allwinner A527 | sunxi | 🔴 Not started | - |
| **CPU** | Cortex-A55 (4x) | ARM | ✅ Core Zircon support | - |
| **GPU** | Mali-G57 | panfrost | 🟡 Partial (mali_g57 driver) | 🔴 |
| **WiFi** | AIC8800D80 | aic8800 | 🟡 Partial (Rust driver) | 🔴 |
| **Bluetooth** | AIC8800D80 | aic8800_btlpm | 🔴 Not started | 🔴 |
| **eMMC** | - | sdhci-sunxi | 🟡 V Translation | ✅ sunxi_mmc.v |
| **SD Card** | - | sdhci-sunxi | 🟡 V Translation | ✅ sunxi_mmc.v |
| **USB** | - | ehci/ohci-sunxi | ✅ V Translation | ✅ sunxi_usb.v |
| **Ethernet** | - | stmmac | 🔴 Not started | 🔴 |
| **GPIO** | Allwinner | gpio-sunxi | ✅ V Translation | ✅ sunxi_gpio.v |
| **I2C** | Allwinner | i2c-mv64xxx | ✅ V Translation | ✅ sunxi_i2c.v |
| **UART** | Allwinner | 8250-sunxi | ✅ Standard 8250 | - |
| **Clock (CCU)** | Allwinner | sunxi-ng | ✅ V Translation | ✅ sunxi_ccu.v |
| **Display** | MIPI-DSI/HDMI | sun4i-drm | 🔴 Not started | 🔴 |
| **Audio** | - | sun4i-codec | 🔴 Not started | 🔴 |

## V Language Driver Translations

All boot-critical drivers have been translated to V language in `third_party/zircon_v/drivers/`:

| Driver | Files | Lines | Status |
|--------|-------|-------|--------|
| **MMC/SDHCI** | `mmc/sunxi_mmc_regs.v`, `mmc/sunxi_mmc.v` | ~1200 | ✅ Complete |
| **Clock (CCU)** | `clock/a527_ccu_regs.v`, `clock/sunxi_ccu.v` | ~900 | ✅ Complete |
| **GPIO** | `gpio/sunxi_gpio_regs.v`, `gpio/sunxi_gpio.v` | ~800 | ✅ Complete |
| **I2C** | `i2c/sunxi_i2c_regs.v`, `i2c/sunxi_i2c.v` | ~900 | ✅ Complete |
| **USB** | `usb/sunxi_usb_regs.v`, `sunxi_usb.v`, `sunxi_ehci.v` | ~1400 | ✅ Complete |

### V Driver Features

Each V driver includes:
- Complete register definitions from hardware manuals
- Full driver implementation with state machines
- Thread-safe locking with `sync.Mutex`
- Comprehensive unit tests
- Documentation comments

## Priority 1: Boot Critical

### 1. SDHCI (SD/eMMC Controller)

**Linux Source**: `drivers/mmc/host/sdhci-of-dwcmshc.c` or `sunxi-mmc.c`

**Required for**: Booting from SD card/eMMC

**Translation Path**:
```
Linux: sunxi-mmc.c → Fuchsia: sdhci-sunxi driver
```

**Key Functions to Port**:
- `sunxi_mmc_probe()` - Initialize controller
- `sunxi_mmc_set_ios()` - Clock/bus width configuration
- DMA descriptor setup

### 2. Clock/Reset Controller (CCU)

**Linux Source**: `drivers/clk/sunxi-ng/ccu-sun50i-a100.c` (closest to A527)

**Required for**: All peripheral clocks

**Key Structures**:
- Clock tree definitions
- PLL configurations
- Gate/divider mappings

## Priority 2: Networking

### 3. AIC8800D80 WiFi (Partially Done)

**Linux Source**: `vendor/aic8800-linux/drivers/aic8800/`
- 45 C source files
- 59 header files

**Fuchsia Status**: 
- ✅ `drivers/wifi/aic8800/aic8800_rust/src/lib.rs` - Core driver
- ✅ `gen/fidl/fuchsia_wlan_softmac/src/lib.rs` - MAC layer
- 🔴 Missing: SDIO platform bindings, firmware loader integration

**Remaining Work**:
| File | Purpose | Status |
|------|---------|--------|
| `aicwf_sdio.c` | SDIO transport | 🟡 Partial in Rust |
| `rwnx_main.c` | Main driver logic | 🟡 Partial |
| `rwnx_tx.c` | TX path | 🔴 Not started |
| `rwnx_rx.c` | RX path | 🔴 Not started |
| `rwnx_msg_tx.c` | Firmware messaging | 🔴 Not started |
| `ipc_host.c` | Host IPC | 🔴 Not started |
| `aic_load_fw/` | Firmware loader | 🔴 Not started |

### 4. Ethernet (GMAC/STMMAC)

**Linux Source**: `drivers/net/ethernet/stmicro/stmmac/`

**Translation Path**: Use existing Fuchsia ethernet framework

## Priority 3: Display

### 5. Mali-G57 GPU

**Current Status**: Basic driver at `drivers/gpu/mali_g57/`

**Linux Source**: panfrost driver + Mali blob

**For Flatland**: Need:
- DRM/KMS interface
- GBM buffer allocation
- Vulkan/GLES support (via ANGLE or native)

### 6. Display Engine (DE3)

**Linux Source**: `drivers/gpu/drm/sun4i/`

**Components**:
- TCON (Timing Controller)
- HDMI encoder
- MIPI-DSI encoder
- Mixer (DE3)

## Priority 4: Other Peripherals

### 7. USB Host

**Linux Source**: `drivers/usb/host/ehci-sunxi.c`

**Fuchsia**: Can use standard xHCI/EHCI drivers with platform bindings

### 8. Audio

**Linux Source**: `sound/soc/sunxi/`

**Lower priority for initial boot**

## Translation Process

### Step 1: Analyze Linux Driver
```bash
# Find key entry points
grep -n "module_init\|probe\|remove" driver.c

# Find register definitions
grep -n "#define.*REG\|0x[0-9A-Fa-f]" driver.h
```

### Step 2: Create Fuchsia Driver Structure
```rust
// drivers/<category>/<driver>/src/lib.rs
pub struct MyDriver {
    mmio: MmioBuffer,
    irq: Interrupt,
    // ...
}

impl MyDriver {
    pub fn bind(ctx: &mut DriverCtx) -> Result<Self, Status> {
        // Initialize from device tree
    }
}
```

### Step 3: Implement DDK Bindings
```cpp
// drivers/<category>/<driver>/bind.fidl
library fuchsia.driver.my_driver;

using fuchsia.platform;

driver my_driver {
    device fuchsia.platform.DRIVER_FRAMEWORK_VERSION == 2;
    fuchsia.platform.DRIVER_FRAMEWORK_VERSION == 2;
}
```

### Step 4: Test on QEMU First
```bash
fx set core.qemu-arm64 --with //drivers/my_driver
fx qemu
```

## Device Tree

The Radxa Cubie A5E device tree needs to be created/adapted:

```dts
// boards/arm64/soliloquy/cubie-a5e.dts

/dts-v1/;
#include <dt-bindings/interrupt-controller/arm-gic.h>
#include <dt-bindings/clock/sun50i-a527-ccu.h>

/ {
    compatible = "radxa,cubie-a5e", "allwinner,sun50i-a527";
    model = "Radxa Cubie A5E";

    cpus {
        #address-cells = <1>;
        #size-cells = <0>;

        cpu@0 {
            compatible = "arm,cortex-a55";
            device_type = "cpu";
            reg = <0>;
        };
        // ... cpu1-3
    };

    soc {
        mmc0: mmc@4020000 {
            compatible = "allwinner,sun50i-a527-mmc";
            reg = <0x04020000 0x1000>;
            interrupts = <GIC_SPI 39 IRQ_TYPE_LEVEL_HIGH>;
            clocks = <&ccu CLK_BUS_MMC0>, <&ccu CLK_MMC0>;
            clock-names = "ahb", "mmc";
            resets = <&ccu RST_BUS_MMC0>;
            status = "okay";
        };

        wifi: wifi@0 {
            compatible = "aicsemi,aic8800d80";
            // SDIO binding
        };
    };
};
```

## Firmware Files Required

| Component | Firmware | Location |
|-----------|----------|----------|
| WiFi | `fmacfw_8800d80.bin` | `/pkg/data/firmware/aic8800/` |
| WiFi | `fmacfw_rf_8800d80.bin` | `/pkg/data/firmware/aic8800/` |
| Bluetooth | `fw_adid_8800d80.bin` | `/pkg/data/firmware/aic8800/` |
| GPU (maybe) | Mali blobs | `/pkg/data/firmware/mali/` |

## Contributing

1. Pick an unclaimed driver from the table above
2. Create issue: "Port <driver> to Fuchsia"
3. Study Linux driver source
4. Implement in Rust or C++ following Fuchsia DDK patterns
5. Test on QEMU, then hardware
6. Submit PR with driver + tests

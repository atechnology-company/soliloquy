// Copyright 2024 Soliloquy Authors
// SPDX-License-Identifier: Apache-2.0
//
// Soliloquy MMC Driver
// Allwinner A527 MMC controller for eMMC/SD storage

#include <lib/ddk/binding.h>
#include <lib/ddk/debug.h>
#include <lib/ddk/device.h>
#include <lib/ddk/driver.h>
#include <lib/ddk/platform-defs.h>
#include <lib/device-protocol/pdev.h>
#include <lib/mmio/mmio.h>

#include <ddktl/device.h>
#include <fbl/alloc_checker.h>

namespace soliloquy_mmc {

// Allwinner MMC controller registers
constexpr uint32_t kMMC_GCTRL = 0x00;       // Global Control Register
constexpr uint32_t kMMC_CLKCR = 0x04;       // Clock Control Register
constexpr uint32_t kMMC_TIMEOUT = 0x08;     // Timeout Register
constexpr uint32_t kMMC_WIDTH = 0x0C;       // Bus Width Register
constexpr uint32_t kMMC_BLKSZ = 0x10;       // Block Size Register
constexpr uint32_t kMMC_BYTECNT = 0x14;     // Byte Count Register
constexpr uint32_t kMMC_CMD = 0x18;         // Command Register
constexpr uint32_t kMMC_CMDARG = 0x1C;      // Command Argument Register
constexpr uint32_t kMMC_RESP0 = 0x20;       // Response Register 0
constexpr uint32_t kMMC_RESP1 = 0x24;       // Response Register 1
constexpr uint32_t kMMC_RESP2 = 0x28;       // Response Register 2
constexpr uint32_t kMMC_RESP3 = 0x2C;       // Response Register 3
constexpr uint32_t kMMC_IMASK = 0x30;       // Interrupt Mask Register
constexpr uint32_t kMMC_MINT = 0x34;        // Masked Interrupt Status
constexpr uint32_t kMMC_RINT = 0x38;        // Raw Interrupt Status
constexpr uint32_t kMMC_STATUS = 0x3C;      // Status Register

class SoliloquyMmc;
using DeviceType = ddk::Device<SoliloquyMmc, ddk::Unbindable>;

class SoliloquyMmc : public DeviceType {
 public:
  explicit SoliloquyMmc(zx_device_t* parent) : DeviceType(parent) {}

  static zx_status_t Create(void* ctx, zx_device_t* parent);

  void DdkRelease() { delete this; }
  void DdkUnbind(ddk::UnbindTxn txn) { txn.Reply(); }

 private:
  zx_status_t Init();
  zx_status_t InitHardware();
  void ResetController();

  std::optional<fdf::MmioBuffer> mmio_;
};

zx_status_t SoliloquyMmc::Create(void* ctx, zx_device_t* parent) {
  fbl::AllocChecker ac;
  auto dev = fbl::make_unique_checked<SoliloquyMmc>(&ac, parent);
  if (!ac.check()) {
    return ZX_ERR_NO_MEMORY;
  }

  auto status = dev->Init();
  if (status != ZX_OK) {
    return status;
  }

  [[maybe_unused]] auto* dummy = dev.release();
  return ZX_OK;
}

zx_status_t SoliloquyMmc::Init() {
  auto status = InitHardware();
  if (status != ZX_OK) {
    zxlogf(WARNING, "Hardware init failed: %s", zx_status_get_string(status));
    // Continue - we can probe for SD/eMMC later
  }

  status = DdkAdd("soliloquy-mmc");
  if (status != ZX_OK) {
    zxlogf(ERROR, "Failed to add device: %s", zx_status_get_string(status));
    return status;
  }

  zxlogf(INFO, "Soliloquy MMC driver initialized");
  return ZX_OK;
}

zx_status_t SoliloquyMmc::InitHardware() {
  ddk::PDevProtocolClient pdev(parent());
  if (!pdev.is_valid()) {
    zxlogf(WARNING, "No platform device");
    return ZX_ERR_NOT_SUPPORTED;
  }

  std::optional<fdf::MmioBuffer> mmio;
  auto status = pdev.MapMmio(0, &mmio);
  if (status != ZX_OK) {
    zxlogf(ERROR, "Failed to map MMIO: %s", zx_status_get_string(status));
    return status;
  }
  mmio_ = std::move(mmio);

  ResetController();
  return ZX_OK;
}

void SoliloquyMmc::ResetController() {
  if (!mmio_.has_value()) {
    return;
  }

  // Soft reset
  mmio_->Write32(0x7, kMMC_GCTRL);
  
  // Wait for reset to complete
  zx_nanosleep(zx_deadline_after(ZX_MSEC(10)));
  
  // Clear interrupts
  mmio_->Write32(0xFFFFFFFF, kMMC_RINT);
  
  // Set default timeout
  mmio_->Write32(0xFFFFFF00, kMMC_TIMEOUT);
  
  zxlogf(DEBUG, "MMC controller reset complete");
}

static constexpr zx_driver_ops_t driver_ops = []() {
  zx_driver_ops_t ops = {};
  ops.version = DRIVER_OPS_VERSION;
  ops.bind = SoliloquyMmc::Create;
  return ops;
}();

}  // namespace soliloquy_mmc

ZIRCON_DRIVER(soliloquy_mmc, soliloquy_mmc::driver_ops, "soliloquy", "0.1");

#include "soliloquy.h"

#include <lib/ddk/debug.h>
#include <lib/ddk/metadata.h>
#include <lib/ddk/platform-defs.h>

namespace soliloquy {

static const pbus_mmio_t sdio_mmios[] = {
    {
        .base = 0x04021000, // SMHC1 (WiFi)
        .length = 0x1000,
    },
};

static const pbus_irq_t sdio_irqs[] = {
    {
        .irq = 58, // SMHC1 IRQ (Placeholder)
        .mode = ZX_INTERRUPT_MODE_LEVEL_HIGH,
    },
};

static const pbus_bti_t sdio_btis[] = {
    {
        .iommu_index = 0,
        .bti_id = kBtiSdio,
    },
};

static const pbus_dev_t sdio_dev = []() {
  pbus_dev_t dev = {};
  dev.name = "sdio";
  dev.vid = PDEV_VID_ALLWINNER;
  dev.pid = PDEV_PID_GENERIC;
  dev.did = PDEV_DID_ALLWINNER_SMHC;
  dev.mmio_list = sdio_mmios;
  dev.mmio_count = countof(sdio_mmios);
  dev.irq_list = sdio_irqs;
  dev.irq_count = countof(sdio_irqs);
  dev.bti_list = sdio_btis;
  dev.bti_count = countof(sdio_btis);
  return dev;
}();

zx_status_t Soliloquy::SdioInit() {
  zx_status_t status = pbus_.DeviceAdd(&sdio_dev);
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: DeviceAdd(sdio) failed: %d", status);
    return status;
  }
  return ZX_OK;
}

} // namespace soliloquy

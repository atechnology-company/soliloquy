// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "soliloquy.h"

#include <ddk/debug.h>
#include <ddk/metadata.h>
#include <ddk/platform-defs.h>
#include <soc/allwinner/a527/a527-hw.h> // Hypothetical header, we'll define constants locally for now

namespace soliloquy {

// TODO: VERIFY THESE VALUES AGAINST A527 DATASHEET
// These are common Allwinner values but might differ for A527
static const pbus_mmio_t eth_mmios[] = {
    {
        .base = 0x04500000, // GMAC Base
        .length = 0x10000,
    },
};

static const pbus_irq_t eth_irqs[] = {
    {
        .irq = 114, // Common GMAC IRQ
        .mode = ZX_INTERRUPT_MODE_LEVEL_HIGH,
    },
};

static const pbus_bti_t eth_btis[] = {
    {
        .iommu_index = 0,
        .bti_id = kBtiEth,
    },
};

static const pbus_dev_t eth_dev = []() {
  pbus_dev_t dev = {};
  dev.name = "dwmac";
  dev.vid = PDEV_VID_DESIGNWARE;
  dev.pid = PDEV_PID_DESIGNWARE_GMAC;
  dev.did = PDEV_DID_DESIGNWARE_ETH_MAC;
  dev.mmio_list = eth_mmios;
  dev.mmio_count = countof(eth_mmios);
  dev.irq_list = eth_irqs;
  dev.irq_count = countof(eth_irqs);
  dev.bti_list = eth_btis;
  dev.bti_count = countof(eth_btis);
  return dev;
}();

zx_status_t Soliloquy::EthInit() {
  zx_status_t status = pbus_.DeviceAdd(&eth_dev);
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: DeviceAdd(eth) failed: %d", status);
    return status;
  }
  return ZX_OK;
}

} // namespace soliloquy

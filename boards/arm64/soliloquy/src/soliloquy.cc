// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "soliloquy.h"

#include <ddk/binding.h>
#include <ddk/debug.h>
#include <ddk/driver.h>
#include <ddk/platform-defs.h>
#include <fbl/alloc_checker.h>
#include <zircon/status.h>
#include <zircon/types.h>

namespace soliloquy {

zx_status_t Soliloquy::Create(void *ctx, zx_device_t *parent) {
  ddk::PBusProtocolClient pbus(parent);
  if (!pbus.is_valid()) {
    zxlogf(ERROR, "Soliloquy: Failed to get PBus protocol");
    return ZX_ERR_NO_RESOURCES;
  }

  fbl::AllocChecker ac;
  auto board = fbl::make_unique_checked<Soliloquy>(&ac, parent, pbus);
  if (!ac.check()) {
    return ZX_ERR_NO_MEMORY;
  }

  zx_status_t status = board->DdkAdd("soliloquy", DEVICE_ADD_NON_BINDABLE);
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: DdkAdd failed: %d", status);
    return status;
  }

  status = board->Start();
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: Start failed: %d", status);
    return status;
  }

  // board is now owned by DDK
  [[maybe_unused]] auto ptr = board.release();
  return ZX_OK;
}

zx_status_t Soliloquy::Start() {
  zx_status_t status;

  // Initialize GPIO
  status = GpioInit();
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: GpioInit failed: %d", status);
  }

  // Initialize Ethernet
  status = EthInit();
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: EthInit failed: %d", status);
  }

  // Initialize SDIO
  status = SdioInit();
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: SdioInit failed: %d", status);
  }

  return ZX_OK;
}

static constexpr zx_driver_ops_t soliloquy_driver_ops = []() {
  zx_driver_ops_t ops = {};
  ops.version = DRIVER_OPS_VERSION;
  ops.bind = Soliloquy::Create;
  return ops;
}();

} // namespace soliloquy

ZIRCON_DRIVER(soliloquy, soliloquy::soliloquy_driver_ops, "zircon", "0.1");

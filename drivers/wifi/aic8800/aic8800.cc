// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "aic8800.h"

#include <lib/ddk/debug.h>
#include <lib/ddk/device.h>
#include <lib/ddk/driver.h>
#include <lib/ddk/platform-defs.h>
#include <zircon/status.h>
#include <zircon/types.h>

#include <memory>

namespace aic8800 {

Aic8800::Aic8800(zx_device_t *parent)
    : Aic8800Type(parent), sdio_(parent), sdio_helper_(&sdio_) {}

Aic8800::~Aic8800() {}

zx_status_t Aic8800::Bind(void *ctx, zx_device_t *device) {
  auto dev = std::make_unique<Aic8800>(device);
  zx_status_t status = dev->DdkAdd("aic8800");
  if (status != ZX_OK) {
    zxlogf(ERROR, "aic8800: Could not create device: %s",
           zx_status_get_string(status));
    return status;
  }
  // dev is now owned by the DDK
  [[maybe_unused]] auto ptr = dev.release();
  return ZX_OK;
}

void Aic8800::DdkInit(ddk::InitTxn txn) {
  zx_status_t status = InitHw();
  txn.Reply(status);
}

void Aic8800::DdkUnbind(ddk::UnbindTxn txn) { txn.Reply(); }

void Aic8800::DdkRelease() { delete this; }

zx_status_t Aic8800::InitHw() {
  zxlogf(INFO, "aic8800: Initializing hardware...");

  const char *kFwName = "fmacfw_8800d80.bin";

  zx::vmo fw_vmo;
  size_t fw_size;
  zx_status_t status = soliloquy_hal::FirmwareLoader::LoadFirmware(
      parent(), kFwName, &fw_vmo, &fw_size);
  if (status != ZX_OK) {
    return status;
  }

  status = sdio_helper_.DownloadFirmware(fw_vmo, fw_size, kFirmwareBaseAddr);
  if (status != ZX_OK) {
    zxlogf(ERROR, "aic8800: Failed to download firmware: %s",
           zx_status_get_string(status));
    return status;
  }

  zxlogf(INFO, "aic8800: Hardware initialization complete");
  return ZX_OK;
}

// WlanphyImplProtocol implementation stubs
zx_status_t Aic8800::WlanphyImplQuery(wlanphy_info_t *out_info) {
  return ZX_ERR_NOT_SUPPORTED;
}

zx_status_t
Aic8800::WlanphyImplCreateIface(const wlanphy_create_iface_req_t *req,
                                uint16_t *out_iface_id) {
  return ZX_ERR_NOT_SUPPORTED;
}

zx_status_t Aic8800::WlanphyImplDestroyIface(uint16_t iface_id) {
  return ZX_ERR_NOT_SUPPORTED;
}

zx_status_t Aic8800::WlanphyImplSetCountry(const wlanphy_country_t *country) {
  return ZX_ERR_NOT_SUPPORTED;
}

zx_status_t Aic8800::WlanphyImplClearCountry() { return ZX_ERR_NOT_SUPPORTED; }

zx_status_t Aic8800::WlanphyImplGetCountry(wlanphy_country_t *out_country) {
  return ZX_ERR_NOT_SUPPORTED;
}

static constexpr zx_driver_ops_t aic8800_driver_ops = []() {
  zx_driver_ops_t ops = {};
  ops.version = DRIVER_OPS_VERSION;
  ops.bind = Aic8800::Bind;
  return ops;
}();

} // namespace aic8800

ZIRCON_DRIVER(aic8800, aic8800::aic8800_driver_ops, "zircon", "0.1");

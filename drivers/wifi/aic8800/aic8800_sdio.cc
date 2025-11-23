// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "aic8800.h"
#include <lib/ddk/debug.h>

namespace aic8800 {

zx_status_t Aic8800::SdioRead(uint32_t addr, uint8_t *val) {
  return sdio_.DoRwByte(false, addr, 0, val);
}

zx_status_t Aic8800::SdioWrite(uint32_t addr, uint8_t val) {
  return sdio_.DoRwByte(true, addr, val, nullptr);
}

zx_status_t Aic8800::DownloadFirmware(const zx::vmo &fw_vmo, size_t size) {
  // TODO: Implement firmware download logic using SDIO block writes
  // This will involve mapping the VMO and writing it to the chip in blocks
  // For now, just log that we would download it
  zxlogf(INFO, "aic8800: Downloading firmware (size: %zu)", size);

  // Placeholder for actual download loop
  // sdio_.DoRwTxn(...)

  return ZX_OK;
}

} // namespace aic8800

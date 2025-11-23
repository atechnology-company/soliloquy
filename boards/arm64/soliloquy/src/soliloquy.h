// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BOARDS_ARM64_SOLILOQUY_SRC_SOLILOQUY_H_
#define BOARDS_ARM64_SOLILOQUY_SRC_SOLILOQUY_H_

#include <ddktl/device.h>
#include <ddktl/protocol/platform/bus.h>
#include <zircon/status.h>
#include <zircon/types.h>

namespace soliloquy {

// BTI IDs
enum {
  kBtiEth = 0,
  kBtiMali,
  kBtiSdio,
};

class Soliloquy : public ddk::Device<Soliloquy> {
public:
  Soliloquy(zx_device_t *parent, ddk::PBusProtocolClient pbus)
      : ddk::Device<Soliloquy>(parent), pbus_(pbus) {}

  static zx_status_t Create(void *ctx, zx_device_t *parent);

  void DdkRelease() { delete this; }

  zx_status_t Start();

private:
  zx_status_t EthInit();
  zx_status_t GpioInit();
  zx_status_t SdioInit();

  ddk::PBusProtocolClient pbus_;
};

// TODO: Move these to a shared header
#define PDEV_VID_ALLWINNER 0x1C
#define PDEV_DID_ALLWINNER_SMHC 0x01
#define PDEV_DID_ALLWINNER_GPIO 0x02
#define kBtiSdio 0x02

} // namespace soliloquy

#endif // BOARDS_ARM64_SOLILOQUY_SRC_SOLILOQUY_H_

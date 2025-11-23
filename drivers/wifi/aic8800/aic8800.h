// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SRC_CONNECTIVITY_WLAN_DRIVERS_THIRD_PARTY_AIC8800_AIC8800_H_
#define SRC_CONNECTIVITY_WLAN_DRIVERS_THIRD_PARTY_AIC8800_AIC8800_H_

#include <ddktl/device.h>
#include <ddktl/protocol/wlanphyimpl.h>
#include <fuchsia/hardware/sdio/cpp/banjo.h>
#include <lib/ddk/device.h>
#include <lib/ddk/driver.h>

#include "../../common/soliloquy_hal/firmware.h"
#include "../../common/soliloquy_hal/sdio.h"

namespace aic8800 {

class Aic8800;
using Aic8800Type = ddk::Device<Aic8800, ddk::Initializable, ddk::Unbindable>;

class Aic8800 : public Aic8800Type,
                public ddk::WlanphyImplProtocol<Aic8800, ddk::base_protocol> {
public:
  explicit Aic8800(zx_device_t *parent);
  virtual ~Aic8800();

  static zx_status_t Bind(void *ctx, zx_device_t *device);

  // DDK Lifecycle methods
  void DdkInit(ddk::InitTxn txn);
  void DdkUnbind(ddk::UnbindTxn txn);
  void DdkRelease();

  // WlanphyImplProtocol methods
  zx_status_t WlanphyImplQuery(wlanphy_info_t *out_info);
  zx_status_t WlanphyImplCreateIface(const wlanphy_create_iface_req_t *req,
                                     uint16_t *out_iface_id);
  zx_status_t WlanphyImplDestroyIface(uint16_t iface_id);
  zx_status_t WlanphyImplSetCountry(const wlanphy_country_t *country);
  zx_status_t WlanphyImplClearCountry();
  zx_status_t WlanphyImplGetCountry(wlanphy_country_t *out_country);

private:
  zx_status_t InitHw();

  ddk::SdioProtocolClient sdio_;
  soliloquy_hal::SdioHelper sdio_helper_;

  // Hardware specific constants
  static constexpr uint32_t kVendorId = 0x1234; // Placeholder
  static constexpr uint32_t kDeviceId = 0x5678; // Placeholder
  static constexpr uint32_t kFirmwareBaseAddr = 0x00100000;
};

} // namespace aic8800

#endif // SRC_CONNECTIVITY_WLAN_DRIVERS_THIRD_PARTY_AIC8800_AIC8800_H_

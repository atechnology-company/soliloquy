// Copyright 2024 Soliloquy Authors
// SPDX-License-Identifier: Apache-2.0
//
// Soliloquy HID Input Driver
// Touchscreen and button input handling

#include <lib/ddk/binding.h>
#include <lib/ddk/debug.h>
#include <lib/ddk/device.h>
#include <lib/ddk/driver.h>
#include <lib/ddk/platform-defs.h>
#include <lib/device-protocol/pdev.h>

#include <ddktl/device.h>
#include <fbl/alloc_checker.h>

#include <fuchsia/hardware/hidbus/cpp/banjo.h>
#include <hid/descriptor.h>

namespace soliloquy_hid {

// Touchscreen HID report descriptor
constexpr uint8_t kTouchReportDesc[] = {
    HID_USAGE_PAGE(0x0D),  // Digitizer
    HID_USAGE(0x04),       // Touch Screen
    HID_COLLECTION_APPLICATION,
    
    // Finger
    HID_USAGE(0x22),  // Finger
    HID_COLLECTION_LOGICAL,
    
    // Tip switch
    HID_USAGE(0x42),
    HID_LOGICAL_MIN(0),
    HID_LOGICAL_MAX(1),
    HID_REPORT_SIZE(1),
    HID_REPORT_COUNT(1),
    HID_INPUT(HID_IOF_DATA | HID_IOF_VARIABLE | HID_IOF_ABSOLUTE),
    
    // Padding
    HID_REPORT_SIZE(7),
    HID_REPORT_COUNT(1),
    HID_INPUT(HID_IOF_CONSTANT),
    
    // X coordinate
    HID_USAGE_PAGE(0x01),  // Generic Desktop
    HID_USAGE(0x30),       // X
    HID_LOGICAL_MIN(0),
    HID_LOGICAL_MAX_N(4095, 2),
    HID_REPORT_SIZE(16),
    HID_REPORT_COUNT(1),
    HID_INPUT(HID_IOF_DATA | HID_IOF_VARIABLE | HID_IOF_ABSOLUTE),
    
    // Y coordinate
    HID_USAGE(0x31),  // Y
    HID_LOGICAL_MIN(0),
    HID_LOGICAL_MAX_N(4095, 2),
    HID_REPORT_SIZE(16),
    HID_REPORT_COUNT(1),
    HID_INPUT(HID_IOF_DATA | HID_IOF_VARIABLE | HID_IOF_ABSOLUTE),
    
    HID_END_COLLECTION,
    HID_END_COLLECTION,
};

class SoliloquyHid;
using DeviceType = ddk::Device<SoliloquyHid, ddk::Unbindable>;

class SoliloquyHid : public DeviceType,
                      public ddk::HidbusProtocol<SoliloquyHid, ddk::base_protocol> {
 public:
  explicit SoliloquyHid(zx_device_t* parent) : DeviceType(parent) {}

  static zx_status_t Create(void* ctx, zx_device_t* parent);

  // Device protocol implementation
  void DdkRelease() { delete this; }
  void DdkUnbind(ddk::UnbindTxn txn) { txn.Reply(); }

  // Hidbus protocol implementation
  zx_status_t HidbusQuery(uint32_t options, hid_info_t* out_info) {
    out_info->dev_num = 0;
    out_info->device_class = HID_DEVICE_CLASS_POINTER;
    out_info->boot_device = false;
    return ZX_OK;
  }

  zx_status_t HidbusStart(const hidbus_ifc_protocol_t* ifc) {
    ifc_ = ddk::HidbusIfcProtocolClient(ifc);
    return ZX_OK;
  }

  void HidbusStop() {
    ifc_.clear();
  }

  zx_status_t HidbusGetDescriptor(hid_description_type_t desc_type, uint8_t* out_data_buffer,
                                   size_t data_size, size_t* out_data_actual) {
    if (desc_type != HID_DESCRIPTION_TYPE_REPORT) {
      return ZX_ERR_NOT_FOUND;
    }
    if (data_size < sizeof(kTouchReportDesc)) {
      return ZX_ERR_BUFFER_TOO_SMALL;
    }
    memcpy(out_data_buffer, kTouchReportDesc, sizeof(kTouchReportDesc));
    *out_data_actual = sizeof(kTouchReportDesc);
    return ZX_OK;
  }

  zx_status_t HidbusGetReport(hid_report_type_t rpt_type, uint8_t rpt_id,
                               uint8_t* out_data_buffer, size_t data_size,
                               size_t* out_data_actual) {
    return ZX_ERR_NOT_SUPPORTED;
  }

  zx_status_t HidbusSetReport(hid_report_type_t rpt_type, uint8_t rpt_id,
                               const uint8_t* data_buffer, size_t data_size) {
    return ZX_ERR_NOT_SUPPORTED;
  }

  zx_status_t HidbusGetIdle(uint8_t rpt_id, uint8_t* out_duration) {
    return ZX_ERR_NOT_SUPPORTED;
  }

  zx_status_t HidbusSetIdle(uint8_t rpt_id, uint8_t duration) {
    return ZX_OK;
  }

  zx_status_t HidbusGetProtocol(hid_protocol_t* out_protocol) {
    *out_protocol = HID_PROTOCOL_REPORT;
    return ZX_OK;
  }

  zx_status_t HidbusSetProtocol(hid_protocol_t protocol) {
    return ZX_OK;
  }

 private:
  zx_status_t Init();

  ddk::HidbusIfcProtocolClient ifc_;
};

zx_status_t SoliloquyHid::Create(void* ctx, zx_device_t* parent) {
  fbl::AllocChecker ac;
  auto dev = fbl::make_unique_checked<SoliloquyHid>(&ac, parent);
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

zx_status_t SoliloquyHid::Init() {
  auto status = DdkAdd("soliloquy-hid");
  if (status != ZX_OK) {
    zxlogf(ERROR, "Failed to add HID device: %s", zx_status_get_string(status));
    return status;
  }

  zxlogf(INFO, "Soliloquy HID driver initialized");
  return ZX_OK;
}

static constexpr zx_driver_ops_t driver_ops = []() {
  zx_driver_ops_t ops = {};
  ops.version = DRIVER_OPS_VERSION;
  ops.bind = SoliloquyHid::Create;
  return ops;
}();

}  // namespace soliloquy_hid

ZIRCON_DRIVER(soliloquy_hid, soliloquy_hid::driver_ops, "soliloquy", "0.1");

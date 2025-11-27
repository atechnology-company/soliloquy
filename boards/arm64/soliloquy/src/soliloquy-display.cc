// Copyright 2024 Soliloquy Authors
// SPDX-License-Identifier: Apache-2.0
//
// Soliloquy Display Driver
// Allwinner DE3.0 Display Engine (DRM-style framebuffer)

#include <lib/ddk/binding.h>
#include <lib/ddk/debug.h>
#include <lib/ddk/device.h>
#include <lib/ddk/driver.h>
#include <lib/ddk/platform-defs.h>
#include <lib/device-protocol/pdev.h>
#include <lib/mmio/mmio.h>
#include <lib/zx/vmo.h>

#include <ddktl/device.h>
#include <ddktl/fidl.h>
#include <fbl/alloc_checker.h>

#include <fuchsia/hardware/display/controller/cpp/banjo.h>

namespace soliloquy_display {

// Allwinner DE3.0 Display Engine registers
constexpr uint32_t kDE3_BASE = 0x01000000;
constexpr uint32_t kTCON_BASE = 0x05461000;

// Display mode configuration
struct DisplayMode {
  uint32_t width;
  uint32_t height;
  uint32_t refresh_hz;
  uint32_t pixel_clock_khz;
};

// Default 720p mode for development
constexpr DisplayMode kDefaultMode = {
    .width = 1280,
    .height = 720,
    .refresh_hz = 60,
    .pixel_clock_khz = 74250,
};

class SoliloquyDisplay;
using DeviceType = ddk::Device<SoliloquyDisplay, ddk::Unbindable>;

class SoliloquyDisplay : public DeviceType,
                          public ddk::DisplayControllerImplProtocol<SoliloquyDisplay,
                                                                     ddk::base_protocol> {
 public:
  explicit SoliloquyDisplay(zx_device_t* parent) : DeviceType(parent) {}

  static zx_status_t Create(void* ctx, zx_device_t* parent);

  // Device protocol implementation
  void DdkRelease() { delete this; }
  void DdkUnbind(ddk::UnbindTxn txn) { txn.Reply(); }

  // DisplayControllerImpl protocol implementation
  void DisplayControllerImplSetDisplayControllerInterface(
      const display_controller_interface_protocol_t* intf) {
    intf_ = ddk::DisplayControllerInterfaceProtocolClient(intf);
    has_display_ = true;
    
    // Notify display manager we have a display
    if (intf_.is_valid()) {
      added_display_args_t args = {};
      args.display_id = kDisplayId;
      args.edid_present = false;
      
      // Report panel type
      args.panel.params.height = mode_.height;
      args.panel.params.width = mode_.width;
      args.panel.params.refresh_rate_e2 = mode_.refresh_hz * 100;
      
      // Supported pixel formats
      static const zx_pixel_format_t kPixelFormats[] = {
          ZX_PIXEL_FORMAT_ARGB_8888,
          ZX_PIXEL_FORMAT_RGB_x888,
      };
      args.pixel_format_list = kPixelFormats;
      args.pixel_format_count = std::size(kPixelFormats);
      
      uint64_t display_added;
      intf_.OnDisplaysChanged(&args, 1, nullptr, 0, &display_added, 1, nullptr, 0);
    }
  }

  zx_status_t DisplayControllerImplImportBufferCollection(
      uint64_t banjo_driver_buffer_collection_id, zx::channel collection_token) {
    return ZX_OK;
  }

  zx_status_t DisplayControllerImplReleaseBufferCollection(
      uint64_t banjo_driver_buffer_collection_id) {
    return ZX_OK;
  }

  zx_status_t DisplayControllerImplImportImage(const image_metadata_t* image_metadata,
                                                 uint64_t banjo_driver_buffer_collection_id,
                                                 uint32_t index, uint64_t* out_image_handle) {
    *out_image_handle = next_image_handle_++;
    return ZX_OK;
  }

  zx_status_t DisplayControllerImplImportImageForCapture(
      uint64_t banjo_driver_buffer_collection_id, uint32_t index, uint64_t* out_capture_handle) {
    return ZX_ERR_NOT_SUPPORTED;
  }

  void DisplayControllerImplReleaseImage(uint64_t image_handle) {}

  config_check_result_t DisplayControllerImplCheckConfiguration(
      const display_config_t** display_configs, size_t display_count,
      client_composition_opcode_t* out_client_composition_opcodes_list,
      size_t client_composition_opcodes_count, size_t* out_client_composition_opcodes_actual) {
    *out_client_composition_opcodes_actual = 0;
    return CONFIG_CHECK_RESULT_OK;
  }

  void DisplayControllerImplApplyConfiguration(const display_config_t** display_configs,
                                                 size_t display_count,
                                                 const config_stamp_t* banjo_config_stamp) {
    // Apply the display configuration
    if (display_count > 0 && display_configs[0]->layer_count > 0) {
      // In a real driver, we'd program the hardware here
      zxlogf(DEBUG, "Applying display config with %zu layers",
             display_configs[0]->layer_count);
    }
  }

  void DisplayControllerImplSetEld(uint64_t display_id, const uint8_t* raw_eld_list,
                                    size_t raw_eld_count) {}

  zx_status_t DisplayControllerImplSetBufferCollectionConstraints(
      const image_buffer_usage_t* usage, uint64_t banjo_driver_buffer_collection_id) {
    return ZX_OK;
  }

  zx_status_t DisplayControllerImplSetDisplayPower(uint64_t display_id, bool power_on) {
    display_powered_ = power_on;
    return ZX_OK;
  }

  bool DisplayControllerImplIsCaptureSupported() { return false; }

  zx_status_t DisplayControllerImplStartCapture(uint64_t capture_handle) {
    return ZX_ERR_NOT_SUPPORTED;
  }

  zx_status_t DisplayControllerImplReleaseCapture(uint64_t capture_handle) {
    return ZX_ERR_NOT_SUPPORTED;
  }

  zx_status_t DisplayControllerImplSetMinimumRgb(uint8_t minimum_rgb) {
    return ZX_OK;
  }

 private:
  static constexpr uint64_t kDisplayId = 1;

  zx_status_t Init();
  zx_status_t InitHardware();

  ddk::DisplayControllerInterfaceProtocolClient intf_;
  std::optional<fdf::MmioBuffer> de_mmio_;
  std::optional<fdf::MmioBuffer> tcon_mmio_;
  
  DisplayMode mode_ = kDefaultMode;
  bool has_display_ = false;
  bool display_powered_ = true;
  uint64_t next_image_handle_ = 1;
};

zx_status_t SoliloquyDisplay::Create(void* ctx, zx_device_t* parent) {
  fbl::AllocChecker ac;
  auto dev = fbl::make_unique_checked<SoliloquyDisplay>(&ac, parent);
  if (!ac.check()) {
    return ZX_ERR_NO_MEMORY;
  }

  auto status = dev->Init();
  if (status != ZX_OK) {
    return status;
  }

  // devmgr is now in charge of the device
  [[maybe_unused]] auto* dummy = dev.release();
  return ZX_OK;
}

zx_status_t SoliloquyDisplay::Init() {
  auto status = InitHardware();
  if (status != ZX_OK) {
    zxlogf(ERROR, "Failed to init display hardware: %s", zx_status_get_string(status));
    // Continue anyway - we can operate in software rendering mode
  }

  status = DdkAdd(ddk::DeviceAddArgs("soliloquy-display")
                      .set_flags(DEVICE_ADD_ALLOW_MULTI_COMPOSITE)
                      .set_proto_id(ZX_PROTOCOL_DISPLAY_CONTROLLER_IMPL));
  if (status != ZX_OK) {
    zxlogf(ERROR, "Failed to add device: %s", zx_status_get_string(status));
    return status;
  }

  zxlogf(INFO, "Soliloquy display driver initialized (%ux%u@%uHz)",
         mode_.width, mode_.height, mode_.refresh_hz);
  return ZX_OK;
}

zx_status_t SoliloquyDisplay::InitHardware() {
  ddk::PDevProtocolClient pdev(parent());
  if (!pdev.is_valid()) {
    zxlogf(WARNING, "No platform device - using software mode");
    return ZX_OK;
  }

  // Map DE3.0 registers
  std::optional<fdf::MmioBuffer> de_mmio;
  auto status = pdev.MapMmio(0, &de_mmio);
  if (status != ZX_OK) {
    zxlogf(WARNING, "Failed to map DE MMIO: %s", zx_status_get_string(status));
  } else {
    de_mmio_ = std::move(de_mmio);
  }

  // Map TCON registers
  std::optional<fdf::MmioBuffer> tcon_mmio;
  status = pdev.MapMmio(1, &tcon_mmio);
  if (status != ZX_OK) {
    zxlogf(WARNING, "Failed to map TCON MMIO: %s", zx_status_get_string(status));
  } else {
    tcon_mmio_ = std::move(tcon_mmio);
  }

  // TODO: Full hardware initialization
  // - Configure display engine clocks
  // - Set up framebuffer
  // - Configure TCON timing generator
  // - Enable display output

  return ZX_OK;
}

static constexpr zx_driver_ops_t driver_ops = []() {
  zx_driver_ops_t ops = {};
  ops.version = DRIVER_OPS_VERSION;
  ops.bind = SoliloquyDisplay::Create;
  return ops;
}();

}  // namespace soliloquy_display

ZIRCON_DRIVER(soliloquy_display, soliloquy_display::driver_ops, "soliloquy", "0.1");

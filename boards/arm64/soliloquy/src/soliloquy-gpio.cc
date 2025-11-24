#include "soliloquy.h"

#include <ddk/debug.h>
#include <ddk/metadata.h>
#include <ddk/platform-defs.h>

namespace soliloquy {

static const pbus_mmio_t gpio_mmios[] = {
    {
        .base = 0x01C20800,
        .length = 0x400,
    },
};

static const pbus_dev_t gpio_dev = []() {
  pbus_dev_t dev = {};
  dev.name = "gpio";
  dev.vid = PDEV_VID_ALLWINNER;
  dev.pid = PDEV_PID_GENERIC;
  dev.did = PDEV_DID_ALLWINNER_GPIO;
  dev.mmio_list = gpio_mmios;
  dev.mmio_count = countof(gpio_mmios);
  return dev;
}();

zx_status_t Soliloquy::GpioInit() {
  zx_status_t status = pbus_.DeviceAdd(&gpio_dev);
  if (status != ZX_OK) {
    zxlogf(ERROR, "Soliloquy: DeviceAdd(gpio) failed: %d", status);
    return status;
  }
  zxlogf(INFO, "Soliloquy: GPIO controller initialized");
  return ZX_OK;
}

} // namespace soliloquy

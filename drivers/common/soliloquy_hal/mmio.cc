// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mmio.h"

#include <lib/ddk/debug.h>
#include <zircon/time.h>

namespace soliloquy_hal {

uint32_t MmioHelper::Read32(uint32_t offset) {
  return mmio_->Read32(offset);
}

void MmioHelper::Write32(uint32_t offset, uint32_t value) {
  mmio_->Write32(value, offset);
}

void MmioHelper::SetBits32(uint32_t offset, uint32_t mask) {
  uint32_t val = Read32(offset);
  Write32(offset, val | mask);
}

void MmioHelper::ClearBits32(uint32_t offset, uint32_t mask) {
  uint32_t val = Read32(offset);
  Write32(offset, val & ~mask);
}

void MmioHelper::ModifyBits32(uint32_t offset, uint32_t mask, uint32_t value) {
  uint32_t val = Read32(offset);
  val = (val & ~mask) | (value & mask);
  Write32(offset, val);
}

uint32_t MmioHelper::ReadMasked32(uint32_t offset, uint32_t mask,
                                  uint32_t shift) {
  return (Read32(offset) & mask) >> shift;
}

void MmioHelper::WriteMasked32(uint32_t offset, uint32_t mask, uint32_t shift,
                               uint32_t value) {
  uint32_t val = Read32(offset);
  val = (val & ~mask) | ((value << shift) & mask);
  Write32(offset, val);
}

bool MmioHelper::WaitForBit32(uint32_t offset, uint32_t bit, bool set,
                              zx::duration timeout) {
  zx_time_t deadline = zx_deadline_after(timeout.get());

  while (zx_clock_get_monotonic() < deadline) {
    uint32_t val = Read32(offset);
    bool bit_set = (val & (1 << bit)) != 0;

    if (bit_set == set) {
      return true;
    }

    zx_nanosleep(zx_deadline_after(ZX_USEC(10)));
  }

  zxlogf(WARNING, "soliloquy_hal: Timeout waiting for bit %u at offset 0x%x",
         bit, offset);
  return false;
}

} // namespace soliloquy_hal

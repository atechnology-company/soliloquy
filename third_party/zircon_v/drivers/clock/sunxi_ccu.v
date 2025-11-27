// Allwinner A527/T527 Clock Control Unit (CCU) Driver
// Translated to V language for Soliloquy OS
//
// Based on Linux sunxi-ng clock driver
// Provides clock gating, reset control, and PLL management
//
// Reference: Linux drivers/clk/sunxi-ng/ccu-sun55i-a527.c

module clock

import sync

// =============================================================================
// ZX Status codes (matching kernel conventions)
// =============================================================================
pub enum ZxStatus {
	ok = 0
	err_invalid_args = -10
	err_not_found = -3
	err_timed_out = -21
	err_io = -5
}

// =============================================================================
// Clock source abstraction
// =============================================================================
pub struct ClockSource {
pub:
	name     string
	id       ClockId
	freq_hz  u64
	parent   ?&ClockSource
}

// =============================================================================
// CCU Driver structure
// =============================================================================
pub struct SunxiCcu {
pub mut:
	base         u64           // MMIO base address
	lock         sync.Mutex    // For thread safety
	hosc_rate    u64           // HOSC frequency (usually 24MHz)
	pll_states   map[ClockId]bool  // Track which PLLs are enabled
	clock_rates  map[ClockId]u64   // Cached clock rates
}

// =============================================================================
// MMIO access helpers (will be linked to actual HAL)
// =============================================================================
fn mmio_read32(base u64, offset u32) u32 {
	// In real implementation, this would do actual MMIO read
	// For now, this is a stub that would be replaced by HAL
	return unsafe { *(&u32(base + u64(offset))) }
}

fn mmio_write32(base u64, offset u32, value u32) {
	// In real implementation, this would do actual MMIO write
	unsafe { *(&u32(base + u64(offset))) = value }
}

fn mmio_set_bits32(base u64, offset u32, bits u32) {
	val := mmio_read32(base, offset)
	mmio_write32(base, offset, val | bits)
}

fn mmio_clear_bits32(base u64, offset u32, bits u32) {
	val := mmio_read32(base, offset)
	mmio_write32(base, offset, val & ~bits)
}

// Simple microsecond delay
fn delay_us(us u32) {
	// Busy-wait loop - will be replaced with proper timer
	mut count := us * 100
	for count > 0 {
		count--
	}
}

// =============================================================================
// CCU Driver implementation
// =============================================================================

// Create a new CCU driver instance
pub fn SunxiCcu.new(base u64) SunxiCcu {
	return SunxiCcu{
		base: base
		hosc_rate: hosc_freq
		pll_states: map[ClockId]bool{}
		clock_rates: map[ClockId]u64{}
	}
}

// Initialize the CCU
pub fn (mut self SunxiCcu) init() ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	// Enable PLL_PERI0 which is parent for most peripherals
	status := self.enable_pll_locked(.pll_peri0)
	if status != .ok {
		return status
	}
	
	// Wait for PLL to lock
	for _ in 0 .. 1000 {
		reg := mmio_read32(self.base, pll_peri0_ctrl)
		if is_pll_locked(reg) {
			break
		}
		delay_us(10)
	}
	
	// Cache the PLL_PERI0 rate
	self.clock_rates[.pll_peri0] = pll_peri0_freq
	
	return .ok
}

// Enable a PLL (internal, must hold lock)
fn (mut self SunxiCcu) enable_pll_locked(pll ClockId) ZxStatus {
	offset := match pll {
		.pll_cpux { pll_cpux_ctrl }
		.pll_peri0 { pll_peri0_ctrl }
		.pll_peri1 { pll_peri1_ctrl }
		.pll_gpu { pll_gpu0_ctrl }
		.pll_video0 { pll_video0_ctrl }
		.pll_video1 { pll_video1_ctrl }
		.pll_video2 { pll_video2_ctrl }
		.pll_ve { pll_ve0_ctrl }
		.pll_audio0 { pll_audio0_ctrl }
		.pll_npu { pll_npu_ctrl }
		.pll_ddr0 { pll_ddr0_ctrl }
		else { return .err_invalid_args }
	}
	
	// Read current value
	mut reg := mmio_read32(self.base, offset)
	
	// Enable LDO first
	reg |= pll_ldo_enable
	mmio_write32(self.base, offset, reg)
	delay_us(5)
	
	// Enable PLL
	reg |= pll_enable
	mmio_write32(self.base, offset, reg)
	
	// Enable lock
	reg |= pll_lock_enable
	mmio_write32(self.base, offset, reg)
	
	// Wait for lock
	for _ in 0 .. 1000 {
		reg = mmio_read32(self.base, offset)
		if (reg & pll_lock) != 0 {
			// Enable output
			reg |= pll_output_enable
			mmio_write32(self.base, offset, reg)
			self.pll_states[pll] = true
			return .ok
		}
		delay_us(10)
	}
	
	return .err_timed_out
}

// Disable a PLL (internal, must hold lock)
fn (mut self SunxiCcu) disable_pll_locked(pll ClockId) ZxStatus {
	offset := match pll {
		.pll_cpux { pll_cpux_ctrl }
		.pll_peri0 { pll_peri0_ctrl }
		.pll_peri1 { pll_peri1_ctrl }
		.pll_gpu { pll_gpu0_ctrl }
		.pll_video0 { pll_video0_ctrl }
		.pll_video1 { pll_video1_ctrl }
		.pll_video2 { pll_video2_ctrl }
		.pll_ve { pll_ve0_ctrl }
		.pll_audio0 { pll_audio0_ctrl }
		.pll_npu { pll_npu_ctrl }
		.pll_ddr0 { pll_ddr0_ctrl }
		else { return .err_invalid_args }
	}
	
	// Disable output first
	mut reg := mmio_read32(self.base, offset)
	reg &= ~pll_output_enable
	mmio_write32(self.base, offset, reg)
	
	// Disable PLL
	reg &= ~pll_enable
	mmio_write32(self.base, offset, reg)
	
	// Disable LDO
	reg &= ~pll_ldo_enable
	mmio_write32(self.base, offset, reg)
	
	self.pll_states[pll] = false
	return .ok
}

// =============================================================================
// Clock enable/disable for peripherals
// =============================================================================

// Enable a peripheral clock
pub fn (mut self SunxiCcu) enable_clock(id ClockId) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	gate_info := self.get_gate_info(id) or { return .err_not_found }
	
	// Set the clock gate bit
	mmio_set_bits32(self.base, gate_info.offset, u32(1) << gate_info.gate_bit)
	
	return .ok
}

// Disable a peripheral clock
pub fn (mut self SunxiCcu) disable_clock(id ClockId) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	gate_info := self.get_gate_info(id) or { return .err_not_found }
	
	// Clear the clock gate bit
	mmio_clear_bits32(self.base, gate_info.offset, u32(1) << gate_info.gate_bit)
	
	return .ok
}

// Assert reset for a peripheral
pub fn (mut self SunxiCcu) assert_reset(id ResetId) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	reset_info := self.get_reset_info(id) or { return .err_not_found }
	
	// Clear the reset bit (active low)
	mmio_clear_bits32(self.base, reset_info.offset, u32(1) << reset_info.reset_bit)
	
	return .ok
}

// Deassert reset for a peripheral
pub fn (mut self SunxiCcu) deassert_reset(id ResetId) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	reset_info := self.get_reset_info(id) or { return .err_not_found }
	
	// Set the reset bit (release from reset)
	mmio_set_bits32(self.base, reset_info.offset, u32(1) << reset_info.reset_bit)
	
	return .ok
}

// Enable clock and deassert reset in one call
pub fn (mut self SunxiCcu) enable_peripheral(clock_id ClockId, reset_id ResetId) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	// Get info for both
	gate_info := self.get_gate_info(clock_id) or { return .err_not_found }
	reset_info := self.get_reset_info(reset_id) or { return .err_not_found }
	
	// If same register, do both at once
	if gate_info.offset == reset_info.offset {
		mask := (u32(1) << gate_info.gate_bit) | (u32(1) << reset_info.reset_bit)
		mmio_set_bits32(self.base, gate_info.offset, mask)
	} else {
		mmio_set_bits32(self.base, gate_info.offset, u32(1) << gate_info.gate_bit)
		mmio_set_bits32(self.base, reset_info.offset, u32(1) << reset_info.reset_bit)
	}
	
	return .ok
}

// Disable clock and assert reset in one call
pub fn (mut self SunxiCcu) disable_peripheral(clock_id ClockId, reset_id ResetId) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	gate_info := self.get_gate_info(clock_id) or { return .err_not_found }
	reset_info := self.get_reset_info(reset_id) or { return .err_not_found }
	
	// Assert reset first, then disable clock
	mmio_clear_bits32(self.base, reset_info.offset, u32(1) << reset_info.reset_bit)
	mmio_clear_bits32(self.base, gate_info.offset, u32(1) << gate_info.gate_bit)
	
	return .ok
}

// =============================================================================
// MMC clock configuration
// =============================================================================

// Configure MMC clock
// target_hz: desired clock frequency
// Returns: actual clock frequency set
pub fn (mut self SunxiCcu) set_mmc_clock(mmc_id u32, target_hz u64) !u64 {
	if mmc_id > 2 {
		return error('Invalid MMC ID')
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	// Determine register offset
	offset := match mmc_id {
		0 { mmc0_clk }
		1 { mmc1_clk }
		2 { mmc2_clk }
		else { return error('Invalid MMC ID') }
	}
	
	// Choose clock source based on target frequency
	mut source_hz := u64(0)
	mut clk_src := u32(0)
	
	if target_hz <= 12_000_000 {
		// Use HOSC for low speeds
		source_hz = hosc_freq
		clk_src = clk_src_hosc
	} else if target_hz <= 100_000_000 {
		// Use PLL_PERI0 / 6 = 100MHz
		source_hz = pll_peri0_freq
		clk_src = clk_src_peri0
	} else {
		// Use PLL_PERI0x2 for higher speeds
		source_hz = pll_peri0x2_freq
		clk_src = clk_src_peri0x2
	}
	
	// Calculate optimal dividers
	n, m, actual_hz := calc_mmc_dividers(source_hz, target_hz)
	
	// Construct register value
	// Bits [31]: Clock enable
	// Bits [26:24]: Clock source select
	// Bits [17:16]: N (pre-divider, 2^N)
	// Bits [3:0]: M (divider, M+1)
	mut reg := u32(1) << 31              // Enable
	reg |= (clk_src & 0x7) << 24         // Clock source
	reg |= (n & 0x3) << 16               // N divider
	reg |= (m & 0xF)                     // M divider
	
	mmio_write32(self.base, offset, reg)
	
	return actual_hz
}

// Get current MMC clock frequency
pub fn (mut self SunxiCcu) get_mmc_clock(mmc_id u32) !u64 {
	if mmc_id > 2 {
		return error('Invalid MMC ID')
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	offset := match mmc_id {
		0 { mmc0_clk }
		1 { mmc1_clk }
		2 { mmc2_clk }
		else { return error('Invalid MMC ID') }
	}
	
	reg := mmio_read32(self.base, offset)
	
	// Check if enabled
	if (reg & (u32(1) << 31)) == 0 {
		return 0
	}
	
	// Get clock source
	clk_src := (reg >> 24) & 0x7
	source_hz := match clk_src {
		clk_src_hosc { hosc_freq }
		clk_src_peri0 { pll_peri0_freq }
		clk_src_peri0x2 { pll_peri0x2_freq }
		else { hosc_freq }
	}
	
	// Get dividers
	n := (reg >> 16) & 0x3
	m := reg & 0xF
	
	return calc_mmc_freq(source_hz, n, m)
}

// =============================================================================
// Helper functions to get gate/reset info
// =============================================================================

fn (self &SunxiCcu) get_gate_info(id ClockId) ?GateResetInfo {
	return match id {
		.mmc0 { mmc_gate_reset[0] }
		.mmc1 { mmc_gate_reset[1] }
		.mmc2 { mmc_gate_reset[2] }
		.uart0 { uart_gate_reset[0] }
		.uart1 { uart_gate_reset[1] }
		.uart2 { uart_gate_reset[2] }
		.uart3 { uart_gate_reset[3] }
		.uart4 { uart_gate_reset[4] }
		.uart5 { uart_gate_reset[5] }
		.i2c0 { i2c_gate_reset[0] }
		.i2c1 { i2c_gate_reset[1] }
		.i2c2 { i2c_gate_reset[2] }
		.i2c3 { i2c_gate_reset[3] }
		.i2c4 { i2c_gate_reset[4] }
		.i2c5 { i2c_gate_reset[5] }
		.spi0 { spi_gate_reset[0] }
		.spi1 { spi_gate_reset[1] }
		else { none }
	}
}

fn (self &SunxiCcu) get_reset_info(id ResetId) ?GateResetInfo {
	return match id {
		.mmc0 { mmc_gate_reset[0] }
		.mmc1 { mmc_gate_reset[1] }
		.mmc2 { mmc_gate_reset[2] }
		.uart0 { uart_gate_reset[0] }
		.uart1 { uart_gate_reset[1] }
		.uart2 { uart_gate_reset[2] }
		.uart3 { uart_gate_reset[3] }
		.uart4 { uart_gate_reset[4] }
		.uart5 { uart_gate_reset[5] }
		.i2c0 { i2c_gate_reset[0] }
		.i2c1 { i2c_gate_reset[1] }
		.i2c2 { i2c_gate_reset[2] }
		.i2c3 { i2c_gate_reset[3] }
		.i2c4 { i2c_gate_reset[4] }
		.i2c5 { i2c_gate_reset[5] }
		.spi0 { spi_gate_reset[0] }
		.spi1 { spi_gate_reset[1] }
		else { none }
	}
}

// =============================================================================
// Convenience functions for common peripherals
// =============================================================================

// Enable MMC controller and clock
pub fn (mut self SunxiCcu) enable_mmc(mmc_id u32, freq_hz u64) !u64 {
	if mmc_id > 2 {
		return error('Invalid MMC ID')
	}
	
	// Enable clock gate and deassert reset
	clock_id := match mmc_id {
		0 { ClockId.mmc0 }
		1 { ClockId.mmc1 }
		2 { ClockId.mmc2 }
		else { return error('Invalid MMC ID') }
	}
	
	reset_id := match mmc_id {
		0 { ResetId.mmc0 }
		1 { ResetId.mmc1 }
		2 { ResetId.mmc2 }
		else { return error('Invalid MMC ID') }
	}
	
	status := self.enable_peripheral(clock_id, reset_id)
	if status != .ok {
		return error('Failed to enable peripheral')
	}
	
	// Configure the module clock
	return self.set_mmc_clock(mmc_id, freq_hz)
}

// Disable MMC controller
pub fn (mut self SunxiCcu) disable_mmc(mmc_id u32) !bool {
	if mmc_id > 2 {
		return error('Invalid MMC ID')
	}
	
	clock_id := match mmc_id {
		0 { ClockId.mmc0 }
		1 { ClockId.mmc1 }
		2 { ClockId.mmc2 }
		else { return error('Invalid MMC ID') }
	}
	
	reset_id := match mmc_id {
		0 { ResetId.mmc0 }
		1 { ResetId.mmc1 }
		2 { ResetId.mmc2 }
		else { return error('Invalid MMC ID') }
	}
	
	status := self.disable_peripheral(clock_id, reset_id)
	return status == .ok
}

// Enable UART
pub fn (mut self SunxiCcu) enable_uart(uart_id u32) ZxStatus {
	if uart_id > 5 {
		return .err_invalid_args
	}
	
	clock_id := match uart_id {
		0 { ClockId.uart0 }
		1 { ClockId.uart1 }
		2 { ClockId.uart2 }
		3 { ClockId.uart3 }
		4 { ClockId.uart4 }
		5 { ClockId.uart5 }
		else { return .err_invalid_args }
	}
	
	reset_id := match uart_id {
		0 { ResetId.uart0 }
		1 { ResetId.uart1 }
		2 { ResetId.uart2 }
		3 { ResetId.uart3 }
		4 { ResetId.uart4 }
		5 { ResetId.uart5 }
		else { return .err_invalid_args }
	}
	
	return self.enable_peripheral(clock_id, reset_id)
}

// Enable I2C
pub fn (mut self SunxiCcu) enable_i2c(i2c_id u32) ZxStatus {
	if i2c_id > 5 {
		return .err_invalid_args
	}
	
	clock_id := match i2c_id {
		0 { ClockId.i2c0 }
		1 { ClockId.i2c1 }
		2 { ClockId.i2c2 }
		3 { ClockId.i2c3 }
		4 { ClockId.i2c4 }
		5 { ClockId.i2c5 }
		else { return .err_invalid_args }
	}
	
	reset_id := match i2c_id {
		0 { ResetId.i2c0 }
		1 { ResetId.i2c1 }
		2 { ResetId.i2c2 }
		3 { ResetId.i2c3 }
		4 { ResetId.i2c4 }
		5 { ResetId.i2c5 }
		else { return .err_invalid_args }
	}
	
	return self.enable_peripheral(clock_id, reset_id)
}

// Enable SPI
pub fn (mut self SunxiCcu) enable_spi(spi_id u32) ZxStatus {
	if spi_id > 1 {
		return .err_invalid_args
	}
	
	clock_id := match spi_id {
		0 { ClockId.spi0 }
		1 { ClockId.spi1 }
		else { return .err_invalid_args }
	}
	
	reset_id := match spi_id {
		0 { ResetId.spi0 }
		1 { ResetId.spi1 }
		else { return .err_invalid_args }
	}
	
	return self.enable_peripheral(clock_id, reset_id)
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_ccu_creation() {
	ccu := SunxiCcu.new(ccu_base)
	assert ccu.base == ccu_base
	assert ccu.hosc_rate == 24_000_000
}

fn test_clock_id_gate_mapping() {
	ccu := SunxiCcu.new(ccu_base)
	
	// Test that we can get gate info for known clocks
	mmc0_info := ccu.get_gate_info(.mmc0) or {
		assert false, 'Should find MMC0'
		return
	}
	assert mmc0_info.offset == smhc_bgr
	assert mmc0_info.gate_bit == 0
	
	uart0_info := ccu.get_gate_info(.uart0) or {
		assert false, 'Should find UART0'
		return
	}
	assert uart0_info.offset == uart_bgr
	assert uart0_info.gate_bit == 0
}

fn test_reset_id_mapping() {
	ccu := SunxiCcu.new(ccu_base)
	
	// Test reset info retrieval
	mmc0_reset := ccu.get_reset_info(.mmc0) or {
		assert false, 'Should find MMC0 reset'
		return
	}
	assert mmc0_reset.reset_bit == 16  // Reset bits are typically gate_bit + 16
	
	i2c0_reset := ccu.get_reset_info(.i2c0) or {
		assert false, 'Should find I2C0 reset'
		return
	}
	assert i2c0_reset.offset == i2c_bgr
}

fn test_mmc_clock_calc() {
	// Test clock calculation for 50MHz
	n, m, actual := calc_mmc_dividers(600_000_000, 50_000_000)
	assert actual <= 50_000_000
	
	// Verify the calculation is correct
	calculated := 600_000_000 / ((u64(1) << n) * u64(m + 1))
	assert calculated == actual
}

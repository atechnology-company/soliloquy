// Allwinner A527/T527 GPIO (PIO) Driver
// Translated to V language for Soliloquy OS
//
// Based on Linux sunxi pinctrl driver
// Provides GPIO pin control, configuration, and interrupt management
//
// Reference: Linux drivers/pinctrl/sunxi/pinctrl-sun55i-a527.c

module gpio

import sync

// =============================================================================
// ZX Status codes
// =============================================================================
pub enum ZxStatus {
	ok = 0
	err_invalid_args = -10
	err_not_found = -3
	err_not_supported = -2
}

// =============================================================================
// GPIO Driver structure
// =============================================================================
pub struct SunxiGpio {
pub mut:
	base         u64           // MMIO base address for main PIO
	r_base       u64           // MMIO base address for R_PIO
	lock         sync.Mutex    // For thread safety
	irq_handlers map[string]fn(Pin)  // Interrupt handlers keyed by "port:pin"
}

// =============================================================================
// MMIO access helpers
// =============================================================================
fn mmio_read32(addr u64) u32 {
	return unsafe { *(&u32(addr)) }
}

fn mmio_write32(addr u64, value u32) {
	unsafe { *(&u32(addr)) = value }
}

fn mmio_set_bits32(addr u64, bits u32) {
	val := mmio_read32(addr)
	mmio_write32(addr, val | bits)
}

fn mmio_clear_bits32(addr u64, bits u32) {
	val := mmio_read32(addr)
	mmio_write32(addr, val & ~bits)
}

fn mmio_modify32(addr u64, mask u32, value u32) {
	val := mmio_read32(addr)
	mmio_write32(addr, (val & ~mask) | (value & mask))
}

// =============================================================================
// GPIO Driver implementation
// =============================================================================

// Create a new GPIO driver instance
pub fn SunxiGpio.new(base u64, r_base u64) SunxiGpio {
	return SunxiGpio{
		base: base
		r_base: r_base
		irq_handlers: map[string]fn(Pin){}
	}
}

// Create with default addresses
pub fn SunxiGpio.default() SunxiGpio {
	return SunxiGpio.new(pio_base, pio_r_base)
}

// Get the appropriate base address for a port
fn (self &SunxiGpio) get_base_for_port(port Port) u64 {
	return if int(port) >= 11 { self.r_base } else { self.base }
}

// Get the full register address for a port's register
fn (self &SunxiGpio) port_reg_addr(p Pin, reg_offset u32) u64 {
	base := self.get_base_for_port(p.port)
	port_num := if int(p.port) >= 11 { int(p.port) - 11 } else { int(p.port) }
	return base + u64(port_num * int(port_offset)) + u64(reg_offset)
}

// =============================================================================
// Pin configuration
// =============================================================================

// Set pin function (mux)
pub fn (mut self SunxiGpio) set_function(p Pin, func PinFunction) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	cfg_offset := get_cfg_offset(p.pin)
	cfg_shift := get_cfg_shift(p.pin)
	
	addr := self.port_reg_addr(p, cfg_offset)
	mask := u32(0xF) << cfg_shift
	value := u32(int(func)) << cfg_shift
	
	mmio_modify32(addr, mask, value)
	
	return .ok
}

// Get current pin function
pub fn (self &SunxiGpio) get_function(p Pin) ?PinFunction {
	if p.pin > 31 {
		return none
	}
	
	cfg_offset := get_cfg_offset(p.pin)
	cfg_shift := get_cfg_shift(p.pin)
	
	addr := self.port_reg_addr(p, cfg_offset)
	val := mmio_read32(addr)
	func_val := (val >> cfg_shift) & 0xF
	
	return unsafe { PinFunction(func_val) }
}

// Set pin as input
pub fn (mut self SunxiGpio) set_input(p Pin) ZxStatus {
	return self.set_function(p, .input)
}

// Set pin as output
pub fn (mut self SunxiGpio) set_output(p Pin) ZxStatus {
	return self.set_function(p, .output)
}

// =============================================================================
// Drive strength
// =============================================================================

// Set pin drive strength
pub fn (mut self SunxiGpio) set_drive(p Pin, level DriveLevel) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	drv_offset := get_drv_offset(p.pin)
	drv_shift := get_drv_shift(p.pin)
	
	addr := self.port_reg_addr(p, drv_offset)
	mask := u32(0x3) << drv_shift
	value := u32(int(level)) << drv_shift
	
	mmio_modify32(addr, mask, value)
	
	return .ok
}

// Get current drive strength
pub fn (self &SunxiGpio) get_drive(p Pin) ?DriveLevel {
	if p.pin > 31 {
		return none
	}
	
	drv_offset := get_drv_offset(p.pin)
	drv_shift := get_drv_shift(p.pin)
	
	addr := self.port_reg_addr(p, drv_offset)
	val := mmio_read32(addr)
	drv_val := (val >> drv_shift) & 0x3
	
	return unsafe { DriveLevel(drv_val) }
}

// =============================================================================
// Pull-up/Pull-down
// =============================================================================

// Set pin pull mode
pub fn (mut self SunxiGpio) set_pull(p Pin, mode PullMode) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	pull_offset := get_pull_offset(p.pin)
	pull_shift := get_pull_shift(p.pin)
	
	addr := self.port_reg_addr(p, pull_offset)
	mask := u32(0x3) << pull_shift
	value := u32(int(mode)) << pull_shift
	
	mmio_modify32(addr, mask, value)
	
	return .ok
}

// Get current pull mode
pub fn (self &SunxiGpio) get_pull(p Pin) ?PullMode {
	if p.pin > 31 {
		return none
	}
	
	pull_offset := get_pull_offset(p.pin)
	pull_shift := get_pull_shift(p.pin)
	
	addr := self.port_reg_addr(p, pull_offset)
	val := mmio_read32(addr)
	pull_val := (val >> pull_shift) & 0x3
	
	return unsafe { PullMode(pull_val) }
}

// =============================================================================
// GPIO read/write
// =============================================================================

// Read pin value
pub fn (self &SunxiGpio) read(p Pin) bool {
	if p.pin > 31 {
		return false
	}
	
	addr := self.port_reg_addr(p, dat)
	val := mmio_read32(addr)
	
	return (val & (u32(1) << p.pin)) != 0
}

// Write pin value
pub fn (mut self SunxiGpio) write(p Pin, value bool) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	addr := self.port_reg_addr(p, dat)
	
	if value {
		mmio_set_bits32(addr, u32(1) << p.pin)
	} else {
		mmio_clear_bits32(addr, u32(1) << p.pin)
	}
	
	return .ok
}

// Set pin high
pub fn (mut self SunxiGpio) set_high(p Pin) ZxStatus {
	return self.write(p, true)
}

// Set pin low
pub fn (mut self SunxiGpio) set_low(p Pin) ZxStatus {
	return self.write(p, false)
}

// Toggle pin value
pub fn (mut self SunxiGpio) toggle(p Pin) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	addr := self.port_reg_addr(p, dat)
	val := mmio_read32(addr)
	mmio_write32(addr, val ^ (u32(1) << p.pin))
	
	return .ok
}

// Read entire port
pub fn (self &SunxiGpio) read_port(port Port) u32 {
	base := self.get_base_for_port(port)
	port_num := if int(port) >= 11 { int(port) - 11 } else { int(port) }
	addr := base + u64(port_num * int(port_offset)) + u64(dat)
	
	return mmio_read32(addr)
}

// Write entire port
pub fn (mut self SunxiGpio) write_port(port Port, value u32) {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	base := self.get_base_for_port(port)
	port_num := if int(port) >= 11 { int(port) - 11 } else { int(port) }
	addr := base + u64(port_num * int(port_offset)) + u64(dat)
	
	mmio_write32(addr, value)
}

// =============================================================================
// External interrupts
// =============================================================================

// Configure pin as external interrupt
pub fn (mut self SunxiGpio) configure_interrupt(p Pin, mode InterruptMode) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	// First, set pin function to EINT mode
	cfg_offset := get_cfg_offset(p.pin)
	cfg_shift := get_cfg_shift(p.pin)
	cfg_addr := self.port_reg_addr(p, cfg_offset)
	
	cfg_mask := u32(0xF) << cfg_shift
	cfg_value := u32(int(PinFunction.eint)) << cfg_shift
	mmio_modify32(cfg_addr, cfg_mask, cfg_value)
	
	// Configure interrupt trigger mode
	eint_base_addr := get_eint_base(p.port)
	if int(p.port) >= 11 {
		// Adjust for R_PIO base
		// Note: get_eint_base already handles this
	}
	
	eint_cfg_off := get_eint_cfg_offset(p.pin)
	eint_shift := (p.pin % 8) * 4
	
	eint_addr := eint_base_addr + u64(eint_cfg_off)
	eint_mask := u32(0xF) << eint_shift
	eint_value := u32(int(mode)) << eint_shift
	
	mmio_modify32(eint_addr, eint_mask, eint_value)
	
	return .ok
}

// Enable interrupt for a pin
pub fn (mut self SunxiGpio) enable_interrupt(p Pin) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	eint_base_addr := get_eint_base(p.port)
	ctl_addr := eint_base_addr + u64(eint_ctl)
	
	mmio_set_bits32(ctl_addr, u32(1) << p.pin)
	
	return .ok
}

// Disable interrupt for a pin
pub fn (mut self SunxiGpio) disable_interrupt(p Pin) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	eint_base_addr := get_eint_base(p.port)
	ctl_addr := eint_base_addr + u64(eint_ctl)
	
	mmio_clear_bits32(ctl_addr, u32(1) << p.pin)
	
	return .ok
}

// Check if interrupt is pending
pub fn (self &SunxiGpio) is_interrupt_pending(p Pin) bool {
	if p.pin > 31 {
		return false
	}
	
	eint_base_addr := get_eint_base(p.port)
	status_addr := eint_base_addr + u64(eint_status)
	
	val := mmio_read32(status_addr)
	return (val & (u32(1) << p.pin)) != 0
}

// Clear interrupt pending flag
pub fn (mut self SunxiGpio) clear_interrupt(p Pin) ZxStatus {
	if p.pin > 31 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	eint_base_addr := get_eint_base(p.port)
	status_addr := eint_base_addr + u64(eint_status)
	
	// Write 1 to clear
	mmio_write32(status_addr, u32(1) << p.pin)
	
	return .ok
}

// Set debounce for port interrupts
pub fn (mut self SunxiGpio) set_debounce(port Port, prescaler u8, source u8) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	eint_base_addr := get_eint_base(port)
	deb_addr := eint_base_addr + u64(eint_deb)
	
	// Debounce register: [7:4] = prescaler, [0] = source (0=LOSC, 1=HOSC)
	value := u32(prescaler & 0xF) << 4 | u32(source & 0x1)
	mmio_write32(deb_addr, value)
	
	return .ok
}

// =============================================================================
// Convenience functions
// =============================================================================

// Configure pin with multiple settings at once
pub fn (mut self SunxiGpio) configure_pin(p Pin, func PinFunction, pull PullMode, drive DriveLevel) ZxStatus {
	mut status := self.set_function(p, func)
	if status != .ok {
		return status
	}
	
	status = self.set_pull(p, pull)
	if status != .ok {
		return status
	}
	
	return self.set_drive(p, drive)
}

// Configure as output with initial value
pub fn (mut self SunxiGpio) configure_output(p Pin, initial_value bool) ZxStatus {
	mut status := self.set_output(p)
	if status != .ok {
		return status
	}
	
	return self.write(p, initial_value)
}

// Configure as input with pull-up
pub fn (mut self SunxiGpio) configure_input_pullup(p Pin) ZxStatus {
	mut status := self.set_input(p)
	if status != .ok {
		return status
	}
	
	return self.set_pull(p, .pull_up)
}

// Configure as input with pull-down
pub fn (mut self SunxiGpio) configure_input_pulldown(p Pin) ZxStatus {
	mut status := self.set_input(p)
	if status != .ok {
		return status
	}
	
	return self.set_pull(p, .pull_down)
}

// =============================================================================
// Common pin mux configurations
// =============================================================================

// Configure pins for SD card (MMC0 on Port F)
pub fn (mut self SunxiGpio) configure_mmc0() ZxStatus {
	// CLK, CMD, D0-D3 as MMC function
	pins := [sd_clk, sd_cmd, sd_d0, sd_d1, sd_d2, sd_d3]
	for p in pins {
		status := self.configure_pin(p, pf_mmc0, .pull_up, .level2)
		if status != .ok {
			return status
		}
	}
	
	// Card detect as input with pull-up
	return self.configure_input_pullup(sd_cd)
}

// Configure pins for eMMC (MMC2 on Port C)
pub fn (mut self SunxiGpio) configure_mmc2() ZxStatus {
	// All eMMC pins
	pins := [emmc_clk, emmc_cmd, emmc_d0, emmc_d1, emmc_d2, emmc_d3,
		emmc_d4, emmc_d5, emmc_d6, emmc_d7, emmc_rst]
	
	for p in pins {
		status := self.configure_pin(p, pc_emmc, .pull_up, .level2)
		if status != .ok {
			return status
		}
	}
	
	return .ok
}

// Configure UART0 for debug console
pub fn (mut self SunxiGpio) configure_uart0() ZxStatus {
	mut status := self.configure_pin(uart0_tx, pb_uart0_tx, .pull_up, .level1)
	if status != .ok {
		return status
	}
	
	return self.configure_pin(uart0_rx, pb_uart0_rx, .pull_up, .level1)
}

// Configure I2C0
pub fn (mut self SunxiGpio) configure_i2c0() ZxStatus {
	mut status := self.configure_pin(i2c0_scl, pb_i2c0, .pull_up, .level1)
	if status != .ok {
		return status
	}
	
	return self.configure_pin(i2c0_sda, pb_i2c0, .pull_up, .level1)
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_gpio_creation() {
	g := SunxiGpio.default()
	assert g.base == pio_base
	assert g.r_base == pio_r_base
}

fn test_port_reg_addr() {
	g := SunxiGpio.default()
	
	// Test main PIO port
	addr := g.port_reg_addr(Pin{ port: .a, pin: 0 }, dat)
	assert addr == pio_base + u64(dat)
	
	// Test Port B
	addr_b := g.port_reg_addr(Pin{ port: .b, pin: 0 }, dat)
	assert addr_b == pio_base + u64(port_offset) + u64(dat)
}

fn test_get_base_for_port() {
	g := SunxiGpio.default()
	
	// Main ports use pio_base
	assert g.get_base_for_port(.a) == pio_base
	assert g.get_base_for_port(.f) == pio_base
	
	// R_PIO ports use r_base
	assert g.get_base_for_port(.l) == pio_r_base
	assert g.get_base_for_port(.m) == pio_r_base
}

fn test_pin_configuration() {
	// This would test against real hardware
	// For unit tests, we'd use mocks
	g := SunxiGpio.default()
	
	// Test that functions exist and can be called
	_ := g.get_function(uart0_tx)
	_ := g.get_drive(uart0_tx)
	_ := g.get_pull(uart0_tx)
}

fn test_interrupt_mode_values() {
	assert int(InterruptMode.positive_edge) == 0
	assert int(InterruptMode.negative_edge) == 1
	assert int(InterruptMode.double_edge) == 4
}

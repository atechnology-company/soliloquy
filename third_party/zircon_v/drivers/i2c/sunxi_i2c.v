// Allwinner A527/T527 I2C (TWI) Driver
// Translated to V language for Soliloquy OS
//
// Based on Linux i2c-mv64xxx driver (used by many Allwinner I2C controllers)
// Implements master mode I2C transactions
//
// Reference: Linux drivers/i2c/busses/i2c-mv64xxx.c

module i2c

import sync

// =============================================================================
// ZX Status codes
// =============================================================================
pub enum ZxStatus {
	ok = 0
	err_invalid_args = -10
	err_not_found = -3
	err_timed_out = -21
	err_io = -5
	err_nack = -25
	err_busy = -16
	err_arb_lost = -26
}

// =============================================================================
// I2C Controller state
// =============================================================================
enum ControllerState {
	idle
	waiting_for_start
	waiting_for_addr_ack
	waiting_for_data_ack
	waiting_for_data
	waiting_for_stop
	done
	error
}

// =============================================================================
// I2C Driver structure
// =============================================================================
pub struct SunxiI2c {
pub mut:
	base         u64                // MMIO base address
	idx          u32                // Controller index (0-5)
	lock         sync.Mutex         // For thread safety
	apb_clock    u64                // APB clock frequency
	target_speed u32                // Target I2C speed in Hz
	state        ControllerState    // Current state machine state
	msg_idx      u16                // Current message index
	byte_idx     u16                // Current byte within message
	msgs         []I2cMessage       // Messages to process
	err_status   ZxStatus           // Error status from last operation
}

// =============================================================================
// MMIO access helpers
// =============================================================================
fn mmio_read32(base u64, offset u32) u32 {
	return unsafe { *(&u32(base + u64(offset))) }
}

fn mmio_write32(base u64, offset u32, value u32) {
	unsafe { *(&u32(base + u64(offset))) = value }
}

// Simple microsecond delay
fn delay_us(us u32) {
	mut count := us * 100
	for count > 0 {
		count--
	}
}

// =============================================================================
// I2C Driver implementation
// =============================================================================

// Create a new I2C driver instance
pub fn SunxiI2c.new(idx u32) !SunxiI2c {
	base := get_twi_base(idx) or { return error('Invalid I2C index') }
	
	return SunxiI2c{
		base: base
		idx: idx
		apb_clock: apb_clock_hz
		target_speed: speed_standard
		state: .idle
	}
}

// Create with specific base address
pub fn SunxiI2c.with_base(base u64, idx u32) SunxiI2c {
	return SunxiI2c{
		base: base
		idx: idx
		apb_clock: apb_clock_hz
		target_speed: speed_standard
		state: .idle
	}
}

// Initialize the I2C controller
pub fn (mut self SunxiI2c) init() ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	// Reset the controller
	self.reset_locked()
	
	// Configure clock
	status := self.set_speed_locked(self.target_speed)
	if status != .ok {
		return status
	}
	
	// Enable the bus
	mmio_write32(self.base, cntr, cntr_bus_en)
	
	self.state = .idle
	return .ok
}

// Reset the controller
fn (mut self SunxiI2c) reset_locked() {
	// Trigger soft reset
	mmio_write32(self.base, srst, srst_reset)
	
	// Wait for reset to complete
	delay_us(10)
	
	// Clear any pending interrupts
	mut ctrl := mmio_read32(self.base, cntr)
	ctrl |= cntr_int_flag
	mmio_write32(self.base, cntr, ctrl)
}

// Set the I2C clock speed
fn (mut self SunxiI2c) set_speed_locked(speed_hz u32) ZxStatus {
	// Calculate dividers
	n, m := calc_clock_dividers(self.apb_clock, speed_hz)
	
	// Write clock control register
	ccr_val := build_ccr(n, m)
	mmio_write32(self.base, ccr, ccr_val)
	
	self.target_speed = speed_hz
	return .ok
}

// Public method to set speed
pub fn (mut self SunxiI2c) set_speed(speed_hz u32) ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	return self.set_speed_locked(speed_hz)
}

// Get current I2C status
fn (self &SunxiI2c) read_status() I2cStatus {
	val := mmio_read32(self.base, stat)
	return unsafe { I2cStatus(val) }
}

// Wait for interrupt flag with timeout
fn (self &SunxiI2c) wait_for_interrupt(timeout_us u32) bool {
	mut remaining := timeout_us
	
	for remaining > 0 {
		ctrl := mmio_read32(self.base, cntr)
		if (ctrl & cntr_int_flag) != 0 {
			return true
		}
		delay_us(10)
		remaining -= 10
	}
	
	return false
}

// Clear interrupt flag
fn (mut self SunxiI2c) clear_interrupt() {
	mut ctrl := mmio_read32(self.base, cntr)
	ctrl |= cntr_int_flag
	mmio_write32(self.base, cntr, ctrl)
}

// Send START condition
fn (mut self SunxiI2c) send_start() {
	mut ctrl := mmio_read32(self.base, cntr)
	ctrl |= cntr_m_sta | cntr_bus_en
	ctrl &= ~cntr_int_flag
	mmio_write32(self.base, cntr, ctrl)
}

// Send STOP condition
fn (mut self SunxiI2c) send_stop() {
	mut ctrl := mmio_read32(self.base, cntr)
	ctrl |= cntr_m_stp | cntr_bus_en
	ctrl &= ~cntr_int_flag
	mmio_write32(self.base, cntr, ctrl)
}

// Send ACK
fn (mut self SunxiI2c) send_ack() {
	mut ctrl := mmio_read32(self.base, cntr)
	ctrl |= cntr_a_ack | cntr_bus_en
	ctrl &= ~cntr_int_flag
	mmio_write32(self.base, cntr, ctrl)
}

// Send NACK
fn (mut self SunxiI2c) send_nack() {
	mut ctrl := mmio_read32(self.base, cntr)
	ctrl &= ~cntr_a_ack
	ctrl |= cntr_bus_en
	ctrl &= ~cntr_int_flag
	mmio_write32(self.base, cntr, ctrl)
}

// Write data byte
fn (mut self SunxiI2c) write_data(byte u8) {
	mmio_write32(self.base, data, u32(byte))
}

// Read data byte
fn (self &SunxiI2c) read_data() u8 {
	return u8(mmio_read32(self.base, data) & 0xFF)
}

// =============================================================================
// Transaction handling
// =============================================================================

// Transfer messages
pub fn (mut self SunxiI2c) transfer(msgs []I2cMessage) ZxStatus {
	if msgs.len == 0 {
		return .err_invalid_args
	}
	
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	self.msgs = msgs
	self.msg_idx = 0
	self.byte_idx = 0
	self.err_status = .ok
	
	// Send START
	self.send_start()
	
	// Process all messages
	for self.msg_idx < u16(self.msgs.len) {
		status := self.process_message_locked()
		if status != .ok {
			self.send_stop()
			delay_us(100)
			return status
		}
		
		self.msg_idx++
		self.byte_idx = 0
		
		// Send repeated START for next message (if any)
		if self.msg_idx < u16(self.msgs.len) {
			self.send_start()
		}
	}
	
	// Send STOP
	self.send_stop()
	delay_us(100)
	
	return .ok
}

// Process a single message
fn (mut self SunxiI2c) process_message_locked() ZxStatus {
	msg := &self.msgs[self.msg_idx]
	is_read := msg.flags.has(.read)
	
	// Wait for START to complete
	if !self.wait_for_interrupt(10000) {
		return .err_timed_out
	}
	
	status := self.read_status()
	if status != .start_transmitted && status != .repeated_start {
		return .err_io
	}
	
	// Send address byte
	addr_byte := u8(msg.addr << 1) | u8(if is_read { 1 } else { 0 })
	self.write_data(addr_byte)
	self.clear_interrupt()
	
	// Wait for address ACK
	if !self.wait_for_interrupt(10000) {
		return .err_timed_out
	}
	
	status2 := self.read_status()
	if is_read {
		if status2 == .addr_rd_nack {
			return .err_nack
		}
		if status2 != .addr_rd_ack {
			return .err_io
		}
	} else {
		if status2 == .addr_wr_nack {
			return .err_nack
		}
		if status2 != .addr_wr_ack {
			return .err_io
		}
	}
	
	// Transfer data
	if is_read {
		return self.read_bytes_locked(msg)
	} else {
		return self.write_bytes_locked(msg)
	}
}

// Write bytes
fn (mut self SunxiI2c) write_bytes_locked(msg &I2cMessage) ZxStatus {
	for i := u16(0); i < msg.len; i++ {
		// Write data byte
		self.write_data(msg.buf[i])
		self.clear_interrupt()
		
		// Wait for ACK
		if !self.wait_for_interrupt(10000) {
			return .err_timed_out
		}
		
		status := self.read_status()
		if status == .data_tx_nack && !msg.flags.has(.ignore_nack) {
			return .err_nack
		}
		if status != .data_tx_ack && status != .data_tx_nack {
			return .err_io
		}
	}
	
	return .ok
}

// Read bytes
fn (mut self SunxiI2c) read_bytes_locked(msg &I2cMessage) ZxStatus {
	for i := u16(0); i < msg.len; i++ {
		// For last byte, send NACK; otherwise send ACK
		if i == msg.len - 1 {
			self.send_nack()
		} else {
			self.send_ack()
		}
		
		// Wait for data
		if !self.wait_for_interrupt(10000) {
			return .err_timed_out
		}
		
		status := self.read_status()
		if status != .data_rx_ack && status != .data_rx_nack {
			return .err_io
		}
		
		// Read data
		unsafe {
			msg.buf[i] = self.read_data()
		}
	}
	
	return .ok
}

// =============================================================================
// Convenience methods
// =============================================================================

// Write bytes to a device
pub fn (mut self SunxiI2c) write_bytes(addr u8, data []u8) ZxStatus {
	msg := write_message(addr, data)
	return self.transfer([msg])
}

// Read bytes from a device
pub fn (mut self SunxiI2c) read_bytes(addr u8, len u16) ![]u8 {
	mut msg := read_message(addr, len)
	status := self.transfer([msg])
	if status != .ok {
		return error('I2C read failed')
	}
	return msg.buf
}

// Write then read (common pattern for register access)
pub fn (mut self SunxiI2c) write_read(addr u8, write_data []u8, read_len u16) ![]u8 {
	mut read_msg := read_message(addr, read_len)
	write_msg := write_message(addr, write_data)
	
	status := self.transfer([write_msg, read_msg])
	if status != .ok {
		return error('I2C write-read failed')
	}
	
	return read_msg.buf
}

// Read a single register
pub fn (mut self SunxiI2c) read_reg(dev_addr u8, reg u8) !u8 {
	result := self.write_read(dev_addr, [reg], 1) or { return error('Read register failed') }
	return result[0]
}

// Write a single register
pub fn (mut self SunxiI2c) write_reg(dev_addr u8, reg u8, value u8) ZxStatus {
	return self.write_bytes(dev_addr, [reg, value])
}

// Read multiple registers
pub fn (mut self SunxiI2c) read_regs(addr u8, start_reg u8, len u16) ![]u8 {
	return self.write_read(addr, [start_reg], len)
}

// Check if device is present (sends address, checks for ACK)
pub fn (mut self SunxiI2c) probe(addr u8) bool {
	// Try to write zero bytes
	status := self.write_bytes(addr, [])
	return status == .ok
}

// Scan bus for devices
pub fn (mut self SunxiI2c) scan() []u8 {
	mut found := []u8{}
	
	// Standard I2C addresses are 0x03 to 0x77
	for dev_addr in u8(0x03) .. u8(0x78) {
		if self.probe(dev_addr) {
			found << dev_addr
		}
	}
	
	return found
}

// =============================================================================
// Bus recovery
// =============================================================================

// Try to recover a stuck bus by generating clock pulses
pub fn (mut self SunxiI2c) recover_bus() ZxStatus {
	self.lock.@lock()
	defer { self.lock.unlock() }
	
	// Enable direct line control
	mut lcr_val := u32(0)
	
	// Check if SDA is stuck low
	lcr_val = mmio_read32(self.base, lcr)
	if (lcr_val & lcr_sda_state) == 0 {
		// SDA is low, try to clock it out
		for _ in 0 .. 9 {
			// Toggle SCL
			lcr_val = lcr_scl_en | lcr_scl_ctl  // SCL high
			mmio_write32(self.base, lcr, lcr_val)
			delay_us(5)
			
			lcr_val = lcr_scl_en  // SCL low
			mmio_write32(self.base, lcr, lcr_val)
			delay_us(5)
			
			// Check if SDA released
			lcr_val = mmio_read32(self.base, lcr)
			if (lcr_val & lcr_sda_state) != 0 {
				break
			}
		}
	}
	
	// Disable direct control
	mmio_write32(self.base, lcr, 0)
	
	// Reset controller
	self.reset_locked()
	
	// Re-initialize
	return self.set_speed_locked(self.target_speed)
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_i2c_creation() ! {
	controller := SunxiI2c.new(0)!
	assert controller.base == twi0_base
	assert controller.idx == 0
	assert controller.state == .idle
}

fn test_i2c_with_base() {
	controller := SunxiI2c.with_base(0x12340000, 99)
	assert controller.base == 0x12340000
	assert controller.idx == 99
}

fn test_i2c_speed_settings() {
	mut controller := SunxiI2c.with_base(0x12340000, 0)
	
	// Default speed should be standard
	assert controller.target_speed == speed_standard
}

fn test_message_helpers() {
	// Test write message
	test_data := [u8(0xAB), 0xCD]
	msg := write_message(0x50, test_data)
	assert msg.addr == 0x50
	assert !msg.flags.has(.read)
	assert msg.buf == test_data
	
	// Test read message
	read_msg := read_message(0x51, 4)
	assert read_msg.addr == 0x51
	assert read_msg.flags.has(.read)
	assert read_msg.len == 4
}

fn test_clock_calculation() {
	// Test that we can calculate valid clock settings
	n, m := calc_clock_dividers(24_000_000, 100_000)
	
	// Should get valid N and M
	assert n < 8
	assert m < 8
	
	// Resulting frequency should be <= target
	actual := calc_scl_freq(24_000_000, n, m)
	assert actual <= 100_000
}

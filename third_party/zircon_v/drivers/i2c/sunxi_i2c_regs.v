// Allwinner A527/T527 I2C (TWI) Register Definitions
// Translated to V language for Soliloquy OS
//
// Based on Allwinner A527 User Manual
// The TWI (Two-Wire Interface) controller implements I2C protocol
//
// Reference: Allwinner A527 User Manual, Linux drivers/i2c/busses/i2c-mv64xxx.c

module i2c

// =============================================================================
// Base addresses for I2C controllers
// =============================================================================
pub const twi0_base = u64(0x02502000)         // TWI0
pub const twi1_base = u64(0x02502400)         // TWI1
pub const twi2_base = u64(0x02502800)         // TWI2
pub const twi3_base = u64(0x02502C00)         // TWI3
pub const twi4_base = u64(0x02503000)         // TWI4
pub const twi5_base = u64(0x02503400)         // TWI5
pub const r_twi_base = u64(0x07020800)        // R_TWI (RTC domain)

// =============================================================================
// Register offsets
// =============================================================================
pub const addr = u32(0x00)            // Slave address register
pub const xaddr = u32(0x04)           // Extended slave address
pub const data = u32(0x08)            // Data register
pub const cntr = u32(0x0C)            // Control register
pub const stat = u32(0x10)            // Status register
pub const ccr = u32(0x14)             // Clock control register
pub const srst = u32(0x18)            // Soft reset register
pub const efr = u32(0x1C)             // Enhance feature register
pub const lcr = u32(0x20)             // Line control register
pub const dvfs = u32(0x24)            // DVFS control register

// =============================================================================
// Control register (CNTR) bits
// =============================================================================
pub const cntr_int_en = u32(1 << 7)       // Interrupt enable
pub const cntr_bus_en = u32(1 << 6)       // Bus enable
pub const cntr_m_sta = u32(1 << 5)        // Master mode start
pub const cntr_m_stp = u32(1 << 4)        // Master mode stop
pub const cntr_int_flag = u32(1 << 3)     // Interrupt flag
pub const cntr_a_ack = u32(1 << 2)        // Assert ACK

// Combined masks for common operations
pub const cntr_start = cntr_bus_en | cntr_m_sta | cntr_int_en
pub const cntr_stop = cntr_bus_en | cntr_m_stp | cntr_int_en

// =============================================================================
// Status register (STAT) values
// These are the state machine states, not bit flags
// =============================================================================
pub enum I2cStatus as u32 {
	// Bus error
	bus_error = 0x00
	
	// Master transmitter states
	start_transmitted = 0x08
	repeated_start = 0x10
	addr_wr_ack = 0x18          // Address+W sent, ACK received
	addr_wr_nack = 0x20         // Address+W sent, NACK received
	data_tx_ack = 0x28          // Data sent, ACK received
	data_tx_nack = 0x30         // Data sent, NACK received
	arb_lost = 0x38             // Arbitration lost
	
	// Master receiver states
	addr_rd_ack = 0x40          // Address+R sent, ACK received
	addr_rd_nack = 0x48         // Address+R sent, NACK received
	data_rx_ack = 0x50          // Data received, ACK sent
	data_rx_nack = 0x58         // Data received, NACK sent
	
	// Second address byte (10-bit addressing)
	second_addr_wr_ack = 0xD0
	second_addr_wr_nack = 0xD8
	
	// Idle
	idle = 0xF8
}

// =============================================================================
// Clock Control Register (CCR) layout
// =============================================================================
// Bits [6:3]: CLK_N - Clock divisor N (2^N)
// Bits [2:0]: CLK_M - Clock divisor M
// SCL frequency = APBCLK / (10 * (2^N * (M+1)))

pub const ccr_clk_m_mask = u32(0x07)      // Bits [2:0]
pub const ccr_clk_m_shift = u32(0)
pub const ccr_clk_n_mask = u32(0x78)      // Bits [6:3]
pub const ccr_clk_n_shift = u32(3)

// =============================================================================
// Soft Reset Register (SRST)
// =============================================================================
pub const srst_reset = u32(1 << 0)        // Write 1 to reset controller

// =============================================================================
// Enhance Feature Register (EFR)
// =============================================================================
pub const efr_dbg_mode = u32(1 << 0)      // Debug mode enable

// =============================================================================
// Line Control Register (LCR)
// =============================================================================
pub const lcr_sda_en = u32(1 << 0)        // SDA line output enable
pub const lcr_sda_ctl = u32(1 << 1)       // SDA line output value
pub const lcr_scl_en = u32(1 << 2)        // SCL line output enable
pub const lcr_scl_ctl = u32(1 << 3)       // SCL line output value
pub const lcr_sda_state = u32(1 << 4)     // SDA line state (read-only)
pub const lcr_scl_state = u32(1 << 5)     // SCL line state (read-only)

// =============================================================================
// Standard I2C speeds
// =============================================================================
pub const speed_standard = u32(100_000)    // 100 kHz
pub const speed_fast = u32(400_000)        // 400 kHz
pub const speed_fast_plus = u32(1_000_000) // 1 MHz
pub const speed_high = u32(3_400_000)      // 3.4 MHz (not typically supported)

// Default APB clock (from CCU)
pub const apb_clock_hz = u64(24_000_000)   // 24 MHz default

// =============================================================================
// I2C message structure
// =============================================================================
pub struct I2cMessage {
pub:
	addr   u16           // 7-bit or 10-bit slave address
	flags  MessageFlags  // Read/write and other flags
	len    u16           // Message length in bytes
pub mut:
	buf    []u8          // Data buffer
}

// Message flags
@[flag]
pub enum MessageFlags {
	read          // Read from slave (vs write)
	ten_bit       // 10-bit addressing mode
	no_start      // Don't send START condition
	rev_dir_addr  // Reverse direction for address
	ignore_nack   // Ignore NACK from slave
	no_read_ack   // Don't send ACK after reading
	stop          // Force STOP after this message
}

// =============================================================================
// Helper functions
// =============================================================================

// Get I2C controller base address by index
pub fn get_twi_base(idx u32) ?u64 {
	return match idx {
		0 { twi0_base }
		1 { twi1_base }
		2 { twi2_base }
		3 { twi3_base }
		4 { twi4_base }
		5 { twi5_base }
		else { none }
	}
}

// Calculate clock dividers for target frequency
// Returns (clk_n, clk_m)
pub fn calc_clock_dividers(apb_hz u64, target_hz u32) (u32, u32) {
	// SCL = APB / (10 * (2^N * (M+1)))
	// We want to find N and M such that SCL is as close as possible to target
	
	mut best_n := u32(0)
	mut best_m := u32(0)
	mut best_diff := u64(0xFFFFFFFF)
	
	for n in u32(0) .. 8 {
		n_div := u64(1) << n
		
		for m in u32(0) .. 8 {
			m_div := u64(m + 1)
			scl := apb_hz / (10 * n_div * m_div)
			
			if scl <= u64(target_hz) {
				diff := u64(target_hz) - scl
				if diff < best_diff {
					best_diff = diff
					best_n = n
					best_m = m
				}
			}
		}
	}
	
	return best_n, best_m
}

// Calculate actual SCL frequency from dividers
pub fn calc_scl_freq(apb_hz u64, clk_n u32, clk_m u32) u64 {
	n_div := u64(1) << clk_n
	m_div := u64(clk_m + 1)
	return apb_hz / (10 * n_div * m_div)
}

// Build CCR register value from dividers
pub fn build_ccr(clk_n u32, clk_m u32) u32 {
	return ((clk_n & 0x7) << ccr_clk_n_shift) | ((clk_m & 0x7) << ccr_clk_m_shift)
}

// Extract clk_n from CCR register
pub fn get_ccr_n(ccr_val u32) u32 {
	return (ccr_val >> ccr_clk_n_shift) & 0x7
}

// Extract clk_m from CCR register
pub fn get_ccr_m(ccr_val u32) u32 {
	return (ccr_val >> ccr_clk_m_shift) & 0x7
}

// Check if status indicates an error
pub fn is_error_status(status I2cStatus) bool {
	return match status {
		.bus_error, .addr_wr_nack, .addr_rd_nack, .data_tx_nack, .arb_lost { true }
		else { false }
	}
}

// Check if status indicates success with ACK
pub fn is_ack_status(status I2cStatus) bool {
	return match status {
		.addr_wr_ack, .data_tx_ack, .addr_rd_ack, .data_rx_ack { true }
		else { false }
	}
}

// Get human-readable status description
pub fn status_description(status I2cStatus) string {
	return match status {
		.bus_error { 'Bus error' }
		.start_transmitted { 'START transmitted' }
		.repeated_start { 'Repeated START transmitted' }
		.addr_wr_ack { 'Address+W, ACK received' }
		.addr_wr_nack { 'Address+W, NACK received' }
		.data_tx_ack { 'Data transmitted, ACK received' }
		.data_tx_nack { 'Data transmitted, NACK received' }
		.arb_lost { 'Arbitration lost' }
		.addr_rd_ack { 'Address+R, ACK received' }
		.addr_rd_nack { 'Address+R, NACK received' }
		.data_rx_ack { 'Data received, ACK sent' }
		.data_rx_nack { 'Data received, NACK sent' }
		.idle { 'Idle' }
		else { 'Unknown status' }
	}
}

// Create a write message
pub fn write_message(addr u8, data []u8) I2cMessage {
	return I2cMessage{
		addr: u16(addr)
		flags: MessageFlags{}
		len: u16(data.len)
		buf: data.clone()
	}
}

// Create a read message
pub fn read_message(addr u8, len u16) I2cMessage {
	return I2cMessage{
		addr: u16(addr)
		flags: .read
		len: len
		buf: []u8{len: int(len)}
	}
}

// =============================================================================
// Common I2C device addresses
// =============================================================================

// PMIC addresses (AXP family)
pub const axp_addr = u8(0x34)

// RTC addresses
pub const rtc_pcf8563_addr = u8(0x51)
pub const rtc_ds1307_addr = u8(0x68)

// EEPROM addresses
pub const eeprom_24c02_addr = u8(0x50)

// Audio codec
pub const wm8960_addr = u8(0x1A)

// Temperature sensors
pub const lm75_addr = u8(0x48)
pub const tmp102_addr = u8(0x48)

// =============================================================================
// Unit tests
// =============================================================================

fn test_get_twi_base() {
	// Valid indices
	assert get_twi_base(0) or { 0 } == twi0_base
	assert get_twi_base(1) or { 0 } == twi1_base
	assert get_twi_base(5) or { 0 } == twi5_base
	
	// Invalid index
	result := get_twi_base(10)
	assert result == none
}

fn test_calc_clock_dividers() {
	// Test for 100kHz with 24MHz APB
	n, m := calc_clock_dividers(24_000_000, 100_000)
	
	// Calculate actual frequency
	actual := calc_scl_freq(24_000_000, n, m)
	
	// Should be close to 100kHz
	assert actual <= 100_000
	assert actual >= 80_000
}

fn test_calc_scl_freq() {
	// 24MHz / (10 * 2^0 * (0+1)) = 24MHz / 10 = 2.4MHz
	freq := calc_scl_freq(24_000_000, 0, 0)
	assert freq == 2_400_000
	
	// 24MHz / (10 * 2^2 * (2+1)) = 24MHz / 120 = 200kHz
	freq2 := calc_scl_freq(24_000_000, 2, 2)
	assert freq2 == 200_000
}

fn test_build_ccr() {
	// N=2, M=3
	ccr_val := build_ccr(2, 3)
	
	// Extract and verify
	assert get_ccr_n(ccr_val) == 2
	assert get_ccr_m(ccr_val) == 3
}

fn test_status_checks() {
	assert is_error_status(.bus_error)
	assert is_error_status(.addr_wr_nack)
	assert is_error_status(.arb_lost)
	
	assert !is_error_status(.addr_wr_ack)
	assert !is_error_status(.idle)
	
	assert is_ack_status(.addr_wr_ack)
	assert is_ack_status(.data_rx_ack)
	assert !is_ack_status(.bus_error)
}

fn test_message_creation() {
	// Write message
	write_data := [u8(0x01), 0x02, 0x03]
	msg := write_message(0x50, write_data)
	
	assert msg.addr == 0x50
	assert .read !in msg.flags
	assert msg.len == 3
	assert msg.buf == write_data
	
	// Read message
	read_msg := read_message(0x50, 10)
	assert read_msg.addr == 0x50
	assert .read in read_msg.flags
	assert read_msg.len == 10
	assert read_msg.buf.len == 10
}

fn test_status_descriptions() {
	desc := status_description(.start_transmitted)
	assert desc == 'START transmitted'
	
	desc2 := status_description(.arb_lost)
	assert desc2 == 'Arbitration lost'
}

fn test_control_register_constants() {
	// Verify control register masks don't overlap unexpectedly
	assert (cntr_int_en & cntr_bus_en) == 0
	assert (cntr_m_sta & cntr_m_stp) == 0
	assert (cntr_int_flag & cntr_a_ack) == 0
}

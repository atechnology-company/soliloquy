// Allwinner A527/T527 GPIO (PIO) Register Definitions
// Translated to V language for Soliloquy OS
//
// Based on Allwinner A527 User Manual
// The PIO controller manages GPIO pins for all port groups
//
// Reference: Allwinner A527 User Manual, Linux drivers/pinctrl/sunxi/

module gpio

// =============================================================================
// Base addresses
// =============================================================================
pub const pio_base = u64(0x02000000)          // Main PIO controller
pub const pio_r_base = u64(0x07022000)        // R_PIO (RTC domain GPIOs)

// =============================================================================
// Port offsets (each port is 0x24 bytes apart)
// =============================================================================
pub const port_offset = u32(0x24)

// =============================================================================
// Port identifiers
// =============================================================================
pub enum Port {
	a = 0     // Port A
	b = 1     // Port B
	c = 2     // Port C
	d = 3     // Port D
	e = 4     // Port E
	f = 5     // Port F
	g = 6     // Port G
	h = 7     // Port H
	i = 8     // Port I
	j = 9     // Port J
	k = 10    // Port K
	l = 11    // Port L (R_PIO domain)
	m = 12    // Port M (R_PIO domain)
}

// =============================================================================
// Register offsets within each port block (relative to port base)
// =============================================================================
pub const cfg0 = u32(0x00)         // Configure register 0 (pins 0-7)
pub const cfg1 = u32(0x04)         // Configure register 1 (pins 8-15)
pub const cfg2 = u32(0x08)         // Configure register 2 (pins 16-23)
pub const cfg3 = u32(0x0C)         // Configure register 3 (pins 24-31)
pub const dat = u32(0x10)          // Data register
pub const drv0 = u32(0x14)         // Drive register 0 (pins 0-15)
pub const drv1 = u32(0x18)         // Drive register 1 (pins 16-31)
pub const pull0 = u32(0x1C)        // Pull register 0 (pins 0-15)
pub const pull1 = u32(0x20)        // Pull register 1 (pins 16-31)

// =============================================================================
// External interrupt register offsets (per port)
// Base: 0x200 + port * 0x20
// =============================================================================
pub const eint_base = u32(0x200)
pub const eint_port_offset = u32(0x20)

pub const eint_cfg0 = u32(0x00)    // External interrupt config 0
pub const eint_cfg1 = u32(0x04)    // External interrupt config 1
pub const eint_cfg2 = u32(0x08)    // External interrupt config 2
pub const eint_cfg3 = u32(0x0C)    // External interrupt config 3
pub const eint_ctl = u32(0x10)     // External interrupt enable
pub const eint_status = u32(0x14) // External interrupt status
pub const eint_deb = u32(0x18)    // External interrupt debounce

// =============================================================================
// Pin function modes (4 bits per pin in CFG registers)
// =============================================================================
pub enum PinFunction {
	input = 0         // GPIO input
	output = 1        // GPIO output
	func2 = 2         // Alternate function 2
	func3 = 3         // Alternate function 3
	func4 = 4         // Alternate function 4
	func5 = 5         // Alternate function 5
	func6 = 6         // Alternate function 6
	func7 = 7         // Alternate function 7
	eint = 14         // External interrupt (0xE)
	disabled = 15     // Disabled (0xF)
}

// =============================================================================
// Drive strength levels (2 bits per pin)
// =============================================================================
pub enum DriveLevel {
	level0 = 0    // 10mA for most pins
	level1 = 1    // 20mA
	level2 = 2    // 30mA
	level3 = 3    // 40mA
}

// =============================================================================
// Pull-up/pull-down modes (2 bits per pin)
// =============================================================================
pub enum PullMode {
	disabled = 0     // Pull disabled
	pull_up = 1      // Pull-up enabled
	pull_down = 2    // Pull-down enabled
	reserved = 3     // Reserved
}

// =============================================================================
// External interrupt trigger modes (4 bits per pin in EINT_CFGn)
// =============================================================================
pub enum InterruptMode {
	positive_edge = 0    // Rising edge
	negative_edge = 1    // Falling edge
	high_level = 2       // High level
	low_level = 3        // Low level
	double_edge = 4      // Both edges
}

// =============================================================================
// Pin descriptor
// =============================================================================
pub struct Pin {
pub:
	port     Port          // Port group
	pin      u8            // Pin number within port (0-31)
}

// Create a pin descriptor
pub fn pin(port Port, pin_num u8) Pin {
	return Pin{
		port: port
		pin: pin_num
	}
}

// =============================================================================
// Common pin definitions for Radxa Cubie A5E
// =============================================================================

// SD Card pins (usually Port F)
pub const sd_clk = Pin{ port: .f, pin: 2 }
pub const sd_cmd = Pin{ port: .f, pin: 3 }
pub const sd_d0 = Pin{ port: .f, pin: 1 }
pub const sd_d1 = Pin{ port: .f, pin: 0 }
pub const sd_d2 = Pin{ port: .f, pin: 5 }
pub const sd_d3 = Pin{ port: .f, pin: 4 }
pub const sd_cd = Pin{ port: .f, pin: 6 }    // Card detect

// eMMC pins (usually Port C)
pub const emmc_clk = Pin{ port: .c, pin: 2 }
pub const emmc_cmd = Pin{ port: .c, pin: 3 }
pub const emmc_d0 = Pin{ port: .c, pin: 4 }
pub const emmc_d1 = Pin{ port: .c, pin: 5 }
pub const emmc_d2 = Pin{ port: .c, pin: 6 }
pub const emmc_d3 = Pin{ port: .c, pin: 7 }
pub const emmc_d4 = Pin{ port: .c, pin: 8 }
pub const emmc_d5 = Pin{ port: .c, pin: 9 }
pub const emmc_d6 = Pin{ port: .c, pin: 10 }
pub const emmc_d7 = Pin{ port: .c, pin: 11 }
pub const emmc_rst = Pin{ port: .c, pin: 1 }

// UART0 (debug console)
pub const uart0_tx = Pin{ port: .b, pin: 9 }
pub const uart0_rx = Pin{ port: .b, pin: 10 }

// I2C0
pub const i2c0_scl = Pin{ port: .b, pin: 0 }
pub const i2c0_sda = Pin{ port: .b, pin: 1 }

// I2C1
pub const i2c1_scl = Pin{ port: .b, pin: 2 }
pub const i2c1_sda = Pin{ port: .b, pin: 3 }

// SPI0 (for NOR flash)
pub const spi0_clk = Pin{ port: .c, pin: 0 }
pub const spi0_mosi = Pin{ port: .c, pin: 2 }
pub const spi0_miso = Pin{ port: .c, pin: 3 }
pub const spi0_cs0 = Pin{ port: .c, pin: 1 }

// PWM (for fan control)
pub const pwm0 = Pin{ port: .d, pin: 22 }

// Status LEDs (example pins - actual pins depend on board design)
pub const led_power = Pin{ port: .l, pin: 2 }
pub const led_status = Pin{ port: .l, pin: 3 }

// =============================================================================
// Register access helpers
// =============================================================================

// Get the base address for a port's registers
pub fn get_port_base(port Port) u64 {
	// Ports L and M are in R_PIO domain
	base := if int(port) >= 11 { pio_r_base } else { pio_base }
	port_num := if int(port) >= 11 { int(port) - 11 } else { int(port) }
	return base + u64(port_num) * u64(port_offset)
}

// Get the CFG register offset for a pin
pub fn get_cfg_offset(pin_num u8) u32 {
	cfg_idx := pin_num / 8
	return match cfg_idx {
		0 { cfg0 }
		1 { cfg1 }
		2 { cfg2 }
		3 { cfg3 }
		else { cfg0 }
	}
}

// Get the bit position within CFG register (4 bits per pin)
pub fn get_cfg_shift(pin_num u8) u8 {
	return (pin_num % 8) * 4
}

// Get the DRV register offset for a pin
pub fn get_drv_offset(pin_num u8) u32 {
	return if pin_num < 16 { drv0 } else { drv1 }
}

// Get the bit position within DRV register (2 bits per pin)
pub fn get_drv_shift(pin_num u8) u8 {
	return (pin_num % 16) * 2
}

// Get the PULL register offset for a pin
pub fn get_pull_offset(pin_num u8) u32 {
	return if pin_num < 16 { pull0 } else { pull1 }
}

// Get the bit position within PULL register (2 bits per pin)
pub fn get_pull_shift(pin_num u8) u8 {
	return (pin_num % 16) * 2
}

// Get external interrupt register base for a port
pub fn get_eint_base(port Port) u64 {
	base := if int(port) >= 11 { pio_r_base } else { pio_base }
	port_num := if int(port) >= 11 { int(port) - 11 } else { int(port) }
	return base + u64(eint_base) + u64(port_num) * u64(eint_port_offset)
}

// Get EINT CFG register offset for a pin
pub fn get_eint_cfg_offset(pin_num u8) u32 {
	cfg_idx := pin_num / 8
	return match cfg_idx {
		0 { eint_cfg0 }
		1 { eint_cfg1 }
		2 { eint_cfg2 }
		3 { eint_cfg3 }
		else { eint_cfg0 }
	}
}

// =============================================================================
// Pin mux definitions - alternate functions for each port
// (Partial list - extend as needed based on A527 datasheet)
// =============================================================================

// Port B alternate functions
pub const pb_uart0_tx = PinFunction.func2     // PB9
pub const pb_uart0_rx = PinFunction.func2     // PB10
pub const pb_i2c0 = PinFunction.func2         // PB0, PB1
pub const pb_i2c1 = PinFunction.func2         // PB2, PB3

// Port C alternate functions (eMMC, SPI)
pub const pc_emmc = PinFunction.func3         // PC1-PC11
pub const pc_spi0 = PinFunction.func4         // PC0-PC3

// Port F alternate functions (SD card)
pub const pf_mmc0 = PinFunction.func2         // PF0-PF5
pub const pf_gpio = PinFunction.input         // PF6 (card detect)

// =============================================================================
// Unit tests
// =============================================================================

fn test_port_base() {
	// Test main PIO ports
	assert get_port_base(.a) == pio_base
	assert get_port_base(.b) == pio_base + 0x24
	assert get_port_base(.c) == pio_base + 0x48
	
	// Test R_PIO ports
	assert get_port_base(.l) == pio_r_base
	assert get_port_base(.m) == pio_r_base + 0x24
}

fn test_cfg_offset() {
	// Pin 0-7 should use CFG0
	assert get_cfg_offset(0) == cfg0
	assert get_cfg_offset(7) == cfg0
	
	// Pin 8-15 should use CFG1
	assert get_cfg_offset(8) == cfg1
	assert get_cfg_offset(15) == cfg1
	
	// Pin 16-23 should use CFG2
	assert get_cfg_offset(16) == cfg2
	assert get_cfg_offset(23) == cfg2
}

fn test_cfg_shift() {
	// Each pin takes 4 bits
	assert get_cfg_shift(0) == 0
	assert get_cfg_shift(1) == 4
	assert get_cfg_shift(2) == 8
	assert get_cfg_shift(7) == 28
	assert get_cfg_shift(8) == 0   // Wraps to next register
}

fn test_drv_offset() {
	// Pins 0-15 use DRV0
	assert get_drv_offset(0) == drv0
	assert get_drv_offset(15) == drv0
	
	// Pins 16-31 use DRV1
	assert get_drv_offset(16) == drv1
	assert get_drv_offset(31) == drv1
}

fn test_drv_shift() {
	// Each pin takes 2 bits
	assert get_drv_shift(0) == 0
	assert get_drv_shift(1) == 2
	assert get_drv_shift(7) == 14
	assert get_drv_shift(16) == 0  // Wraps to next register
}

fn test_pull_offset() {
	// Same pattern as DRV
	assert get_pull_offset(0) == pull0
	assert get_pull_offset(15) == pull0
	assert get_pull_offset(16) == pull1
}

fn test_pin_creation() {
	p := pin(.b, 9)
	assert p.port == .b
	assert p.pin == 9
	
	// Test predefined pins
	assert uart0_tx.port == .b
	assert uart0_tx.pin == 9
}

fn test_eint_base() {
	// Port A external interrupts
	assert get_eint_base(.a) == pio_base + u64(eint_base)
	
	// Port B external interrupts
	assert get_eint_base(.b) == pio_base + u64(eint_base) + u64(eint_port_offset)
}

fn test_eint_cfg_offset() {
	assert get_eint_cfg_offset(0) == eint_cfg0
	assert get_eint_cfg_offset(8) == eint_cfg1
	assert get_eint_cfg_offset(16) == eint_cfg2
	assert get_eint_cfg_offset(24) == eint_cfg3
}

fn test_pin_function_values() {
	assert int(PinFunction.input) == 0
	assert int(PinFunction.output) == 1
	assert int(PinFunction.eint) == 14
	assert int(PinFunction.disabled) == 15
}

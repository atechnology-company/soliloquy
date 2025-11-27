// Allwinner (Sunxi) MMC/SD Host Controller Driver
// Translated to V language for Soliloquy OS
//
// Supports Allwinner A527/T527 SoCs used in Radxa Cubie A5E
// Based on Linux sunxi-mmc driver
//
// Reference: third_party/zircon_c/drivers/mmc/sunxi_mmc.h

module mmc

import sync

// Simple microsecond delay (busy-wait for now)
fn delay_us(us u32) {
	mut count := us * 100
	for count > 0 {
		count--
	}
}

// =============================================================================
// Status codes (matching Zircon)
// =============================================================================
pub enum MmcStatus {
	ok = 0
	err_internal = -1
	err_no_memory = -4
	err_invalid_args = -10
	err_bad_state = -20
	err_timed_out = -21
	err_io = -40
	err_not_supported = -2
}

// =============================================================================
// Bus timing modes
// =============================================================================
pub enum SdmmcTiming {
	legacy
	high_speed
	sdr12
	sdr25
	sdr50
	sdr104
	ddr50
	hs200
	hs400
}

// =============================================================================
// Bus voltage
// =============================================================================
pub enum SdmmcVoltage {
	v330  // 3.3V
	v180  // 1.8V
}

// =============================================================================
// MMIO interface trait (for hardware abstraction)
// =============================================================================
pub interface MmioInterface {
	read32(offset u32) u32
	write32(offset u32, value u32)
}

// =============================================================================
// Simple MMIO buffer implementation
// =============================================================================
pub struct MmioBuffer {
pub:
	base_addr u64
mut:
	// In real implementation, this would be memory-mapped
	regs [256]u32
}

pub fn MmioBuffer.new(base_addr u64) MmioBuffer {
	return MmioBuffer{
		base_addr: base_addr
	}
}

pub fn (m &MmioBuffer) read32(offset u32) u32 {
	idx := offset >> 2
	if idx < 256 {
		return m.regs[idx]
	}
	return 0
}

pub fn (mut m MmioBuffer) write32(offset u32, value u32) {
	idx := offset >> 2
	if idx < 256 {
		m.regs[idx] = value
	}
}

// =============================================================================
// Request structure
// =============================================================================
pub struct SdmmcRequest {
pub:
	cmd_idx    u32
	arg        u32
	cmd_flags  u32
	blocksize  u32
	blocks     u32
pub mut:
	response   [4]u32
}

// Command flags
pub const sdmmc_resp_none = u32(0)
pub const sdmmc_resp_len_48 = u32(1 << 0)
pub const sdmmc_resp_len_136 = u32(1 << 1)
pub const sdmmc_resp_len_48b = u32(1 << 2)      // 48-bit with busy
pub const sdmmc_resp_crc_check = u32(1 << 3)
pub const sdmmc_resp_data_present = u32(1 << 4)
pub const sdmmc_cmd_read = u32(1 << 5)
pub const sdmmc_cmd_write = u32(0)              // Default is write
pub const sdmmc_cmd_auto12 = u32(1 << 6)

// =============================================================================
// Sunxi MMC Controller
// =============================================================================
pub struct SunxiMmc {
pub:
	soc_variant SocVariant
	caps        SunxiMmcCaps
mut:
	mmio          MmioBuffer
	mtx           sync.Mutex
	clock_hz      u32
	bus_width     u32
	timing        SdmmcTiming
	voltage       SdmmcVoltage
	initialized   bool
	dma_enabled   bool
	// DMA descriptors (simplified - real impl would use pinned memory)
	descriptors   [512]DmaDescriptor
	desc_count    u32
}

// Create a new Sunxi MMC controller instance
pub fn SunxiMmc.new(base_addr u64, soc SocVariant) SunxiMmc {
	return SunxiMmc{
		soc_variant: soc
		caps: get_soc_caps(soc)
		mmio: MmioBuffer.new(base_addr)
		clock_hz: 0
		bus_width: 1
		timing: .legacy
		voltage: .v330
		initialized: false
		dma_enabled: false
	}
}

// =============================================================================
// Initialization
// =============================================================================

// Initialize the controller
pub fn (mut c SunxiMmc) init() MmcStatus {
	c.mtx.@lock()
	defer { c.mtx.unlock() }
	
	// Reset the controller
	status := c.reset_controller()
	if status != .ok {
		return status
	}
	
	// Set FIFO thresholds
	fifo_val := (c.caps.fifo_depth / 2) << 16 |  // RX threshold
	            (c.caps.fifo_depth / 2) |         // TX threshold
	            (burst_size_8 << 28) |            // Burst size
	            (1 << 31)                         // Burst size mode
	c.mmio.write32(reg_fifo_threshold, fifo_val)
	
	// Set default timeout
	c.mmio.write32(reg_timeout, default_timeout)
	
	// Start with 400kHz for card detection
	c.set_clock(init_clock_hz) or { return .err_io }
	
	// Enable global interrupt
	mut gctrl := c.mmio.read32(reg_global_control)
	gctrl |= gctrl_interrupt_enable
	c.mmio.write32(reg_global_control, gctrl)
	
	// Enable interrupts
	c.enable_interrupts()
	
	c.initialized = true
	return .ok
}

// Reset the controller
fn (mut c SunxiMmc) reset_controller() MmcStatus {
	// Assert soft reset, FIFO reset, DMA reset
	gctrl := gctrl_soft_reset | gctrl_fifo_reset | gctrl_dma_reset
	c.mmio.write32(reg_global_control, gctrl)
	
	// Wait for reset to complete
	return c.wait_for_reset(reset_timeout_us)
}

// Wait for reset bits to clear
fn (mut c SunxiMmc) wait_for_reset(timeout_us u32) MmcStatus {
	reset_mask := gctrl_soft_reset | gctrl_fifo_reset | gctrl_dma_reset
	
	mut elapsed := u32(0)
	for elapsed < timeout_us {
		gctrl := c.mmio.read32(reg_global_control)
		if (gctrl & reset_mask) == 0 {
			return .ok
		}
		delay_us(100)
		elapsed += 100
	}
	
	return .err_timed_out
}

// Reset FIFO only
fn (mut c SunxiMmc) reset_fifo() MmcStatus {
	mut gctrl := c.mmio.read32(reg_global_control)
	gctrl |= gctrl_fifo_reset
	c.mmio.write32(reg_global_control, gctrl)
	
	mut elapsed := u32(0)
	for elapsed < reset_timeout_us {
		gctrl = c.mmio.read32(reg_global_control)
		if (gctrl & gctrl_fifo_reset) == 0 {
			return .ok
		}
		delay_us(10)
		elapsed += 10
	}
	
	return .err_timed_out
}

// =============================================================================
// Clock management
// =============================================================================

// Set the bus clock frequency
pub fn (mut c SunxiMmc) set_clock(freq_hz u32) !u32 {
	if freq_hz == 0 {
		// Disable clock
		c.update_clock_register(false)!
		c.clock_hz = 0
		return 0
	}
	
	// Clamp to maximum
	target := if freq_hz > c.caps.max_clock_hz { c.caps.max_clock_hz } else { freq_hz }
	
	// Assume 24MHz source clock (typical for Allwinner)
	source_clock := u32(24_000_000)
	
	m, n, actual := calc_clock_dividers(source_clock, target)
	
	// Disable clock first
	c.update_clock_register(false)!
	
	// Set dividers
	clkctrl := (m & 0xFF) | ((n & 0xFF) << 8)
	c.mmio.write32(reg_clock_control, clkctrl)
	
	// Enable clock
	c.update_clock_register(true)!
	
	c.clock_hz = actual
	return actual
}

// Update clock register (enable/disable card clock)
fn (mut c SunxiMmc) update_clock_register(enable bool) ! {
	mut clkctrl := c.mmio.read32(reg_clock_control)
	
	if enable {
		clkctrl |= clkctrl_card_clock_on
	} else {
		clkctrl &= ~clkctrl_card_clock_on
	}
	c.mmio.write32(reg_clock_control, clkctrl)
	
	// Send clock update command
	cmd := cmd_start | cmd_update_clock | cmd_wait_data_complete
	c.mmio.write32(reg_command, cmd)
	
	// Wait for command to complete
	mut elapsed := u32(0)
	for elapsed < 100_000 {
		cmd_reg := c.mmio.read32(reg_command)
		if (cmd_reg & cmd_start) == 0 {
			return
		}
		delay_us(10)
		elapsed += 10
	}
	
	return error('clock update timeout')
}

// =============================================================================
// Bus configuration
// =============================================================================

// Set bus width
pub fn (mut c SunxiMmc) set_bus_width(width u32) MmcStatus {
	c.mtx.@lock()
	defer { c.mtx.unlock() }
	
	width_val := match width {
		1 { bus_width_1bit }
		4 { bus_width_4bit }
		8 {
			if !c.caps.supports_8bit {
				return .err_not_supported
			}
			bus_width_8bit
		}
		else { return .err_invalid_args }
	}
	
	c.mmio.write32(reg_bus_width, width_val)
	c.bus_width = width
	return .ok
}

// Set timing mode
pub fn (mut c SunxiMmc) set_timing(timing SdmmcTiming) MmcStatus {
	c.mtx.@lock()
	defer { c.mtx.unlock() }
	
	mut gctrl := c.mmio.read32(reg_global_control)
	
	// Enable DDR mode for DDR50/HS400
	ddr_mode := timing == .ddr50 || timing == .hs400
	if ddr_mode {
		gctrl |= gctrl_ddr_mode
	} else {
		gctrl &= ~gctrl_ddr_mode
	}
	c.mmio.write32(reg_global_control, gctrl)
	
	// Configure new timing mode for UHS speeds
	if c.caps.has_new_timing {
		mut ntsr := c.mmio.read32(reg_ntsr)
		new_mode := timing != .legacy
		if new_mode {
			ntsr |= (1 << 31)  // mode_select bit
		} else {
			ntsr &= ~u32(1 << 31)
		}
		c.mmio.write32(reg_ntsr, ntsr)
	}
	
	c.timing = timing
	return .ok
}

// Set signal voltage
pub fn (mut c SunxiMmc) set_voltage(voltage SdmmcVoltage) MmcStatus {
	if voltage == .v180 && !c.caps.supports_1v8 {
		return .err_not_supported
	}
	c.voltage = voltage
	return .ok
}

// Hardware reset (for eMMC)
pub fn (mut c SunxiMmc) hw_reset() MmcStatus {
	// Assert hardware reset (active low)
	c.mmio.write32(reg_hardware_rst, 0)
	delay_us(10)
	
	// Deassert reset
	c.mmio.write32(reg_hardware_rst, 1)
	delay_us(1000)  // 1ms
	
	return .ok
}

// =============================================================================
// Command execution
// =============================================================================

// Execute a command/request
pub fn (mut c SunxiMmc) request(mut req SdmmcRequest) MmcStatus {
	c.mtx.@lock()
	defer { c.mtx.unlock() }
	
	if !c.initialized {
		return .err_bad_state
	}
	
	// Reset FIFO before data transfers
	if (req.cmd_flags & sdmmc_resp_data_present) != 0 {
		status := c.reset_fifo()
		if status != .ok {
			return status
		}
	}
	
	// Set block size and byte count for data transfers
	if (req.cmd_flags & sdmmc_resp_data_present) != 0 {
		c.mmio.write32(reg_block_size, req.blocksize)
		c.mmio.write32(reg_byte_count, req.blocksize * req.blocks)
	}
	
	// Set command argument
	c.mmio.write32(reg_command_arg, req.arg)
	
	// Build command register value
	cmd := c.build_cmd_reg(req.cmd_idx, req.cmd_flags)
	c.mmio.write32(reg_command, cmd)
	
	// Wait for command complete
	status := c.wait_command_complete(cmd_timeout_us)
	if status != .ok {
		c.error_recovery()
		return status
	}
	
	// Get response
	c.get_response(mut req)
	
	// Wait for data if needed
	if (req.cmd_flags & sdmmc_resp_data_present) != 0 {
		data_status := c.wait_data_complete(data_timeout_us)
		if data_status != .ok {
			c.error_recovery()
			return data_status
		}
	}
	
	return .ok
}

// Build command register value from request flags
fn (c &SunxiMmc) build_cmd_reg(cmd_idx u32, flags u32) u32 {
	mut cmd := cmd_start | (cmd_idx & 0x3F)
	
	// Response handling
	if (flags & sdmmc_resp_len_136) != 0 {
		cmd |= cmd_response_expected | cmd_long_response | cmd_check_resp_crc
	} else if (flags & sdmmc_resp_len_48) != 0 {
		cmd |= cmd_response_expected
		if (flags & sdmmc_resp_crc_check) != 0 {
			cmd |= cmd_check_resp_crc
		}
	} else if (flags & sdmmc_resp_len_48b) != 0 {
		cmd |= cmd_response_expected | cmd_wait_data_complete
		if (flags & sdmmc_resp_crc_check) != 0 {
			cmd |= cmd_check_resp_crc
		}
	}
	
	// Data handling
	if (flags & sdmmc_resp_data_present) != 0 {
		cmd |= cmd_data_expected
		if (flags & sdmmc_cmd_read) == 0 {
			cmd |= cmd_write
		}
	}
	
	// Auto-stop
	if (flags & sdmmc_cmd_auto12) != 0 {
		cmd |= cmd_auto_stop
	}
	
	return cmd
}

// Wait for command complete
fn (mut c SunxiMmc) wait_command_complete(timeout_us u32) MmcStatus {
	mut elapsed := u32(0)
	
	for elapsed < timeout_us {
		status := c.mmio.read32(reg_raw_status)
		
		// Check for errors
		if has_error(status) {
			// Clear interrupt
			c.mmio.write32(reg_raw_status, status)
			return .err_io
		}
		
		// Check for command done
		if (status & int_command_done) != 0 {
			// Clear interrupt
			c.mmio.write32(reg_raw_status, int_command_done)
			return .ok
		}
		
		delay_us(10)
		elapsed += 10
	}
	
	return .err_timed_out
}

// Wait for data transfer complete
fn (mut c SunxiMmc) wait_data_complete(timeout_us u32) MmcStatus {
	mut elapsed := u32(0)
	
	for elapsed < timeout_us {
		status := c.mmio.read32(reg_raw_status)
		
		// Check for errors
		if has_error(status) {
			c.mmio.write32(reg_raw_status, status)
			return .err_io
		}
		
		// Check for data complete
		if (status & int_data_complete) != 0 {
			c.mmio.write32(reg_raw_status, int_data_complete | int_auto_cmd_done)
			return .ok
		}
		
		delay_us(10)
		elapsed += 10
	}
	
	return .err_timed_out
}

// Get response from hardware
fn (c &SunxiMmc) get_response(mut req SdmmcRequest) {
	if (req.cmd_flags & sdmmc_resp_len_136) != 0 {
		// 136-bit response (R2)
		req.response[0] = c.mmio.read32(reg_response0)
		req.response[1] = c.mmio.read32(reg_response1)
		req.response[2] = c.mmio.read32(reg_response2)
		req.response[3] = c.mmio.read32(reg_response3)
	} else {
		// 48-bit response
		req.response[0] = c.mmio.read32(reg_response0)
		req.response[1] = 0
		req.response[2] = 0
		req.response[3] = 0
	}
}

// =============================================================================
// Interrupt management
// =============================================================================

// Enable interrupts
fn (mut c SunxiMmc) enable_interrupts() {
	mask := int_error_mask | int_data_complete | int_command_done | int_auto_cmd_done
	c.mmio.write32(reg_interrupt_mask, mask)
	
	mut gctrl := c.mmio.read32(reg_global_control)
	gctrl |= gctrl_interrupt_enable
	c.mmio.write32(reg_global_control, gctrl)
}

// Disable interrupts
fn (mut c SunxiMmc) disable_interrupts() {
	c.mmio.write32(reg_interrupt_mask, 0)
	
	mut gctrl := c.mmio.read32(reg_global_control)
	gctrl &= ~gctrl_interrupt_enable
	c.mmio.write32(reg_global_control, gctrl)
}

// Clear all interrupts
fn (mut c SunxiMmc) clear_interrupts() {
	c.mmio.write32(reg_raw_status, 0xFFFFFFFF)
}

// =============================================================================
// Error recovery
// =============================================================================

fn (mut c SunxiMmc) error_recovery() {
	// Clear all interrupts
	c.clear_interrupts()
	
	// Reset FIFO
	c.reset_fifo()
	
	// Reset DMA if enabled
	if c.dma_enabled {
		mut gctrl := c.mmio.read32(reg_global_control)
		gctrl |= gctrl_dma_reset
		c.mmio.write32(reg_global_control, gctrl)
	}
}

// =============================================================================
// Tuning (for HS200/HS400)
// =============================================================================

// Execute tuning procedure
pub fn (mut c SunxiMmc) execute_tuning(cmd_idx u32) MmcStatus {
	if !c.caps.has_delay_control {
		return .err_not_supported
	}
	
	// Search for optimal sampling delay
	mut best_delay := u32(0)
	mut best_window := u32(0)
	mut window_start := u32(0)
	mut window_size := u32(0)
	mut in_window := false
	
	for delay in 0 .. 64 {
		// Set sample delay
		samp := u32((1 << 17) | delay)  // enable bit + delay value
		c.mmio.write32(reg_samp_dl, samp)
		
		// Send tuning command (simplified)
		mut req := SdmmcRequest{
			cmd_idx: cmd_idx
			arg: 0
			cmd_flags: sdmmc_resp_len_48 | sdmmc_resp_data_present | sdmmc_cmd_read
			blocksize: 64
			blocks: 1
		}
		
		success := c.request(mut req) == .ok
		
		if success {
			if !in_window {
				window_start = u32(delay)
				in_window = true
			}
			window_size++
		} else {
			if in_window {
				if window_size > best_window {
					best_window = window_size
					best_delay = window_start + window_size / 2
				}
				window_size = 0
				in_window = false
			}
		}
	}
	
	// Check last window
	if in_window && window_size > best_window {
		best_window = window_size
		best_delay = window_start + window_size / 2
	}
	
	if best_window == 0 {
		return .err_io
	}
	
	// Set optimal delay
	samp := (1 << 17) | best_delay
	c.mmio.write32(reg_samp_dl, samp)
	
	return .ok
}

// =============================================================================
// Debug
// =============================================================================

// Dump register state (for debugging)
pub fn (c &SunxiMmc) dump_registers() {
	println('=== Sunxi MMC Register Dump ===')
	println('GCTRL:  0x${c.mmio.read32(reg_global_control):08x}')
	println('CLKCTL: 0x${c.mmio.read32(reg_clock_control):08x}')
	println('STATUS: 0x${c.mmio.read32(reg_status):08x}')
	println('RINTST: 0x${c.mmio.read32(reg_raw_status):08x}')
	println('IMASK:  0x${c.mmio.read32(reg_interrupt_mask):08x}')
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_sunxi_mmc_new() {
	controller := SunxiMmc.new(0x4020000, .a527)
	
	assert controller.soc_variant == .a527
	assert controller.caps.supports_hs400
	assert controller.bus_width == 1
	assert controller.timing == .legacy
}

fn test_build_cmd_reg() {
	controller := SunxiMmc.new(0x4020000, .a527)
	
	// CMD17 - Read single block with R1 response
	flags := sdmmc_resp_len_48 | sdmmc_resp_crc_check | sdmmc_resp_data_present | sdmmc_cmd_read
	cmd := controller.build_cmd_reg(17, flags)
	
	assert (cmd & 0x3F) == 17
	assert (cmd & cmd_start) != 0
	assert (cmd & cmd_response_expected) != 0
	assert (cmd & cmd_data_expected) != 0
	assert (cmd & cmd_write) == 0  // Read command
}

fn test_set_bus_width() {
	mut controller := SunxiMmc.new(0x4020000, .a527)
	controller.initialized = true  // Skip init for test
	
	assert controller.set_bus_width(1) == .ok
	assert controller.bus_width == 1
	
	assert controller.set_bus_width(4) == .ok
	assert controller.bus_width == 4
	
	assert controller.set_bus_width(8) == .ok
	assert controller.bus_width == 8
	
	// Invalid width
	assert controller.set_bus_width(3) == .err_invalid_args
}

fn test_set_timing() {
	mut controller := SunxiMmc.new(0x4020000, .a527)
	
	assert controller.set_timing(.high_speed) == .ok
	assert controller.timing == .high_speed
	
	assert controller.set_timing(.ddr50) == .ok
	assert controller.timing == .ddr50
}

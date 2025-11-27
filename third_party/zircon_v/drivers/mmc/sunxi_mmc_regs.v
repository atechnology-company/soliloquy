// Allwinner (Sunxi) MMC/SD Host Controller Register Definitions
// Translated to V language for Soliloquy OS
//
// Based on Allwinner A527/T527 User Manual and Linux sunxi-mmc driver
// Supports: A527, T527, H616, H618, D1, and other sun50i/sun55i variants
//
// Reference: third_party/zircon_c/drivers/mmc/sunxi_mmc_regs.h

module mmc

// =============================================================================
// Register offsets
// =============================================================================
pub const reg_global_control = u32(0x00)    // Global Control Register
pub const reg_clock_control = u32(0x04)     // Clock Control Register
pub const reg_timeout = u32(0x08)           // Timeout Register
pub const reg_bus_width = u32(0x0C)         // Bus Width Register
pub const reg_block_size = u32(0x10)        // Block Size Register
pub const reg_byte_count = u32(0x14)        // Byte Count Register
pub const reg_command = u32(0x18)           // Command Register
pub const reg_command_arg = u32(0x1C)       // Command Argument Register
pub const reg_response0 = u32(0x20)         // Response Register 0
pub const reg_response1 = u32(0x24)         // Response Register 1
pub const reg_response2 = u32(0x28)         // Response Register 2
pub const reg_response3 = u32(0x2C)         // Response Register 3
pub const reg_interrupt_mask = u32(0x30)    // Interrupt Mask Register
pub const reg_masked_status = u32(0x34)     // Masked Interrupt Status Register
pub const reg_raw_status = u32(0x38)        // Raw Interrupt Status Register
pub const reg_status = u32(0x3C)            // Status Register
pub const reg_fifo_threshold = u32(0x40)    // FIFO Water Level Register
pub const reg_func_select = u32(0x44)       // Function Select Register
pub const reg_cbcr = u32(0x48)              // CIU Byte Count Register
pub const reg_bbcr = u32(0x4C)              // BIU Byte Count Register
pub const reg_ntsr = u32(0x5C)              // SD New Timing Set Register
pub const reg_hardware_rst = u32(0x78)      // Hardware Reset Register
pub const reg_dmac = u32(0x80)              // Internal DMA Control Register
pub const reg_dlba = u32(0x84)              // Descriptor List Base Address Register
pub const reg_idst = u32(0x88)              // Internal DMA Status Register
pub const reg_idie = u32(0x8C)              // Internal DMA Interrupt Enable Register
pub const reg_chda = u32(0x90)              // Current Host Descriptor Address Register
pub const reg_cbda = u32(0x94)              // Current Buffer Descriptor Address Register
pub const reg_fifo = u32(0x100)             // Read/Write FIFO
pub const reg_fifo_new = u32(0x200)         // New FIFO access (A527/T527)

// For A527/T527 enhanced features
pub const reg_drv_dl = u32(0x140)           // Drive Delay Control Register
pub const reg_samp_dl = u32(0x144)          // Sample Delay Control Register
pub const reg_ds_delay = u32(0x148)         // Data Strobe Delay Register
pub const reg_hs400_dl = u32(0x14C)         // HS400 Delay Control Register

// =============================================================================
// Global Control Register (0x00) bits
// =============================================================================
pub const gctrl_access_by_ahb = u32(1 << 31)      // DMA access mode: 0=DMA, 1=AHB
pub const gctrl_ddr_mode = u32(1 << 10)           // DDR mode enable
pub const gctrl_dma_enable = u32(1 << 9)          // Internal DMA enable
pub const gctrl_interrupt_enable = u32(1 << 8)    // Global interrupt enable
pub const gctrl_debug_mode = u32(1 << 7)          // Debug mode
pub const gctrl_dma_reset = u32(1 << 5)           // DMA controller reset
pub const gctrl_fifo_reset = u32(1 << 2)          // FIFO reset
pub const gctrl_soft_reset = u32(1 << 1)          // Controller soft reset

// =============================================================================
// Clock Control Register (0x04) bits
// =============================================================================
pub const clkctrl_mask_data0 = u32(1 << 31)       // Mask DATA0 busy
pub const clkctrl_card_clock_on = u32(1 << 17)    // Card clock on/off
pub const clkctrl_low_power_mode = u32(1 << 16)   // Low power mode

// =============================================================================
// Command Register (0x18) bits
// =============================================================================
pub const cmd_start = u32(1 << 31)                // Start command
pub const cmd_hold_reg = u32(1 << 28)             // Hold CMD/DAT lines
pub const cmd_vol_switch = u32(1 << 27)           // Voltage switch
pub const cmd_boot_abort = u32(1 << 26)           // Boot abort
pub const cmd_expect_boot_ack = u32(1 << 25)      // Expect boot acknowledge
pub const cmd_boot_mode = u32(1 << 24)            // Boot mode
pub const cmd_update_clock = u32(1 << 21)         // Update clock only
pub const cmd_send_init_seq = u32(1 << 14)        // Send 80 clocks for init
pub const cmd_stop_abort = u32(1 << 13)           // Stop/abort command
pub const cmd_wait_data_complete = u32(1 << 12)   // Wait for data complete
pub const cmd_auto_stop = u32(1 << 11)            // Send auto stop
pub const cmd_write = u32(1 << 9)                 // 0=read, 1=write
pub const cmd_data_expected = u32(1 << 8)         // Data transfer expected
pub const cmd_check_resp_crc = u32(1 << 7)        // Check response CRC
pub const cmd_long_response = u32(1 << 6)         // 136-bit response
pub const cmd_response_expected = u32(1 << 5)     // Response expected

// =============================================================================
// Interrupt bits (for mask and status registers)
// =============================================================================
pub const int_sdio = u32(1 << 31)                 // SDIO interrupt
pub const int_card_removal = u32(1 << 16)         // Card removal
pub const int_card_insert = u32(1 << 15)          // Card insertion
pub const int_data_starve_timeout = u32(1 << 13)  // Data starvation timeout
pub const int_fifo_run_error = u32(1 << 12)       // FIFO underrun/overrun
pub const int_data_start_error = u32(1 << 11)     // Data start bit error
pub const int_data_end_bit_error = u32(1 << 10)   // Data end bit error
pub const int_data_crc_error = u32(1 << 9)        // Data CRC error
pub const int_data_timeout = u32(1 << 8)          // Data timeout
pub const int_response_timeout = u32(1 << 7)      // Response timeout
pub const int_response_crc_error = u32(1 << 6)    // Response CRC error
pub const int_resp_error = u32(1 << 5)            // Response error
pub const int_auto_cmd_done = u32(1 << 4)         // Auto command done
pub const int_data_complete = u32(1 << 3)         // Data transfer complete
pub const int_command_done = u32(1 << 2)          // Command done

// Error mask
pub const int_error_mask = int_data_starve_timeout | int_fifo_run_error |
	int_data_start_error | int_data_end_bit_error | int_data_crc_error |
	int_data_timeout | int_response_timeout | int_response_crc_error | int_resp_error

// =============================================================================
// Status Register (0x3C) bits
// =============================================================================
pub const status_data_busy = u32(1 << 11)         // Data state machine busy
pub const status_card_busy = u32(1 << 10)         // Card is busy
pub const status_card_present = u32(1 << 9)       // Card detected
pub const status_fifo_full = u32(1 << 8)          // FIFO full
pub const status_fifo_empty = u32(1 << 7)         // FIFO empty
pub const status_cmd_busy = u32(1 << 1)           // Command busy

// =============================================================================
// Bus width values
// =============================================================================
pub const bus_width_1bit = u32(0)
pub const bus_width_4bit = u32(1)
pub const bus_width_8bit = u32(2)

// =============================================================================
// FIFO threshold burst sizes
// =============================================================================
pub const burst_size_1 = u32(0)
pub const burst_size_4 = u32(1)
pub const burst_size_8 = u32(2)
pub const burst_size_16 = u32(3)

// =============================================================================
// DMA Control Register (0x80) bits
// =============================================================================
pub const dmac_fix_burst = u32(1 << 31)           // Fixed burst transfers
pub const dmac_idma_on = u32(1 << 7)              // Internal DMA enable
pub const dmac_idma_rst = u32(1 << 1)             // Internal DMA reset
pub const dmac_idma_enable = u32(1 << 0)          // DMA transfer enable

// =============================================================================
// DMA Descriptor structure
// =============================================================================
pub struct DmaDescriptor {
pub mut:
	config    u32    // Configuration word
	buf_size  u32    // Buffer size
	buf_addr  u32    // Buffer address (32-bit)
	next_desc u32    // Next descriptor address
}

// DMA descriptor config bits
pub const dma_own = u32(1 << 31)                  // DMA owns this descriptor
pub const dma_end_of_ring = u32(1 << 5)           // End of ring
pub const dma_chained = u32(1 << 4)               // Second address chained
pub const dma_last = u32(1 << 3)                  // Last descriptor
pub const dma_first = u32(1 << 2)                 // First descriptor
pub const dma_disable_int = u32(1 << 1)           // Disable interrupt on completion

// Set first descriptor flag
pub fn (mut d DmaDescriptor) set_first() {
	d.config |= dma_first
}

// Set last descriptor flag
pub fn (mut d DmaDescriptor) set_last() {
	d.config |= dma_last
}

// Set chained flag
pub fn (mut d DmaDescriptor) set_chained() {
	d.config |= dma_chained
}

// Set DMA ownership
pub fn (mut d DmaDescriptor) set_own() {
	d.config |= dma_own
}

// Check if DMA owns descriptor
pub fn (d &DmaDescriptor) is_owned() bool {
	return (d.config & dma_own) != 0
}

// =============================================================================
// Clock and timing constants
// =============================================================================
pub const default_timeout = u32(0xFFFFFF40)       // Default data/response timeout
pub const fifo_depth_words = u32(64)              // 64 words = 256 bytes FIFO
pub const block_size_max = u32(65535)             // Maximum block size
pub const max_clock_hz = u32(200_000_000)         // 200MHz max
pub const init_clock_hz = u32(400_000)            // 400kHz for init
pub const default_clock_hz = u32(25_000_000)      // 25MHz default
pub const high_speed_clock_hz = u32(50_000_000)   // 50MHz HS mode
pub const uhs_sdr50_clock_hz = u32(100_000_000)   // 100MHz SDR50
pub const uhs_sdr104_clock_hz = u32(200_000_000)  // 200MHz SDR104

// Timeouts in microseconds
pub const reset_timeout_us = u32(100_000)         // 100ms reset timeout
pub const cmd_timeout_us = u32(1_000_000)         // 1s command timeout
pub const data_timeout_us = u32(2_000_000)        // 2s data timeout

// =============================================================================
// SoC variants
// =============================================================================
pub enum SocVariant {
	a527     // Allwinner A527 (Cubie A5E)
	t527     // Allwinner T527 (industrial variant)
	h616     // Allwinner H616
	d1       // Allwinner D1 (RISC-V)
}

// =============================================================================
// Controller capabilities
// =============================================================================
pub struct SunxiMmcCaps {
pub:
	supports_hs400    bool
	supports_hs200    bool
	supports_ddr50    bool
	supports_sdr104   bool
	supports_sdr50    bool
	supports_8bit     bool
	supports_1v8      bool
	has_new_timing    bool
	has_delay_control bool
	max_clock_hz      u32
	fifo_depth        u32
}

// Get capabilities for a specific SoC
pub fn get_soc_caps(soc SocVariant) SunxiMmcCaps {
	return match soc {
		.a527, .t527 {
			SunxiMmcCaps{
				supports_hs400: true
				supports_hs200: true
				supports_ddr50: true
				supports_sdr104: true
				supports_sdr50: true
				supports_8bit: true
				supports_1v8: true
				has_new_timing: true
				has_delay_control: true
				max_clock_hz: 200_000_000
				fifo_depth: 64
			}
		}
		.h616 {
			SunxiMmcCaps{
				supports_hs400: false
				supports_hs200: true
				supports_ddr50: true
				supports_sdr104: true
				supports_sdr50: true
				supports_8bit: true
				supports_1v8: true
				has_new_timing: true
				has_delay_control: false
				max_clock_hz: 150_000_000
				fifo_depth: 64
			}
		}
		.d1 {
			SunxiMmcCaps{
				supports_hs400: false
				supports_hs200: true
				supports_ddr50: true
				supports_sdr104: false
				supports_sdr50: true
				supports_8bit: false
				supports_1v8: true
				has_new_timing: true
				has_delay_control: false
				max_clock_hz: 100_000_000
				fifo_depth: 64
			}
		}
	}
}

// =============================================================================
// Helper functions for register manipulation
// =============================================================================

// Build command register value
pub fn build_command(cmd_idx u32, has_response bool, long_resp bool, has_data bool, 
                     is_write bool, check_crc bool, auto_stop bool) u32 {
	mut cmd := cmd_start | (cmd_idx & 0x3F)
	
	if has_response {
		cmd |= cmd_response_expected
	}
	if long_resp {
		cmd |= cmd_long_response
	}
	if has_data {
		cmd |= cmd_data_expected
		if is_write {
			cmd |= cmd_write
		}
	}
	if check_crc {
		cmd |= cmd_check_resp_crc
	}
	if auto_stop {
		cmd |= cmd_auto_stop
	}
	
	return cmd
}

// Check if status indicates any error
pub fn has_error(status u32) bool {
	return (status & int_error_mask) != 0
}

// Calculate clock dividers
// Returns (m_divider, n_divider, actual_frequency)
pub fn calc_clock_dividers(source_hz u32, target_hz u32) (u32, u32, u32) {
	// Allwinner MMC clock = source / (2^n) / (m+1)
	// where n is 0-3 and m is 0-15
	
	mut best_m := u32(0)
	mut best_n := u32(0)
	mut best_diff := u32(0xFFFFFFFF)
	mut best_actual := u32(0)
	
	for n in 0 .. 4 {
		divided := source_hz >> n
		
		for m in 0 .. 16 {
			actual := divided / (m + 1)
			
			// We want actual <= target (don't go over)
			if actual <= target_hz {
				diff := target_hz - actual
				if diff < best_diff {
					best_diff = diff
					best_m = u32(m)
					best_n = u32(n)
					best_actual = actual
				}
			}
		}
	}
	
	return best_m, best_n, best_actual
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_dma_descriptor() {
	mut desc := DmaDescriptor{}
	
	desc.set_first()
	assert (desc.config & dma_first) != 0
	
	desc.set_last()
	assert (desc.config & dma_last) != 0
	
	desc.set_own()
	assert desc.is_owned()
}

fn test_build_command() {
	// CMD17 - Read single block
	cmd := build_command(17, true, false, true, false, true, false)
	
	assert (cmd & 0x3F) == 17
	assert (cmd & cmd_start) != 0
	assert (cmd & cmd_response_expected) != 0
	assert (cmd & cmd_long_response) == 0
	assert (cmd & cmd_data_expected) != 0
	assert (cmd & cmd_write) == 0
	assert (cmd & cmd_check_resp_crc) != 0
}

fn test_calc_clock_dividers() {
	// 24MHz source, target 400kHz
	_, _, actual := calc_clock_dividers(24_000_000, 400_000)
	
	// Should get close to 400kHz
	assert actual <= 400_000
	assert actual > 300_000  // Not too far below
}

fn test_soc_caps() {
	caps := get_soc_caps(.a527)
	
	assert caps.supports_hs400
	assert caps.supports_hs200
	assert caps.max_clock_hz == 200_000_000
	assert caps.has_delay_control
}

fn test_error_detection() {
	// No error
	assert !has_error(int_command_done)
	
	// CRC error
	assert has_error(int_data_crc_error)
	
	// Timeout
	assert has_error(int_response_timeout)
}

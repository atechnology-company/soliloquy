// Allwinner A527/T527 Clock Control Unit (CCU) Register Definitions
// Translated to V language for Soliloquy OS
//
// Based on Allwinner A527 User Manual and Linux sunxi-ng clock driver
// The CCU controls all clocks and resets on the SoC
//
// Reference: Allwinner A527 User Manual, Linux drivers/clk/sunxi-ng/

module clock

// =============================================================================
// Base addresses for different clock domains
// =============================================================================
pub const ccu_base = u64(0x02001000)          // Main CCU
pub const ccu_r_base = u64(0x07010000)        // RTC domain CCU (PRCM)
pub const ccu_dsp_base = u64(0x07100000)      // DSP domain CCU
pub const ccu_sys_base = u64(0x03001000)      // System control

// =============================================================================
// PLL Register Offsets (Main CCU)
// =============================================================================
pub const pll_cpux_ctrl = u32(0x000)          // CPU PLL Control
pub const pll_ddr0_ctrl = u32(0x010)          // DDR0 PLL Control
pub const pll_peri0_ctrl = u32(0x020)         // Peripheral 0 PLL (600MHz)
pub const pll_peri1_ctrl = u32(0x028)         // Peripheral 1 PLL
pub const pll_gpu0_ctrl = u32(0x030)          // GPU PLL
pub const pll_video0_ctrl = u32(0x040)        // Video 0 PLL
pub const pll_video1_ctrl = u32(0x048)        // Video 1 PLL
pub const pll_video2_ctrl = u32(0x050)        // Video 2 PLL
pub const pll_ve0_ctrl = u32(0x058)           // Video Engine 0 PLL
pub const pll_audio0_ctrl = u32(0x078)        // Audio 0 PLL
pub const pll_npu_ctrl = u32(0x080)           // NPU PLL

// =============================================================================
// Clock Gate/Divider Register Offsets
// =============================================================================
pub const cpux_axi_cfg = u32(0x500)           // CPU AXI Configuration
pub const ahb_cfg = u32(0x510)                // AHB Configuration
pub const apb0_cfg = u32(0x520)               // APB0 Configuration
pub const apb1_cfg = u32(0x524)               // APB1 Configuration
pub const mbus_cfg = u32(0x540)               // MBUS Configuration

// Peripheral clock registers
pub const de_clk = u32(0x600)                 // Display Engine Clock
pub const di0_clk = u32(0x620)                // De-interlacer Clock
pub const g2d_clk = u32(0x630)                // 2D Graphics Engine
pub const gpu_clk = u32(0x670)                // GPU Clock
pub const ce_clk = u32(0x680)                 // Crypto Engine Clock
pub const ve_clk = u32(0x690)                 // Video Engine Clock
pub const npu_clk = u32(0x6E0)                // NPU Clock

// Storage clocks
pub const dram_clk = u32(0x800)               // DRAM Clock
pub const mmc0_clk = u32(0x830)               // MMC0 Clock
pub const mmc1_clk = u32(0x834)               // MMC1 Clock
pub const mmc2_clk = u32(0x838)               // MMC2 (eMMC) Clock
pub const smhc_bgr = u32(0x84C)               // SMHC Bus Gating Reset

// Interface clocks
pub const uart_bgr = u32(0x90C)               // UART Bus Gating Reset
pub const i2c_bgr = u32(0x91C)                // I2C Bus Gating Reset
pub const spi0_clk = u32(0x940)               // SPI0 Clock
pub const spi1_clk = u32(0x944)               // SPI1 Clock
pub const spi_bgr = u32(0x96C)                // SPI Bus Gating Reset
pub const gpadc_bgr = u32(0x9EC)              // GPADC Bus Gating Reset

// USB clocks
pub const usb0_clk = u32(0xA70)               // USB0 Clock
pub const usb1_clk = u32(0xA74)               // USB1 Clock
pub const usb_bgr = u32(0xA8C)                // USB Bus Gating Reset

// Display/HDMI clocks
pub const hdmi_clk = u32(0xB00)               // HDMI Clock
pub const hdmi_bgr = u32(0xB1C)               // HDMI Bus Gating Reset
pub const dsi_clk = u32(0xB24)                // DSI Clock
pub const tcon_lcd0_clk = u32(0xB60)          // TCON LCD0 Clock
pub const tcon_tv0_clk = u32(0xB80)           // TCON TV0 Clock
pub const tve_bgr = u32(0xBBC)                // TVE Bus Gating Reset
pub const lvds_clk = u32(0xBAC)               // LVDS Clock

// =============================================================================
// PLL Control Register bits
// =============================================================================
pub const pll_enable = u32(1 << 31)           // PLL enable
pub const pll_lock_enable = u32(1 << 30)      // Lock enable
pub const pll_sdm_enable = u32(1 << 29)       // Sigma-delta enable
pub const pll_lock = u32(1 << 28)             // PLL is locked (read-only)
pub const pll_output_enable = u32(1 << 27)    // Output enable
pub const pll_ldo_enable = u32(1 << 26)       // LDO enable

// =============================================================================
// Clock source selections
// =============================================================================
pub const clk_src_hosc = u32(0)               // 24MHz oscillator
pub const clk_src_peri0 = u32(1)              // PLL_PERI0 (600MHz)
pub const clk_src_peri0x2 = u32(2)            // PLL_PERI0 x2 (1.2GHz)
pub const clk_src_peri1 = u32(3)              // PLL_PERI1
pub const clk_src_peri1x2 = u32(4)            // PLL_PERI1 x2

// =============================================================================
// Common clock frequencies
// =============================================================================
pub const hosc_freq = u64(24_000_000)         // 24 MHz crystal
pub const losc_freq = u64(32_768)             // 32.768 kHz crystal
pub const pll_peri0_freq = u64(600_000_000)   // 600 MHz
pub const pll_peri0x2_freq = u64(1_200_000_000) // 1.2 GHz

// =============================================================================
// Clock IDs
// =============================================================================
pub enum ClockId {
	// PLLs
	pll_cpux
	pll_ddr0
	pll_peri0
	pll_peri1
	pll_gpu
	pll_video0
	pll_video1
	pll_video2
	pll_ve
	pll_audio0
	pll_npu
	// Bus clocks
	ahb
	apb0
	apb1
	mbus
	// Peripheral clocks
	mmc0
	mmc1
	mmc2
	uart0
	uart1
	uart2
	uart3
	uart4
	uart5
	i2c0
	i2c1
	i2c2
	i2c3
	i2c4
	i2c5
	spi0
	spi1
	usb0
	usb1
	ehci0
	ehci1
	ohci0
	ohci1
	de
	gpu
	hdmi
	tcon_lcd0
	tcon_tv0
}

// =============================================================================
// Reset IDs
// =============================================================================
pub enum ResetId {
	mmc0
	mmc1
	mmc2
	uart0
	uart1
	uart2
	uart3
	uart4
	uart5
	i2c0
	i2c1
	i2c2
	i2c3
	i2c4
	i2c5
	spi0
	spi1
	usb0
	usb1
	ehci0
	ehci1
	ohci0
	ohci1
	de
	gpu
	hdmi
}

// =============================================================================
// PLL configuration structure
// =============================================================================
pub struct PllConfig {
pub:
	offset     u32     // Register offset
	n_shift    u32     // N factor shift
	n_width    u32     // N factor width
	m0_shift   u32     // M0 factor shift
	m0_width   u32     // M0 factor width
	m1_shift   u32     // M1 factor shift
	m1_width   u32     // M1 factor width
	p_shift    u32     // P factor shift
	p_width    u32     // P factor width
}

// Standard PLL configurations
pub const pll_cpux_config = PllConfig{
	offset: pll_cpux_ctrl
	n_shift: 8
	n_width: 8
	m0_shift: 0
	m0_width: 2
	m1_shift: 0
	m1_width: 0
	p_shift: 16
	p_width: 2
}

pub const pll_peri0_config = PllConfig{
	offset: pll_peri0_ctrl
	n_shift: 8
	n_width: 8
	m0_shift: 0
	m0_width: 2
	m1_shift: 4
	m1_width: 2
	p_shift: 16
	p_width: 5
}

// =============================================================================
// Clock/Reset gate register info
// =============================================================================
pub struct GateResetInfo {
pub:
	offset      u32    // Register offset
	gate_bit    u32    // Clock gate bit position
	reset_bit   u32    // Reset bit position (usually gate_bit + 16)
}

// Gate/reset configurations for peripherals
pub const mmc_gate_reset = [
	GateResetInfo{ offset: smhc_bgr, gate_bit: 0, reset_bit: 16 },   // MMC0
	GateResetInfo{ offset: smhc_bgr, gate_bit: 1, reset_bit: 17 },   // MMC1
	GateResetInfo{ offset: smhc_bgr, gate_bit: 2, reset_bit: 18 },   // MMC2
]

pub const uart_gate_reset = [
	GateResetInfo{ offset: uart_bgr, gate_bit: 0, reset_bit: 16 },   // UART0
	GateResetInfo{ offset: uart_bgr, gate_bit: 1, reset_bit: 17 },   // UART1
	GateResetInfo{ offset: uart_bgr, gate_bit: 2, reset_bit: 18 },   // UART2
	GateResetInfo{ offset: uart_bgr, gate_bit: 3, reset_bit: 19 },   // UART3
	GateResetInfo{ offset: uart_bgr, gate_bit: 4, reset_bit: 20 },   // UART4
	GateResetInfo{ offset: uart_bgr, gate_bit: 5, reset_bit: 21 },   // UART5
]

pub const i2c_gate_reset = [
	GateResetInfo{ offset: i2c_bgr, gate_bit: 0, reset_bit: 16 },    // I2C0
	GateResetInfo{ offset: i2c_bgr, gate_bit: 1, reset_bit: 17 },    // I2C1
	GateResetInfo{ offset: i2c_bgr, gate_bit: 2, reset_bit: 18 },    // I2C2
	GateResetInfo{ offset: i2c_bgr, gate_bit: 3, reset_bit: 19 },    // I2C3
	GateResetInfo{ offset: i2c_bgr, gate_bit: 4, reset_bit: 20 },    // I2C4
	GateResetInfo{ offset: i2c_bgr, gate_bit: 5, reset_bit: 21 },    // I2C5
]

pub const spi_gate_reset = [
	GateResetInfo{ offset: spi_bgr, gate_bit: 0, reset_bit: 16 },    // SPI0
	GateResetInfo{ offset: spi_bgr, gate_bit: 1, reset_bit: 17 },    // SPI1
]

// =============================================================================
// Helper functions
// =============================================================================

// Calculate PLL output frequency
// PLL output = (24MHz * N) / (M0 * M1 * 2^P)
pub fn calc_pll_freq(n u32, m0 u32, m1 u32, p u32) u64 {
	n_val := u64(n)
	m0_val := u64(if m0 == 0 { 1 } else { m0 })
	m1_val := u64(if m1 == 0 { 1 } else { m1 })
	p_val := u64(1) << p
	
	return (hosc_freq * n_val) / (m0_val * m1_val * p_val)
}

// Extract N factor from PLL register value
pub fn get_pll_n(reg_val u32, config &PllConfig) u32 {
	mask := (u32(1) << config.n_width) - 1
	return (reg_val >> config.n_shift) & mask
}

// Extract M0 factor from PLL register value
pub fn get_pll_m0(reg_val u32, config &PllConfig) u32 {
	if config.m0_width == 0 {
		return 1
	}
	mask := (u32(1) << config.m0_width) - 1
	return ((reg_val >> config.m0_shift) & mask) + 1
}

// Extract M1 factor from PLL register value
pub fn get_pll_m1(reg_val u32, config &PllConfig) u32 {
	if config.m1_width == 0 {
		return 1
	}
	mask := (u32(1) << config.m1_width) - 1
	return ((reg_val >> config.m1_shift) & mask) + 1
}

// Extract P factor from PLL register value
pub fn get_pll_p(reg_val u32, config &PllConfig) u32 {
	if config.p_width == 0 {
		return 0
	}
	mask := (u32(1) << config.p_width) - 1
	return (reg_val >> config.p_shift) & mask
}

// Check if PLL is enabled
pub fn is_pll_enabled(reg_val u32) bool {
	return (reg_val & pll_enable) != 0
}

// Check if PLL is locked
pub fn is_pll_locked(reg_val u32) bool {
	return (reg_val & pll_lock) != 0
}

// Calculate MMC clock frequency
// MMC clock = source / (2^N) / (M+1)
pub fn calc_mmc_freq(source_hz u64, n u32, m u32) u64 {
	n_div := u64(1) << n
	m_div := u64(m + 1)
	return source_hz / (n_div * m_div)
}

// Calculate optimal dividers for target frequency
// Returns (n, m, actual_freq)
pub fn calc_mmc_dividers(source_hz u64, target_hz u64) (u32, u32, u64) {
	mut best_n := u32(0)
	mut best_m := u32(0)
	mut best_diff := u64(0xFFFFFFFFFFFFFFFF)
	mut best_actual := u64(0)
	
	for n in u32(0) .. 4 {
		n_div := u64(1) << n
		
		for m in u32(0) .. 16 {
			actual := source_hz / (n_div * u64(m + 1))
			
			// We want actual <= target
			if actual <= target_hz {
				diff := target_hz - actual
				if diff < best_diff {
					best_diff = diff
					best_n = n
					best_m = m
					best_actual = actual
				}
			}
		}
	}
	
	return best_n, best_m, best_actual
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_calc_pll_freq() {
	// Test: 24MHz * 100 / (1 * 1 * 1) = 2.4GHz
	freq := calc_pll_freq(100, 1, 1, 0)
	assert freq == 2_400_000_000
	
	// Test: 24MHz * 50 / (1 * 1 * 2) = 600MHz
	freq2 := calc_pll_freq(50, 1, 1, 1)
	assert freq2 == 600_000_000
}

fn test_pll_factor_extraction() {
	// Simulated register value with N=100, M0=1, P=0
	// N is at bits 15:8, M0 at 1:0, P at 17:16
	reg_val := u32(100 << 8) | u32(0 << 0) | u32(0 << 16)
	
	n := get_pll_n(reg_val, &pll_cpux_config)
	m0 := get_pll_m0(reg_val, &pll_cpux_config)
	p := get_pll_p(reg_val, &pll_cpux_config)
	
	assert n == 100
	assert m0 == 1
	assert p == 0
}

fn test_pll_status() {
	// Test enabled and locked
	reg_val := pll_enable | pll_lock
	assert is_pll_enabled(reg_val)
	assert is_pll_locked(reg_val)
	
	// Test disabled
	assert !is_pll_enabled(0)
	assert !is_pll_locked(0)
}

fn test_calc_mmc_dividers() {
	// 600MHz source, 50MHz target
	n, m, actual := calc_mmc_dividers(600_000_000, 50_000_000)
	
	// Should get close to 50MHz
	assert actual <= 50_000_000
	assert actual >= 40_000_000
	
	// Verify calculation
	calculated := calc_mmc_freq(600_000_000, n, m)
	assert calculated == actual
}

fn test_gate_reset_info() {
	// Verify MMC0 gate/reset configuration
	assert mmc_gate_reset[0].offset == smhc_bgr
	assert mmc_gate_reset[0].gate_bit == 0
	assert mmc_gate_reset[0].reset_bit == 16
	
	// Verify UART0 configuration
	assert uart_gate_reset[0].offset == uart_bgr
	assert uart_gate_reset[0].gate_bit == 0
}

fn test_clock_constants() {
	assert hosc_freq == 24_000_000
	assert pll_peri0_freq == 600_000_000
	assert pll_peri0x2_freq == 1_200_000_000
}

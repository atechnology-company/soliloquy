// Allwinner A527/T527 EHCI Host Controller Driver
// Translated to V language for Soliloquy OS
//
// This driver implements the EHCI (Enhanced Host Controller Interface)
// for USB 2.0 high-speed host operations on USB1/USB2 ports
//
// Reference: EHCI Specification 1.0, Linux drivers/usb/host/ehci-sunxi.c

module usb

import sync

// =============================================================================
// EHCI Transfer Descriptor (qTD)
// =============================================================================
struct EhciQtd {
mut:
	next_qtd        u32      // Next qTD pointer
	alt_next_qtd    u32      // Alternate next qTD pointer
	token           u32      // Token (status, PID, etc.)
	buffer          [5]u32   // Buffer pointers (page-aligned)
	buffer_hi       [5]u32   // High 32 bits for 64-bit addressing
	// Driver-private data
	qtd_dma         u64      // DMA address of this qTD
	length          u32      // Transfer length
}

// qTD token bits
const qtd_toggle = u32(1 << 31)
const qtd_total_bytes_mask = u32(0x7FFF << 16)
const qtd_total_bytes_shift = u32(16)
const qtd_ioc = u32(1 << 15)           // Interrupt on complete
const qtd_cerr_mask = u32(3 << 10)     // Error counter
const qtd_cerr_shift = u32(10)
const qtd_pid_mask = u32(3 << 8)
const qtd_pid_out = u32(0 << 8)
const qtd_pid_in = u32(1 << 8)
const qtd_pid_setup = u32(2 << 8)
const qtd_status_active = u32(1 << 7)
const qtd_status_halted = u32(1 << 6)
const qtd_status_buffer_err = u32(1 << 5)
const qtd_status_babble = u32(1 << 4)
const qtd_status_xact_err = u32(1 << 3)
const qtd_status_missed_mf = u32(1 << 2)
const qtd_status_split_xstate = u32(1 << 1)
const qtd_status_ping = u32(1 << 0)

const qtd_terminate = u32(1)

// =============================================================================
// EHCI Queue Head (QH)
// =============================================================================
struct EhciQh {
mut:
	hw_next         u32      // Next QH pointer (horizontal)
	hw_info1        u32      // Endpoint characteristics
	hw_info2        u32      // Endpoint capabilities
	hw_current      u32      // Current qTD pointer
	// Overlay area (qTD copied here)
	hw_qtd_next     u32
	hw_alt_next     u32
	hw_token        u32
	hw_buf          [5]u32
	hw_buf_hi       [5]u32
	// Driver-private data
	qh_dma          u64      // DMA address of this QH
	qtd_list        []&EhciQtd
}

// QH info1 bits
const qh_head = u32(1 << 15)           // Head of reclamation list
const qh_data_toggle = u32(1 << 14)    // Data toggle control
const qh_eps_mask = u32(3 << 12)       // Endpoint speed
const qh_eps_full = u32(0 << 12)
const qh_eps_low = u32(1 << 12)
const qh_eps_high = u32(2 << 12)
const qh_ep_mask = u32(0xF << 8)       // Endpoint number
const qh_dev_addr_mask = u32(0x7F)     // Device address

// QH info2 bits
const qh_mult_mask = u32(3 << 30)      // High-bandwidth multiplier
const qh_port_mask = u32(0x7F << 23)   // Hub port number
const qh_hub_addr_mask = u32(0x7F << 16) // Hub address
const qh_cmask_mask = u32(0xFF << 8)   // Complete-split mask
const qh_smask_mask = u32(0xFF)        // Start-split mask

// =============================================================================
// EHCI Host Controller
// =============================================================================
pub struct EhciController {
pub:
	base            u64              // MMIO base address
	idx             u32              // Controller index (1 or 2)
pub mut:
	lock            sync.Mutex       // Thread safety
	cap_length      u8               // Capability register length
	hcs_params      u32              // Structural parameters
	hcc_params      u32              // Capability parameters
	num_ports       u8               // Number of ports
	is_running      bool             // Controller running
	periodic_list   u64              // Periodic frame list (physical)
	async_qh        ?&EhciQh         // Async list head
}

// =============================================================================
// EHCI Controller implementation
// =============================================================================

// Create a new EHCI controller instance
pub fn EhciController.new(idx u32) !EhciController {
	base := get_ehci_base(idx) or { return error('Invalid EHCI index') }
	
	return EhciController{
		base: base
		idx: idx
		cap_length: 0
		num_ports: 0
		is_running: false
		periodic_list: 0
		async_qh: none
	}
}

// Create with specific base address
pub fn EhciController.with_base(base u64, idx u32) EhciController {
	return EhciController{
		base: base
		idx: idx
		cap_length: 0
		num_ports: 0
		is_running: false
		periodic_list: 0
		async_qh: none
	}
}

// =============================================================================
// Initialization
// =============================================================================

// Initialize the controller
pub fn (mut c EhciController) init() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Read capability registers
	c.cap_length = mmio_read8(c.base, ehci_caplength)
	c.hcs_params = mmio_read32(c.base, ehci_hcsparams)
	c.hcc_params = mmio_read32(c.base, ehci_hccparams)
	
	// Extract number of ports
	c.num_ports = u8(c.hcs_params & 0x0F)
	
	// Reset the controller
	status := c.reset_locked()
	if status != .ok {
		return status
	}
	
	// Configure
	status2 := c.configure_locked()
	if status2 != .ok {
		return status2
	}
	
	return .ok
}

// Reset the controller
fn (mut c EhciController) reset_locked() ZxStatus {
	op_base := u32(c.cap_length)
	
	// Stop the controller first
	mut cmd := mmio_read32(c.base, op_base + ehci_usbcmd)
	cmd &= ~u32(cmd_run)
	mmio_write32(c.base, op_base + ehci_usbcmd, cmd)
	
	// Wait for halt
	mut timeout := u32(1000)
	for timeout > 0 {
		status := mmio_read32(c.base, op_base + ehci_usbsts)
		if (status & sts_halted) != 0 {
			break
		}
		delay_us(100)
		timeout -= 1
	}
	
	if timeout == 0 {
		return .err_timed_out
	}
	
	// Reset
	cmd = mmio_read32(c.base, op_base + ehci_usbcmd)
	cmd |= cmd_reset
	mmio_write32(c.base, op_base + ehci_usbcmd, cmd)
	
	// Wait for reset to complete
	timeout = 1000
	for timeout > 0 {
		cmd = mmio_read32(c.base, op_base + ehci_usbcmd)
		if (cmd & cmd_reset) == 0 {
			break
		}
		delay_us(100)
		timeout -= 1
	}
	
	if timeout == 0 {
		return .err_timed_out
	}
	
	c.is_running = false
	return .ok
}

// Configure the controller
fn (mut c EhciController) configure_locked() ZxStatus {
	op_base := u32(c.cap_length)
	
	// Set configure flag (route all ports to EHCI)
	mmio_write32(c.base, op_base + ehci_configflag, 1)
	
	// Set interrupt threshold to 1 microframe (125us)
	mut cmd := mmio_read32(c.base, op_base + ehci_usbcmd)
	cmd &= ~cmd_int_threshold_mask
	cmd |= (1 << 16)  // 1 microframe
	mmio_write32(c.base, op_base + ehci_usbcmd, cmd)
	
	return .ok
}

// Start the controller
pub fn (mut c EhciController) start() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	op_base := u32(c.cap_length)
	
	// Enable interrupts
	mmio_write32(c.base, op_base + ehci_usbintr, 
		sts_int | sts_err | sts_port_change | sts_host_error)
	
	// Start the controller
	mut cmd := mmio_read32(c.base, op_base + ehci_usbcmd)
	cmd |= cmd_run | cmd_async_en
	mmio_write32(c.base, op_base + ehci_usbcmd, cmd)
	
	// Wait for running
	mut timeout := u32(1000)
	for timeout > 0 {
		status := mmio_read32(c.base, op_base + ehci_usbsts)
		if (status & sts_halted) == 0 {
			c.is_running = true
			return .ok
		}
		delay_us(100)
		timeout -= 1
	}
	
	return .err_timed_out
}

// Stop the controller
pub fn (mut c EhciController) stop() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	op_base := u32(c.cap_length)
	
	// Stop
	mut cmd := mmio_read32(c.base, op_base + ehci_usbcmd)
	cmd &= ~u32(cmd_run | cmd_async_en | cmd_periodic_en)
	mmio_write32(c.base, op_base + ehci_usbcmd, cmd)
	
	// Wait for halt
	mut timeout := u32(1000)
	for timeout > 0 {
		status := mmio_read32(c.base, op_base + ehci_usbsts)
		if (status & sts_halted) != 0 {
			c.is_running = false
			return .ok
		}
		delay_us(100)
		timeout -= 1
	}
	
	return .err_timed_out
}

// =============================================================================
// Port operations
// =============================================================================

// Get number of ports
pub fn (c &EhciController) get_num_ports() u8 {
	return c.num_ports
}

// Get port status
pub fn (c &EhciController) get_port_status(port u8) u32 {
	if port >= c.num_ports {
		return 0
	}
	
	op_base := u32(c.cap_length)
	port_offset := ehci_portsc + u32(port) * 4
	
	return mmio_read32(c.base, op_base + port_offset)
}

// Reset a port
pub fn (mut c EhciController) reset_port(port u8) ZxStatus {
	if port >= c.num_ports {
		return .err_invalid_args
	}
	
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	op_base := u32(c.cap_length)
	port_offset := ehci_portsc + u32(port) * 4
	
	// Read current status
	mut status := mmio_read32(c.base, op_base + port_offset)
	
	// Check if connected
	if (status & portsc_connect) == 0 {
		return .err_not_found
	}
	
	// Set reset bit
	status |= portsc_reset
	status &= ~u32(portsc_enabled)  // Will be set after reset
	mmio_write32(c.base, op_base + port_offset, status)
	
	// Wait at least 50ms for reset
	delay_us(50000)
	
	// Clear reset bit
	status = mmio_read32(c.base, op_base + port_offset)
	status &= ~u32(portsc_reset)
	mmio_write32(c.base, op_base + port_offset, status)
	
	// Wait for reset to complete and port to be enabled
	mut timeout := u32(1000)
	for timeout > 0 {
		status = mmio_read32(c.base, op_base + port_offset)
		if (status & portsc_reset) == 0 {
			if (status & portsc_enabled) != 0 {
				return .ok
			}
			// Device might be low/full speed, hand off to companion
			if (status & portsc_connect) != 0 {
				return .err_not_supported  // Need companion controller
			}
			return .err_io
		}
		delay_us(100)
		timeout -= 1
	}
	
	return .err_timed_out
}

// Power on a port
pub fn (mut c EhciController) power_port(port u8, on bool) ZxStatus {
	if port >= c.num_ports {
		return .err_invalid_args
	}
	
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	op_base := u32(c.cap_length)
	port_offset := ehci_portsc + u32(port) * 4
	
	mut status := mmio_read32(c.base, op_base + port_offset)
	
	if on {
		status |= portsc_power
	} else {
		status &= ~u32(portsc_power)
	}
	
	mmio_write32(c.base, op_base + port_offset, status)
	
	return .ok
}

// Get connected device speed
pub fn (c &EhciController) get_port_speed(port u8) UsbSpeed {
	status := c.get_port_status(port)
	return get_port_speed(status)
}

// Check if port is connected
pub fn (c &EhciController) is_port_connected(port u8) bool {
	status := c.get_port_status(port)
	return is_port_connected(status)
}

// Check if port is enabled
pub fn (c &EhciController) is_port_enabled(port u8) bool {
	status := c.get_port_status(port)
	return is_port_enabled(status)
}

// =============================================================================
// Interrupt handling
// =============================================================================

// Handle EHCI interrupt
pub fn (mut c EhciController) handle_interrupt() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	op_base := u32(c.cap_length)
	
	// Read and clear status
	status := mmio_read32(c.base, op_base + ehci_usbsts)
	
	// Only handle enabled interrupts
	intr_en := mmio_read32(c.base, op_base + ehci_usbintr)
	active := status & intr_en
	
	if active == 0 {
		return .ok  // Not our interrupt
	}
	
	// Clear handled interrupts
	mmio_write32(c.base, op_base + ehci_usbsts, active)
	
	// Handle various interrupt types
	if (active & sts_port_change) != 0 {
		c.handle_port_change_locked()
	}
	
	if (active & sts_err) != 0 {
		// USB error - log for debugging
	}
	
	if (active & sts_host_error) != 0 {
		// Fatal error - reset may be needed
		return .err_io
	}
	
	if (active & sts_int) != 0 {
		// Transfer complete - handled by async/periodic processing
	}
	
	return .ok
}

// Handle port status change
fn (mut c EhciController) handle_port_change_locked() {
	op_base := u32(c.cap_length)
	
	for port := u8(0); port < c.num_ports; port++ {
		port_offset := ehci_portsc + u32(port) * 4
		status := mmio_read32(c.base, op_base + port_offset)
		
		// Check for changes that need acknowledgment
		if (status & portsc_connect_change) != 0 {
			// Clear the change bit
			mmio_write32(c.base, op_base + port_offset, status | portsc_connect_change)
			
			if (status & portsc_connect) != 0 {
				// Device connected
			} else {
				// Device disconnected
			}
		}
		
		if (status & portsc_enable_change) != 0 {
			mmio_write32(c.base, op_base + port_offset, status | portsc_enable_change)
		}
		
		if (status & portsc_oc_change) != 0 {
			mmio_write32(c.base, op_base + port_offset, status | portsc_oc_change)
		}
	}
}

// =============================================================================
// Status and debugging
// =============================================================================

// Check if controller is running
pub fn (c &EhciController) running() bool {
	return c.is_running
}

// Dump controller state
pub fn (c &EhciController) dump_state() {
	op_base := u32(c.cap_length)
	
	println('EHCI Controller ${c.idx} @ 0x${c.base:x}')
	println('  CAPLENGTH: ${c.cap_length}')
	println('  HCSPARAMS: 0x${c.hcs_params:08x}')
	println('  HCCPARAMS: 0x${c.hcc_params:08x}')
	println('  Ports: ${c.num_ports}')
	println('  USBCMD: 0x${mmio_read32(c.base, op_base + ehci_usbcmd):08x}')
	println('  USBSTS: 0x${mmio_read32(c.base, op_base + ehci_usbsts):08x}')
	
	for port := u8(0); port < c.num_ports; port++ {
		port_offset := ehci_portsc + u32(port) * 4
		status := mmio_read32(c.base, op_base + port_offset)
		println('  Port ${port}: 0x${status:08x}')
	}
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_ehci_creation() {
	controller := EhciController.with_base(0x04200000, 1)
	
	assert controller.base == 0x04200000
	assert controller.idx == 1
	assert controller.is_running == false
}

fn test_ehci_port_count() {
	mut controller := EhciController.with_base(0x04200000, 1)
	controller.num_ports = 1
	
	assert controller.get_num_ports() == 1
}

fn test_qtd_constants() {
	// Verify qTD constants are sensible
	assert qtd_status_active == 0x80
	assert qtd_ioc == 0x8000
	assert qtd_terminate == 1
}

fn test_qh_constants() {
	// Verify QH constants
	assert qh_eps_high == 0x2000
	assert (qh_dev_addr_mask & 0x7F) == 0x7F
}

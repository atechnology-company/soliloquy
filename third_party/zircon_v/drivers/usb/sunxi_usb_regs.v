// Allwinner A527/T527 USB Controller Register Definitions
// Translated to V language for Soliloquy OS
//
// The A527 SoC contains:
// - USB0: OTG (dual-role) controller with Mentor Graphics MUSB IP
// - USB1/2: EHCI/OHCI host controllers
//
// Reference: Allwinner A527 User Manual, Linux drivers/usb/musb/sunxi.c

module usb

// =============================================================================
// Base addresses for USB controllers
// =============================================================================
pub const usb0_base = u64(0x04100000)         // USB0 OTG (MUSB)
pub const usb1_base = u64(0x04200000)         // USB1 EHCI
pub const usb1_ohci_base = u64(0x04200400)    // USB1 OHCI
pub const usb2_base = u64(0x04300000)         // USB2 EHCI (if present)
pub const usb2_ohci_base = u64(0x04300400)    // USB2 OHCI (if present)

// PHY controller base addresses
pub const usb0_phy_base = u64(0x04100400)     // USB0 PHY control
pub const usb1_phy_base = u64(0x04200800)     // USB1 PHY control

// =============================================================================
// USB OTG (MUSB) Register offsets - USB0
// =============================================================================

// Common USB registers
pub const musb_faddr = u32(0x98)              // Function address
pub const musb_power = u32(0x40)              // Power management
pub const musb_intrtx = u32(0x44)             // TX interrupt status
pub const musb_intrrx = u32(0x46)             // RX interrupt status
pub const musb_intrtxe = u32(0x48)            // TX interrupt enable
pub const musb_intrrxe = u32(0x4A)            // RX interrupt enable
pub const musb_intrusb = u32(0x4C)            // USB interrupt status
pub const musb_intrusbe = u32(0x50)           // USB interrupt enable
pub const musb_frame = u32(0x54)              // Frame number
pub const musb_index = u32(0x42)              // Index register for endpoints
pub const musb_testmode = u32(0x7C)           // Test mode register

// Indexed endpoint registers (select with INDEX register)
pub const musb_txmaxp = u32(0x80)             // TX max packet size
pub const musb_csr0 = u32(0x82)               // EP0 control/status
pub const musb_txcsr = u32(0x82)              // TX control/status (EP1+)
pub const musb_rxmaxp = u32(0x84)             // RX max packet size
pub const musb_rxcsr = u32(0x86)              // RX control/status
pub const musb_rxcount = u32(0x88)            // RX byte count
pub const musb_txtype = u32(0x8A)             // TX endpoint type
pub const musb_txinterval = u32(0x8B)         // TX polling interval
pub const musb_rxtype = u32(0x8C)             // RX endpoint type
pub const musb_rxinterval = u32(0x8D)         // RX polling interval

// FIFO addresses (one per endpoint, 32-bit access)
pub const musb_fifo_base = u32(0x00)          // FIFO base (EP0 at 0x00)
pub const musb_fifo_size = u32(0x04)          // FIFO spacing per endpoint

// DMA registers (MUSB DMA channels)
pub const musb_dma_intr = u32(0x200)          // DMA interrupt status
pub const musb_dma_cntl_base = u32(0x204)     // DMA control base
pub const musb_dma_addr_base = u32(0x208)     // DMA address base
pub const musb_dma_count_base = u32(0x20C)    // DMA count base
pub const musb_dma_channel_size = u32(0x10)   // Size of each DMA channel regs

// =============================================================================
// Sunxi-specific USB control registers
// =============================================================================
pub const sunxi_ctl = u32(0x400)              // Sunxi USB control
pub const sunxi_phy_ctl = u32(0x410)          // PHY control
pub const sunxi_phy_status = u32(0x414)       // PHY status
pub const sunxi_phy_tune = u32(0x418)         // PHY tuning

// Sunxi ISCR (Interrupt Status/Control Register)
pub const sunxi_iscr = u32(0x404)             // Interrupt status/control

// =============================================================================
// Power register bits
// =============================================================================
pub const power_isoupdate = u32(1 << 7)       // ISO update
pub const power_softconn = u32(1 << 6)        // Soft connect
pub const power_hsen = u32(1 << 5)            // High-speed enable
pub const power_hsmode = u32(1 << 4)          // High-speed mode
pub const power_reset = u32(1 << 3)           // Reset signaling
pub const power_resume = u32(1 << 2)          // Resume signaling
pub const power_suspendm = u32(1 << 1)        // Suspend mode
pub const power_ensuspend = u32(1 << 0)       // Enable suspend

// =============================================================================
// USB interrupt bits (INTRUSB)
// =============================================================================
pub const int_vbus_error = u32(1 << 7)        // VBUS error
pub const int_sess_req = u32(1 << 6)          // Session request
pub const int_disconnect = u32(1 << 5)        // Disconnect
pub const int_connect = u32(1 << 4)           // Device connected
pub const int_sof = u32(1 << 3)               // Start of frame
pub const int_reset = u32(1 << 2)             // Reset/babble
pub const int_resume = u32(1 << 1)            // Resume
pub const int_suspend = u32(1 << 0)           // Suspend

// =============================================================================
// EP0 CSR0 register bits (control endpoint)
// =============================================================================
pub const csr0_flushfifo = u32(1 << 8)        // Flush FIFO
pub const csr0_serv_setup = u32(1 << 7)       // Serviced setup end
pub const csr0_serv_rxpktrdy = u32(1 << 6)    // Serviced RX packet ready
pub const csr0_sendstall = u32(1 << 5)        // Send stall
pub const csr0_setupend = u32(1 << 4)         // Setup end
pub const csr0_dataend = u32(1 << 3)          // Data end
pub const csr0_sentstall = u32(1 << 2)        // Sent stall
pub const csr0_txpktrdy = u32(1 << 1)         // TX packet ready
pub const csr0_rxpktrdy = u32(1 << 0)         // RX packet ready

// =============================================================================
// TXCSR register bits (TX endpoints)
// =============================================================================
pub const txcsr_autoset = u32(1 << 15)        // Auto set TxPktRdy
pub const txcsr_iso = u32(1 << 14)            // Isochronous mode
pub const txcsr_mode = u32(1 << 13)           // TX mode (1=TX)
pub const txcsr_dmaenab = u32(1 << 12)        // DMA enable
pub const txcsr_frcdatatog = u32(1 << 11)     // Force data toggle
pub const txcsr_dmamode = u32(1 << 10)        // DMA mode
pub const txcsr_clrdatatog = u32(1 << 6)      // Clear data toggle
pub const txcsr_sentstall = u32(1 << 5)       // Sent stall
pub const txcsr_sendstall = u32(1 << 4)       // Send stall
pub const txcsr_flushfifo = u32(1 << 3)       // Flush FIFO
pub const txcsr_underrun = u32(1 << 2)        // Underrun error
pub const txcsr_fifonotempty = u32(1 << 1)    // FIFO not empty
pub const txcsr_txpktrdy = u32(1 << 0)        // TX packet ready

// =============================================================================
// RXCSR register bits (RX endpoints)
// =============================================================================
pub const rxcsr_autoclear = u32(1 << 15)      // Auto clear RxPktRdy
pub const rxcsr_autoreq = u32(1 << 14)        // Auto request IN
pub const rxcsr_dmaenab = u32(1 << 13)        // DMA enable
pub const rxcsr_disnyet = u32(1 << 12)        // Disable NYET (HS)
pub const rxcsr_dmamode = u32(1 << 11)        // DMA mode
pub const rxcsr_incomprx = u32(1 << 8)        // Incomplete RX
pub const rxcsr_clrdatatog = u32(1 << 7)      // Clear data toggle
pub const rxcsr_sentstall = u32(1 << 6)       // Sent stall
pub const rxcsr_sendstall = u32(1 << 5)       // Send stall
pub const rxcsr_flushfifo = u32(1 << 4)       // Flush FIFO
pub const rxcsr_dataerr = u32(1 << 3)         // Data error
pub const rxcsr_overrun = u32(1 << 2)         // Overrun
pub const rxcsr_fifofull = u32(1 << 1)        // FIFO full
pub const rxcsr_rxpktrdy = u32(1 << 0)        // RX packet ready

// =============================================================================
// Sunxi USB control register bits
// =============================================================================
pub const ctl_phy_rst = u32(1 << 0)           // PHY reset
pub const ctl_vbus_det = u32(1 << 1)          // VBUS detect enable
pub const ctl_id_det = u32(1 << 2)            // ID detect enable
pub const ctl_dpdm_pullup = u32(1 << 4)       // DP/DM pull-up

// =============================================================================
// EHCI Register offsets (USB1/2 host controller)
// =============================================================================

// Capability registers
pub const ehci_caplength = u32(0x00)          // Capability length
pub const ehci_hciversion = u32(0x02)         // Interface version
pub const ehci_hcsparams = u32(0x04)          // Structural parameters
pub const ehci_hccparams = u32(0x08)          // Capability parameters

// Operational registers (offset by CAPLENGTH)
pub const ehci_usbcmd = u32(0x10)             // USB command
pub const ehci_usbsts = u32(0x14)             // USB status
pub const ehci_usbintr = u32(0x18)            // USB interrupt enable
pub const ehci_frindex = u32(0x1C)            // Frame index
pub const ehci_ctrldssegment = u32(0x20)      // 4G segment selector
pub const ehci_periodiclistbase = u32(0x24)   // Periodic frame list base
pub const ehci_asynclistaddr = u32(0x28)      // Async list address
pub const ehci_configflag = u32(0x50)         // Configure flag
pub const ehci_portsc = u32(0x54)             // Port status/control

// =============================================================================
// EHCI USBCMD register bits
// =============================================================================
pub const cmd_run = u32(1 << 0)               // Run/stop
pub const cmd_reset = u32(1 << 1)             // Host controller reset
pub const cmd_periodic_en = u32(1 << 4)       // Periodic schedule enable
pub const cmd_async_en = u32(1 << 5)          // Async schedule enable
pub const cmd_int_threshold_mask = u32(0xFF << 16)  // Interrupt threshold

// =============================================================================
// EHCI USBSTS register bits
// =============================================================================
pub const sts_int = u32(1 << 0)               // USB interrupt
pub const sts_err = u32(1 << 1)               // USB error interrupt
pub const sts_port_change = u32(1 << 2)       // Port change detect
pub const sts_frame_rollover = u32(1 << 3)    // Frame list rollover
pub const sts_host_error = u32(1 << 4)        // Host system error
pub const sts_async_advance = u32(1 << 5)     // Async advance
pub const sts_halted = u32(1 << 12)           // HCHalted
pub const sts_reclamation = u32(1 << 13)      // Reclamation
pub const sts_periodic_active = u32(1 << 14)  // Periodic schedule status
pub const sts_async_active = u32(1 << 15)     // Async schedule status

// =============================================================================
// EHCI PORTSC register bits
// =============================================================================
pub const portsc_connect = u32(1 << 0)        // Current connect status
pub const portsc_connect_change = u32(1 << 1) // Connect status change
pub const portsc_enabled = u32(1 << 2)        // Port enabled
pub const portsc_enable_change = u32(1 << 3)  // Port enable change
pub const portsc_overcurrent = u32(1 << 4)    // Over-current active
pub const portsc_oc_change = u32(1 << 5)      // Over-current change
pub const portsc_resume = u32(1 << 6)         // Force port resume
pub const portsc_suspend = u32(1 << 7)        // Suspend
pub const portsc_reset = u32(1 << 8)          // Port reset
pub const portsc_line_status_mask = u32(3 << 10)    // Line status
pub const portsc_power = u32(1 << 12)         // Port power
pub const portsc_owner = u32(1 << 13)         // Port owner (0=EHCI, 1=companion)
pub const portsc_speed_mask = u32(3 << 26)    // Port speed

// Line status values
pub const line_status_se0 = u32(0 << 10)      // SE0
pub const line_status_j = u32(2 << 10)        // J-state
pub const line_status_k = u32(1 << 10)        // K-state

// Speed values (from PORTSC)
pub const speed_full = u32(0 << 26)           // Full-speed
pub const speed_low = u32(1 << 26)            // Low-speed
pub const speed_high = u32(2 << 26)           // High-speed

// =============================================================================
// USB device types
// =============================================================================
pub enum UsbSpeed {
	low = 0          // 1.5 Mbps
	full = 1         // 12 Mbps
	high = 2         // 480 Mbps
	super_ = 3       // 5 Gbps (USB 3.0, not supported by A527)
}

pub enum UsbTransferType {
	control = 0
	isochronous = 1
	bulk = 2
	interrupt = 3
}

pub enum UsbDirection {
	out = 0          // Host to device
	in_ = 1          // Device to host
}

pub enum ControllerType {
	musb_otg         // USB0 OTG controller
	ehci_host        // EHCI host controller
	ohci_host        // OHCI host controller (companion)
}

// =============================================================================
// Endpoint configuration
// =============================================================================
pub struct EndpointConfig {
pub:
	number      u8              // Endpoint number (0-15)
	direction   UsbDirection    // IN or OUT
	xfer_type   UsbTransferType // Transfer type
	max_packet  u16             // Maximum packet size
	interval    u8              // Polling interval (interrupt/iso)
}

// USB request (for control transfers)
pub struct UsbSetupPacket {
pub:
	bm_request_type  u8
	b_request        u8
	w_value          u16
	w_index          u16
	w_length         u16
}

// Standard requests
pub const req_get_status = u8(0)
pub const req_clear_feature = u8(1)
pub const req_set_feature = u8(3)
pub const req_set_address = u8(5)
pub const req_get_descriptor = u8(6)
pub const req_set_descriptor = u8(7)
pub const req_get_config = u8(8)
pub const req_set_config = u8(9)
pub const req_get_interface = u8(10)
pub const req_set_interface = u8(11)
pub const req_synch_frame = u8(12)

// Descriptor types
pub const desc_device = u8(1)
pub const desc_config = u8(2)
pub const desc_string = u8(3)
pub const desc_interface = u8(4)
pub const desc_endpoint = u8(5)
pub const desc_device_qualifier = u8(6)
pub const desc_other_speed_config = u8(7)
pub const desc_interface_power = u8(8)

// =============================================================================
// Helper functions
// =============================================================================

// Get USB controller base by index
pub fn get_usb_base(idx u32) ?u64 {
	return match idx {
		0 { usb0_base }
		1 { usb1_base }
		2 { usb2_base }
		else { none }
	}
}

// Get EHCI base address
pub fn get_ehci_base(idx u32) ?u64 {
	return match idx {
		1 { usb1_base }
		2 { usb2_base }
		else { none }
	}
}

// Get OHCI base address
pub fn get_ohci_base(idx u32) ?u64 {
	return match idx {
		1 { usb1_ohci_base }
		2 { usb2_ohci_base }
		else { none }
	}
}

// Get FIFO address for endpoint
pub fn get_fifo_addr(ep_num u8) u32 {
	return musb_fifo_base + u32(ep_num) * musb_fifo_size
}

// Get DMA channel register base
pub fn get_dma_channel_base(channel u8) u32 {
	return musb_dma_cntl_base + u32(channel) * musb_dma_channel_size
}

// Parse endpoint address to number and direction
pub fn parse_endpoint_addr(addr u8) (u8, UsbDirection) {
	ep_num := addr & 0x0F
	direction := if (addr & 0x80) != 0 { UsbDirection.in_ } else { UsbDirection.out }
	return ep_num, direction
}

// Build endpoint address from number and direction
pub fn build_endpoint_addr(ep_num u8, direction UsbDirection) u8 {
	return ep_num | (if direction == .in_ { u8(0x80) } else { u8(0) })
}

// Calculate max packet size for endpoint type and speed
pub fn max_packet_size(xfer_type UsbTransferType, speed UsbSpeed) u16 {
	return match xfer_type {
		.control {
			match speed {
				.low { 8 }
				.full { 64 }
				.high { 64 }
				else { 64 }
			}
		}
		.bulk {
			match speed {
				.full { 64 }
				.high { 512 }
				else { 64 }
			}
		}
		.interrupt {
			match speed {
				.low { 8 }
				.full { 64 }
				.high { 1024 }
				else { 64 }
			}
		}
		.isochronous {
			match speed {
				.full { 1023 }
				.high { 1024 }
				else { 1023 }
			}
		}
	}
}

// Get speed from EHCI PORTSC register
pub fn get_port_speed(portsc u32) UsbSpeed {
	speed_bits := (portsc & portsc_speed_mask) >> 26
	return match speed_bits {
		0 { UsbSpeed.full }
		1 { UsbSpeed.low }
		2 { UsbSpeed.high }
		else { UsbSpeed.full }
	}
}

// Check if port is connected
pub fn is_port_connected(portsc u32) bool {
	return (portsc & portsc_connect) != 0
}

// Check if port is enabled
pub fn is_port_enabled(portsc u32) bool {
	return (portsc & portsc_enabled) != 0
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_get_usb_base() {
	// Valid indices
	assert get_usb_base(0) or { 0 } == usb0_base
	assert get_usb_base(1) or { 0 } == usb1_base
	
	// Invalid index
	result := get_usb_base(10)
	assert result == none
}

fn test_parse_endpoint_addr() {
	// OUT endpoint 1
	ep_num, dir := parse_endpoint_addr(0x01)
	assert ep_num == 1
	assert dir == .out
	
	// IN endpoint 2
	ep_num2, dir2 := parse_endpoint_addr(0x82)
	assert ep_num2 == 2
	assert dir2 == .in_
}

fn test_build_endpoint_addr() {
	// OUT endpoint 1
	addr := build_endpoint_addr(1, .out)
	assert addr == 0x01
	
	// IN endpoint 2
	addr2 := build_endpoint_addr(2, .in_)
	assert addr2 == 0x82
}

fn test_max_packet_size() {
	// Control EP at various speeds
	assert max_packet_size(.control, .low) == 8
	assert max_packet_size(.control, .full) == 64
	assert max_packet_size(.control, .high) == 64
	
	// Bulk EP
	assert max_packet_size(.bulk, .full) == 64
	assert max_packet_size(.bulk, .high) == 512
	
	// Interrupt EP
	assert max_packet_size(.interrupt, .high) == 1024
}

fn test_get_fifo_addr() {
	assert get_fifo_addr(0) == musb_fifo_base
	assert get_fifo_addr(1) == musb_fifo_base + musb_fifo_size
	assert get_fifo_addr(5) == musb_fifo_base + 5 * musb_fifo_size
}

fn test_port_status() {
	// Port connected and enabled
	portsc := portsc_connect | portsc_enabled | speed_high
	assert is_port_connected(portsc)
	assert is_port_enabled(portsc)
	assert get_port_speed(portsc) == .high
	
	// Port disconnected
	assert !is_port_connected(0)
	assert !is_port_enabled(0)
}

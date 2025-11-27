// Allwinner A527/T527 USB OTG (MUSB) Driver
// Translated to V language for Soliloquy OS
//
// This driver supports the Mentor Graphics MUSB OTG controller
// used in Allwinner SoCs for USB0 (dual-role port)
//
// Reference: Linux drivers/usb/musb/sunxi.c

module usb

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
	err_no_memory = -4
	err_not_supported = -2
	err_already_exists = -26
	err_busy = -16
}

// =============================================================================
// OTG state machine states
// =============================================================================
enum OtgState {
	undefined
	b_idle
	b_peripheral
	b_host
	a_idle
	a_wait_vrise
	a_wait_bcon
	a_host
	a_suspend
	a_peripheral
}

// =============================================================================
// Endpoint state
// =============================================================================
enum EpState {
	idle
	tx_pending
	rx_pending
	stalled
}

// =============================================================================
// Endpoint descriptor
// =============================================================================
struct Endpoint {
mut:
	number       u8
	direction    UsbDirection
	xfer_type    UsbTransferType
	max_packet   u16
	fifo_addr    u32
	fifo_size    u16
	state        EpState
	// DMA channel (-1 if not using DMA)
	dma_channel  i8
}

// =============================================================================
// MUSB OTG Controller
// =============================================================================
pub struct MusbController {
pub:
	base         u64              // MMIO base address
	idx          u32              // Controller index (usually 0)
pub mut:
	lock         sync.Mutex       // Thread safety
	otg_state    OtgState         // Current OTG state
	is_host      bool             // Host mode vs device mode
	speed        UsbSpeed         // Current USB speed
	address      u8               // Device address (device mode)
	config       u8               // Current configuration
	endpoints    [16]Endpoint     // Endpoint descriptors
	dma_enabled  bool             // Whether DMA is enabled
}

// =============================================================================
// MMIO access helpers
// =============================================================================
fn mmio_read8(base u64, offset u32) u8 {
	return unsafe { *(&u8(base + u64(offset))) }
}

fn mmio_write8(base u64, offset u32, value u8) {
	unsafe { *(&u8(base + u64(offset))) = value }
}

fn mmio_read16(base u64, offset u32) u16 {
	return unsafe { *(&u16(base + u64(offset))) }
}

fn mmio_write16(base u64, offset u32, value u16) {
	unsafe { *(&u16(base + u64(offset))) = value }
}

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
// MUSB Controller implementation
// =============================================================================

// Create a new MUSB controller instance
pub fn MusbController.new(idx u32) !MusbController {
	base := get_usb_base(idx) or { return error('Invalid USB index') }
	
	mut ctrl := MusbController{
		base: base
		idx: idx
		otg_state: .undefined
		is_host: false
		speed: .full
		dma_enabled: false
	}
	
	// Initialize endpoint descriptors
	for i in 0 .. 16 {
		ctrl.endpoints[i] = Endpoint{
			number: u8(i)
			direction: .out
			xfer_type: .control
			max_packet: 64
			fifo_addr: get_fifo_addr(u8(i))
			fifo_size: 64
			state: .idle
			dma_channel: -1
		}
	}
	
	return ctrl
}

// Create with specific base address (for testing)
pub fn MusbController.with_base(base u64, idx u32) MusbController {
	mut ctrl := MusbController{
		base: base
		idx: idx
		otg_state: .undefined
		is_host: false
		speed: .full
		dma_enabled: false
	}
	
	for i in 0 .. 16 {
		ctrl.endpoints[i] = Endpoint{
			number: u8(i)
			direction: .out
			xfer_type: .control
			max_packet: 64
			fifo_addr: get_fifo_addr(u8(i))
			fifo_size: 64
			state: .idle
			dma_channel: -1
		}
	}
	
	return ctrl
}

// =============================================================================
// Initialization
// =============================================================================

// Initialize the controller
pub fn (mut c MusbController) init() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Reset the controller
	status := c.reset_locked()
	if status != .ok {
		return status
	}
	
	// Enable interrupts
	c.enable_interrupts_locked()
	
	// Start in device mode by default
	c.is_host = false
	c.otg_state = .b_idle
	
	return .ok
}

// Reset the controller
fn (mut c MusbController) reset_locked() ZxStatus {
	// Disable soft connect
	mut power := mmio_read8(c.base, musb_power)
	power &= ~u8(power_softconn)
	mmio_write8(c.base, musb_power, power)
	
	// Wait a bit
	delay_us(100)
	
	// Clear all interrupts
	mmio_write16(c.base, musb_intrtx, 0xFFFF)
	mmio_write16(c.base, musb_intrrx, 0xFFFF)
	mmio_write8(c.base, musb_intrusb, 0xFF)
	
	// Disable all endpoint interrupts
	mmio_write16(c.base, musb_intrtxe, 0)
	mmio_write16(c.base, musb_intrrxe, 0)
	
	// Reset address
	c.address = 0
	mmio_write8(c.base, musb_faddr, 0)
	
	// Enable high-speed if supported
	power = mmio_read8(c.base, musb_power)
	power |= u8(power_hsen)
	mmio_write8(c.base, musb_power, power)
	
	return .ok
}

// Enable interrupts
fn (mut c MusbController) enable_interrupts_locked() {
	// Enable USB-level interrupts (connect, disconnect, reset, etc.)
	intrusbe := u8(int_reset | int_disconnect | int_connect | int_suspend | int_resume)
	mmio_write8(c.base, musb_intrusbe, intrusbe)
	
	// Enable EP0 TX interrupt
	mmio_write16(c.base, musb_intrtxe, 1)  // EP0 only
}

// =============================================================================
// Mode control
// =============================================================================

// Switch to host mode
pub fn (mut c MusbController) set_host_mode() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	c.is_host = true
	c.otg_state = .a_idle
	
	// Configure for host mode (Sunxi-specific)
	ctl := mmio_read32(c.base, sunxi_ctl)
	mmio_write32(c.base, sunxi_ctl, ctl | ctl_vbus_det)
	
	return .ok
}

// Switch to device mode
pub fn (mut c MusbController) set_device_mode() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	c.is_host = false
	c.otg_state = .b_idle
	
	return .ok
}

// Connect (device mode) - enable soft connect to appear on bus
pub fn (mut c MusbController) connect() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	if c.is_host {
		return .err_not_supported
	}
	
	mut power := mmio_read8(c.base, musb_power)
	power |= u8(power_softconn)
	mmio_write8(c.base, musb_power, power)
	
	return .ok
}

// Disconnect (device mode)
pub fn (mut c MusbController) disconnect() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	mut power := mmio_read8(c.base, musb_power)
	power &= ~u8(power_softconn)
	mmio_write8(c.base, musb_power, power)
	
	return .ok
}

// =============================================================================
// Endpoint configuration
// =============================================================================

// Configure an endpoint
pub fn (mut c MusbController) configure_endpoint(config EndpointConfig) ZxStatus {
	if config.number >= 16 {
		return .err_invalid_args
	}
	
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	ep := config.number
	
	// Select endpoint
	mmio_write8(c.base, musb_index, ep)
	
	if config.direction == .in_ {
		// TX endpoint
		mmio_write16(c.base, musb_txmaxp, config.max_packet)
		
		// Set mode based on transfer type
		mut txtype := u8(0)
		txtype = match config.xfer_type {
			.isochronous { 0x10 }
			.bulk { 0x20 }
			.interrupt { 0x30 }
			else { 0x00 }
		}
		mmio_write8(c.base, musb_txtype, txtype)
		
		if config.xfer_type == .interrupt || config.xfer_type == .isochronous {
			mmio_write8(c.base, musb_txinterval, config.interval)
		}
	} else {
		// RX endpoint
		mmio_write16(c.base, musb_rxmaxp, config.max_packet)
		
		mut rxtype := u8(0)
		rxtype = match config.xfer_type {
			.isochronous { 0x10 }
			.bulk { 0x20 }
			.interrupt { 0x30 }
			else { 0x00 }
		}
		mmio_write8(c.base, musb_rxtype, rxtype)
		
		if config.xfer_type == .interrupt || config.xfer_type == .isochronous {
			mmio_write8(c.base, musb_rxinterval, config.interval)
		}
	}
	
	// Update endpoint descriptor
	c.endpoints[ep].direction = config.direction
	c.endpoints[ep].xfer_type = config.xfer_type
	c.endpoints[ep].max_packet = config.max_packet
	c.endpoints[ep].state = .idle
	
	// Enable interrupt for this endpoint
	if config.direction == .in_ {
		mut intrtxe := mmio_read16(c.base, musb_intrtxe)
		intrtxe |= u16(1 << ep)
		mmio_write16(c.base, musb_intrtxe, intrtxe)
	} else {
		mut intrrxe := mmio_read16(c.base, musb_intrrxe)
		intrrxe |= u16(1 << ep)
		mmio_write16(c.base, musb_intrrxe, intrrxe)
	}
	
	return .ok
}

// Stall an endpoint
pub fn (mut c MusbController) stall_endpoint(ep_num u8, direction UsbDirection) ZxStatus {
	if ep_num >= 16 {
		return .err_invalid_args
	}
	
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Select endpoint
	mmio_write8(c.base, musb_index, ep_num)
	
	if ep_num == 0 {
		// EP0 stall
		mut csr := mmio_read16(c.base, musb_csr0)
		csr |= u16(csr0_sendstall)
		mmio_write16(c.base, musb_csr0, csr)
	} else if direction == .in_ {
		// TX stall
		mut csr := mmio_read16(c.base, musb_txcsr)
		csr |= u16(txcsr_sendstall)
		mmio_write16(c.base, musb_txcsr, csr)
	} else {
		// RX stall
		mut csr := mmio_read16(c.base, musb_rxcsr)
		csr |= u16(rxcsr_sendstall)
		mmio_write16(c.base, musb_rxcsr, csr)
	}
	
	c.endpoints[ep_num].state = .stalled
	return .ok
}

// Clear stall on an endpoint
pub fn (mut c MusbController) clear_stall(ep_num u8, direction UsbDirection) ZxStatus {
	if ep_num >= 16 {
		return .err_invalid_args
	}
	
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Select endpoint
	mmio_write8(c.base, musb_index, ep_num)
	
	if ep_num == 0 {
		// EP0 - clear sent stall
		mut csr := mmio_read16(c.base, musb_csr0)
		csr &= ~u16(csr0_sentstall | csr0_sendstall)
		mmio_write16(c.base, musb_csr0, csr)
	} else if direction == .in_ {
		// TX - clear stall and data toggle
		mut csr := mmio_read16(c.base, musb_txcsr)
		csr &= ~u16(txcsr_sentstall | txcsr_sendstall)
		csr |= u16(txcsr_clrdatatog)
		mmio_write16(c.base, musb_txcsr, csr)
	} else {
		// RX - clear stall and data toggle
		mut csr := mmio_read16(c.base, musb_rxcsr)
		csr &= ~u16(rxcsr_sentstall | rxcsr_sendstall)
		csr |= u16(rxcsr_clrdatatog)
		mmio_write16(c.base, musb_rxcsr, csr)
	}
	
	c.endpoints[ep_num].state = .idle
	return .ok
}

// =============================================================================
// Data transfer (EP0 control)
// =============================================================================

// Write data to EP0 TX FIFO (for control transfers)
pub fn (mut c MusbController) ep0_write(data []u8) ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Select EP0
	mmio_write8(c.base, musb_index, 0)
	
	// Write to FIFO
	fifo_addr := c.base + u64(musb_fifo_base)
	for i := 0; i < data.len; i++ {
		mmio_write8(fifo_addr, 0, data[i])
	}
	
	return .ok
}

// Read data from EP0 RX FIFO
pub fn (mut c MusbController) ep0_read(max_len u16) []u8 {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Select EP0
	mmio_write8(c.base, musb_index, 0)
	
	// Get byte count
	count := mmio_read16(c.base, musb_rxcount)
	len := if count > max_len { max_len } else { count }
	
	// Read from FIFO
	mut result := []u8{len: int(len)}
	fifo_addr := c.base + u64(musb_fifo_base)
	for i := u16(0); i < len; i++ {
		result[i] = mmio_read8(fifo_addr, 0)
	}
	
	return result
}

// Complete EP0 transaction (set DataEnd)
pub fn (mut c MusbController) ep0_complete() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Select EP0
	mmio_write8(c.base, musb_index, 0)
	
	// Set DataEnd
	mut csr := mmio_read16(c.base, musb_csr0)
	csr |= u16(csr0_dataend)
	mmio_write16(c.base, musb_csr0, csr)
	
	return .ok
}

// =============================================================================
// Bulk/Interrupt endpoint transfers
// =============================================================================

// Write data to a TX endpoint
pub fn (mut c MusbController) ep_write(ep_num u8, packet_data []u8) ZxStatus {
	if ep_num == 0 || ep_num >= 16 {
		return .err_invalid_args
	}
	
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Select endpoint
	mmio_write8(c.base, musb_index, ep_num)
	
	// Check if FIFO is available
	csr := mmio_read16(c.base, musb_txcsr)
	if (csr & u16(txcsr_fifonotempty)) != 0 {
		return .err_busy
	}
	
	// Write to FIFO
	fifo_offset := get_fifo_addr(ep_num)
	for i := 0; i < packet_data.len; i++ {
		mmio_write8(c.base, fifo_offset, packet_data[i])
	}
	
	// Set TxPktRdy
	mut new_csr := mmio_read16(c.base, musb_txcsr)
	new_csr |= u16(txcsr_txpktrdy)
	mmio_write16(c.base, musb_txcsr, new_csr)
	
	c.endpoints[ep_num].state = .tx_pending
	return .ok
}

// Read data from an RX endpoint
pub fn (mut c MusbController) ep_read(ep_num u8, max_len u16) ([]u8, ZxStatus) {
	if ep_num == 0 || ep_num >= 16 {
		return []u8{}, ZxStatus.err_invalid_args
	}
	
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Select endpoint
	mmio_write8(c.base, musb_index, ep_num)
	
	// Check if packet is ready
	csr := mmio_read16(c.base, musb_rxcsr)
	if (csr & u16(rxcsr_rxpktrdy)) == 0 {
		return []u8{}, ZxStatus.err_not_found
	}
	
	// Get byte count
	count := mmio_read16(c.base, musb_rxcount)
	len := if count > max_len { max_len } else { count }
	
	// Read from FIFO
	mut result := []u8{len: int(len)}
	fifo_offset := get_fifo_addr(ep_num)
	for i := u16(0); i < len; i++ {
		result[i] = mmio_read8(c.base, fifo_offset)
	}
	
	// Clear RxPktRdy
	mut new_csr := mmio_read16(c.base, musb_rxcsr)
	new_csr &= ~u16(rxcsr_rxpktrdy)
	mmio_write16(c.base, musb_rxcsr, new_csr)
	
	c.endpoints[ep_num].state = .idle
	return result, ZxStatus.ok
}

// =============================================================================
// Interrupt handling
// =============================================================================

// Process USB interrupts (called from ISR)
pub fn (mut c MusbController) handle_interrupt() ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	// Read interrupt status
	intrusb := mmio_read8(c.base, musb_intrusb)
	intrtx := mmio_read16(c.base, musb_intrtx)
	intrrx := mmio_read16(c.base, musb_intrrx)
	
	// Handle USB-level interrupts first
	if (intrusb & u8(int_reset)) != 0 {
		c.handle_reset_locked()
		// Clear interrupt
		mmio_write8(c.base, musb_intrusb, u8(int_reset))
	}
	
	if (intrusb & u8(int_connect)) != 0 {
		c.handle_connect_locked()
		mmio_write8(c.base, musb_intrusb, u8(int_connect))
	}
	
	if (intrusb & u8(int_disconnect)) != 0 {
		c.handle_disconnect_locked()
		mmio_write8(c.base, musb_intrusb, u8(int_disconnect))
	}
	
	// Handle EP0 interrupt
	if (intrtx & 1) != 0 {
		c.handle_ep0_locked()
		// Clear by reading CSR
	}
	
	// Handle TX endpoint interrupts
	for ep := u8(1); ep < 16; ep++ {
		if (intrtx & u16(1 << ep)) != 0 {
			c.handle_tx_endpoint_locked(ep)
		}
	}
	
	// Handle RX endpoint interrupts
	for ep := u8(1); ep < 16; ep++ {
		if (intrrx & u16(1 << ep)) != 0 {
			c.handle_rx_endpoint_locked(ep)
		}
	}
	
	return .ok
}

// Handle USB reset
fn (mut c MusbController) handle_reset_locked() {
	// Read power register to check speed
	power := mmio_read8(c.base, musb_power)
	
	c.speed = if (power & u8(power_hsmode)) != 0 { UsbSpeed.high } else { UsbSpeed.full }
	c.address = 0
	c.config = 0
	c.otg_state = .b_peripheral
	
	// Reset all endpoints to idle
	for i in 0 .. 16 {
		c.endpoints[i].state = .idle
	}
}

// Handle device connect (host mode)
fn (mut c MusbController) handle_connect_locked() {
	if c.is_host {
		c.otg_state = .a_host
	}
}

// Handle device disconnect
fn (mut c MusbController) handle_disconnect_locked() {
	if c.is_host {
		c.otg_state = .a_idle
	} else {
		c.otg_state = .b_idle
	}
	c.address = 0
	c.config = 0
}

// Handle EP0 interrupt
fn (mut c MusbController) handle_ep0_locked() {
	// Select EP0
	mmio_write8(c.base, musb_index, 0)
	
	// Read CSR
	csr := mmio_read16(c.base, musb_csr0)
	
	// Handle setup end
	if (csr & u16(csr0_setupend)) != 0 {
		mut new_csr := csr | u16(csr0_serv_setup)
		mmio_write16(c.base, musb_csr0, new_csr)
	}
	
	// Handle stall sent
	if (csr & u16(csr0_sentstall)) != 0 {
		mut new_csr := csr & ~u16(csr0_sentstall)
		mmio_write16(c.base, musb_csr0, new_csr)
	}
}

// Handle TX endpoint interrupt
fn (mut c MusbController) handle_tx_endpoint_locked(ep_num u8) {
	// Select endpoint
	mmio_write8(c.base, musb_index, ep_num)
	
	// Read CSR
	csr := mmio_read16(c.base, musb_txcsr)
	
	// Check for errors
	if (csr & u16(txcsr_underrun)) != 0 {
		// Clear underrun
		mut new_csr := csr & ~u16(txcsr_underrun)
		mmio_write16(c.base, musb_txcsr, new_csr)
	}
	
	// Packet transmitted
	if (csr & u16(txcsr_txpktrdy)) == 0 {
		c.endpoints[ep_num].state = .idle
	}
}

// Handle RX endpoint interrupt
fn (mut c MusbController) handle_rx_endpoint_locked(ep_num u8) {
	// Select endpoint
	mmio_write8(c.base, musb_index, ep_num)
	
	// Read CSR
	csr := mmio_read16(c.base, musb_rxcsr)
	
	// Check for errors
	if (csr & u16(rxcsr_overrun)) != 0 {
		// Clear overrun
		mut new_csr := csr & ~u16(rxcsr_overrun)
		mmio_write16(c.base, musb_rxcsr, new_csr)
	}
	
	// Packet received
	if (csr & u16(rxcsr_rxpktrdy)) != 0 {
		c.endpoints[ep_num].state = .rx_pending
	}
}

// =============================================================================
// Status and debugging
// =============================================================================

// Get current USB speed
pub fn (c &MusbController) get_speed() UsbSpeed {
	return c.speed
}

// Check if connected (device mode)
pub fn (c &MusbController) is_connected() bool {
	return c.otg_state == .b_peripheral
}

// Get device address (device mode)
pub fn (c &MusbController) get_address() u8 {
	return c.address
}

// Set device address (called after SET_ADDRESS request)
pub fn (mut c MusbController) set_address(addr u8) ZxStatus {
	c.lock.@lock()
	defer { c.lock.unlock() }
	
	c.address = addr
	mmio_write8(c.base, musb_faddr, addr)
	
	return .ok
}

// Dump registers for debugging
pub fn (c &MusbController) dump_regs() {
	println('MUSB Controller ${c.idx} @ 0x${c.base:x}')
	println('  POWER: 0x${mmio_read8(c.base, musb_power):02x}')
	println('  FADDR: 0x${mmio_read8(c.base, musb_faddr):02x}')
	println('  INTRUSB: 0x${mmio_read8(c.base, musb_intrusb):02x}')
	println('  INTRTX: 0x${mmio_read16(c.base, musb_intrtx):04x}')
	println('  INTRRX: 0x${mmio_read16(c.base, musb_intrrx):04x}')
}

// =============================================================================
// Unit tests
// =============================================================================

fn test_musb_creation() {
	controller := MusbController.with_base(0x04100000, 0)
	
	assert controller.base == 0x04100000
	assert controller.idx == 0
	assert controller.is_host == false
	assert controller.speed == .full
}

fn test_endpoint_config() {
	_ := MusbController.with_base(0x04100000, 0)
	
	config := EndpointConfig{
		number: 1
		direction: .in_
		xfer_type: .bulk
		max_packet: 512
		interval: 0
	}
	
	// Just verify we can configure (can't test MMIO without hardware)
	_ := config.number
	assert config.max_packet == 512
}

fn test_otg_state() {
	mut controller := MusbController.with_base(0x04100000, 0)
	
	assert controller.otg_state == .undefined
	
	controller.otg_state = .b_idle
	assert controller.otg_state == .b_idle
}

fn test_address() {
	mut controller := MusbController.with_base(0x04100000, 0)
	
	assert controller.get_address() == 0
	
	controller.address = 5
	assert controller.get_address() == 5
}

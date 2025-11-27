// Zircon IPC Types - Core type definitions for inter-process communication
//
// This module defines the fundamental types used in Zircon IPC including
// handles, channels, and message packets.
//
// Translated from: third_party/zircon_c/ipc/

module ipc

// Maximum message size in bytes
pub const max_msg_size = u32(65536)

// Maximum handles per message
pub const max_msg_handles = u32(64)

// Handle rights (bitmask)
pub const rights_none = u32(0)
pub const rights_duplicate = u32(1 << 0)
pub const rights_transfer = u32(1 << 1)
pub const rights_read = u32(1 << 2)
pub const rights_write = u32(1 << 3)
pub const rights_execute = u32(1 << 4)
pub const rights_map = u32(1 << 5)
pub const rights_get_property = u32(1 << 6)
pub const rights_set_property = u32(1 << 7)
pub const rights_enumerate = u32(1 << 8)
pub const rights_destroy = u32(1 << 9)
pub const rights_set_policy = u32(1 << 10)
pub const rights_get_policy = u32(1 << 11)
pub const rights_signal = u32(1 << 12)
pub const rights_signal_peer = u32(1 << 13)
pub const rights_wait = u32(1 << 14)
pub const rights_inspect = u32(1 << 15)
pub const rights_manage_job = u32(1 << 16)
pub const rights_manage_process = u32(1 << 17)
pub const rights_manage_thread = u32(1 << 18)
pub const rights_apply_profile = u32(1 << 19)

// Common handle right combinations
pub const rights_basic = rights_transfer | rights_duplicate | rights_wait | rights_inspect
pub const rights_io = rights_read | rights_write
pub const rights_property = rights_get_property | rights_set_property
pub const rights_policy = rights_get_policy | rights_set_policy
pub const rights_default_channel = rights_basic | rights_io | rights_signal | rights_signal_peer

// Status codes
pub enum ZxStatus {
	ok                  = 0
	err_internal        = -1
	err_not_supported   = -2
	err_no_resources    = -3
	err_no_memory       = -4
	err_invalid_args    = -10
	err_bad_handle      = -11
	err_wrong_type      = -12
	err_bad_syscall     = -13
	err_out_of_range    = -14
	err_buffer_too_small= -15
	err_bad_state       = -20
	err_timed_out       = -21
	err_should_wait     = -22
	err_canceled        = -23
	err_peer_closed     = -24
	err_not_found       = -25
	err_already_exists  = -26
	err_already_bound   = -27
	err_unavailable     = -28
	err_access_denied   = -30
	err_io              = -40
	err_io_refused      = -41
	err_io_data_integrity = -42
	err_io_data_loss    = -43
	err_io_not_present  = -44
	err_io_overrun      = -45
	err_io_missed_deadline = -46
	err_io_invalid      = -47
}

// Object types
pub enum ObjType {
	none           = 0
	process        = 1
	thread         = 2
	vmo            = 3
	channel        = 4
	event          = 5
	port           = 6
	interrupt      = 9
	pci_device     = 11
	log            = 12
	socket         = 14
	resource       = 15
	eventpair      = 16
	job            = 17
	vmar           = 18
	fifo           = 19
	guest          = 20
	vcpu           = 21
	timer          = 22
	iommu          = 23
	bti            = 24
	profile        = 25
	pmt            = 26
	suspend_token  = 27
	pager          = 28
	exception      = 29
	clock          = 30
	stream         = 31
	msi            = 32
}

// Signals (bitmask)
pub const signal_none = u32(0)
pub const signal_object0 = u32(1 << 0)
pub const signal_object1 = u32(1 << 1)
pub const signal_object2 = u32(1 << 2)
pub const signal_object3 = u32(1 << 3)
pub const signal_object4 = u32(1 << 4)
pub const signal_object5 = u32(1 << 5)
pub const signal_object6 = u32(1 << 6)
pub const signal_object7 = u32(1 << 7)
pub const signal_object_all = u32(0xff)
pub const signal_user0 = u32(1 << 24)
pub const signal_user1 = u32(1 << 25)
pub const signal_user2 = u32(1 << 26)
pub const signal_user3 = u32(1 << 27)
pub const signal_user4 = u32(1 << 28)
pub const signal_user5 = u32(1 << 29)
pub const signal_user6 = u32(1 << 30)
pub const signal_user7 = u32(1 << 31)
pub const signal_user_all = u32(0xff << 24)

// Channel-specific signals
pub const channel_readable = signal_object0
pub const channel_writable = signal_object1
pub const channel_peer_closed = signal_object2

// Handle value type (kernel object reference)
pub type KernelObjectId = u64

// Handle entry with object reference and rights
pub struct HandleEntry {
pub:
	object_id  KernelObjectId
	obj_type   ObjType
	rights     u32
mut:
	ref_count  u32
}

// Create a new handle entry
pub fn HandleEntry.new(object_id KernelObjectId, obj_type ObjType, rights u32) HandleEntry {
	return HandleEntry{
		object_id: object_id
		obj_type: obj_type
		rights: rights
		ref_count: 1
	}
}

// Check if handle has specific rights
pub fn (h &HandleEntry) has_rights(required u32) bool {
	return (h.rights & required) == required
}

// Message header for IPC
pub struct MessageHeader {
pub:
	txid       u32      // Transaction ID
	flags      u8       // Message flags
	magic      u8       // Protocol magic (should be 0x01)
	ordinal    u64      // Method ordinal for FIDL
}

// Message flags
pub const msg_flag_sync_call = u8(1 << 0)
pub const msg_flag_event = u8(1 << 1)

// FIDL magic number
pub const fidl_magic = u8(0x01)

// Create a new message header
pub fn MessageHeader.new(txid u32, ordinal u64) MessageHeader {
	return MessageHeader{
		txid: txid
		flags: 0
		magic: fidl_magic
		ordinal: ordinal
	}
}

// Check if valid FIDL header
pub fn (h &MessageHeader) is_valid_fidl() bool {
	return h.magic == fidl_magic
}

// Wait item for multi-wait operations
pub struct WaitItem {
pub:
	handle           KernelObjectId
	waitfor          u32   // Signals to wait for
mut:
	pending          u32   // Signals that are pending
}

// Create a new wait item
pub fn WaitItem.new(handle KernelObjectId, signals u32) WaitItem {
	return WaitItem{
		handle: handle
		waitfor: signals
		pending: 0
	}
}

// Port packet types
pub enum PacketType {
	user           = 0
	signal_one     = 1
	signal_rep     = 2
	guest_bell     = 3
	guest_mem      = 4
	guest_io       = 5
	guest_vcpu     = 6
	interrupt      = 7
	page_request   = 8
}

// Port packet
pub struct PortPacket {
pub mut:
	key        u64
	pkt_type   PacketType
	status     ZxStatus
	// Union payload - simplified for V
	user       [32]u8  // For user packets
	signal     SignalPacket
}

// Signal packet payload
pub struct SignalPacket {
pub:
	trigger    u32
	observed   u32
	count      u64
	timestamp  i64
}

// Tests
fn test_handle_rights() {
	h := HandleEntry.new(1, .channel, rights_default_channel)
	assert h.has_rights(rights_read)
	assert h.has_rights(rights_write)
	assert h.has_rights(rights_transfer)
	assert !h.has_rights(rights_execute)
}

fn test_message_header() {
	hdr := MessageHeader.new(1, 0x12345678)
	assert hdr.is_valid_fidl()
	assert hdr.txid == 1
	assert hdr.ordinal == 0x12345678
}

fn test_status_codes() {
	assert int(ZxStatus.ok) == 0
	assert int(ZxStatus.err_no_memory) == -4
	assert int(ZxStatus.err_peer_closed) == -24
}

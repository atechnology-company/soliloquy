// Zircon Channel Implementation - Bidirectional IPC primitive
//
// Channels are the fundamental IPC mechanism in Zircon. They provide
// bidirectional message passing with handle transfer capabilities.
//
// Translated from: third_party/zircon_c/ipc/channel.c

module ipc

import sync

// Channel endpoint identifier
pub type ChannelEndpoint = u8

pub const endpoint_0 = ChannelEndpoint(0)
pub const endpoint_1 = ChannelEndpoint(1)

// Maximum pending messages per channel endpoint
const max_pending_messages = usize(256)

// Message stored in a channel
pub struct ChannelMessage {
pub:
	data       []u8           // Message data bytes
	handles    []KernelObjectId  // Transferred handle IDs
	timestamp  i64            // When message was sent
}

// Create a new channel message
pub fn ChannelMessage.new(data []u8, handles []KernelObjectId) ChannelMessage {
	return ChannelMessage{
		data: data.clone()
		handles: handles.clone()
		timestamp: 0  // Would use zx_clock_get_monotonic()
	}
}

// Get message data length
pub fn (m &ChannelMessage) data_len() usize {
	return m.data.len
}

// Get number of handles
pub fn (m &ChannelMessage) handle_count() usize {
	return m.handles.len
}

// Single endpoint of a channel
struct ChannelEndpointState {
mut:
	messages     []ChannelMessage   // Pending messages
	signals      u32                // Current signal state
	waiters      u32                // Number of waiters
	closed       bool               // Endpoint closed
}

fn ChannelEndpointState.new() ChannelEndpointState {
	return ChannelEndpointState{
		messages: []ChannelMessage{cap: 16}
		signals: channel_writable  // Initially writable
		waiters: 0
		closed: false
	}
}

// Channel pair implementation
pub struct Channel {
	id         KernelObjectId
mut:
	endpoints  [2]ChannelEndpointState
	lock       sync.Mutex
}

// Create a new channel pair
pub fn Channel.new(id KernelObjectId) Channel {
	return Channel{
		id: id
		endpoints: [ChannelEndpointState.new(), ChannelEndpointState.new()]
		lock: sync.Mutex{}
	}
}

// Get channel ID
pub fn (c &Channel) get_id() KernelObjectId {
	return c.id
}

// Check if endpoint is valid
fn valid_endpoint(ep ChannelEndpoint) bool {
	return ep == endpoint_0 || ep == endpoint_1
}

// Get peer endpoint
fn peer_endpoint(ep ChannelEndpoint) ChannelEndpoint {
	return if ep == endpoint_0 { endpoint_1 } else { endpoint_0 }
}

// Write a message to the channel (sends to peer)
pub fn (mut c Channel) write(src_endpoint ChannelEndpoint, data []u8, handles []KernelObjectId) ZxStatus {
	if !valid_endpoint(src_endpoint) {
		return .err_invalid_args
	}

	if data.len > max_msg_size {
		return .err_out_of_range
	}

	if handles.len > max_msg_handles {
		return .err_out_of_range
	}

	c.lock.@lock()
	defer { c.lock.unlock() }

	peer := peer_endpoint(src_endpoint)
	peer_state := &c.endpoints[int(peer)]
	
	// Check if peer is closed
	if peer_state.closed {
		return .err_peer_closed
	}

	// Check if peer has room
	if peer_state.messages.len >= max_pending_messages {
		return .err_should_wait
	}

	// Create and queue message
	msg := ChannelMessage.new(data, handles)
	unsafe {
		mut ps := &c.endpoints[int(peer)]
		ps.messages << msg
		ps.signals |= channel_readable
	}

	return .ok
}

// Read a message from the channel
pub fn (mut c Channel) read(endpoint ChannelEndpoint, may_discard bool) ?(ChannelMessage, ZxStatus) {
	if !valid_endpoint(endpoint) {
		return none
	}

	c.lock.@lock()
	defer { c.lock.unlock() }

	ep_state := &c.endpoints[int(endpoint)]
	
	if ep_state.messages.len == 0 {
		peer := peer_endpoint(endpoint)
		if c.endpoints[int(peer)].closed {
			return ChannelMessage{}, ZxStatus.err_peer_closed
		}
		return ChannelMessage{}, ZxStatus.err_should_wait
	}

	// Get first message
	unsafe {
		mut es := &c.endpoints[int(endpoint)]
		msg := es.messages[0]
		es.messages.delete(0)
		
		// Update signals
		if es.messages.len == 0 {
			es.signals &= ~channel_readable
		}
		
		return msg, ZxStatus.ok
	}
}

// Check if channel has pending messages
pub fn (c &Channel) has_pending(endpoint ChannelEndpoint) bool {
	if !valid_endpoint(endpoint) {
		return false
	}
	
	return c.endpoints[int(endpoint)].messages.len > 0
}

// Get pending message count
pub fn (c &Channel) pending_count(endpoint ChannelEndpoint) usize {
	if !valid_endpoint(endpoint) {
		return 0
	}
	
	return c.endpoints[int(endpoint)].messages.len
}

// Get current signals for an endpoint
pub fn (c &Channel) get_signals(endpoint ChannelEndpoint) u32 {
	if !valid_endpoint(endpoint) {
		return 0
	}
	
	return c.endpoints[int(endpoint)].signals
}

// Close an endpoint
pub fn (mut c Channel) close_endpoint(endpoint ChannelEndpoint) ZxStatus {
	if !valid_endpoint(endpoint) {
		return .err_invalid_args
	}

	c.lock.@lock()
	defer { c.lock.unlock() }

	unsafe {
		mut es := &c.endpoints[int(endpoint)]
		if es.closed {
			return .err_bad_state
		}
		es.closed = true
		es.signals = 0
	}

	// Signal peer that this endpoint is closed
	peer := peer_endpoint(endpoint)
	unsafe {
		mut ps := &c.endpoints[int(peer)]
		ps.signals |= channel_peer_closed
	}

	return .ok
}

// Check if endpoint is closed
pub fn (c &Channel) is_closed(endpoint ChannelEndpoint) bool {
	if !valid_endpoint(endpoint) {
		return true
	}
	
	return c.endpoints[int(endpoint)].closed
}

// Check if peer is closed
pub fn (c &Channel) is_peer_closed(endpoint ChannelEndpoint) bool {
	if !valid_endpoint(endpoint) {
		return true
	}
	
	peer := peer_endpoint(endpoint)
	return c.endpoints[int(peer)].closed
}

// Call: send message and wait for reply (synchronous RPC)
pub fn (mut c Channel) call(endpoint ChannelEndpoint, request []u8, handles []KernelObjectId, timeout_ns i64) ?(ChannelMessage, ZxStatus) {
	// Write request
	status := c.write(endpoint, request, handles)
	if status != .ok {
		return ChannelMessage{}, status
	}

	// Wait for response (simplified - real impl would use futex)
	// For now, just try to read immediately
	return c.read(endpoint, false)
}

// ChannelPair factory for creating connected channel pairs
pub struct ChannelPair {
pub:
	channel   Channel
	handle0   KernelObjectId
	handle1   KernelObjectId
}

// Create a new channel pair
pub fn create_channel_pair(base_id KernelObjectId) ChannelPair {
	return ChannelPair{
		channel: Channel.new(base_id)
		handle0: base_id
		handle1: base_id + 1
	}
}

// Tests
fn test_channel_create() {
	pair := create_channel_pair(100)
	assert pair.handle0 == 100
	assert pair.handle1 == 101
	assert !pair.channel.is_closed(endpoint_0)
	assert !pair.channel.is_closed(endpoint_1)
}

fn test_channel_write_read() {
	mut pair := create_channel_pair(100)
	
	// Write from endpoint 0 to 1
	data := [u8(0x01), 0x02, 0x03, 0x04]
	status := pair.channel.write(endpoint_0, data, [])
	assert status == .ok
	
	// Check signals
	signals := pair.channel.get_signals(endpoint_1)
	assert (signals & channel_readable) != 0
	
	// Read from endpoint 1
	msg, read_status := pair.channel.read(endpoint_1, false) or {
		assert false, 'read failed'
		return
	}
	assert read_status == .ok
	assert msg.data == data
}

fn test_channel_handle_transfer() {
	mut pair := create_channel_pair(100)
	
	data := [u8(0x42)]
	handles := [KernelObjectId(200), KernelObjectId(201)]
	
	status := pair.channel.write(endpoint_0, data, handles)
	assert status == .ok
	
	msg, read_status := pair.channel.read(endpoint_1, false) or {
		assert false, 'read failed'
		return
	}
	assert read_status == .ok
	assert msg.handles.len == 2
	assert msg.handles[0] == 200
	assert msg.handles[1] == 201
}

fn test_channel_close() {
	mut pair := create_channel_pair(100)
	
	// Close endpoint 0
	status := pair.channel.close_endpoint(endpoint_0)
	assert status == .ok
	
	// Check peer sees closure
	assert pair.channel.is_peer_closed(endpoint_1)
	
	signals := pair.channel.get_signals(endpoint_1)
	assert (signals & channel_peer_closed) != 0
	
	// Write to closed peer should fail
	data := [u8(0x01)]
	write_status := pair.channel.write(endpoint_1, data, [])
	assert write_status == .err_peer_closed
}

fn test_channel_full() {
	mut pair := create_channel_pair(100)
	
	// Fill the channel
	data := [u8(0x42)]
	for i in 0 .. max_pending_messages {
		status := pair.channel.write(endpoint_0, data, [])
		assert status == .ok
	}
	
	// Next write should fail
	status := pair.channel.write(endpoint_0, data, [])
	assert status == .err_should_wait
}

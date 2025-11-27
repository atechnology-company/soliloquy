// Zircon Port Implementation - Asynchronous event notification
//
// Ports are the mechanism for asynchronous I/O in Zircon. They allow
// waiting on multiple objects and receiving packets when signals trigger.
//
// Translated from: third_party/zircon_c/ipc/port.c

module ipc

import sync

// Maximum queued packets per port
const max_port_packets = usize(4096)

// Port implementation
pub struct Port {
	id         KernelObjectId
mut:
	packets    []PortPacket
	lock       sync.Mutex
	closed     bool
}

// Create a new port
pub fn Port.new(id KernelObjectId) Port {
	return Port{
		id: id
		packets: []PortPacket{cap: 64}
		lock: sync.Mutex{}
		closed: false
	}
}

// Get port ID
pub fn (p &Port) get_id() KernelObjectId {
	return p.id
}

// Queue a user packet
pub fn (mut p Port) queue_user(key u64, data [32]u8) ZxStatus {
	p.lock.@lock()
	defer { p.lock.unlock() }

	if p.closed {
		return .err_bad_state
	}

	if p.packets.len >= max_port_packets {
		return .err_should_wait
	}

	pkt := PortPacket{
		key: key
		pkt_type: .user
		status: .ok
		user: data
	}

	p.packets << pkt
	return .ok
}

// Queue a signal packet (internal, called by wait operations)
pub fn (mut p Port) queue_signal(key u64, trigger u32, observed u32, count u64) ZxStatus {
	p.lock.@lock()
	defer { p.lock.unlock() }

	if p.closed {
		return .err_bad_state
	}

	if p.packets.len >= max_port_packets {
		return .err_should_wait
	}

	pkt := PortPacket{
		key: key
		pkt_type: .signal_one
		status: .ok
		signal: SignalPacket{
			trigger: trigger
			observed: observed
			count: count
			timestamp: 0  // Would use monotonic clock
		}
	}

	p.packets << pkt
	return .ok
}

// Wait for a packet
pub fn (mut p Port) wait(timeout_ns i64) ?(PortPacket, ZxStatus) {
	p.lock.@lock()
	defer { p.lock.unlock() }

	if p.closed {
		return PortPacket{}, ZxStatus.err_bad_state
	}

	if p.packets.len == 0 {
		// Would block on futex with timeout
		// Simplified: just return should_wait
		return PortPacket{}, ZxStatus.err_should_wait
	}

	// Dequeue first packet
	pkt := p.packets[0]
	p.packets.delete(0)
	return pkt, ZxStatus.ok
}

// Check if port has pending packets
pub fn (p &Port) has_pending() bool {
	return p.packets.len > 0
}

// Get pending packet count
pub fn (p &Port) pending_count() usize {
	return p.packets.len
}

// Cancel pending waits with a specific key
pub fn (mut p Port) cancel(key u64) ZxStatus {
	p.lock.@lock()
	defer { p.lock.unlock() }

	// Remove all packets with matching key
	mut i := 0
	for i < p.packets.len {
		if p.packets[i].key == key {
			p.packets.delete(i)
		} else {
			i++
		}
	}

	return .ok
}

// Close the port
pub fn (mut p Port) close() ZxStatus {
	p.lock.@lock()
	defer { p.lock.unlock() }

	if p.closed {
		return .err_bad_state
	}

	p.closed = true
	p.packets.clear()
	return .ok
}

// Check if closed
pub fn (p &Port) is_closed() bool {
	return p.closed
}

// Object wait binding for port
pub struct PortWaitBinding {
pub:
	port_id      KernelObjectId
	object_id    KernelObjectId
	key          u64
	signals      u32
mut:
	active       bool
	triggered    bool
}

// Create a new wait binding
pub fn PortWaitBinding.new(port_id KernelObjectId, object_id KernelObjectId, key u64, signals u32) PortWaitBinding {
	return PortWaitBinding{
		port_id: port_id
		object_id: object_id
		key: key
		signals: signals
		active: true
		triggered: false
	}
}

// Cancel the binding
pub fn (mut b PortWaitBinding) cancel() {
	b.active = false
}

// Check if binding matches signal
pub fn (b &PortWaitBinding) matches_signal(observed u32) bool {
	return (b.signals & observed) != 0
}

// Tests
fn test_port_create() {
	port := Port.new(100)
	assert port.get_id() == 100
	assert !port.is_closed()
	assert port.pending_count() == 0
}

fn test_port_queue_user() {
	mut port := Port.new(100)
	
	mut data := [32]u8{}
	data[0] = 0x42
	data[1] = 0x43
	
	status := port.queue_user(1, data)
	assert status == .ok
	assert port.pending_count() == 1
	
	// Dequeue
	pkt, wait_status := port.wait(0) or {
		assert false, 'wait failed'
		return
	}
	assert wait_status == .ok
	assert pkt.key == 1
	assert pkt.pkt_type == .user
	assert pkt.user[0] == 0x42
}

fn test_port_queue_signal() {
	mut port := Port.new(100)
	
	status := port.queue_signal(42, channel_readable, channel_readable | channel_writable, 1)
	assert status == .ok
	
	pkt, wait_status := port.wait(0) or {
		assert false, 'wait failed'
		return
	}
	assert wait_status == .ok
	assert pkt.key == 42
	assert pkt.pkt_type == .signal_one
	assert pkt.signal.trigger == channel_readable
	assert pkt.signal.observed == (channel_readable | channel_writable)
}

fn test_port_cancel() {
	mut port := Port.new(100)
	
	data := [32]u8{}
	port.queue_user(1, data)
	port.queue_user(2, data)
	port.queue_user(1, data)
	
	assert port.pending_count() == 3
	
	port.cancel(1)
	assert port.pending_count() == 1
}

fn test_port_close() {
	mut port := Port.new(100)
	
	data := [32]u8{}
	port.queue_user(1, data)
	
	status := port.close()
	assert status == .ok
	assert port.is_closed()
	assert port.pending_count() == 0
	
	// Queue after close should fail
	status2 := port.queue_user(2, data)
	assert status2 == .err_bad_state
}

fn test_wait_binding() {
	binding := PortWaitBinding.new(100, 200, 42, channel_readable | channel_writable)
	
	assert binding.port_id == 100
	assert binding.object_id == 200
	assert binding.key == 42
	assert binding.active
	
	// Test signal matching
	assert binding.matches_signal(channel_readable)
	assert binding.matches_signal(channel_writable)
	assert binding.matches_signal(channel_readable | channel_peer_closed)
	assert !binding.matches_signal(channel_peer_closed)
}

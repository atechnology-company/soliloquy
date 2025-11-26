module hal

// Memory-mapped I/O helper functions
// Translated from drivers/common/soliloquy_hal/mmio.cc

// FFI declarations for C++ ddk::MmioBuffer
fn C.mmio_read32(mmio voidptr, offset u32) u32
fn C.mmio_write32(mmio voidptr, value u32, offset u32)
fn C.zx_clock_get_monotonic() i64
fn C.zx_nanosleep(deadline i64)
fn C.zx_deadline_after(duration i64) i64

pub struct MmioHelper {
pub mut:
	mmio voidptr // Opaque pointer to C++ ddk::MmioBuffer
}

// Create a new MmioHelper from an opaque C++ MmioBuffer pointer
pub fn new_mmio_helper(mmio voidptr) MmioHelper {
	return MmioHelper{
		mmio: mmio
	}
}

// Read a 32-bit value from a memory-mapped register
pub fn (m &MmioHelper) read32(offset u32) u32 {
	return C.mmio_read32(m.mmio, offset)
}

// Write a 32-bit value to a memory-mapped register
pub fn (m &MmioHelper) write32(offset u32, value u32) {
	C.mmio_write32(m.mmio, value, offset)
}

// Set specific bits in a register (bitwise OR)
// Operation: reg[offset] = reg[offset] | mask
pub fn (m &MmioHelper) set_bits32(offset u32, mask u32) {
	val := m.read32(offset)
	m.write32(offset, val | mask)
}

// Clear specific bits in a register (bitwise AND with inverted mask)
// Operation: reg[offset] = reg[offset] & ~mask
pub fn (m &MmioHelper) clear_bits32(offset u32, mask u32) {
	val := m.read32(offset)
	m.write32(offset, val & ~mask)
}

// Modify specific bits in a register while preserving others
// Operation: reg[offset] = (reg[offset] & ~mask) | (value & mask)
pub fn (m &MmioHelper) modify_bits32(offset u32, mask u32, value u32) {
	val := m.read32(offset)
	new_val := (val & ~mask) | (value & mask)
	m.write32(offset, new_val)
}

// Read a masked bit field from a register
// Operation: (reg[offset] & mask) >> shift
pub fn (m &MmioHelper) read_masked32(offset u32, mask u32, shift u32) u32 {
	return (m.read32(offset) & mask) >> shift
}

// Write a value to a masked bit field in a register
// Operation: reg[offset] = (reg[offset] & ~mask) | ((value << shift) & mask)
pub fn (m &MmioHelper) write_masked32(offset u32, mask u32, shift u32, value u32) {
	val := m.read32(offset)
	new_val := (val & ~mask) | ((value << shift) & mask)
	m.write32(offset, new_val)
}

// Poll a register bit until it reaches expected state or timeout
// Returns true if bit reached expected state, false on timeout
// Polling interval: 10 microseconds
pub fn (m &MmioHelper) wait_for_bit32(offset u32, bit u32, set bool, timeout_ns i64) bool {
	deadline := C.zx_deadline_after(timeout_ns)
	
	for C.zx_clock_get_monotonic() < deadline {
		val := m.read32(offset)
		bit_set := (val & (u32(1) << bit)) != 0
		
		if bit_set == set {
			return true
		}
		
		// Sleep for 10 microseconds
		C.zx_nanosleep(C.zx_deadline_after(10000)) // 10 µs = 10,000 ns
	}
	
	// Timeout - in real implementation would log warning
	return false
}

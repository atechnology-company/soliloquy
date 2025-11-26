module hal

// Firmware loading helper functions
// Translated from drivers/common/soliloquy_hal/firmware.cc

// Zircon status codes
const zx_ok = 0
const zx_err_invalid_args = -10
const zx_err_not_found = -3

// FFI declarations for C++ firmware loading
fn C.load_firmware(parent voidptr, name &char, out_vmo &u32, out_size &u64) int
fn C.zx_vmar_map(vmar u32, options u32, vmar_offset u64, vmo u32, vmo_offset u64, length u64, mapped_addr &u64) int
fn C.zx_vmar_root_self() u32

// VMAR map options
const zx_vm_perm_read = u32(1)

// Load firmware from system and return VMO handle and size
pub fn load_firmware(parent voidptr, name string) !(u32, u64, int) {
	if unsafe { parent == nil } || name.len == 0 {
		return error('Invalid arguments'), 0, 0, zx_err_invalid_args
	}
	
	mut vmo_handle := u32(0)
	mut size := u64(0)
	
	// Call C++ load_firmware function
	status := C.load_firmware(parent, name.str, &vmo_handle, &size)
	if status != zx_ok {
		return error('Failed to load firmware ${name}'), 0, 0, status
	}
	
	return vmo_handle, size, status
}

// Map firmware VMO into memory
pub fn map_firmware(vmo_handle u32, size u64) !(&u8, int) {
	if size == 0 {
		return error('Invalid size'), unsafe { nil }, zx_err_invalid_args
	}
	
	mut mapped_addr := u64(0)
	
	// Map the VMO into the address space
	status := C.zx_vmar_map(
		C.zx_vmar_root_self(),
		zx_vm_perm_read,
		0, // vmar_offset (0 = kernel chooses)
		vmo_handle,
		0, // vmo_offset
		size,
		&mapped_addr
	)
	
	if status != zx_ok {
		return error('Failed to map firmware VMO'), unsafe { nil }, status
	}
	
	// Cast mapped address to byte pointer
	data := unsafe { &u8(mapped_addr) }
	return data, status
}

// Helper function to load and map firmware in one call
pub fn load_and_map_firmware(parent voidptr, name string) !(&u8, u64, u32, int) {
	// Load firmware
	vmo_handle, size, load_status := load_firmware(parent, name)!
	if load_status != zx_ok {
		return error('Failed to load firmware'), unsafe { nil }, 0, 0, load_status
	}
	
	// Map firmware
	data, map_status := map_firmware(vmo_handle, size)!
	if map_status != zx_ok {
		return error('Failed to map firmware'), unsafe { nil }, 0, vmo_handle, map_status
	}
	
	return data, size, vmo_handle, zx_ok
}

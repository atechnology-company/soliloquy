module hal

// SDIO protocol helper functions
// Translated from drivers/common/soliloquy_hal/sdio.cc

// Zircon status codes
const zx_ok = 0
const zx_err_invalid_args = -10
const zx_err_io = -40

// FFI declarations for C++ ddk::SdioProtocolClient
fn C.sdio_do_rw_byte(sdio voidptr, write bool, addr u32, write_byte u8, out_read_byte &u8) int
fn C.sdio_do_rw_txn(sdio voidptr, addr u32, buf &u8, length u64, write bool, incr bool) int
fn C.zx_vmo_read(vmo u32, buffer voidptr, offset u64, length u64) int

const block_size = 512

pub struct SdioHelper {
pub mut:
	sdio voidptr // Opaque pointer to C++ ddk::SdioProtocolClient
}

// Create a new SdioHelper from an opaque C++ SdioProtocolClient pointer
pub fn new_sdio_helper(sdio voidptr) SdioHelper {
	return SdioHelper{
		sdio: sdio
	}
}

// Read a single byte from SDIO function register
pub fn (s &SdioHelper) read_byte(address u32) !(u8, int) {
	mut value := u8(0)
	status := C.sdio_do_rw_byte(s.sdio, false, address, 0, &value)
	if status != zx_ok {
		return error('SDIO read byte failed'), status
	}
	return value, status
}

// Write a single byte to SDIO function register
pub fn (s &SdioHelper) write_byte(address u32, value u8) !int {
	status := C.sdio_do_rw_byte(s.sdio, true, address, value, unsafe { nil })
	if status != zx_ok {
		return error('SDIO write byte failed')
	}
	return status
}

// Read multiple blocks from SDIO function
pub fn (s &SdioHelper) read_multi_block(address u32, buf &u8, length u64) !int {
	if unsafe { buf == nil } || length == 0 {
		return error('Invalid arguments')
	}
	
	blocks := (length + block_size - 1) / block_size
	
	for i in 0 .. blocks {
		mut chunk_size := if i == blocks - 1 {
			rem := length % block_size
			if rem == 0 { block_size } else { rem }
		} else {
			block_size
		}
		
		offset := i * block_size
		chunk_addr := address + u32(offset)
		chunk_buf := unsafe { buf + offset }
		
		status := C.sdio_do_rw_txn(s.sdio, chunk_addr, chunk_buf, chunk_size, false, false)
		if status != zx_ok {
			return error('SDIO read block ${i} failed')
		}
	}
	
	return zx_ok
}

// Write multiple blocks to SDIO function
pub fn (s &SdioHelper) write_multi_block(address u32, buf &u8, length u64) !int {
	if unsafe { buf == nil } || length == 0 {
		return error('Invalid arguments')
	}
	
	blocks := (length + block_size - 1) / block_size
	
	for i in 0 .. blocks {
		mut chunk_size := if i == blocks - 1 {
			rem := length % block_size
			if rem == 0 { block_size } else { rem }
		} else {
			block_size
		}
		
		offset := i * block_size
		chunk_addr := address + u32(offset)
		chunk_buf := unsafe { buf + offset }
		
		status := C.sdio_do_rw_txn(s.sdio, chunk_addr, chunk_buf, chunk_size, true, false)
		if status != zx_ok {
			return error('SDIO write block ${i} failed')
		}
	}
	
	return zx_ok
}

// Download firmware to SDIO device
pub fn (s &SdioHelper) download_firmware(vmo_handle u32, size u64, address u32) !int {
	if size == 0 {
		return error('Invalid firmware size')
	}
	
	// Allocate temporary buffer for firmware chunks
	chunk_size := u64(4096)
	mut buffer := []u8{len: int(chunk_size)}
	
	mut offset := u64(0)
	for offset < size {
		bytes_to_read := if size - offset < chunk_size {
			size - offset
		} else {
			chunk_size
		}
		
		// Read from VMO
		status := C.zx_vmo_read(vmo_handle, buffer.data, offset, bytes_to_read)
		if status != zx_ok {
			return error('Failed to read firmware VMO')
		}
		
		// Write to SDIO
		write_addr := address + u32(offset)
		write_status := s.write_multi_block(write_addr, buffer.data, bytes_to_read)!
		if write_status != zx_ok {
			return error('Failed to write firmware chunk at offset ${offset}')
		}
		
		offset += bytes_to_read
	}
	
	return zx_ok
}

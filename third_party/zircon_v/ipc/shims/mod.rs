// Rust FFI shims for V IPC implementation
//
// This module provides a Rust-friendly interface to the V-translated Zircon IPC subsystem.
// The V code is compiled to object files and linked with the Rust binary.

use std::slice;

pub type ZxHandle = u32;
pub type ZxRights = u32;
pub type ZxStatus = i32;

pub const ZX_HANDLE_INVALID: ZxHandle = 0;

pub const ZX_RIGHT_NONE: ZxRights = 0;
pub const ZX_RIGHT_READ: ZxRights = 1 << 0;
pub const ZX_RIGHT_WRITE: ZxRights = 1 << 1;
pub const ZX_RIGHT_DUPLICATE: ZxRights = 1 << 2;
pub const ZX_RIGHT_TRANSFER: ZxRights = 1 << 3;

pub const ZX_OK: ZxStatus = 0;
pub const ZX_ERR_BAD_HANDLE: ZxStatus = -11;
pub const ZX_ERR_INVALID_ARGS: ZxStatus = -10;
pub const ZX_ERR_NO_MEMORY: ZxStatus = -4;

extern "C" {
    fn ipc__channel_create(
        out_handle0: *mut ZxHandle,
        out_handle1: *mut ZxHandle,
    ) -> ZxStatus;

    fn ipc__channel_write(
        handle: ZxHandle,
        data_ptr: *const u8,
        data_len: u32,
        handles_ptr: *const ZxHandle,
        handles_len: u32,
    ) -> ZxStatus;

    fn ipc__channel_read(
        handle: ZxHandle,
        data_ptr: *mut u8,
        data_cap: u32,
        actual_data_size: *mut u32,
        handles_ptr: *mut ZxHandle,
        handles_cap: u32,
        actual_num_handles: *mut u32,
    ) -> ZxStatus;

    fn ipc__channel_close(handle: ZxHandle) -> ZxStatus;
}

pub struct ChannelPair {
    pub handle0: ZxHandle,
    pub handle1: ZxHandle,
}

impl ChannelPair {
    pub fn create() -> Result<Self, ZxStatus> {
        let mut handle0 = ZX_HANDLE_INVALID;
        let mut handle1 = ZX_HANDLE_INVALID;

        let status = unsafe { ipc__channel_create(&mut handle0, &mut handle1) };

        if status == ZX_OK {
            Ok(ChannelPair { handle0, handle1 })
        } else {
            Err(status)
        }
    }
}

pub struct Channel {
    handle: ZxHandle,
}

impl Channel {
    pub fn from_handle(handle: ZxHandle) -> Self {
        Channel { handle }
    }

    pub fn write(&self, data: &[u8], handles: &[ZxHandle]) -> Result<(), ZxStatus> {
        let status = unsafe {
            ipc__channel_write(
                self.handle,
                data.as_ptr(),
                data.len() as u32,
                handles.as_ptr(),
                handles.len() as u32,
            )
        };

        if status == ZX_OK {
            Ok(())
        } else {
            Err(status)
        }
    }

    pub fn read(&self, data_buffer: &mut [u8], handles_buffer: &mut [ZxHandle]) -> Result<(usize, usize), ZxStatus> {
        let mut actual_data_size = 0u32;
        let mut actual_num_handles = 0u32;

        let status = unsafe {
            ipc__channel_read(
                self.handle,
                data_buffer.as_mut_ptr(),
                data_buffer.len() as u32,
                &mut actual_data_size,
                handles_buffer.as_mut_ptr(),
                handles_buffer.len() as u32,
                &mut actual_num_handles,
            )
        };

        if status == ZX_OK {
            Ok((actual_data_size as usize, actual_num_handles as usize))
        } else {
            Err(status)
        }
    }

    pub fn close(self) -> Result<(), ZxStatus> {
        let status = unsafe { ipc__channel_close(self.handle) };

        if status == ZX_OK {
            Ok(())
        } else {
            Err(status)
        }
    }

    pub fn handle(&self) -> ZxHandle {
        self.handle
    }
}

impl Drop for Channel {
    fn drop(&mut self) {
        if self.handle != ZX_HANDLE_INVALID {
            let _ = unsafe { ipc__channel_close(self.handle) };
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_channel_create() {
        let result = ChannelPair::create();
        assert!(result.is_ok());
        let pair = result.unwrap();
        assert_ne!(pair.handle0, ZX_HANDLE_INVALID);
        assert_ne!(pair.handle1, ZX_HANDLE_INVALID);
    }

    #[test]
    fn test_channel_write_read() {
        let pair = ChannelPair::create().unwrap();
        let ch0 = Channel::from_handle(pair.handle0);
        let ch1 = Channel::from_handle(pair.handle1);

        let data = b"Hello, IPC!";
        let result = ch0.write(data, &[]);
        assert!(result.is_ok());

        let mut read_buffer = vec![0u8; 64];
        let mut handles_buffer = vec![0u32; 8];
        let result = ch1.read(&mut read_buffer, &mut handles_buffer);
        assert!(result.is_ok());

        let (data_size, _) = result.unwrap();
        assert_eq!(data_size, data.len());
        assert_eq!(&read_buffer[..data_size], data);
    }

    #[test]
    fn test_channel_close() {
        let pair = ChannelPair::create().unwrap();
        let ch = Channel::from_handle(pair.handle0);
        let result = ch.close();
        assert!(result.is_ok());
    }
}

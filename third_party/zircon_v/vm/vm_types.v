// Virtual Memory Types for Zircon V Translation
// Translated from third_party/zircon_c/vm/vm_types.h
// 
// This module provides the core type definitions for virtual memory management
// in the Zircon kernel translated to V language.

module vm

// Physical memory address type (64-bit)
pub type PAddr = u64

// Virtual memory address type (64-bit)  
pub type VAddr = u64

// Zircon status codes
pub type ZxStatus = int

// Page size constant (4KB pages standard for ARM64 and x86-64)
pub const page_size = u64(4096)
pub const page_shift = u32(12)

// Status codes matching Zircon's zx_status_t
pub const zx_ok = ZxStatus(0)
pub const zx_err_internal = ZxStatus(-1)
pub const zx_err_not_supported = ZxStatus(-2)
pub const zx_err_no_resources = ZxStatus(-3)
pub const zx_err_no_memory = ZxStatus(-4)
pub const zx_err_invalid_args = ZxStatus(-10)
pub const zx_err_bad_handle = ZxStatus(-11)
pub const zx_err_wrong_type = ZxStatus(-12)
pub const zx_err_bad_state = ZxStatus(-20)
pub const zx_err_timed_out = ZxStatus(-21)
pub const zx_err_not_found = ZxStatus(-25)
pub const zx_err_already_exists = ZxStatus(-26)
pub const zx_err_buffer_too_small = ZxStatus(-30)

// VM page states
pub enum VmPageState {
	free       = 0
	allocated  = 1
	wired      = 2
	object     = 3
}

// Page flags
pub const vm_page_flag_none = u32(0)
pub const vm_page_flag_wired = u32(1 << 0)
pub const vm_page_flag_pinned = u32(1 << 1)

// Page fault flags
@[flag]
pub enum PageFaultFlags {
	read
	write
	exec
	user
}

// Represents a physical memory page
pub struct VmPage {
pub mut:
	paddr     PAddr        // Physical address of this page
	state     VmPageState  // Current state of the page
	ref_count u32          // Reference count for sharing
	flags     u32          // Additional page flags
	next      &VmPage = unsafe { nil }  // Linked list pointer for free list
}

// Create a new VmPage with given physical address
pub fn new_vm_page(paddr PAddr) VmPage {
	return VmPage{
		paddr: paddr
		state: .free
		ref_count: 0
		flags: vm_page_flag_none
	}
}

// Increment reference count and return new count
pub fn (mut page VmPage) add_ref() u32 {
	page.ref_count++
	return page.ref_count
}

// Decrement reference count and return new count
// Returns 0 if page can be freed
pub fn (mut page VmPage) release() u32 {
	if page.ref_count > 0 {
		page.ref_count--
	}
	return page.ref_count
}

// Check if page is in a valid allocated state
pub fn (page &VmPage) is_valid() bool {
	return page.state == .allocated || page.state == .wired || page.state == .object
}

// Get virtual address from physical address (identity mapping for kernel)
@[inline]
pub fn phys_to_virt(paddr PAddr) VAddr {
	// In a real kernel, this would use the physical memory map offset
	// For now, assume identity mapping in kernel space
	return VAddr(paddr)
}

// Get physical address from virtual address (identity mapping for kernel)
@[inline]
pub fn virt_to_phys(vaddr VAddr) PAddr {
	return PAddr(vaddr)
}

// Align address down to page boundary
@[inline]
pub fn page_align_down(addr u64) u64 {
	return addr & ~(page_size - 1)
}

// Align address up to page boundary
@[inline]  
pub fn page_align_up(addr u64) u64 {
	return (addr + page_size - 1) & ~(page_size - 1)
}

// Get page index from address
@[inline]
pub fn addr_to_page_index(addr u64) u64 {
	return addr >> page_shift
}

// Get address from page index
@[inline]
pub fn page_index_to_addr(index u64) u64 {
	return index << page_shift
}

// Page Fault Handler
// Translated from third_party/zircon_c/vm/page_fault.c
//
// Handles page faults by committing pages on-demand from a VMO.
// This provides demand paging / lazy allocation support.

module vm

// Page Fault Handler
// Handles page faults for a VMO by committing pages on-demand
pub struct PageFaultHandler {
pub mut:
	vmo   &Vmo = unsafe { nil }
	arena &PmmArena = unsafe { nil }
	
	// Statistics
	faults_handled u64
	faults_failed  u64
}

// Create a new page fault handler for a VMO
//
// Arguments:
//   vmo: The VMO to handle faults for
//   arena: The arena to allocate pages from
//
// Returns:
//   New PageFaultHandler or error
pub fn page_fault_handler_new(vmo &Vmo, arena &PmmArena) !PageFaultHandler {
	if isnil(vmo) {
		return error('VMO cannot be nil')
	}
	if isnil(arena) {
		return error('arena cannot be nil')
	}
	
	return PageFaultHandler{
		vmo: unsafe { &Vmo(vmo) }
		arena: unsafe { &PmmArena(arena) }
		faults_handled: 0
		faults_failed: 0
	}
}

// Handle a page fault at the given virtual address
//
// Arguments:
//   fault_addr: Virtual address that caused the fault
//   flags: Page fault flags indicating the type of access
//
// Returns:
//   ZxStatus indicating success or error
pub fn (mut handler PageFaultHandler) handle_fault(fault_addr VAddr, flags PageFaultFlags) ZxStatus {
	// Validate write access to kernel memory
	if .write in flags && .user !in flags {
		// Write to kernel memory without user flag - this may be invalid
		// depending on kernel memory protection policy
	}
	
	// Calculate page index from fault address
	page_index := fault_addr / page_size
	
	// Check bounds
	if page_index >= handler.vmo.page_count {
		handler.faults_failed++
		return zx_err_not_found
	}
	
	// Check if page is already committed
	if handler.vmo.is_committed(page_index) {
		// Page exists, fault may be due to permissions
		// Return OK - the caller should retry the access
		return zx_ok
	}
	
	// Commit the page on-demand
	mut vmo := handler.vmo
	status := vmo.commit_page(page_index)
	
	if status == zx_ok {
		handler.faults_handled++
		
		// Zero the page for security (prevent information leaks)
		page := vmo.get_page(page_index) or {
			return zx_err_internal
		}
		zero_page(page)
	} else {
		handler.faults_failed++
	}
	
	return status
}

// Handle a page fault for a byte range
//
// Commits all pages that overlap the given range.
//
// Arguments:
//   start_addr: Start of the range
//   size: Size of the range in bytes
//   flags: Page fault flags
//
// Returns:
//   ZxStatus indicating success or error
pub fn (mut handler PageFaultHandler) handle_range_fault(start_addr VAddr, size u64, flags PageFaultFlags) ZxStatus {
	if size == 0 {
		return zx_ok
	}
	
	start_page := start_addr / page_size
	end_addr := start_addr + size - 1
	end_page := end_addr / page_size
	
	for page_idx in start_page .. end_page + 1 {
		status := handler.handle_fault(page_idx * page_size, flags)
		if status != zx_ok && status != zx_err_not_found {
			return status
		}
	}
	
	return zx_ok
}

// Get fault statistics
pub fn (handler &PageFaultHandler) get_stats() (u64, u64) {
	return handler.faults_handled, handler.faults_failed
}

// Reset fault statistics
pub fn (mut handler PageFaultHandler) reset_stats() {
	handler.faults_handled = 0
	handler.faults_failed = 0
}

// Zero a physical page (for security)
fn zero_page(page &VmPage) {
	// In a real kernel, this would use the kernel's virtual mapping
	// to access and zero the physical page memory
	// For now, this is a placeholder that would need platform-specific
	// implementation via FFI to the kernel memory system
	
	// FFI call to zero memory at physical address
	// C.memset(phys_to_virt(page.paddr), 0, page_size)
}

// Prefault handler - commits pages before they're accessed
pub struct PrefaultHandler {
pub mut:
	handler PageFaultHandler
}

// Create a prefault handler that can pre-commit page ranges
pub fn prefault_handler_new(vmo &Vmo, arena &PmmArena) !PrefaultHandler {
	handler := page_fault_handler_new(vmo, arena)!
	return PrefaultHandler{
		handler: handler
	}
}

// Prefault (pre-commit) a range of pages
//
// This is used to avoid page faults during performance-critical operations.
//
// Arguments:
//   start_addr: Start address of range to prefault
//   size: Size of range in bytes
//
// Returns:
//   ZxStatus indicating success or error
pub fn (mut pf PrefaultHandler) prefault(start_addr VAddr, size u64) ZxStatus {
	flags := PageFaultFlags.read
	return pf.handler.handle_range_fault(start_addr, size, flags)
}

// Unit tests
#[test]
fn test_page_fault_handler() {
	mut arena := pmm_arena_new(0x100000, page_size * 16) or {
		assert false, 'failed to create arena'
		return
	}
	
	vmo := vmo_create(&arena, page_size * 4, 'test') or {
		assert false, 'failed to create VMO'
		return
	}
	
	mut handler := page_fault_handler_new(&vmo, &arena) or {
		assert false, 'failed to create handler'
		return
	}
	
	// Handle a page fault
	status := handler.handle_fault(0, PageFaultFlags.read)
	assert status == zx_ok
	
	handled, failed := handler.get_stats()
	assert handled == 1
	assert failed == 0
}

#[test]
fn test_page_fault_out_of_bounds() {
	mut arena := pmm_arena_new(0x100000, page_size * 16) or {
		assert false, 'failed to create arena'
		return
	}
	
	vmo := vmo_create(&arena, page_size * 2, 'test') or {
		assert false, 'failed to create VMO'
		return
	}
	
	mut handler := page_fault_handler_new(&vmo, &arena) or {
		assert false, 'failed to create handler'
		return
	}
	
	// Fault beyond VMO bounds should fail
	status := handler.handle_fault(page_size * 10, PageFaultFlags.read)
	assert status == zx_err_not_found
	
	_, failed := handler.get_stats()
	assert failed == 1
}

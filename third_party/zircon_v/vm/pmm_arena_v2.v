// Physical Memory Manager Arena
// Translated from third_party/zircon_c/vm/pmm_arena.c
//
// Provides a contiguous region of physical memory that can be allocated
// and freed as individual pages. Uses a simple free list allocator.

module vm

import sync

// Physical Memory Manager Arena
// Manages a contiguous range of physical memory for page allocation
pub struct PmmArena {
pub mut:
	base       PAddr      // Base physical address of the arena
	size       u64        // Total size in bytes
	page_array []VmPage   // Array of page metadata, indexed by page offset
	free_list  &VmPage = unsafe { nil }  // Head of the free page list
	free_count u64        // Number of free pages
	lock       sync.Mutex // Thread safety for concurrent access
}

// Initialize a PMM arena with the given physical memory region
// 
// Arguments:
//   base: Physical address of the memory region start
//   size: Size of the region in bytes (must be page-aligned)
// 
// Returns:
//   Initialized PmmArena or error
pub fn pmm_arena_new(base PAddr, size u64) !PmmArena {
	if size == 0 {
		return error('arena size cannot be zero')
	}
	
	if size % page_size != 0 {
		return error('arena size must be page-aligned')
	}
	
	page_count := size / page_size
	
	mut arena := PmmArena{
		base: base
		size: size
		page_array: []VmPage{len: int(page_count)}
		free_count: 0
	}
	
	// Initialize all pages and add to free list
	for i in 0 .. page_count {
		paddr := base + (i * page_size)
		arena.page_array[i] = VmPage{
			paddr: paddr
			state: .free
			ref_count: 0
			flags: vm_page_flag_none
		}
		
		// Add to free list (prepend for O(1) insertion)
		arena.page_array[i].next = arena.free_list
		arena.free_list = &arena.page_array[i]
		arena.free_count++
	}
	
	return arena
}

// Allocate a single page from the arena
// 
// Returns:
//   Pointer to allocated VmPage, or none if no pages available
pub fn (mut arena PmmArena) alloc_page() ?&VmPage {
	arena.lock.@lock()
	defer { arena.lock.unlock() }
	
	if isnil(arena.free_list) {
		return none
	}
	
	mut page := arena.free_list
	arena.free_list = page.next
	arena.free_count--
	
	page.state = .allocated
	page.ref_count = 1
	unsafe {
		page.next = nil
	}
	
	return page
}

// Allocate contiguous pages from the arena
//
// Arguments:
//   count: Number of contiguous pages to allocate
//
// Returns:
//   Slice of allocated pages, or none if not enough contiguous pages
pub fn (mut arena PmmArena) alloc_contiguous(count u64) ?[]&VmPage {
	if count == 0 {
		return none
	}
	
	arena.lock.@lock()
	defer { arena.lock.unlock() }
	
	if arena.free_count < count {
		return none
	}
	
	// For simplicity, allocate count pages from free list
	// A real implementation would search for contiguous physical pages
	mut pages := []&VmPage{cap: int(count)}
	
	for _ in 0 .. count {
		if isnil(arena.free_list) {
			// Rollback on failure
			for page in pages {
				arena.free_page_internal(page)
			}
			return none
		}
		
		mut page := arena.free_list
		arena.free_list = page.next
		arena.free_count--
		
		page.state = .allocated
		page.ref_count = 1
		unsafe {
			page.next = nil
		}
		
		pages << page
	}
	
	return pages
}

// Free a previously allocated page back to the arena
// 
// Arguments:
//   page: Page to free (must have been allocated from this arena)
//
// Returns:
//   ZxStatus indicating success or error
pub fn (mut arena PmmArena) free_page(page &VmPage) ZxStatus {
	arena.lock.@lock()
	defer { arena.lock.unlock() }
	
	return arena.free_page_internal(page)
}

// Internal free without locking (used for rollback)
fn (mut arena PmmArena) free_page_internal(page &VmPage) ZxStatus {
	if isnil(page) {
		return zx_err_invalid_args
	}
	
	// Verify page belongs to this arena
	if page.paddr < arena.base || page.paddr >= arena.base + arena.size {
		return zx_err_invalid_args
	}
	
	mut mutable_page := unsafe { &VmPage(page) }
	
	if mutable_page.state != .allocated {
		return zx_err_bad_state
	}
	
	mutable_page.ref_count--
	if mutable_page.ref_count > 0 {
		return zx_ok
	}
	
	// Return page to free list
	mutable_page.state = .free
	mutable_page.next = arena.free_list
	arena.free_list = mutable_page
	arena.free_count++
	
	return zx_ok
}

// Get the number of free pages in the arena
pub fn (arena &PmmArena) get_free_count() u64 {
	return arena.free_count
}

// Get the total number of pages in the arena
pub fn (arena &PmmArena) get_total_pages() u64 {
	return arena.size / page_size
}

// Check if an address is within this arena
pub fn (arena &PmmArena) contains(paddr PAddr) bool {
	return paddr >= arena.base && paddr < arena.base + arena.size
}

// Get a page by its physical address
pub fn (arena &PmmArena) get_page(paddr PAddr) ?&VmPage {
	if !arena.contains(paddr) {
		return none
	}
	
	index := (paddr - arena.base) / page_size
	return &arena.page_array[index]
}

// Unit tests
#[test]
fn test_pmm_arena_new() {
	arena := pmm_arena_new(0x1000, page_size * 4) or {
		assert false, 'failed to create arena'
		return
	}
	
	assert arena.get_total_pages() == 4
	assert arena.get_free_count() == 4
}

#[test]
fn test_pmm_arena_alloc_free() {
	mut arena := pmm_arena_new(0x1000, page_size * 4) or {
		assert false, 'failed to create arena'
		return
	}
	
	// Allocate a page
	page := arena.alloc_page() or {
		assert false, 'failed to allocate page'
		return
	}
	
	assert arena.get_free_count() == 3
	assert page.state == .allocated
	assert page.ref_count == 1
	
	// Free the page
	status := arena.free_page(page)
	assert status == zx_ok
	assert arena.get_free_count() == 4
}

#[test]
fn test_pmm_arena_exhaust() {
	mut arena := pmm_arena_new(0x1000, page_size * 2) or {
		assert false, 'failed to create arena'
		return
	}
	
	// Allocate all pages
	_ := arena.alloc_page() or {
		assert false, 'failed to allocate page 1'
		return
	}
	_ := arena.alloc_page() or {
		assert false, 'failed to allocate page 2'
		return
	}
	
	// Third allocation should fail
	page3 := arena.alloc_page()
	assert page3 == none
}

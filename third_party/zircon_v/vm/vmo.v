// Virtual Memory Object (VMO) Implementation
// Translated from third_party/zircon_c/vm/vmo_bootstrap.c
//
// A VMO represents a contiguous region of virtual memory backed by
// physical pages that can be committed on-demand.

module vm

// Virtual Memory Object
// Represents a contiguous virtual address range backed by physical pages
pub struct Vmo {
pub mut:
	size       u64          // Size of the VMO in bytes
	pages      []&VmPage    // Array of page pointers (nil = uncommitted)
	page_count u64          // Number of page slots
	arena      &PmmArena = unsafe { nil }  // Arena for page allocation
	committed  u64          // Number of committed pages
	name       string       // Optional name for debugging
}

// Create a new VMO with the given size
//
// Pages are not allocated until explicitly committed or accessed
// (demand paging).
//
// Arguments:
//   arena: PmmArena to allocate pages from
//   size: Size in bytes (will be rounded up to page boundary)
//   name: Optional name for debugging
//
// Returns:
//   New VMO or error
pub fn vmo_create(arena &PmmArena, size u64, name string) !Vmo {
	if size == 0 {
		return error('VMO size cannot be zero')
	}
	
	if isnil(arena) {
		return error('arena cannot be nil')
	}
	
	page_count := (size + page_size - 1) / page_size
	aligned_size := page_count * page_size
	
	mut vmo := Vmo{
		size: aligned_size
		pages: []&VmPage{len: int(page_count), init: unsafe { nil }}
		page_count: page_count
		arena: unsafe { &PmmArena(arena) }
		committed: 0
		name: name
	}
	
	return vmo
}

// Commit a specific page in the VMO
//
// Allocates a physical page from the arena if not already committed.
//
// Arguments:
//   page_index: Index of the page to commit (0-based)
//
// Returns:
//   ZxStatus indicating success or error
pub fn (mut vmo Vmo) commit_page(page_index u64) ZxStatus {
	if page_index >= vmo.page_count {
		return zx_err_invalid_args
	}
	
	// Already committed
	if !isnil(vmo.pages[page_index]) {
		return zx_ok
	}
	
	// Allocate from arena
	mut arena := vmo.arena
	page := arena.alloc_page() or {
		return zx_err_no_memory
	}
	
	vmo.pages[page_index] = page
	vmo.committed++
	
	return zx_ok
}

// Commit a range of pages
//
// Arguments:
//   start_page: First page index to commit
//   count: Number of pages to commit
//
// Returns:
//   ZxStatus indicating success or error
pub fn (mut vmo Vmo) commit_range(start_page u64, count u64) ZxStatus {
	if start_page + count > vmo.page_count {
		return zx_err_invalid_args
	}
	
	for i in start_page .. start_page + count {
		status := vmo.commit_page(i)
		if status != zx_ok {
			return status
		}
	}
	
	return zx_ok
}

// Commit all pages in the VMO
pub fn (mut vmo Vmo) commit_all() ZxStatus {
	return vmo.commit_range(0, vmo.page_count)
}

// Decommit a specific page, returning it to the arena
//
// Arguments:
//   page_index: Index of the page to decommit
//
// Returns:
//   ZxStatus indicating success or error
pub fn (mut vmo Vmo) decommit_page(page_index u64) ZxStatus {
	if page_index >= vmo.page_count {
		return zx_err_invalid_args
	}
	
	page := vmo.pages[page_index]
	if isnil(page) {
		return zx_ok // Already uncommitted
	}
	
	mut arena := vmo.arena
	status := arena.free_page(page)
	if status != zx_ok {
		return status
	}
	
	vmo.pages[page_index] = unsafe { nil }
	vmo.committed--
	
	return zx_ok
}

// Get the page at a specific index (may be nil if uncommitted)
pub fn (vmo &Vmo) get_page(page_index u64) ?&VmPage {
	if page_index >= vmo.page_count {
		return none
	}
	
	page := vmo.pages[page_index]
	if isnil(page) {
		return none
	}
	
	return page
}

// Get the physical address for an offset in the VMO
//
// Arguments:
//   offset: Byte offset into the VMO
//
// Returns:
//   Physical address or none if page is uncommitted
pub fn (vmo &Vmo) get_physical_address(offset u64) ?PAddr {
	if offset >= vmo.size {
		return none
	}
	
	page_index := offset / page_size
	page := vmo.get_page(page_index) or {
		return none
	}
	
	page_offset := offset % page_size
	return page.paddr + page_offset
}

// Check if a page is committed
pub fn (vmo &Vmo) is_committed(page_index u64) bool {
	if page_index >= vmo.page_count {
		return false
	}
	return !isnil(vmo.pages[page_index])
}

// Get the number of committed pages
pub fn (vmo &Vmo) get_committed_count() u64 {
	return vmo.committed
}

// Get the size of committed memory in bytes
pub fn (vmo &Vmo) get_committed_bytes() u64 {
	return vmo.committed * page_size
}

// Destroy the VMO, freeing all committed pages
pub fn (mut vmo Vmo) destroy() {
	mut arena := vmo.arena
	
	for i in 0 .. vmo.page_count {
		page := vmo.pages[i]
		if !isnil(page) {
			arena.free_page(page)
			vmo.pages[i] = unsafe { nil }
		}
	}
	
	vmo.pages.clear()
	vmo.page_count = 0
	vmo.size = 0
	vmo.committed = 0
}

// Unit tests
#[test]
fn test_vmo_create() {
	mut arena := pmm_arena_new(0x100000, page_size * 16) or {
		assert false, 'failed to create arena'
		return
	}
	
	vmo := vmo_create(&arena, page_size * 4, 'test_vmo') or {
		assert false, 'failed to create VMO'
		return
	}
	
	assert vmo.size == page_size * 4
	assert vmo.page_count == 4
	assert vmo.committed == 0
}

#[test]
fn test_vmo_commit() {
	mut arena := pmm_arena_new(0x100000, page_size * 16) or {
		assert false, 'failed to create arena'
		return
	}
	
	mut vmo := vmo_create(&arena, page_size * 4, 'test_vmo') or {
		assert false, 'failed to create VMO'
		return
	}
	
	// Commit first page
	status := vmo.commit_page(0)
	assert status == zx_ok
	assert vmo.is_committed(0)
	assert !vmo.is_committed(1)
	assert vmo.get_committed_count() == 1
	
	// Commit range
	status2 := vmo.commit_range(1, 2)
	assert status2 == zx_ok
	assert vmo.get_committed_count() == 3
}

#[test]
fn test_vmo_decommit() {
	mut arena := pmm_arena_new(0x100000, page_size * 16) or {
		assert false, 'failed to create arena'
		return
	}
	
	mut vmo := vmo_create(&arena, page_size * 4, 'test_vmo') or {
		assert false, 'failed to create VMO'
		return
	}
	
	// Commit and then decommit
	vmo.commit_page(0)
	assert vmo.get_committed_count() == 1
	
	status := vmo.decommit_page(0)
	assert status == zx_ok
	assert !vmo.is_committed(0)
	assert vmo.get_committed_count() == 0
}

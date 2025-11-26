module zircon_vm

pub type Paddr_t = u64
pub type Vaddr_t = u64
pub type Vm_page_state_t = u64
pub type Zx_status_t = int

pub const (
	page_size = 4096
	page_shift = 12
	vm_page_state_free = u64(0)
	vm_page_state_allocated = u64(1)
	vm_page_state_wired = u64(2)
	vm_page_state_object = u64(3)
	zx_ok = 0
	zx_err_no_memory = -1
	zx_err_invalid_args = -2
	zx_err_not_found = -3
)

pub struct Vm_page_t {
pub mut:
	paddr Paddr_t
	state Vm_page_state_t
	ref_count u32
	next &Vm_page_t = unsafe { nil }
}

pub struct Pmm_arena_t {
pub mut:
	base Paddr_t
	size usize
	page_array &Vm_page_t = unsafe { nil }
	free_list &Vm_page_t = unsafe { nil }
	free_count usize
}

pub fn pmm_arena_init(mut arena &Pmm_arena_t, base Paddr_t, size usize) Zx_status_t {
	if unsafe { arena == nil } || size == 0 {
		return zx_err_invalid_args
	}
	arena.base = base
	arena.size = size
	page_count := size / page_size
	arena.page_array = unsafe { &Vm_page_t(C.calloc(page_count, sizeof(Vm_page_t))) }
	if unsafe { arena.page_array == nil } {
		return zx_err_no_memory
	}
	arena.free_list = unsafe { nil }
	arena.free_count = 0
	for i := usize(0); i < page_count; i++ {
		unsafe {
			mut page := &arena.page_array[i]
			page.paddr = base + (i * page_size)
			page.state = vm_page_state_free
			page.ref_count = 0
			page.next = arena.free_list
			arena.free_list = page
		}
		arena.free_count++
	}
	return zx_ok
}

pub fn pmm_arena_alloc_page(mut arena &Pmm_arena_t, mut out_page &&Vm_page_t) Zx_status_t {
	if unsafe { arena == nil || out_page == nil } {
		return zx_err_invalid_args
	}
	if unsafe { arena.free_list == nil } {
		return zx_err_no_memory
	}
	unsafe {
		page := arena.free_list
		arena.free_list = page.next
		arena.free_count--
		mut p := &Vm_page_t(page)
		p.state = vm_page_state_allocated
		p.ref_count = 1
		p.next = nil
		*out_page = page
	}
	return zx_ok
}

pub fn pmm_arena_free_page(mut arena &Pmm_arena_t, mut page &Vm_page_t) Zx_status_t {
	if unsafe { arena == nil || page == nil } {
		return zx_err_invalid_args
	}
	if page.state != vm_page_state_allocated {
		return zx_err_invalid_args
	}
	if page.ref_count == 0 {
		return zx_err_invalid_args
	}
	page.ref_count--
	if page.ref_count > 0 {
		return zx_ok
	}
	unsafe {
		page.state = vm_page_state_free
		page.next = arena.free_list
		arena.free_list = page
	}
	arena.free_count++
	return zx_ok
}

pub fn pmm_arena_free_count(arena &Pmm_arena_t) usize {
	if unsafe { arena == nil } {
		return 0
	}
	return arena.free_count
}

pub struct Vmo_t {
pub mut:
	size u64
	pages &&Vm_page_t = unsafe { nil }
	page_count usize
}

pub fn vmo_bootstrap_init(mut vmo &Vmo_t, arena &Pmm_arena_t, size usize) Zx_status_t {
	if unsafe { vmo == nil || arena == nil } || size == 0 {
		return zx_err_invalid_args
	}
	vmo.size = size
	vmo.page_count = (size + page_size - 1) / page_size
	vmo.pages = unsafe { &&Vm_page_t(C.calloc(vmo.page_count, sizeof(&Vm_page_t))) }
	if unsafe { vmo.pages == nil } {
		return zx_err_no_memory
	}
	for i := usize(0); i < vmo.page_count; i++ {
		unsafe {
			vmo.pages[i] = nil
		}
	}
	return zx_ok
}

pub fn vmo_bootstrap_commit_page(mut vmo &Vmo_t, mut arena &Pmm_arena_t, page_index usize) Zx_status_t {
	if unsafe { vmo == nil || arena == nil } {
		return zx_err_invalid_args
	}
	if page_index >= vmo.page_count {
		return zx_err_invalid_args
	}
	if unsafe { vmo.pages[page_index] != nil } {
		return zx_ok
	}
	mut page := &Vm_page_t(unsafe { nil })
	status := pmm_arena_alloc_page(mut arena, mut &page)
	if status != zx_ok {
		return status
	}
	unsafe {
		vmo.pages[page_index] = page
	}
	return zx_ok
}

pub fn vmo_bootstrap_destroy(mut vmo &Vmo_t, mut arena &Pmm_arena_t) {
	if unsafe { vmo == nil || arena == nil } {
		return
	}
	for i := usize(0); i < vmo.page_count; i++ {
		unsafe {
			if vmo.pages[i] != nil {
				pmm_arena_free_page(mut arena, mut vmo.pages[i])
				vmo.pages[i] = nil
			}
		}
	}
	unsafe {
		C.free(vmo.pages)
		vmo.pages = nil
	}
	vmo.page_count = 0
	vmo.size = 0
}

pub enum Page_fault_flags {
	read = 1 << 0
	write = 1 << 1
	exec = 1 << 2
	user = 1 << 3
}

pub struct Page_fault_handler_t {
pub mut:
	vmo &Vmo_t = unsafe { nil }
	arena &Pmm_arena_t = unsafe { nil }
}

pub fn page_fault_handler_init(mut handler &Page_fault_handler_t, vmo &Vmo_t, arena &Pmm_arena_t) Zx_status_t {
	if unsafe { handler == nil || vmo == nil || arena == nil } {
		return zx_err_invalid_args
	}
	handler.vmo = vmo
	handler.arena = arena
	return zx_ok
}

pub fn page_fault_handle(mut handler &Page_fault_handler_t, fault_addr Vaddr_t, flags u32) Zx_status_t {
	if unsafe { handler == nil } {
		return zx_err_invalid_args
	}
	if (flags & u32(Page_fault_flags.write)) != 0 && (flags & u32(Page_fault_flags.user)) == 0 {
		return zx_err_invalid_args
	}
	page_index := fault_addr / page_size
	if page_index >= handler.vmo.page_count {
		return zx_err_not_found
	}
	unsafe {
		if handler.vmo.pages[page_index] == nil {
			status := vmo_bootstrap_commit_page(mut handler.vmo, mut handler.arena, page_index)
			if status != zx_ok {
				return status
			}
		}
	}
	return zx_ok
}

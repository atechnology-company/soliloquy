@[translated]
module main

type Paddr_t = u64
type Vaddr_t = u64
type Vm_page_state_t = u64
type Zx_status_t = int
struct Vm_page_t { 
	paddr Paddr_t
	state Vm_page_state_t
	ref_count u32
	next &Vm_page
}
struct Pmm_arena_t { 
	base Paddr_t
	size usize
	page_array &Vm_page_t
	free_list &Vm_page_t
	free_count usize
}
struct Vmo_t { 
	size u64
	pages &&Vm_page_t
	page_count usize
}
fn vmo_bootstrap_commit_page(vmo &Vmo_t, arena &Pmm_arena_t, page_index usize) Zx_status_t

enum Page_fault_flags_t {
	page_fault_flag_read = 1 << 0
	page_fault_flag_write = 1 << 1
	page_fault_flag_exec = 1 << 2
	page_fault_flag_user = 1 << 3
}

struct Page_fault_handler_t { 
	vmo &Vmo_t
	arena &Pmm_arena_t
}
fn page_fault_handler_init(handler &Page_fault_handler_t, vmo &Vmo_t, arena &Pmm_arena_t) Zx_status_t

fn page_fault_handle(handler &Page_fault_handler_t, fault_addr Vaddr_t, flags u32) Zx_status_t

fn page_fault_handler_init(handler &Page_fault_handler_t, vmo &Vmo_t, arena &Pmm_arena_t) Zx_status_t {
	if handler == (voidptr(0)) || vmo == (voidptr(0)) || arena == (voidptr(0)) {
		return -2
	}
	handler.vmo = vmo
	handler.arena = arena
	return 0
}

fn page_fault_handle(handler &Page_fault_handler_t, fault_addr Vaddr_t, flags u32) Zx_status_t {
	if handler == (voidptr(0)) {
		return -2
	}
	if (flags & Page_fault_flags_t.page_fault_flag_write) && !(flags & Page_fault_flags_t.page_fault_flag_user) {
		return -2
	}
	page_index := fault_addr / 4096
	if page_index >= handler.vmo.page_count {
		return -3
	}
	if handler.vmo.pages [page_index]  == (voidptr(0)) {
		status := vmo_bootstrap_commit_page(handler.vmo, handler.arena, page_index)
		if status != 0 {
			return status
		}
	}
	return 0
}


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
fn pmm_arena_alloc_page(arena &Pmm_arena_t, out_page &&Vm_page_t) Zx_status_t

fn pmm_arena_free_page(arena &Pmm_arena_t, page &Vm_page_t) Zx_status_t

struct Vmo_t { 
	size u64
	pages &&Vm_page_t
	page_count usize
}
fn vmo_bootstrap_init(vmo &Vmo_t, arena &Pmm_arena_t, size usize) Zx_status_t

fn vmo_bootstrap_commit_page(vmo &Vmo_t, arena &Pmm_arena_t, page_index usize) Zx_status_t

fn vmo_bootstrap_destroy(vmo &Vmo_t, arena &Pmm_arena_t)

fn vmo_bootstrap_init(vmo &Vmo_t, arena &Pmm_arena_t, size usize) Zx_status_t {
	if vmo == (voidptr(0)) || arena == (voidptr(0)) || size == 0 {
		return -2
	}
	vmo.size = size
	vmo.page_count = (size + 4096 - 1) / 4096
	vmo.pages = &&Vm_page_t(C.calloc(vmo.page_count, sizeof(&Vm_page_t)))
	if vmo.pages == (voidptr(0)) {
		return -1
	}
	for i := 0 ; i < vmo.page_count ; i ++ {
		vmo.pages [i]  = (voidptr(0))
	}
	return 0
}

fn vmo_bootstrap_commit_page(vmo &Vmo_t, arena &Pmm_arena_t, page_index usize) Zx_status_t {
	if vmo == (voidptr(0)) || arena == (voidptr(0)) {
		return -2
	}
	if page_index >= vmo.page_count {
		return -2
	}
	if vmo.pages [page_index]  != (voidptr(0)) {
		return 0
	}
	page := &Vm_page_t(0)
	status := pmm_arena_alloc_page(arena, &page)
	if status != 0 {
		return status
	}
	vmo.pages [page_index]  = page
	return 0
}

fn vmo_bootstrap_destroy(vmo &Vmo_t, arena &Pmm_arena_t) {
	if vmo == (voidptr(0)) || arena == (voidptr(0)) {
		return 
	}
	for i := 0 ; i < vmo.page_count ; i ++ {
		if vmo.pages [i]  != (voidptr(0)) {
			pmm_arena_free_page(arena, vmo.pages [i] )
			vmo.pages [i]  = (voidptr(0))
		}
	}
	C.free(vmo.pages)
	vmo.pages = (voidptr(0))
	vmo.page_count = 0
	vmo.size = 0
}


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
fn pmm_arena_init(arena &Pmm_arena_t, base Paddr_t, size usize) Zx_status_t

fn pmm_arena_alloc_page(arena &Pmm_arena_t, out_page &&Vm_page_t) Zx_status_t

fn pmm_arena_free_page(arena &Pmm_arena_t, page &Vm_page_t) Zx_status_t

fn pmm_arena_free_count(arena &Pmm_arena_t) usize

fn pmm_arena_init(arena &Pmm_arena_t, base Paddr_t, size usize) Zx_status_t {
	if arena == (voidptr(0)) || size == 0 {
		return -2
	}
	arena.base = base
	arena.size = size
	page_count := size / 4096
	arena.page_array = &Vm_page_t(C.calloc(page_count, sizeof(Vm_page_t)))
	if arena.page_array == (voidptr(0)) {
		return -1
	}
	arena.free_list = (voidptr(0))
	arena.free_count = 0
	for i := 0 ; i < page_count ; i ++ {
		page := &arena.page_array [i] 
		page.paddr = base + (i * 4096)
		page.state = 0
		page.ref_count = 0
		page.next = arena.free_list
		arena.free_list = page
		arena.free_count ++
	}
	return 0
}

fn pmm_arena_alloc_page(arena &Pmm_arena_t, out_page &&Vm_page_t) Zx_status_t {
	if arena == (voidptr(0)) || out_page == (voidptr(0)) {
		return -2
	}
	if arena.free_list == (voidptr(0)) {
		return -1
	}
	page := arena.free_list
	arena.free_list = page.next
	arena.free_count --
	page.state = 1
	page.ref_count = 1
	page.next = (voidptr(0))
	*out_page = page
	return 0
}

fn pmm_arena_free_page(arena &Pmm_arena_t, page &Vm_page_t) Zx_status_t {
	if arena == (voidptr(0)) || page == (voidptr(0)) {
		return -2
	}
	if page.state != 1 {
		return -2
	}
	if page.ref_count == 0 {
		return -2
	}
	page.ref_count --
	if page.ref_count > 0 {
		return 0
	}
	page.state = 0
	page.next = arena.free_list
	arena.free_list = page
	arena.free_count ++
	return 0
}

fn pmm_arena_free_count(arena &Pmm_arena_t) usize {
	if arena == (voidptr(0)) {
		return 0
	}
	return arena.free_count
}


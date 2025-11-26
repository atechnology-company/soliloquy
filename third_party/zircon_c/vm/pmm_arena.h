#ifndef THIRD_PARTY_ZIRCON_C_VM_PMM_ARENA_H_
#define THIRD_PARTY_ZIRCON_C_VM_PMM_ARENA_H_

#include "vm_types.h"
#include "vm_page.h"

typedef struct pmm_arena {
    paddr_t base;
    size_t size;
    vm_page_t* page_array;
    vm_page_t* free_list;
    size_t free_count;
} pmm_arena_t;

zx_status_t pmm_arena_init(pmm_arena_t* arena, paddr_t base, size_t size);
zx_status_t pmm_arena_alloc_page(pmm_arena_t* arena, vm_page_t** out_page);
zx_status_t pmm_arena_free_page(pmm_arena_t* arena, vm_page_t* page);
size_t pmm_arena_free_count(pmm_arena_t* arena);

#endif

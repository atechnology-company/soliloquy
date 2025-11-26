#ifndef THIRD_PARTY_ZIRCON_C_VM_VMO_BOOTSTRAP_H_
#define THIRD_PARTY_ZIRCON_C_VM_VMO_BOOTSTRAP_H_

#include "vm_types.h"
#include "vm_page.h"
#include "pmm_arena.h"

typedef struct vmo {
    uint64_t size;
    vm_page_t** pages;
    size_t page_count;
} vmo_t;

zx_status_t vmo_bootstrap_init(vmo_t* vmo, pmm_arena_t* arena, size_t size);
zx_status_t vmo_bootstrap_commit_page(vmo_t* vmo, pmm_arena_t* arena, size_t page_index);
void vmo_bootstrap_destroy(vmo_t* vmo, pmm_arena_t* arena);

#endif

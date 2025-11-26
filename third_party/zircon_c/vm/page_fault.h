#ifndef THIRD_PARTY_ZIRCON_C_VM_PAGE_FAULT_H_
#define THIRD_PARTY_ZIRCON_C_VM_PAGE_FAULT_H_

#include "vm_types.h"
#include "vmo_bootstrap.h"
#include "pmm_arena.h"

typedef enum page_fault_flags {
    PAGE_FAULT_FLAG_READ = (1 << 0),
    PAGE_FAULT_FLAG_WRITE = (1 << 1),
    PAGE_FAULT_FLAG_EXEC = (1 << 2),
    PAGE_FAULT_FLAG_USER = (1 << 3),
} page_fault_flags_t;

typedef struct page_fault_handler {
    vmo_t* vmo;
    pmm_arena_t* arena;
} page_fault_handler_t;

zx_status_t page_fault_handler_init(page_fault_handler_t* handler, vmo_t* vmo, pmm_arena_t* arena);
zx_status_t page_fault_handle(page_fault_handler_t* handler, vaddr_t fault_addr, uint32_t flags);

#endif

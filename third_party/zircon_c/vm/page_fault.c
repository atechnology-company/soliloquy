#include "page_fault.h"

zx_status_t page_fault_handler_init(page_fault_handler_t* handler, vmo_t* vmo, pmm_arena_t* arena) {
    if (handler == NULL || vmo == NULL || arena == NULL) {
        return ZX_ERR_INVALID_ARGS;
    }

    handler->vmo = vmo;
    handler->arena = arena;
    return ZX_OK;
}

zx_status_t page_fault_handle(page_fault_handler_t* handler, vaddr_t fault_addr, uint32_t flags) {
    if (handler == NULL) {
        return ZX_ERR_INVALID_ARGS;
    }

    if ((flags & PAGE_FAULT_FLAG_WRITE) && !(flags & PAGE_FAULT_FLAG_USER)) {
        return ZX_ERR_INVALID_ARGS;
    }

    size_t page_index = fault_addr / PAGE_SIZE;
    
    if (page_index >= handler->vmo->page_count) {
        return ZX_ERR_NOT_FOUND;
    }

    if (handler->vmo->pages[page_index] == NULL) {
        zx_status_t status = vmo_bootstrap_commit_page(handler->vmo, handler->arena, page_index);
        if (status != ZX_OK) {
            return status;
        }
    }

    return ZX_OK;
}

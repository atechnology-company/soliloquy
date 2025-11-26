#include "vmo_bootstrap.h"
#include <stdlib.h>
#include <string.h>

zx_status_t vmo_bootstrap_init(vmo_t* vmo, pmm_arena_t* arena, size_t size) {
    if (vmo == NULL || arena == NULL || size == 0) {
        return ZX_ERR_INVALID_ARGS;
    }

    vmo->size = size;
    vmo->page_count = (size + PAGE_SIZE - 1) / PAGE_SIZE;
    
    vmo->pages = (vm_page_t**)calloc(vmo->page_count, sizeof(vm_page_t*));
    if (vmo->pages == NULL) {
        return ZX_ERR_NO_MEMORY;
    }

    for (size_t i = 0; i < vmo->page_count; i++) {
        vmo->pages[i] = NULL;
    }

    return ZX_OK;
}

zx_status_t vmo_bootstrap_commit_page(vmo_t* vmo, pmm_arena_t* arena, size_t page_index) {
    if (vmo == NULL || arena == NULL) {
        return ZX_ERR_INVALID_ARGS;
    }

    if (page_index >= vmo->page_count) {
        return ZX_ERR_INVALID_ARGS;
    }

    if (vmo->pages[page_index] != NULL) {
        return ZX_OK;
    }

    vm_page_t* page;
    zx_status_t status = pmm_arena_alloc_page(arena, &page);
    if (status != ZX_OK) {
        return status;
    }

    vmo->pages[page_index] = page;
    return ZX_OK;
}

void vmo_bootstrap_destroy(vmo_t* vmo, pmm_arena_t* arena) {
    if (vmo == NULL || arena == NULL) {
        return;
    }

    for (size_t i = 0; i < vmo->page_count; i++) {
        if (vmo->pages[i] != NULL) {
            pmm_arena_free_page(arena, vmo->pages[i]);
            vmo->pages[i] = NULL;
        }
    }

    free(vmo->pages);
    vmo->pages = NULL;
    vmo->page_count = 0;
    vmo->size = 0;
}

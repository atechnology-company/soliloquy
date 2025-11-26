#include "pmm_arena.h"
#include <string.h>
#include <stdlib.h>

zx_status_t pmm_arena_init(pmm_arena_t* arena, paddr_t base, size_t size) {
    if (arena == NULL || size == 0) {
        return ZX_ERR_INVALID_ARGS;
    }

    arena->base = base;
    arena->size = size;
    
    size_t page_count = size / PAGE_SIZE;
    arena->page_array = (vm_page_t*)calloc(page_count, sizeof(vm_page_t));
    if (arena->page_array == NULL) {
        return ZX_ERR_NO_MEMORY;
    }

    arena->free_list = NULL;
    arena->free_count = 0;

    for (size_t i = 0; i < page_count; i++) {
        vm_page_t* page = &arena->page_array[i];
        page->paddr = base + (i * PAGE_SIZE);
        page->state = VM_PAGE_STATE_FREE;
        page->ref_count = 0;
        
        page->next = arena->free_list;
        arena->free_list = page;
        arena->free_count++;
    }

    return ZX_OK;
}

zx_status_t pmm_arena_alloc_page(pmm_arena_t* arena, vm_page_t** out_page) {
    if (arena == NULL || out_page == NULL) {
        return ZX_ERR_INVALID_ARGS;
    }

    if (arena->free_list == NULL) {
        return ZX_ERR_NO_MEMORY;
    }

    vm_page_t* page = arena->free_list;
    arena->free_list = page->next;
    arena->free_count--;

    page->state = VM_PAGE_STATE_ALLOCATED;
    page->ref_count = 1;
    page->next = NULL;

    *out_page = page;
    return ZX_OK;
}

zx_status_t pmm_arena_free_page(pmm_arena_t* arena, vm_page_t* page) {
    if (arena == NULL || page == NULL) {
        return ZX_ERR_INVALID_ARGS;
    }

    if (page->state != VM_PAGE_STATE_ALLOCATED) {
        return ZX_ERR_INVALID_ARGS;
    }

    if (page->ref_count == 0) {
        return ZX_ERR_INVALID_ARGS;
    }

    page->ref_count--;
    if (page->ref_count > 0) {
        return ZX_OK;
    }

    page->state = VM_PAGE_STATE_FREE;
    page->next = arena->free_list;
    arena->free_list = page;
    arena->free_count++;

    return ZX_OK;
}

size_t pmm_arena_free_count(pmm_arena_t* arena) {
    if (arena == NULL) {
        return 0;
    }
    return arena->free_count;
}

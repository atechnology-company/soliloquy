#ifndef THIRD_PARTY_ZIRCON_C_VM_VM_PAGE_H_
#define THIRD_PARTY_ZIRCON_C_VM_VM_PAGE_H_

#include "vm_types.h"

typedef struct vm_page {
    paddr_t paddr;
    vm_page_state_t state;
    uint32_t ref_count;
    struct vm_page* next;
} vm_page_t;

static inline paddr_t vm_page_to_paddr(vm_page_t* page) {
    return page->paddr;
}

static inline vm_page_t* paddr_to_vm_page(paddr_t paddr, vm_page_t* base, size_t count) {
    size_t index = paddr >> PAGE_SHIFT;
    if (index >= count) {
        return NULL;
    }
    return &base[index];
}

#endif

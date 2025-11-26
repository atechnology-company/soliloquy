#ifndef THIRD_PARTY_ZIRCON_C_VM_VM_TYPES_H_
#define THIRD_PARTY_ZIRCON_C_VM_VM_TYPES_H_

#include <stdint.h>
#include <stddef.h>

typedef uint64_t paddr_t;
typedef uint64_t vaddr_t;
typedef uint64_t vm_page_state_t;

#define PAGE_SIZE 4096
#define PAGE_SHIFT 12

#define VM_PAGE_STATE_FREE 0
#define VM_PAGE_STATE_ALLOCATED 1
#define VM_PAGE_STATE_WIRED 2
#define VM_PAGE_STATE_OBJECT 3

typedef int32_t zx_status_t;

#define ZX_OK 0
#define ZX_ERR_NO_MEMORY -1
#define ZX_ERR_INVALID_ARGS -2
#define ZX_ERR_NOT_FOUND -3

#endif

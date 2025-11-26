#ifndef ZIRCON_IPC_HANDLE_H_
#define ZIRCON_IPC_HANDLE_H_

#include <stdint.h>
#include <stdbool.h>

typedef uint32_t zx_handle_t;
typedef uint32_t zx_rights_t;
typedef int32_t zx_status_t;

#define ZX_HANDLE_INVALID ((zx_handle_t)0)

#define ZX_RIGHT_NONE       0u
#define ZX_RIGHT_READ       (1u << 0)
#define ZX_RIGHT_WRITE      (1u << 1)
#define ZX_RIGHT_DUPLICATE  (1u << 2)
#define ZX_RIGHT_TRANSFER   (1u << 3)

#define ZX_OK               0
#define ZX_ERR_BAD_HANDLE   (-11)
#define ZX_ERR_INVALID_ARGS (-10)
#define ZX_ERR_NO_MEMORY    (-4)

typedef struct handle_table_entry {
    void* object;
    zx_rights_t rights;
    uint32_t ref_count;
    struct handle_table_entry* next;
} handle_table_entry_t;

typedef struct handle_table {
    handle_table_entry_t** buckets;
    uint32_t num_buckets;
    uint32_t count;
} handle_table_t;

zx_status_t handle_table_init(handle_table_t* table, uint32_t initial_buckets);
void handle_table_destroy(handle_table_t* table);

zx_status_t handle_alloc(handle_table_t* table, void* object, zx_rights_t rights, zx_handle_t* out_handle);
zx_status_t handle_get(handle_table_t* table, zx_handle_t handle, zx_rights_t required_rights, void** out_object);
zx_status_t handle_close(handle_table_t* table, zx_handle_t handle);
zx_status_t handle_duplicate(handle_table_t* table, zx_handle_t handle, zx_rights_t rights, zx_handle_t* out_handle);

bool handle_has_rights(zx_rights_t handle_rights, zx_rights_t required_rights);

#endif

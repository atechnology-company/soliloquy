#include "handle.h"
#include <stdlib.h>
#include <string.h>

#define HANDLE_TABLE_INITIAL_BUCKETS 64
#define HANDLE_HASH(h) ((h) % table->num_buckets)

zx_status_t handle_table_init(handle_table_t* table, uint32_t initial_buckets) {
    if (!table) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    table->num_buckets = initial_buckets > 0 ? initial_buckets : HANDLE_TABLE_INITIAL_BUCKETS;
    table->buckets = (handle_table_entry_t**)calloc(table->num_buckets, sizeof(handle_table_entry_t*));
    if (!table->buckets) {
        return ZX_ERR_NO_MEMORY;
    }
    
    table->count = 0;
    return ZX_OK;
}

void handle_table_destroy(handle_table_t* table) {
    if (!table || !table->buckets) {
        return;
    }
    
    for (uint32_t i = 0; i < table->num_buckets; i++) {
        handle_table_entry_t* entry = table->buckets[i];
        while (entry) {
            handle_table_entry_t* next = entry->next;
            free(entry);
            entry = next;
        }
    }
    
    free(table->buckets);
    table->buckets = NULL;
    table->count = 0;
}

zx_status_t handle_alloc(handle_table_t* table, void* object, zx_rights_t rights, zx_handle_t* out_handle) {
    if (!table || !object || !out_handle) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    handle_table_entry_t* entry = (handle_table_entry_t*)malloc(sizeof(handle_table_entry_t));
    if (!entry) {
        return ZX_ERR_NO_MEMORY;
    }
    
    entry->object = object;
    entry->rights = rights;
    entry->ref_count = 1;
    
    zx_handle_t handle = (zx_handle_t)(table->count + 1);
    uint32_t bucket = HANDLE_HASH(handle);
    
    entry->next = table->buckets[bucket];
    table->buckets[bucket] = entry;
    table->count++;
    
    *out_handle = handle;
    return ZX_OK;
}

static handle_table_entry_t* find_entry(handle_table_t* table, zx_handle_t handle, handle_table_entry_t*** out_prev) {
    uint32_t bucket = HANDLE_HASH(handle);
    handle_table_entry_t** prev = &table->buckets[bucket];
    handle_table_entry_t* entry = *prev;
    
    uint32_t target_index = handle - 1;
    uint32_t current_index = 0;
    
    while (entry) {
        if (current_index == target_index) {
            if (out_prev) {
                *out_prev = prev;
            }
            return entry;
        }
        prev = &entry->next;
        entry = entry->next;
        current_index++;
    }
    
    return NULL;
}

zx_status_t handle_get(handle_table_t* table, zx_handle_t handle, zx_rights_t required_rights, void** out_object) {
    if (!table || handle == ZX_HANDLE_INVALID || !out_object) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    handle_table_entry_t* entry = find_entry(table, handle, NULL);
    if (!entry) {
        return ZX_ERR_BAD_HANDLE;
    }
    
    if (!handle_has_rights(entry->rights, required_rights)) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    *out_object = entry->object;
    return ZX_OK;
}

zx_status_t handle_close(handle_table_t* table, zx_handle_t handle) {
    if (!table || handle == ZX_HANDLE_INVALID) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    handle_table_entry_t** prev_ptr;
    handle_table_entry_t* entry = find_entry(table, handle, &prev_ptr);
    if (!entry) {
        return ZX_ERR_BAD_HANDLE;
    }
    
    entry->ref_count--;
    if (entry->ref_count == 0) {
        *prev_ptr = entry->next;
        free(entry);
        table->count--;
    }
    
    return ZX_OK;
}

zx_status_t handle_duplicate(handle_table_t* table, zx_handle_t handle, zx_rights_t rights, zx_handle_t* out_handle) {
    if (!table || handle == ZX_HANDLE_INVALID || !out_handle) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    handle_table_entry_t* entry = find_entry(table, handle, NULL);
    if (!entry) {
        return ZX_ERR_BAD_HANDLE;
    }
    
    if (!handle_has_rights(entry->rights, ZX_RIGHT_DUPLICATE)) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    zx_rights_t new_rights = rights & entry->rights;
    return handle_alloc(table, entry->object, new_rights, out_handle);
}

bool handle_has_rights(zx_rights_t handle_rights, zx_rights_t required_rights) {
    return (handle_rights & required_rights) == required_rights;
}

#include "channel.h"
#include <stdlib.h>
#include <string.h>

static handle_table_t g_handle_table;
static bool g_handle_table_initialized = false;

handle_table_t* get_current_handle_table(void) {
    if (!g_handle_table_initialized) {
        handle_table_init(&g_handle_table, 64);
        g_handle_table_initialized = true;
    }
    return &g_handle_table;
}

static void channel_endpoint_init(channel_endpoint_t* endpoint) {
    message_queue_init(&endpoint->message_queue);
    endpoint->peer = NULL;
    endpoint->is_closed = false;
    endpoint->ref_count = 1;
}

zx_status_t channel_create(zx_handle_t* out_handle0, zx_handle_t* out_handle1) {
    if (!out_handle0 || !out_handle1) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    channel_t* channel = (channel_t*)malloc(sizeof(channel_t));
    if (!channel) {
        return ZX_ERR_NO_MEMORY;
    }
    
    channel_endpoint_init(&channel->endpoint0);
    channel_endpoint_init(&channel->endpoint1);
    
    channel->endpoint0.peer = &channel->endpoint1;
    channel->endpoint1.peer = &channel->endpoint0;
    
    handle_table_t* table = get_current_handle_table();
    
    zx_status_t status = handle_alloc(table, &channel->endpoint0, 
                                      ZX_RIGHT_READ | ZX_RIGHT_WRITE | ZX_RIGHT_TRANSFER,
                                      out_handle0);
    if (status != ZX_OK) {
        free(channel);
        return status;
    }
    
    status = handle_alloc(table, &channel->endpoint1,
                         ZX_RIGHT_READ | ZX_RIGHT_WRITE | ZX_RIGHT_TRANSFER,
                         out_handle1);
    if (status != ZX_OK) {
        handle_close(table, *out_handle0);
        free(channel);
        return status;
    }
    
    return ZX_OK;
}

zx_status_t channel_write(zx_handle_t handle, const void* data, uint32_t data_size,
                          const zx_handle_t* handles, uint32_t num_handles) {
    if (handle == ZX_HANDLE_INVALID) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    handle_table_t* table = get_current_handle_table();
    channel_endpoint_t* endpoint;
    
    zx_status_t status = handle_get(table, handle, ZX_RIGHT_WRITE, (void**)&endpoint);
    if (status != ZX_OK) {
        return status;
    }
    
    if (endpoint->is_closed || !endpoint->peer || endpoint->peer->is_closed) {
        return ZX_ERR_BAD_HANDLE;
    }
    
    message_packet_t* packet;
    status = message_packet_create(data, data_size, handles, num_handles, &packet);
    if (status != ZX_OK) {
        return status;
    }
    
    message_queue_enqueue(&endpoint->peer->message_queue, packet);
    
    return ZX_OK;
}

zx_status_t channel_read(zx_handle_t handle, void* data, uint32_t data_size, uint32_t* actual_data_size,
                         zx_handle_t* handles, uint32_t num_handles, uint32_t* actual_num_handles) {
    if (handle == ZX_HANDLE_INVALID) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    handle_table_t* table = get_current_handle_table();
    channel_endpoint_t* endpoint;
    
    zx_status_t status = handle_get(table, handle, ZX_RIGHT_READ, (void**)&endpoint);
    if (status != ZX_OK) {
        return status;
    }
    
    if (endpoint->is_closed) {
        return ZX_ERR_BAD_HANDLE;
    }
    
    if (message_queue_is_empty(&endpoint->message_queue)) {
        return ZX_ERR_BAD_HANDLE;
    }
    
    message_packet_t* packet = message_queue_dequeue(&endpoint->message_queue);
    if (!packet) {
        return ZX_ERR_BAD_HANDLE;
    }
    
    if (actual_data_size) {
        *actual_data_size = packet->data_size;
    }
    
    if (data && data_size >= packet->data_size) {
        memcpy(data, packet->data, packet->data_size);
    }
    
    if (actual_num_handles) {
        *actual_num_handles = packet->num_handles;
    }
    
    if (handles && num_handles >= packet->num_handles) {
        memcpy(handles, packet->handles, packet->num_handles * sizeof(zx_handle_t));
    }
    
    message_packet_destroy(packet);
    return ZX_OK;
}

zx_status_t channel_close(zx_handle_t handle) {
    if (handle == ZX_HANDLE_INVALID) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    handle_table_t* table = get_current_handle_table();
    channel_endpoint_t* endpoint;
    
    zx_status_t status = handle_get(table, handle, ZX_RIGHT_NONE, (void**)&endpoint);
    if (status != ZX_OK) {
        return status;
    }
    
    endpoint->is_closed = true;
    message_queue_destroy(&endpoint->message_queue);
    
    if (endpoint->peer) {
        endpoint->peer->peer = NULL;
    }
    
    return handle_close(table, handle);
}

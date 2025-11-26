#ifndef ZIRCON_IPC_CHANNEL_H_
#define ZIRCON_IPC_CHANNEL_H_

#include "handle.h"
#include "message_packet.h"

typedef struct channel_endpoint {
    message_queue_t message_queue;
    struct channel_endpoint* peer;
    bool is_closed;
    uint32_t ref_count;
} channel_endpoint_t;

typedef struct channel {
    channel_endpoint_t endpoint0;
    channel_endpoint_t endpoint1;
} channel_t;

zx_status_t channel_create(zx_handle_t* out_handle0, zx_handle_t* out_handle1);

zx_status_t channel_write(zx_handle_t handle, const void* data, uint32_t data_size,
                          const zx_handle_t* handles, uint32_t num_handles);

zx_status_t channel_read(zx_handle_t handle, void* data, uint32_t data_size, uint32_t* actual_data_size,
                         zx_handle_t* handles, uint32_t num_handles, uint32_t* actual_num_handles);

zx_status_t channel_close(zx_handle_t handle);

extern handle_table_t* get_current_handle_table(void);

#endif

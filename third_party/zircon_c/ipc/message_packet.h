#ifndef ZIRCON_IPC_MESSAGE_PACKET_H_
#define ZIRCON_IPC_MESSAGE_PACKET_H_

#include "handle.h"
#include <stddef.h>

typedef struct message_packet {
    struct message_packet* next;
    struct message_packet* prev;
    
    uint32_t data_size;
    uint32_t num_handles;
    
    uint8_t* data;
    zx_handle_t* handles;
} message_packet_t;

typedef struct message_queue {
    message_packet_t* head;
    message_packet_t* tail;
    uint32_t count;
} message_queue_t;

zx_status_t message_packet_create(const void* data, uint32_t data_size, 
                                   const zx_handle_t* handles, uint32_t num_handles,
                                   message_packet_t** out_packet);

void message_packet_destroy(message_packet_t* packet);

void message_queue_init(message_queue_t* queue);
void message_queue_enqueue(message_queue_t* queue, message_packet_t* packet);
message_packet_t* message_queue_dequeue(message_queue_t* queue);
bool message_queue_is_empty(message_queue_t* queue);
void message_queue_destroy(message_queue_t* queue);

#endif

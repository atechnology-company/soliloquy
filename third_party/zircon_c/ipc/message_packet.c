#include "message_packet.h"
#include <stdlib.h>
#include <string.h>

zx_status_t message_packet_create(const void* data, uint32_t data_size,
                                   const zx_handle_t* handles, uint32_t num_handles,
                                   message_packet_t** out_packet) {
    if (!out_packet) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    if (data_size > 0 && !data) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    if (num_handles > 0 && !handles) {
        return ZX_ERR_INVALID_ARGS;
    }
    
    message_packet_t* packet = (message_packet_t*)malloc(sizeof(message_packet_t));
    if (!packet) {
        return ZX_ERR_NO_MEMORY;
    }
    
    packet->next = NULL;
    packet->prev = NULL;
    packet->data_size = data_size;
    packet->num_handles = num_handles;
    
    if (data_size > 0) {
        packet->data = (uint8_t*)malloc(data_size);
        if (!packet->data) {
            free(packet);
            return ZX_ERR_NO_MEMORY;
        }
        memcpy(packet->data, data, data_size);
    } else {
        packet->data = NULL;
    }
    
    if (num_handles > 0) {
        packet->handles = (zx_handle_t*)malloc(num_handles * sizeof(zx_handle_t));
        if (!packet->handles) {
            free(packet->data);
            free(packet);
            return ZX_ERR_NO_MEMORY;
        }
        memcpy(packet->handles, handles, num_handles * sizeof(zx_handle_t));
    } else {
        packet->handles = NULL;
    }
    
    *out_packet = packet;
    return ZX_OK;
}

void message_packet_destroy(message_packet_t* packet) {
    if (!packet) {
        return;
    }
    
    free(packet->data);
    free(packet->handles);
    free(packet);
}

void message_queue_init(message_queue_t* queue) {
    if (!queue) {
        return;
    }
    
    queue->head = NULL;
    queue->tail = NULL;
    queue->count = 0;
}

void message_queue_enqueue(message_queue_t* queue, message_packet_t* packet) {
    if (!queue || !packet) {
        return;
    }
    
    packet->next = NULL;
    packet->prev = queue->tail;
    
    if (queue->tail) {
        queue->tail->next = packet;
    } else {
        queue->head = packet;
    }
    
    queue->tail = packet;
    queue->count++;
}

message_packet_t* message_queue_dequeue(message_queue_t* queue) {
    if (!queue || !queue->head) {
        return NULL;
    }
    
    message_packet_t* packet = queue->head;
    queue->head = packet->next;
    
    if (queue->head) {
        queue->head->prev = NULL;
    } else {
        queue->tail = NULL;
    }
    
    packet->next = NULL;
    packet->prev = NULL;
    queue->count--;
    
    return packet;
}

bool message_queue_is_empty(message_queue_t* queue) {
    return !queue || queue->count == 0;
}

void message_queue_destroy(message_queue_t* queue) {
    if (!queue) {
        return;
    }
    
    message_packet_t* packet = queue->head;
    while (packet) {
        message_packet_t* next = packet->next;
        message_packet_destroy(packet);
        packet = next;
    }
    
    queue->head = NULL;
    queue->tail = NULL;
    queue->count = 0;
}

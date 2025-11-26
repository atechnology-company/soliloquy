module ipc

pub struct MessagePacket {
mut:
    next &MessagePacket = unsafe { nil }
    prev &MessagePacket = unsafe { nil }
    
    data_size   u32
    num_handles u32
    
    data    []u8
    handles []ZxHandle
}

pub struct MessageQueue {
mut:
    head  &MessagePacket = unsafe { nil }
    tail  &MessagePacket = unsafe { nil }
    count u32
}

pub fn message_packet_create(data []u8, handles []ZxHandle) !&MessagePacket {
    mut packet := &MessagePacket{
        data_size: u32(data.len)
        num_handles: u32(handles.len)
        data: data.clone()
        handles: handles.clone()
    }
    
    return packet
}

pub fn (mut packet MessagePacket) destroy() {
    unsafe {
        packet.data.free()
        packet.handles.free()
    }
}

pub fn message_queue_init() MessageQueue {
    return MessageQueue{
        count: 0
    }
}

pub fn (mut queue MessageQueue) enqueue(mut packet MessagePacket) {
    unsafe {
        packet.next = nil
    }
    packet.prev = queue.tail
    
    if !isnil(queue.tail) {
        unsafe {
            queue.tail.next = packet
        }
    } else {
        queue.head = packet
    }
    
    queue.tail = packet
    queue.count++
}

pub fn (mut queue MessageQueue) dequeue() ?&MessagePacket {
    if isnil(queue.head) {
        return none
    }
    
    mut packet := queue.head
    queue.head = packet.next
    
    unsafe {
        if !isnil(queue.head) {
            queue.head.prev = nil
        } else {
            queue.tail = nil
        }
        
        packet.next = nil
        packet.prev = nil
    }
    queue.count--
    
    return packet
}

pub fn (queue &MessageQueue) is_empty() bool {
    return queue.count == 0
}

pub fn (mut queue MessageQueue) destroy() {
    mut packet := queue.head
    for !isnil(packet) {
        next := packet.next
        unsafe {
            packet.destroy()
            free(packet)
        }
        packet = next
    }
    
    unsafe {
        queue.head = nil
        queue.tail = nil
    }
    queue.count = 0
}

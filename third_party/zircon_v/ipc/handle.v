module ipc

pub type ZxHandle = u32
pub type ZxRights = u32
pub type ZxStatus = int

pub const zx_handle_invalid = ZxHandle(0)

pub const zx_right_none = ZxRights(0)
pub const zx_right_read = ZxRights(1 << 0)
pub const zx_right_write = ZxRights(1 << 1)
pub const zx_right_duplicate = ZxRights(1 << 2)
pub const zx_right_transfer = ZxRights(1 << 3)

pub const zx_ok = 0
pub const zx_err_bad_handle = -11
pub const zx_err_invalid_args = -10
pub const zx_err_no_memory = -4

struct HandleTableEntry {
mut:
    object    voidptr
    rights    ZxRights
    ref_count u32
    next      &HandleTableEntry = unsafe { nil }
}

pub struct HandleTable {
mut:
    buckets     []&HandleTableEntry
    num_buckets u32
    count       u32
}

pub fn handle_table_init(initial_buckets u32) !HandleTable {
    num_buckets := if initial_buckets > 0 { initial_buckets } else { u32(64) }
    mut buckets := unsafe { []&HandleTableEntry{len: int(num_buckets)} }
    
    return HandleTable{
        buckets: buckets
        num_buckets: num_buckets
        count: 0
    }
}

pub fn (mut table HandleTable) destroy() {
    for i in 0 .. table.num_buckets {
        mut entry := table.buckets[i]
        for !isnil(entry) {
            next := entry.next
            unsafe { free(entry) }
            entry = next
        }
    }
    table.buckets.clear()
    table.count = 0
}

pub fn (mut table HandleTable) alloc(object voidptr, rights ZxRights) !(ZxHandle, ZxStatus) {
    if isnil(object) {
        return error('invalid object')
    }
    
    mut entry := &HandleTableEntry{
        object: object
        rights: rights
        ref_count: 1
    }
    
    handle := ZxHandle(table.count + 1)
    bucket := int(handle % table.num_buckets)
    
    entry.next = table.buckets[bucket]
    table.buckets[bucket] = entry
    table.count++
    
    return handle, zx_ok
}

fn (table &HandleTable) find_entry(handle ZxHandle) ?&HandleTableEntry {
    if handle == zx_handle_invalid {
        return none
    }
    
    bucket := int(handle % table.num_buckets)
    mut entry := table.buckets[bucket]
    target_index := handle - 1
    mut current_index := u32(0)
    
    for !isnil(entry) {
        if current_index == target_index {
            return entry
        }
        entry = entry.next
        current_index++
    }
    
    return none
}

pub fn (table &HandleTable) get(handle ZxHandle, required_rights ZxRights) !(voidptr, ZxStatus) {
    if handle == zx_handle_invalid {
        return error('invalid handle')
    }
    
    entry := table.find_entry(handle) or {
        return error('handle not found')
    }
    
    if !handle_has_rights(entry.rights, required_rights) {
        return error('insufficient rights')
    }
    
    return entry.object, zx_ok
}

pub fn (mut table HandleTable) close(handle ZxHandle) !ZxStatus {
    if handle == zx_handle_invalid {
        return error('invalid handle')
    }
    
    mut entry := table.find_entry(handle) or {
        return error('handle not found')
    }
    
    entry.ref_count--
    if entry.ref_count == 0 {
        bucket := int(handle % table.num_buckets)
        mut prev := &table.buckets[bucket]
        mut curr := *prev
        
        for !isnil(curr) {
            if curr.object == entry.object {
                unsafe {
                    *prev = curr.next
                    free(curr)
                }
                table.count--
                break
            }
            prev = &curr.next
            curr = curr.next
        }
    }
    
    return zx_ok
}

pub fn (mut table HandleTable) duplicate(handle ZxHandle, rights ZxRights) !(ZxHandle, ZxStatus) {
    if handle == zx_handle_invalid {
        return error('invalid handle')
    }
    
    entry := table.find_entry(handle) or {
        return error('handle not found')
    }
    
    if !handle_has_rights(entry.rights, zx_right_duplicate) {
        return error('cannot duplicate handle')
    }
    
    new_rights := rights & entry.rights
    return table.alloc(entry.object, new_rights)!
}

pub fn handle_has_rights(handle_rights ZxRights, required_rights ZxRights) bool {
    return (handle_rights & required_rights) == required_rights
}

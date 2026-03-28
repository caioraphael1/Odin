import "base:internal"
import "base:intrinsics"
import "base:mem"


// 32-bytes on 64-bit
// 16-bytes on 32-bit
Map :: struct($K, $V: typeid) {
    // A single allocation spanning all keys, values, and hashes.
    // {
    //   k: Map_Cell(K) * (capacity / ks_per_cell)
    //   v: Map_Cell(V) * (capacity / vs_per_cell)
    //   h: Map_Cell(H) * (capacity / hs_per_cell)
    // }
    //
    // The data is allocated assuming 64-u8 alignment, meaning the address is
    // always a multiple of 64. This means we have 6 bits of zeros in the pointer
    // to store the capacity. We can store a value as large as 2^6-1 or 63 in
    // there. This conveniently is the maximum log2 capacity we can have for a map
    // as Odin uses signed integers to represent capacity.
    //
    // Since the hashes are backed by Map_Hash, which is just a 64-bit unsigned
    // integer, the cell structure for hashes is unnecessary because 64/8 is 8 and
    // requires no padding, meaning it can be indexed as a regular array of
    // Map_Hash directly, though for consistency sake it's written as if it were
    // an array of Map_Cell(Map_Hash).
    data:      uintptr,   // 8-bytes on 64-bits,  4-bytes on 32-bits
    len:       uintptr,   // 8-bytes on 64-bits,  4-bytes on 32-bits
    cap:       uint,
    allocator: Allocator, // 16-bytes on 64-bits, 8-bytes on 32-bits
}

Map_Entry :: struct($Key, $Value: typeid) {
    key:   Key,
    value: Value,
}

Map_Entry_Info :: struct($Key, $Value: typeid) {
    hash:  uintptr,
    key:   Key,
    value: Value,
}

// When working with the type-erased structure at runtime we need information
// about the map to make working with it possible. This info structure stores
// that.
//
// `Map_Info` and `Map_Cell_Info` are read only data structures and cannot be
// modified after creation
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Map_Info :: struct {
    ks: ^Map_Cell_Info, // 8-bytes on 64-bit, 4-bytes on 32-bit
    vs: ^Map_Cell_Info, // 8-bytes on 64-bit, 4-bytes on 32-bit
    key_hasher: proc(key: rawptr, seed: Map_Hash) -> Map_Hash, // 8-bytes on 64-bit, 4-bytes on 32-bit
    key_equal:  proc(lhs, rhs: rawptr) -> bool,                // 8-bytes on 64-bit, 4-bytes on 32-bit
}


// So we can operate on a cell data structure at runtime without any type
// information, we have a simple table that stores some traits about the cell.
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Map_Cell_Info :: struct {
    size_of_type:      uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
    align_of_type:     uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
    size_of_cell:      uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
    elements_per_cell: uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
}


// `create` initializes a map with an allocator. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
create :: proc($K, $V: typeid, allocator: mem.Allocator, loc := #caller_location) -> (m: Map($K, $V)) {
    m.allocator = allocator
    return m
}

// `create_cap` initializes a map with an allocator and allocates space using `cap`.
// Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
create_cap :: proc($K, $V: typeid, cap: uint, allocator: mem.Allocator, loc := #caller_location) -> (m: Map($K, $V), err: mem.Allocator_Error) {
    map_expr_create_error_loc(loc, cap)
    m.allocator = allocator
    err = reserve(&m, cap, loc)
    return
}

// `clear` will set the length of a passed map to `0`
clear :: proc(m: ^Map($K, $V)) {
    _clear(m, intrinsics.type_map_info(T))
}

_clear :: #force_inline proc(m: ^Map, info: ^Map_Info) {
    if m.data == 0 {
        return
    }
    _, _, hs, _, _ := _map_kvh_data_dynamic(m^, info)
    intrinsics.mem_zero(rawptr(hs), m.cap * size_of(Map_Hash))
    m.len = 0
}


// `delete` will try to free the underlying data of the passed map, with the given `allocator` if the allocator supports this operation.
delete :: proc(m: Map($K, $V), loc := #caller_location) -> mem.Allocator_Error {
    return map_free_dynamic(m, intrinsics.type_map_info(T), loc)
}

map_free_dynamic :: #force_no_inline proc(m: Map, info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
    ptr := rawptr(m.data)
    size := uint(total_allocation_size(uintptr(m.cap), info))
    err := mem_free_with_size(ptr, size, m.allocator, loc)
    #partial switch err {
    case .None, .Mode_Not_Implemented:
        return nil
    }
    return err
}


// `reserve` will try to reserve memory of a passed map to the requested element count (setting the `cap`).
reserve :: proc(m: ^Map($K, $V), cap: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _reserve(m, intrinsics.type_map_info(T), uintptr(cap), loc)
}

_reserve :: #force_no_inline proc(m: ^Map, info: ^Map_Info, new_capacity: uintptr, loc := #caller_location) -> Allocator_Error {
    ceil_log2 :: #force_inline proc(x: uintptr) -> uintptr {
        z := intrinsics.count_leading_zeros(x)
        if z > 0 && x & (x-1) != 0 {
            z -= 1
        }
        return size_of(uintptr)*8 - 1 - z
    }

    internal.assert(m.allocator.procedure != nil, "Allocator not defined", loc=loc)

    new_capacity := new_capacity
    old_capacity := uintptr(m.cap)

    if old_capacity >= new_capacity {
        return nil
    }

    // ceiling nearest power of two
    log2_new_capacity := ceil_log2(new_capacity)

    log2_min_cap := max(MAP_MIN_CAPACITY, log2_new_capacity)

    if m.data == 0 {
        m^ = _alloc_dynamic(info, log2_min_cap, m.allocator, loc) or_return
        return nil
    }

    resized := _alloc_dynamic(info, log2_min_cap, m.allocator, loc) or_return

    ks, vs, hs, _, _ := _map_kvh_data_dynamic(m^, info)

    // Cache these loads to avoid hitting them in the for loop.
    n := m.len
    for i in 0..<old_capacity {
        hash := hs[i]
        if hash_is_empty(hash) {
            continue
        }
        if hash_is_deleted(hash) {
            continue
        }
        k := _cell_index_dynamic(ks, info.ks, i)
        v := _cell_index_dynamic(vs, info.vs, i)
        hash = info.key_hasher(rawptr(k), seed(resized))
        _, _ = insert_hash_dynamic_with_key(&resized, info, hash, k, v)
        // Only need to do this comparison on each actually added pair, so do not
        // fold it into the for loop comparator as a micro-optimization.
        n -= 1
        if n == 0 {
            break
        }
    }

    map_free_dynamic(m^, info, loc) or_return
    m.data = resized.data
    return nil
}



_check_grow :: proc(m: ^Map, info: ^Map_Info, loc := #caller_location) -> (err: Allocator_Error, has_grown: bool) {
    if m.len >= load_factor(m.cap) {
        return _grow(m, info, loc), true
    }
    return nil, false
}

_grow :: proc(m: ^Map, info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
    new_capacity := max(m.cap * 2, MAP_MIN_CAPACITY)
    return _reserve(m, info, uintptr(new_capacity), loc)
}


// Shrinks the cap of a map down to the current length.
shrink :: proc(m: ^Map($K, $V), loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    return _shrink(m, intrinsics.type_map_info(T), loc)
}

_shrink :: #force_no_inline proc(m: ^Map, info: ^Map_Info, loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    internal.assert(m.allocator.procedure != nil, "Allocator not defined", loc)

    // Cannot shrink the cap if the number of items in the map would exceed
    // one minus the current log2 cap's resize threshold. That is the shrunk
    // map needs to be within the max load factor.
    log2_capacity := map_log2_cap(m^)
    if uintptr(m.len) >= load_factor(m.cap / 2) {
        return false, nil
    }

    shrunk := _alloc_dynamic(info, log2_capacity - 1, m.allocator) or_return

    ks, vs, hs, _, _ := _map_kvh_data_dynamic(m^, info)

    n := m.len
    for i in 0..<m.cap {
        hash := hs[i]
        if hash_is_empty(hash) {
            continue
        }
        if hash_is_deleted(hash) {
            continue
        }

        k := _cell_index_dynamic(ks, info.ks, i)
        v := _cell_index_dynamic(vs, info.vs, i)
        hash = info.key_hasher(rawptr(k), seed(shrunk))
        _, _ = insert_hash_dynamic_with_key(&shrunk, info, hash, k, v)
        // Only need to do this comparison on each actually added pair, so do not
        // fold it into the for loop comparator as a micro-optimization.
        n -= 1
        if n == 0 {
            break
        }
    }

    map_free_dynamic(m^, info, loc) or_return
    m.data = shrunk.data
    return true, nil
}


_alloc_dynamic :: proc(info: ^Map_Info, log2_capacity: uintptr, allocator: Allocator, loc := #caller_location) -> (result: Map, err: Allocator_Error) {
    result.allocator = allocator // set the allocator always
    if log2_capacity == 0 {
        return
    }

    if log2_capacity >= 64 {
        // Overflowed, would be caused by log2_capacity > 64
        return {}, .Out_Of_Memory
    }

    capacity := uintptr(1) << max(log2_capacity, MAP_MIN_CAPACITY)

    CACHE_MASK :: MAP_CACHE_LINE_SIZE - 1

    size := uint(total_allocation_size(capacity, info))

    data := mem_alloc_non_zeroed(size, MAP_CACHE_LINE_SIZE, allocator, loc) or_return
    data_ptr := uintptr(raw_data(data))
    if data_ptr == 0 {
        err = .Out_Of_Memory
        return
    }
    if intrinsics.expect(data_ptr & CACHE_MASK != 0, false) {
        internal.panic("allocation not aligned to a cache line", loc)
    } else {
        result.data = data_ptr | log2_capacity // Tagged pointer representation for capacity.
        result.len = 0

        _clear(&result, info)
    }
    return
}



@(optional_results)
insert :: proc(m: ^Map($K, $V), key: K, value: V, loc := #caller_location) -> (ptr: ^V) {
    key, value := key, value
    return (^V)(raw_map_dynamic_set_without_hash(m, intrinsics.type_map_info(T), rawptr(&key), rawptr(&value), loc))
}

// Explicitly inserts a key and value into a map `m`, the same as `insert`, but the return values differ.
// - `prev_key` will return the previous pointer of a key if it exists, check `found_previous` if was previously found
// - `value_ptr` will return the pointer of the memory where the insertion happens, and `nil` if the map failed to resize
// - `found_previous` will be true a previous key was found
upsert :: proc(m: ^Map($K, $V), key: K, value: V, loc := #caller_location) -> (prev_key: K, value_ptr: ^V, found_previous: bool) {
    key, value := key, value
    kp, vp := dynamic_map_set_extra_without_hash(m, intrinsics.type_map_info(T), rawptr(&key), rawptr(&value), loc)
    if kp != nil {
        prev_key = (^K)(kp)^
        found_previous = true
    }
    value_ptr = (^V)(vp)
    return
}

// The delete_key built-in procedure deletes the element with the specified key (m[key]) from the map.
// If m is nil, or there is no such element, this procedure is a no-op
@(optional_results)
delete_key :: proc(m: ^Map($K, $V), key: K) -> (deleted_key: K, deleted_value: V) {
    if m != nil {
        key := key
        old_k, old_v, ok := raw_map_dynamic_erase(m, intrinsics.type_map_info(T), uintptr(&key))
        if ok {
            deleted_key   = (^K)(old_k)^
            deleted_value = (^V)(old_v)^
        }
    }
    return
}


/*
Retrieves a pointer to the key and value for a possibly just inserted entry into the map.
If the `key` was not in the map `m`, an entry is inserted with the zero value and `just_inserted` will be `true`.
Otherwise the existing entry is left untouched and pointers to its key and value are returned.
If the map has to grow in order to insert the entry and the allocation fails, `err` is set and returned.
If `err` is `nil`, `key_ptr` and `value_ptr` are valid pointers and will not be `nil`.
WARN: User modification of the key pointed at by `key_ptr` should only be done if the new key is equal to (in hash) the old key.
If that is not the case you will corrupt the map.
*/
entry :: proc(m: ^Map($K, $V), key: K, loc := #caller_location) -> (key_ptr: ^K, value_ptr: ^V, just_inserted: bool, err: mem.Allocator_Error) {
    key := key
    zero: V

    _key_ptr, _value_ptr: rawptr
    _key_ptr, _value_ptr, just_inserted, err = raw_map_dynamic_entry(m, intrinsics.type_map_info(T), &key, &zero, loc)

    key_ptr   = (^K)(_key_ptr)
    value_ptr = (^V)(_value_ptr)
    return
}

/* 
keys :: proc(m: $Map($K, $V), allocator: mem.Allocator, loc := #caller_location) -> (keys: []K, err: mem.Allocator_Error) {
    keys = make(type_of(keys), m.len, allocator, loc) or_return
    i := 0
    for key in m {
        keys[i] = key
        i += 1
    }
    return
}
*/

/* 
values :: proc(m: $Map($K, $V), allocator: mem.Allocator, loc := #caller_location) -> (values: []V, err: mem.Allocator_Error) {
    values = make(type_of(values), m.len, allocator, loc) or_return
    i := 0
    for _, value in m {
        values[i] = value
        i += 1
    }
    return
}
*/

/* 
entries :: proc(m: $Map($K, $V), allocator: mem.Allocator, loc := #caller_location) -> (entries: []Map_Entry(K, V), err: mem.Allocator_Error) {
    entries = make(type_of(entries), m.len, allocator, loc) or_return
    i := 0
    for key, value in m {
        entries[i].key   = key
        entries[i].value = value
        i += 1
    }
    return
}
*/

/* 
entry_infos :: proc(m: $Map($K, $V), allocator: mem.Allocator, loc := #caller_location) -> (entries: []Map_Entry_Info(K, V), err: mem.Allocator_Error) #no_bounds_check {
    m := m

    info := reflect.type_info_base(type_info_of(M)).variant.(reflect.Type_Info_Map)
    if info.map_info != nil {
        entries = make(type_of(entries), m.len, allocator, loc) or_return

        ks, vs, hs, _, _ := _map_kvh_data_dynamic(m, info.map_info)
        entry_index := 0
        for bucket_index in 0..<uintptr(m.cap) {
            if hash := hs[bucket_index]; hash_is_valid(hash) {
                key   := _cell_index_dynamic(ks, info.map_info.ks, bucket_index)
                value := _cell_index_dynamic(vs, info.map_info.vs, bucket_index)
                entries[entry_index].hash  = hash
                entries[entry_index].key   = (^K)(key)^
                entries[entry_index].value = (^V)(value)^

                entry_index += 1
            }
        }
    }
    return
}
*/

/* 
get :: proc(m: Map($K, $V), key: K) -> (stored_key: K, stored_value: V, ok: bool) {
    if m.len == 0 {
        return
    }
    info := intrinsics.type_map_info(T)
    key := key

    h := info.key_hasher(&key, seed(m))
    pos := _desired_position(m, h)
    distance := uintptr(0)
    mask := (m.cap) - 1
    ks, vs, hs := map_kvh_data_static(m)
    for {
        element_hash := hs[pos]
        if hash_is_empty(element_hash) {
            return
        } else if distance > _probe_distance(m, element_hash, pos) {
            return
        } else if element_hash == h {
            element_key := map_cell_index_static(ks, pos)
            if info.key_equal(&key, rawptr(element_key)) {
                element_value := map_cell_index_static(vs, pos)
                stored_key   = (^K)(element_key)^
                stored_value = (^V)(element_value)^
                ok = true
                return
            }

        }
        pos = (pos + 1) & mask
        distance += 1
    }
} 
*/


//--------------------------------------------------------------------------------------------------
// Evaluation
//--------------------------------------------------------------------------------------------------

hash_is_valid :: #force_inline proc(hash: Map_Hash) -> bool {
    // The MSB indicates a tombstone
    return (hash != 0) & (hash & TOMBSTONE_MASK == 0)
}

// Procedure to check if a slot is empty for a given hash. This is represented
// by the zero value to make the zero value useful. This is a procedure just
// for prose reasons.
hash_is_empty :: #force_inline proc(hash: Map_Hash) -> bool {
    return hash == 0
}

hash_is_deleted :: #force_no_inline proc(hash: Map_Hash) -> bool {
    // The MSB indicates a tombstone
    return hash & TOMBSTONE_MASK != 0
}


total_allocation_size_from_value :: #force_inline proc(m: Map($K, $V)) -> uintptr {
    return total_allocation_size(uintptr(m.cap), intrinsics.type_map_info(M))
}


total_allocation_size :: #force_inline proc(capacity: uintptr, info: ^Map_Info) -> uintptr {
    round :: #force_inline proc(value: uintptr) -> uintptr {
        CACHE_MASK :: MAP_CACHE_LINE_SIZE - 1
        return (value + CACHE_MASK) &~ CACHE_MASK
    }
    INFO_HS := intrinsics.type_map_cell_info(Map_Hash)

    size := uintptr(0)
    size = round(_cell_index_dynamic(size, info.ks, capacity))
    size = round(_cell_index_dynamic(size, info.vs, capacity))
    size = round(_cell_index_dynamic(size, INFO_HS, capacity))
    size = round(_cell_index_dynamic(size, info.ks, 2)) // Two additional ks for scratch storage
    size = round(_cell_index_dynamic(size, info.vs, 2)) // Two additional vs for scratch storage
    return size
}

// Query the load factor of the map. This is not actually configurable, but
// some math is needed to compute it. Compute it as a fixed point percentage to
// avoid floating point operations. This division can be optimized out by
// multiplying by the multiplicative inverse of 100.
load_factor :: #force_inline proc(cap: uint) -> uint {
    return (cap * MAP_LOAD_FACTOR) / 100
}


_probe_distance :: #force_inline proc(m: Map, hash: Map_Hash, slot: uintptr) -> uintptr {
    return (slot + m.cap - _desired_position(m, hash)) & (m.cap - 1)
}

// Computes the desired position in the array. This is just index % capacity,
// but a procedure as there's some math involved here to recover the capacity.
_desired_position :: #force_inline proc(m: Map, hash: Map_Hash) -> uintptr {
    return uintptr(hash & Map_Hash(m.cap - 1))
}


seed :: #force_inline proc(m: Map) -> uintptr {
    return _seed_from_map_data(m.data)
}

// splitmix for uintptr
_seed_from_map_data :: #force_inline proc(data: uintptr) -> uintptr {
    when size_of(uintptr) == size_of(u64) {
        mix := data + 0x9e3779b97f4a7c15
        mix = (mix ~ (mix >> 30)) * 0xbf58476d1ce4e5b9
        mix = (mix ~ (mix >> 27)) * 0x94d049bb133111eb
        return mix ~ (mix >> 31)
    } else {
        mix := data + 0x9e3779b9
        mix = (mix ~ (mix >> 16)) * 0x21f0aaad
        mix = (mix ~ (mix >> 15)) * 0x735a2d97
        return mix ~ (mix >> 15)
    }
}




//--------------------------------------------------------------------------------------------------
// Raw Map stuff
//--------------------------------------------------------------------------------------------------

// We always round the cap to a power of two so this becomes [16]Foo, which
// works out to [4]Cell(Foo).
//
// The following compile-time procedure indexes such a [N]Cell(T) structure as
// if it were a flat array accounting for the internal padding introduced by the
// Cell structure.
map_cell_index_static :: #force_inline proc(cells: [^]Map_Cell($T), index: uintptr) -> ^T #no_bounds_check {
    N :: size_of(Map_Cell(T){}.data) / size_of(T) when size_of(T) > 0 else 1

    #assert(N <= MAP_CACHE_LINE_SIZE)

    when size_of(Map_Cell(T)) == size_of([N]T) {
        // No padding case, can treat as a regular array of []T.

        return &([^]T)(cells)[index]
    } else when (N & (N - 1)) == 0 && N <= 8*size_of(uintptr) {
        // Likely case, N is a power of two because T is a power of two.

        // Unique case, no need to index data here since only one element.
        when N == 1 {
            return &cells[index].data[0]
        }

        // Compute the integer log 2 of N, this is the shift amount to index the
        // correct cell. Odin's intrinsics.count_leading_zeros does not produce a
        // constant, hence this approach. We only need to check up to N = 64.
        SHIFT :: 1 when N == 2  else
                 2 when N == 4  else
                 3 when N == 8  else
                 4 when N == 16 else
                 5 when N == 32 else 6
        #assert(SHIFT <= MAP_CACHE_LINE_LOG2)
        return &cells[index >> SHIFT].data[index & (N - 1)]
    } else {
        // Least likely (and worst case), we pay for a division operation but we
        // assume the compiler does not actually generate a division. N will be in the
        // range [1, CACHE_LINE_SIZE) and not a power of two.
        return &cells[index / N].data[index % N]
    }
}


map_kvh_data_static :: #force_inline proc(m: Map($K, $V)) -> (ks: [^]Map_Cell(K), vs: [^]Map_Cell(V), hs: [^]Map_Hash) {
    cap := uintptr(m.cap)
    ks = ([^]Map_Cell(K))(m.data)
    vs = ([^]Map_Cell(V))(map_cell_index_static(ks, cap))
    hs = ([^]Map_Hash)(map_cell_index_static(vs, cap))
    return
}


raw_map_dynamic_kvh_data_values :: proc(m: Map, info: ^Map_Info) -> (vs: uintptr) {
    return _cell_index_dynamic(m.data, info.ks, m.cap) // Skip past ks to get start of vs
}

raw_map_dynamic_exists :: #force_no_inline proc(m: Map, info: ^Map_Info, k: uintptr) -> (ok: bool) {
    if raw_map_len(m) == 0 {
        return false
    }
    h := info.key_hasher(rawptr(k), seed(m))
    p := _desired_position(m, h)
    d := uintptr(0)
    c := uintptr(m.cap) - 1
    ks, _, hs, _, _ := _map_kvh_data_dynamic(m, info)
    for {
        element_hash := hs[p]
        if hash_is_empty(element_hash) {
            return false
        } else if d > _probe_distance(m, element_hash, p) {
            return false
        } else if element_hash == h && info.key_equal(rawptr(k), rawptr(_cell_index_dynamic(ks, info.ks, p))) {
            return true
        }
        p = (p + 1) & c
        d += 1
    }
}

raw_map_dynamic_lookup :: #force_no_inline proc(m: Map, info: ^Map_Info, k: uintptr) -> (index: uintptr, ok: bool) {
    if raw_map_len(m) == 0 {
        return 0, false
    }
    h := info.key_hasher(rawptr(k), seed(m))
    p := _desired_position(m, h)
    d := uintptr(0)
    c := uintptr(m.cap) - 1
    ks, _, hs, _, _ := _map_kvh_data_dynamic(m, info)
    for {
        element_hash := hs[p]
        if hash_is_empty(element_hash) {
            return 0, false
        } else if d > _probe_distance(m, element_hash, p) {
            return 0, false
        } else if element_hash == h && info.key_equal(rawptr(k), rawptr(_cell_index_dynamic(ks, info.ks, p))) {
            return p, true
        }
        p = (p + 1) & c
        d += 1
    }
}

raw_map_dynamic_erase :: #force_no_inline proc(m: ^Map, info: ^Map_Info, k: uintptr) -> (old_k, old_v: uintptr, ok: bool) {
    index := raw_map_dynamic_lookup(m^, info, k) or_return
    ks, vs, hs, _, _ := _map_kvh_data_dynamic(m^, info)
    hs[index] |= TOMBSTONE_MASK
    old_k = _cell_index_dynamic(ks, info.ks, index)
    old_v = _cell_index_dynamic(vs, info.vs, index)
    m.len -= 1
    ok = true

    mask := uintptr(m.cap) - 1
    curr_index := uintptr(index)
    next_index := (curr_index + 1) & mask

    // if the next element is empty or has zero probe distance, then any lookup
    // will always fail on the next, so we can clear both of them
    hash := hs[next_index]
    if hash_is_empty(hash) || _probe_distance(m^, hash, next_index) == 0 {
        hs[curr_index] = 0
    } else {
        hs[curr_index] |= TOMBSTONE_MASK
    }

    return
}

raw_map_dynamic_get_key_and_value :: proc(m: ^Map, info: ^Map_Info, h: Map_Hash, key: rawptr) -> (key_ptr, value_ptr: rawptr) {
    if m.len == 0 {
        return nil, nil
    }
    pos := _desired_position(m^, h)
    distance := uintptr(0)
    mask := uintptr(m.cap) - 1
    ks, vs, hs, _, _ := _map_kvh_data_dynamic(m^, info)
    for {
        element_hash := hs[pos]
        if hash_is_empty(element_hash) {
            return nil, nil
        } else if distance > _probe_distance(m^, element_hash, pos) {
            return nil, nil
        } else if element_hash == h {
            other_key := rawptr(_cell_index_dynamic(ks, info.ks, pos))
            if info.key_equal(key, other_key) {
                key_ptr   = other_key
                value_ptr = rawptr(_cell_index_dynamic(vs, info.vs, pos))
                return
            }
        }
        pos = (pos + 1) & mask
        distance += 1
    }
}



raw_map_dynamic_set_without_hash :: proc(m: ^Map, info: ^Map_Info, key, value: rawptr, loc := #caller_location) -> rawptr {
    return _dynamic_set(m, info, info.key_hasher(key, seed(m^)), key, value, loc)
}

_dynamic_set :: proc(m: ^Map, info: ^Map_Info, hash: Map_Hash, key, value: rawptr, loc := #caller_location) -> rawptr {
    if found := _dynamic_get(m, info, hash, key); found != nil {
        intrinsics.mem_copy_non_overlapping(found, value, info.vs.size_of_type)
        return found
    }

    hash := hash
    err, has_grown := _check_grow(m, info, loc)
    if err != nil {
        return nil
    }
    if has_grown {
        hash = info.key_hasher(key, seed(m^))
    }

    _, result := insert_hash_dynamic_with_key(m, info, hash, uintptr(key), uintptr(value))
    if result != 0 {
        m.len += 1
    }
    return rawptr(result)
}

_dynamic_get :: proc(m: ^Map, info: ^Map_Info, h: Map_Hash, key: rawptr) -> (ptr: rawptr) {
    if m.len == 0 {
        return nil
    }
    pos := _desired_position(m^, h)
    distance := uintptr(0)
    mask := m.cap - 1
    ks, vs, hs, _, _ := _map_kvh_data_dynamic(m^, info)
    for {
        element_hash := hs[pos]
        if hash_is_empty(element_hash) {
            return nil
        } else if distance > _probe_distance(m^, element_hash, pos) {
            return nil
        } else if element_hash == h && info.key_equal(key, rawptr(_cell_index_dynamic(ks, info.ks, pos))) {
            return rawptr(_cell_index_dynamic(vs, info.vs, pos))
        }
        pos = (pos + 1) & mask
        distance += 1
    }
}




raw_map_dynamic_set_extra_without_hash :: proc(m: ^Map, info: ^Map_Info, key, value: rawptr, loc := #caller_location) -> (prev_key_ptr, value_ptr: rawptr) {
    return raw_map_dynamic_set_extra(m, info, info.key_hasher(key, seed(m^)), key, value, loc)
}

raw_map_dynamic_set_extra :: proc(m: ^Map, info: ^Map_Info, hash: Map_Hash, key, value: rawptr, loc := #caller_location) -> (prev_key_ptr, value_ptr: rawptr) {
    if prev_key_ptr, value_ptr = raw_map_dynamic_get_key_and_value(m, info, hash, key); value_ptr != nil {
        mem.copy_non_overlapping(value_ptr, value, info.vs.size_of_type)
        return
    }

    hash := hash
    err, has_grown := _check_grow(m, info, loc)
    if err != nil {
        return nil, nil
    }
    if has_grown {
        hash = info.key_hasher(key, seed(m^))
    }

    _, result := insert_hash_dynamic_with_key(m, info, hash, uintptr(key), uintptr(value))
    if result != 0 {
        m.len += 1
    }
    return nil, rawptr(result)
}

raw_map_dynamic_entry :: proc(m: ^Map, info: ^Map_Info, key: rawptr, zero: rawptr, loc := #caller_location) -> (key_ptr: rawptr, value_ptr: rawptr, just_inserted: bool, err: mem.Allocator_Error) {
    hash := info.key_hasher(key, seed(m^))

    if key_ptr, value_ptr = raw_map_dynamic_get_key_and_value(m, info, hash, key); value_ptr != nil {
        return
    }

    has_grown: bool
    if err, has_grown = _check_grow(m, info, loc); err != nil {
        return
    } else if has_grown {
        hash = info.key_hasher(key, seed(m^))
    }

    kp, vp := insert_hash_dynamic_with_key(m, info, hash, uintptr(key), uintptr(zero))
    key_ptr   = rawptr(kp)
    value_ptr = rawptr(vp)

    m.len += 1
    just_inserted = true
    return
}


//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(disabled=ODIN_NO_BOUNDS_CHECK)
map_expr_create_error_loc :: #force_inline proc(loc := #caller_location, cap: uint) {
    if 0 <= cap {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(loc: Source_Code_Location, cap: uint)  -> ! {
        print_caller_location(loc)
        print_string(" Invalid map cap for make: ")
        print_i64(i64(cap))
        print_byte('\n')
        bounds_trap()
    }
    handle_error(loc, cap)
}

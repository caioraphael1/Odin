import "base:mem"
import "base:internal"
import "base:intrinsics"

MAP_CACHE_LINE_SIZE :: internal.MAP_CACHE_LINE_SIZE
TOMBSTONE_MASK :: internal.TOMBSTONE_MASK

Raw_Map  :: internal.Raw_Map
Map_Cell :: internal.Map_Cell
Map_Hash :: internal.Map_Hash
Map_Info :: internal.Map_Info



// `map_create` initializes a map with an allocator. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
map_create :: proc($T: typeid/map[$K]$E, allocator: mem.Allocator, loc := #caller_location) -> (m: T) {
    m.allocator = allocator
    return m
}

// `map_create_cap` initializes a map with an allocator and allocates space using `capacity`.
// Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
map_create_cap :: proc($T: typeid/map[$K]$E, #any_int capacity: int, allocator: mem.Allocator, loc := #caller_location) -> (m: T, err: mem.Allocator_Error) {
    map_expr_create_error_loc(loc, capacity)
    m.allocator = allocator
    err = map_reserve(&m, capacity, loc)
    return
}

// `map_clear` will set the length of a passed map to `0`
map_clear :: proc(m: ^$T/map[$K]$V) {
    if m == nil {
        return
    }
    map_clear_dynamic((^Raw_Map)(m), map_info(T))
}

// `map_delete` will try to free the underlying data of the passed map, with the given `allocator` if the allocator supports this operation.
map_delete :: proc(m: $T/map[$K]$V, loc := #caller_location) -> mem.Allocator_Error {
    return internal.map_free_dynamic(transmute(Raw_Map)m, map_info(T), loc)
}

// `map_reserve` will try to reserve memory of a passed map to the requested element count (setting the `cap`).
map_reserve :: proc(m: ^$T/map[$K]$V, #any_int capacity: int, loc := #caller_location) -> mem.Allocator_Error {
    return __dynamic_map_reserve((^Raw_Map)(m), map_info(T), uint(capacity), loc)
}

// Shrinks the capacity of a map down to the current length.
map_shrink :: proc(m: ^$T/map[$K]$V, loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    if m != nil {
        return map_shrink_dynamic((^Raw_Map)(m), map_info(T), loc)
    }
    return
}

@(optional_results)
map_insert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (ptr: ^V) {
    key, value := key, value
    return (^V)(dynamic_map_set_without_hash((^Raw_Map)(m), map_info(T), rawptr(&key), rawptr(&value), loc))
}

// Explicitly inserts a key and value into a map `m`, the same as `map_insert`, but the return values differ.
// - `prev_key` will return the previous pointer of a key if it exists, check `found_previous` if was previously found
// - `value_ptr` will return the pointer of the memory where the insertion happens, and `nil` if the map failed to resize
// - `found_previous` will be true a previous key was found
map_upsert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (prev_key: K, value_ptr: ^V, found_previous: bool) {
    key, value := key, value
    kp, vp := dynamic_map_set_extra_without_hash((^Raw_Map)(m), map_info(T), rawptr(&key), rawptr(&value), loc)
    if kp != nil {
        prev_key = (^K)(kp)^
        found_previous = true
    }
    value_ptr = (^V)(vp)
    return
}

// The map_delete_key built-in procedure deletes the element with the specified key (m[key]) from the map.
// If m is nil, or there is no such element, this procedure is a no-op
@(optional_results)
map_delete_key :: proc(m: ^$T/map[$K]$V, key: K) -> (deleted_key: K, deleted_value: V) {
    if m != nil {
        key := key
        old_k, old_v, ok := map_erase_dynamic((^Raw_Map)(m), map_info(T), uintptr(&key))
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
map_entry :: proc(m: ^$T/map[$K]$V, key: K, loc := #caller_location) -> (key_ptr: ^K, value_ptr: ^V, just_inserted: bool, err: mem.Allocator_Error) {
    key := key
    zero: V

    _key_ptr, _value_ptr: rawptr
    _key_ptr, _value_ptr, just_inserted, err = dynamic_map_entry((^Raw_Map)(m), map_info(T), &key, &zero, loc)

    key_ptr   = (^K)(_key_ptr)
    value_ptr = (^V)(_value_ptr)
    return
}



map_keys :: proc(m: $M/map[$K]$V, allocator: mem.Allocator, loc := #caller_location) -> (keys: []K, err: mem.Allocator_Error) {
    keys = make(type_of(keys), len(m), allocator, loc) or_return
    i := 0
    for key in m {
        keys[i] = key
        i += 1
    }
    return
}
map_values :: proc(m: $M/map[$K]$V, allocator: mem.Allocator, loc := #caller_location) -> (values: []V, err: mem.Allocator_Error) {
    values = make(type_of(values), len(m), allocator, loc) or_return
    i := 0
    for _, value in m {
        values[i] = value
        i += 1
    }
    return
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


map_entries :: proc(m: $M/map[$K]$V, allocator: mem.Allocator, loc := #caller_location) -> (entries: []Map_Entry(K, V), err: mem.Allocator_Error) {
    entries = make(type_of(entries), len(m), allocator, loc) or_return
    i := 0
    for key, value in m {
        entries[i].key   = key
        entries[i].value = value
        i += 1
    }
    return
}

map_entry_infos :: proc(m: $M/map[$K]$V, allocator: mem.Allocator, loc := #caller_location) -> (entries: []Map_Entry_Info(K, V), err: mem.Allocator_Error) #no_bounds_check {
    m := m
    rm := (^internal.Raw_Map)(&m)

    info := internal.type_info_base(type_info_of(M)).variant.(internal.Type_Info_Map)
    if info.map_info != nil {
        entries = make(type_of(entries), len(m), allocator, loc) or_return

        map_cap := uintptr(cap(m))
        ks, vs, hs, _, _ := internal.map_kvh_data_dynamic(rm^, info.map_info)
        entry_index := 0
        for bucket_index in 0..<map_cap {
            if hash := hs[bucket_index]; internal.map_hash_is_valid(hash) {
                key   := internal.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index)
                value := internal.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index)
                entries[entry_index].hash  = hash
                entries[entry_index].key   = (^K)(key)^
                entries[entry_index].value = (^V)(value)^

                entry_index += 1
            }
        }
    }
    return
}


//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(disabled=ODIN_NO_BOUNDS_CHECK)
map_expr_create_error_loc :: #force_inline proc(loc := #caller_location, cap: int) {
    if 0 <= cap {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(loc: internal.Source_Code_Location, cap: int)  -> ! {
        internal.print_caller_location(loc)
        internal.print_string(" Invalid map capacity for make: ")
        internal.print_i64(i64(cap))
        internal.print_byte('\n')
        internal.bounds_trap()
    }
    handle_error(loc, cap)
}

// map_cell_info :: proc($T: typeid) -> ^Map_Cell_Info {...}
map_cell_info :: intrinsics.type_map_cell_info


// We always round the capacity to a power of two so this becomes [16]Foo, which
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

map_len :: #force_inline proc(m: Raw_Map) -> int {
    return int(m.len)
}


map_hash_is_valid :: #force_inline proc(hash: Map_Hash) -> bool {
    // The MSB indicates a tombstone
    return (hash != 0) & (hash & TOMBSTONE_MASK == 0)
}


// The Map_Info structure is basically a pseudo-table of information for a given K and V pair.
// map_info :: proc($T: typeid/map[$K]$V) -> ^Map_Info {...}
map_info :: intrinsics.type_map_info


map_kvh_data_values_dynamic :: proc(m: Raw_Map, #no_alias info: ^Map_Info) -> (vs: uintptr) {
    capacity := uintptr(1) << internal.map_log2_cap(m)
    return internal.map_cell_index_dynamic(internal.map_data(m), info.ks, capacity) // Skip past ks to get start of vs
}

map_total_allocation_size_from_value :: #force_inline proc(m: $M/map[$K]$V) -> uintptr {
    return map_total_allocation_size(uintptr(cap(m)), map_info(M))
}



map_shrink_dynamic :: #force_no_inline proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    assert(m.allocator.procedure != nil)

    // Cannot shrink the capacity if the number of items in the map would exceed
    // one minus the current log2 capacity's resize threshold. That is the shrunk
    // map needs to be within the max load factor.
    log2_capacity := internal.map_log2_cap(m^)
    if uintptr(m.len) >= internal.map_load_factor(log2_capacity - 1) {
        return false, nil
    }

    shrunk := internal.map_alloc_dynamic(info, log2_capacity - 1, m.allocator) or_return

    capacity := uintptr(1) << log2_capacity

    ks, vs, hs, _, _ := internal.map_kvh_data_dynamic(m^, info)

    n := m.len
    for i in 0..<capacity {
        hash := hs[i]
        if internal.map_hash_is_empty(hash) {
            continue
        }
        if internal.map_hash_is_deleted(hash) {
            continue
        }

        k := internal.map_cell_index_dynamic(ks, info.ks, i)
        v := internal.map_cell_index_dynamic(vs, info.vs, i)
        hash = info.key_hasher(rawptr(k), internal.map_seed(shrunk))
        _ = internal.__map_insert_hash_dynamic(&shrunk, info, hash, k, v)
        // Only need to do this comparison on each actually added pair, so do not
        // fold it into the for loop comparator as a micro-optimization.
        n -= 1
        if n == 0 {
            break
        }
    }

    internal.map_free_dynamic(m^, info, loc) or_return
    m.data = shrunk.data
    return true, nil
}


map_lookup_dynamic :: #force_no_inline proc(m: Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (index: uintptr, ok: bool) {
    if map_len(m) == 0 {
        return 0, false
    }
    h := info.key_hasher(rawptr(k), internal.map_seed(m))
    p := internal.__map_desired_position(m, h)
    d := uintptr(0)
    c := (uintptr(1) << internal.map_log2_cap(m)) - 1
    ks, _, hs, _, _ := internal.map_kvh_data_dynamic(m, info)
    for {
        element_hash := hs[p]
        if internal.map_hash_is_empty(element_hash) {
            return 0, false
        } else if d > internal.__map_probe_distance(m, element_hash, p) {
            return 0, false
        } else if element_hash == h && info.key_equal(rawptr(k), rawptr(internal.map_cell_index_dynamic(ks, info.ks, p))) {
            return p, true
        }
        p = (p + 1) & c
        d += 1
    }
}

map_exists_dynamic :: #force_no_inline proc(m: Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (ok: bool) {
    if map_len(m) == 0 {
        return false
    }
    h := info.key_hasher(rawptr(k), internal.map_seed(m))
    p := internal.__map_desired_position(m, h)
    d := uintptr(0)
    c := (uintptr(1) << internal.map_log2_cap(m)) - 1
    ks, _, hs, _, _ := internal.map_kvh_data_dynamic(m, info)
    for {
        element_hash := hs[p]
        if internal.map_hash_is_empty(element_hash) {
            return false
        } else if d > internal.__map_probe_distance(m, element_hash, p) {
            return false
        } else if element_hash == h && info.key_equal(rawptr(k), rawptr(internal.map_cell_index_dynamic(ks, info.ks, p))) {
            return true
        }
        p = (p + 1) & c
        d += 1
    }
}

map_erase_dynamic :: #force_no_inline proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, k: uintptr) -> (old_k, old_v: uintptr, ok: bool) {
    index := map_lookup_dynamic(m^, info, k) or_return
    ks, vs, hs, _, _ := internal.map_kvh_data_dynamic(m^, info)
    hs[index] |= TOMBSTONE_MASK
    old_k = internal.map_cell_index_dynamic(ks, info.ks, index)
    old_v = internal.map_cell_index_dynamic(vs, info.vs, index)
    m.len -= 1
    ok = true

    mask := (uintptr(1)<<internal.map_log2_cap(m^)) - 1
    curr_index := uintptr(index)
    next_index := (curr_index + 1) & mask

    // if the next element is empty or has zero probe distance, then any lookup
    // will always fail on the next, so we can clear both of them
    hash := hs[next_index]
    if internal.map_hash_is_empty(hash) || internal.__map_probe_distance(m^, hash, next_index) == 0 {
        hs[curr_index] = 0
    } else {
        hs[curr_index] |= TOMBSTONE_MASK
    }

    return
}


map_kvh_data_static :: #force_inline proc(m: $T/map[$K]$V) -> (ks: [^]Map_Cell(K), vs: [^]Map_Cell(V), hs: [^]Map_Hash) {
    capacity := uintptr(cap(m))
    ks = ([^]Map_Cell(K))(internal.map_data(transmute(Raw_Map)m))
    vs = ([^]Map_Cell(V))(map_cell_index_static(ks, capacity))
    hs = ([^]Map_Hash)(map_cell_index_static(vs, capacity))
    return
}

map_get :: proc(m: $T/map[$K]$V, key: K) -> (stored_key: K, stored_value: V, ok: bool) {
    rm := transmute(Raw_Map)m
    if rm.len == 0 {
        return
    }
    info := intrinsics.type_map_info(T)
    key := key

    h := info.key_hasher(&key, internal.map_seed(rm))
    pos := internal.__map_desired_position(rm, h)
    distance := uintptr(0)
    mask := (uintptr(1) << internal.map_log2_cap(rm)) - 1
    ks, vs, hs := map_kvh_data_static(m)
    for {
        element_hash := hs[pos]
        if internal.map_hash_is_empty(element_hash) {
            return
        } else if distance > internal.__map_probe_distance(rm, element_hash, pos) {
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

dynamic_map_get_key_and_value :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, key: rawptr) -> (key_ptr, value_ptr: rawptr) {
    if m.len == 0 {
        return nil, nil
    }
    pos := internal.__map_desired_position(m^, h)
    distance := uintptr(0)
    mask := (uintptr(1) << internal.map_log2_cap(m^)) - 1
    ks, vs, hs, _, _ := internal.map_kvh_data_dynamic(m^, info)
    for {
        element_hash := hs[pos]
        if internal.map_hash_is_empty(element_hash) {
            return nil, nil
        } else if distance > internal.__map_probe_distance(m^, element_hash, pos) {
            return nil, nil
        } else if element_hash == h {
            other_key := rawptr(internal.map_cell_index_dynamic(ks, info.ks, pos))
            if info.key_equal(key, other_key) {
                key_ptr   = other_key
                value_ptr = rawptr(internal.map_cell_index_dynamic(vs, info.vs, pos))
                return
            }
        }
        pos = (pos + 1) & mask
        distance += 1
    }
}

dynamic_map_set_without_hash :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, key, value: rawptr, loc := #caller_location) -> rawptr {
    return internal.__dynamic_map_set(m, info, info.key_hasher(key, internal.map_seed(m^)), key, value, loc)
}

dynamic_map_set_extra_without_hash :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, key, value: rawptr, loc := #caller_location) -> (prev_key_ptr, value_ptr: rawptr) {
    return dynamic_map_set_extra(m, info, info.key_hasher(key, internal.map_seed(m^)), key, value, loc)
}

dynamic_map_set_extra :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, hash: Map_Hash, key, value: rawptr, loc := #caller_location) -> (prev_key_ptr, value_ptr: rawptr) {
    if prev_key_ptr, value_ptr = dynamic_map_get_key_and_value(m, info, hash, key); value_ptr != nil {
        intrinsics.mem_copy_non_overlapping(value_ptr, value, info.vs.size_of_type)
        return
    }

    hash := hash
    err, has_grown := internal.__dynamic_map_check_grow(m, info, loc)
    if err != nil {
        return nil, nil
    }
    if has_grown {
        hash = info.key_hasher(key, internal.map_seed(m^))
    }

    result := internal.__map_insert_hash_dynamic(m, info, hash, uintptr(key), uintptr(value))
    if result != 0 {
        m.len += 1
    }
    return nil, rawptr(result)
}

dynamic_map_entry :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, key: rawptr, zero: rawptr, loc := #caller_location) -> (key_ptr: rawptr, value_ptr: rawptr, just_inserted: bool, err: mem.Allocator_Error) {
    hash := info.key_hasher(key, internal.map_seed(m^))

    if key_ptr, value_ptr = dynamic_map_get_key_and_value(m, info, hash, key); value_ptr != nil {
        return
    }

    has_grown: bool
    if err, has_grown = internal.__dynamic_map_check_grow(m, info, loc); err != nil {
        return
    } else if has_grown {
        hash = info.key_hasher(key, internal.map_seed(m^))
    }

    kp, vp := internal.map_insert_hash_dynamic_with_key(m, info, hash, uintptr(key), uintptr(zero))
    key_ptr   = rawptr(kp)
    value_ptr = rawptr(vp)

    m.len += 1
    just_inserted = true
    return
}





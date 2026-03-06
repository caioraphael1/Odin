
// `map_create` initializes a map with an allocator. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
@(builtin)
map_create :: proc($T: typeid/map[$K]$E, allocator: Allocator, loc := #caller_location) -> (m: T) {
    m.allocator = allocator
    return m
}

// `map_create_cap` initializes a map with an allocator and allocates space using `capacity`.
// Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
@(builtin)
map_create_cap :: proc($T: typeid/map[$K]$E, #any_int capacity: int, allocator: Allocator, loc := #caller_location) -> (m: T, err: Allocator_Error) {
    map_expr_create_error_loc(loc, capacity)
    m.allocator = allocator
    err = map_reserve(&m, capacity, loc)
    return
}

// `map_clear` will set the length of a passed map to `0`
@(builtin)
map_clear :: proc(m: ^$T/map[$K]$V) {
    if m == nil {
        return
    }
    map_clear_dynamic((^Raw_Map)(m), map_info(T))
}

// `map_delete` will try to free the underlying data of the passed map, with the given `allocator` if the allocator supports this operation.
@(builtin)
map_delete :: proc(m: $T/map[$K]$V, loc := #caller_location) -> Allocator_Error {
    return map_free_dynamic(transmute(Raw_Map)m, map_info(T), loc)
}

// `map_reserve` will try to reserve memory of a passed map to the requested element count (setting the `cap`).
@(builtin)
map_reserve :: proc(m: ^$T/map[$K]$V, #any_int capacity: int, loc := #caller_location) -> Allocator_Error {
    return __dynamic_map_reserve((^Raw_Map)(m), map_info(T), uint(capacity), loc)
}

// Shrinks the capacity of a map down to the current length.
@(builtin)
map_shrink :: proc(m: ^$T/map[$K]$V, loc := #caller_location) -> (did_shrink: bool, err: Allocator_Error) {
    if m != nil {
        return map_shrink_dynamic((^Raw_Map)(m), map_info(T), loc)
    }
    return
}

@(builtin, optional_results)
map_insert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (ptr: ^V) {
    key, value := key, value
    return (^V)(__dynamic_map_set_without_hash((^Raw_Map)(m), map_info(T), rawptr(&key), rawptr(&value), loc))
}

// Explicitly inserts a key and value into a map `m`, the same as `map_insert`, but the return values differ.
// - `prev_key` will return the previous pointer of a key if it exists, check `found_previous` if was previously found
// - `value_ptr` will return the pointer of the memory where the insertion happens, and `nil` if the map failed to resize
// - `found_previous` will be true a previous key was found
@(builtin)
map_upsert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (prev_key: K, value_ptr: ^V, found_previous: bool) {
    key, value := key, value
    kp, vp := __dynamic_map_set_extra_without_hash((^Raw_Map)(m), map_info(T), rawptr(&key), rawptr(&value), loc)
    if kp != nil {
        prev_key = (^K)(kp)^
        found_previous = true
    }
    value_ptr = (^V)(vp)
    return
}

// The map_delete_key built-in procedure deletes the element with the specified key (m[key]) from the map.
// If m is nil, or there is no such element, this procedure is a no-op
@(builtin, optional_results)
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
@(builtin)
map_entry :: proc(m: ^$T/map[$K]$V, key: K, loc := #caller_location) -> (key_ptr: ^K, value_ptr: ^V, just_inserted: bool, err: Allocator_Error) {
    key := key
    zero: V

    _key_ptr, _value_ptr: rawptr
    _key_ptr, _value_ptr, just_inserted, err = __dynamic_map_entry((^Raw_Map)(m), map_info(T), &key, &zero, loc)

    key_ptr   = (^K)(_key_ptr)
    value_ptr = (^V)(_value_ptr)
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
    handle_error :: proc(loc: Source_Code_Location, cap: int)  -> ! {
        print_caller_location(loc)
        print_string(" Invalid map capacity for make: ")
        print_i64(i64(cap))
        print_byte('\n')
        bounds_trap()
    }
    handle_error(loc, cap)
}


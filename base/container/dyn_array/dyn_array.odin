import "base:internal"
import "base:intrinsics"
import "base:mem"

import base_slice "base:container/slice"
    // only base_slice.copy


DEFAULT_DYNAMIC_ARRAY_CAPACITY :: 8

Dyn_Array :: struct($T: typeid) {
    data:      [^]T,
    len:       uint,
    cap:       uint,
    allocator: mem.Allocator,
}


init :: proc(a: ^Dyn_Array($T), allocator: mem.Allocator) {
    a^ = {} // Reset the struct first.
    a.allocator = allocator
}

create :: proc($T: typeid, allocator: mem.Allocator) -> (a: Dyn_Array(T)) {
    a.allocator = allocator
    return
}

create_len :: proc($T: typeid, len: uint, allocator: mem.Allocator, loc := #caller_location) -> (a: Dyn_Array(T), err: mem.Allocator_Error) {
    err = _dyn_array_init_len_cap(&a, size_of(T), align_of(T), len, len, allocator, loc)
    return
}

create_len_cap :: proc($T: typeid, len: uint, cap: uint, allocator: mem.Allocator, loc := #caller_location) -> (a: Dyn_Array(T), err: mem.Allocator_Error) {
    err = _dyn_array_init_len_cap(&a, size_of(T), align_of(T), len, cap, allocator, loc)
    return
}


create_from_slice :: proc(backing: []$T) -> Dyn_Array(T) {
    return {
        data      = raw_data(backing),
        len       = 0,
        cap       = len(backing),
        allocator = {
            procedure = {},
            data      = nil,
        },
    }
}


_dyn_array_init_len_cap :: proc(a: ^Dyn_Array($T), size_of_elem, align_of_elem: uint, len: uint, cap: uint, allocator: mem.Allocator, loc := #caller_location) -> (err: mem.Allocator_Error) {
    if len < 0 || len > cap {
        return .Invalid_Argument
    }
    if cap == 0 {
        return .Invalid_Argument
    }
    a.allocator = allocator // initialize allocator before just in case it fails to allocate any memory
    data := mem.alloc(size_of_elem*cap, align_of_elem, allocator, loc) or_return
    use_zero := data == nil && size_of_elem != 0
    a.data = ([^]T)(raw_data(data))
    a.len = 0 if use_zero else len
    a.cap = 0 if use_zero else cap
    return
}


clear :: proc(a: ^Dyn_Array($T)) {
    a.len = 0
}

delete :: proc(a: Dyn_Array($T), loc := #caller_location) -> mem.Allocator_Error {
    return mem.free_with_size(a.data, a.cap * size_of(T), a.allocator, loc)
}

slice :: proc(a: Dyn_Array($T)) -> []T {
    return a.data[:a.len]
}

append :: proc(a: ^Dyn_Array($T), #no_broadcast arg: T, loc := #caller_location) -> (err: mem.Allocator_Error) {
    // where !intrinsics.type_is_string(T) {
    arg := arg
    return _append(a, size_of(T), align_of(T), &arg, true, loc=loc)
}

append_non_zero :: proc(a: ^Dyn_Array($T), #no_broadcast arg: T, loc := #caller_location) -> (err: mem.Allocator_Error) {
    // where !intrinsics.type_is_string(T) {
    arg := arg
    return _append(a, size_of(T), align_of(T), &arg, false, loc=loc)
}

_append :: #force_no_inline proc(a: ^Dyn_Array($T), size_of_elem, align_of_elem: uint, arg_ptr: rawptr, should_zero: bool, loc := #caller_location) -> (err: mem.Allocator_Error) {
    if a.cap < a.len + 1 {
        // Same behavior as _append_many but there's only one arg, so we always just add DEFAULT_DYNAMIC_ARRAY_CAPACITY.
        cap := 2 * a.cap + DEFAULT_DYNAMIC_ARRAY_CAPACITY

        // do not 'or_return' here as it could be a partial success
        err = _reserve(a, size_of_elem, align_of_elem, cap, should_zero, loc)
    }
    if a.cap - a.len > 0 {
        internal.assert(a.data != nil, loc=loc)
        mem.copy_non_overlapping(a.data[a.len:], arg_ptr, size_of_elem) // must be mem_copy (overlapping)
        a.len += 1
    }
    return
}

append_many :: proc(a: ^Dyn_Array($T), #no_broadcast args: ..T, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_many(a, size_of(T), align_of(T), true, loc, raw_data(args), len(args))
}

append_many_non_zero :: proc(a: ^Dyn_Array($T), #no_broadcast args: ..T, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_many(a, size_of(T), align_of(T), false, loc, raw_data(args), len(args))
}

_append_many :: #force_no_inline proc(a: ^Dyn_Array($T), size_of_elem, align_of_elem: uint, should_zero: bool, loc := #caller_location, args: rawptr, arg_len: uint) -> (err: mem.Allocator_Error) {
    if arg_len <= 0 {
        return nil
    }

    if a.cap < a.len + arg_len {
        cap := 2 * a.cap + max(DEFAULT_DYNAMIC_ARRAY_CAPACITY, arg_len)

        // do not 'or_return' here as it could be a partial success
        err = _reserve(a, size_of_elem, align_of_elem, cap, should_zero, loc)
    }
    arg_len := arg_len
    arg_len = min(a.cap - a.len, arg_len)
    if arg_len > 0 {
        internal.assert(a.data != nil, loc=loc)
        intrinsics.mem_copy(a.data[a.len:], args, arg_len * size_of_elem) // must be mem_copy (overlapping)
        a.len += arg_len
    }
    return err
}

append_string_to_bytes :: proc(a: ^Dyn_Array(u8), arg: string, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_string(a, arg, true, loc)
}

append_string_to_bytes_non_zero :: proc(a: ^Dyn_Array(u8), arg: string, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_string(a, arg, false, loc)
}

append_many_strings_to_bytes :: proc(a: ^Dyn_Array($T), args: ..string, loc := #caller_location) -> (err: mem.Allocator_Error) {
    for arg in args {
        _append_string(a, arg, true, loc=loc) or_return
    }
    return
}

_append_string :: proc(a: ^Dyn_Array($T), arg: string, should_zero: bool, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_many(a, 1, 1, should_zero, loc, raw_data(arg), len(arg))
}


inject_at :: proc(a: ^Dyn_Array($T), index: uint, #no_broadcast arg: T, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(index >= 0, "Index must be positive.", loc)
    }
    if a == nil {
        return
    }
    n := max(a.len, index)
    m :: 1
    new_size := n + m

    resize(a, new_size, loc) or_return

    base_slice.copy(a.data[index + m:a.len], a.data[index:a.len])
    a.data[index] = arg

    ok = true
    return
}

inject_many_at :: proc(a: ^Dyn_Array($T), index: uint, #no_broadcast args: ..T, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) {
    n := max(a.len, index)
    m := len(args)
    new_size := n + m

    _ = resize(a, new_size, loc) or_return
    base_slice.copy(a.data[index + m:a.len], a.data[index:a.len])
    base_slice.copy(a.data[index:a.len], args)
    ok = true
    return
}

inject_string_at :: proc(a: ^Dyn_Array($T), index: uint, arg: string, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) {
    if a == nil {
        return
    }
    if len(arg) == 0 {
        ok = true
        return
    }

    n := max(a.len, index)
    m := len(arg)
    new_size := n + m

    _ = resize(a, new_size, loc) or_return
    base_slice.copy(a.data[index+m:a.len], a.data[index:a.len])
    base_slice.copy(a.data[index:a.len], arg)
    ok = true
    return
}


assign_at :: proc(a: ^Dyn_Array($T), index: uint, arg: T, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) {
    if index < a.len {
        a[index] = arg
        ok = true
    } else {
        _ = resize(a, index+1, loc) or_return
        a[index] = arg
        ok = true
    }
    return
}

assign_many_at :: proc(a: ^Dyn_Array($T), index: uint, #no_broadcast args: ..T, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) {
    new_size := index + len(args)
    if len(args) == 0 {
        ok = true
    } else if new_size < a.len {
        base_slice.copy(a.data[index:a.len], args)
        ok = true
    } else {
        _ = resize(a, new_size, loc) or_return
        base_slice.copy(a.data[index:a.len], args)
        ok = true
    }
    return
}

assign_string_at :: proc(a: ^Dyn_Array($T), index: uint, arg: string, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) {
    new_size := index + len(arg)
    if len(arg) == 0 {
        ok = true
    } else if new_size < a.len {
        base_slice.copy(a.data[index:a.len], arg)
        ok = true
    } else {
        _ = resize(a, new_size, loc) or_return
        base_slice.copy(a.data[index:a.len], arg)
        ok = true
    }
    return
}


unordered_remove :: proc(a: ^Dyn_Array($T), index: uint, loc := #caller_location) {
    internal.bounds_check_error_loc(loc, index, a.len)
    n := a.len - 1
    if index != n {
        a.data[index] = a.data[n]
    }
    a.len -= 1
}

unordered_remove_element :: proc(a: ^Dyn_Array($T), elem: T) -> (ok: bool) {
    if index, found := base_slice.linear_search(a.data[:a.len], elem); found {
        unordered_remove(a, index)
        return true
    }
    return false
}

ordered_remove :: proc(a: ^Dyn_Array($T), index: uint, loc := #caller_location) -> (ok: bool) {
    if uint(index) >= uint(a.len) {
        return false
    }
    if index + 1 < a.len {
        base_slice.copy(a.data[index:a.len], a.data[index+1:a.len])
    }
    a.len -= 1
    return true
}

remove_range :: proc(a: ^Dyn_Array($T), lo, hi: uint) -> (ok: bool) {
    if lo < 0 || lo > a.len || lo > hi || hi > a.len {
        return false
    }

    n := max(hi - lo, 0)
    if n > 0 {
        if hi != a.len {
            base_slice.copy(a.data[lo:a.len], a.data[hi:a.len])
        }
        a.len -= n
    }
    return true
}


pop_back :: proc(a: ^Dyn_Array($T)) -> (res: T, ok: bool) {
    if a.len == 0 {
        return
    }
    res, ok = a.data[a.len - 1], true
    a.len -= 1
    return
}

pop_front :: proc(a: ^Dyn_Array($T)) -> (res: T, ok: bool) {
    if a.len == 0 {
        return
    }
    res, ok = a[0], true
    if a.len > 1 {
        base_slice.copy(a.data[0:a.len], a.data[1:a.len])
    }
    a.len -= 1
    return
}


reserve :: proc(a: ^Dyn_Array($T), cap: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _reserve(a, size_of(T), align_of(T), cap, true, loc)
}

reserve_non_zero :: proc(a: ^Dyn_Array($T), cap: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _reserve(a, size_of(T), align_of(T), cap, false, loc)
}

_reserve :: #force_no_inline proc(a: ^Dyn_Array($T), size_of_elem, align_of_elem: uint, cap: uint, should_zero: bool, loc := #caller_location) -> mem.Allocator_Error {
    internal.assert(a.allocator.procedure != nil, "Allocator not defined", loc)

    if cap <= a.cap {
        return nil
    }

    old_size  := a.cap * size_of_elem
    new_size  := cap * size_of_elem
    allocator := a.allocator

    new_data: []u8
    if should_zero {
        new_data = mem.resize(a.data, old_size, new_size, align_of_elem, allocator, loc) or_return
    } else {
        new_data = mem.resize_non_zero(a.data, old_size, new_size, align_of_elem, allocator, loc) or_return
    }
    if new_data == nil && new_size > 0 {
        return .Out_Of_Memory
    }

    a.data = (^T)(raw_data(new_data))
    a.cap = cap
    return nil
}


resize :: proc(a: ^Dyn_Array($T), length: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _resize(a, size_of(T), align_of(T), length, true, loc)
}

resize_non_zero :: proc(a: ^Dyn_Array($T), length: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _resize(a, size_of(T), align_of(T), length, false, loc)
}

_resize :: #force_no_inline proc(a: ^Dyn_Array($T), size_of_elem, align_of_elem: uint, length: uint, should_zero: bool, loc := #caller_location) -> mem.Allocator_Error {    
    internal.assert(a.allocator.procedure != nil, "mem.Allocator not defined", loc)

    if should_zero && a.len < length {
        num_reused := min(a.cap, length) - a.len
        mem.zero(([^]u8)(a.data)[a.len * size_of_elem:], num_reused * size_of_elem)
    }

    if length <= a.cap {
        a.len = max(length, 0)
        return nil
    }

    old_size  := a.cap  * size_of_elem
    new_size  := length * size_of_elem

    new_data : []u8
    if should_zero {
        new_data = mem.resize(a.data, old_size, new_size, align_of_elem, a.allocator, loc) or_return
    } else {
        new_data = mem.resize_non_zero(a.data, old_size, new_size, align_of_elem, a.allocator, loc) or_return
    }
    if new_data == nil && new_size > 0 {
        return .Out_Of_Memory
    }

    a.data = (^T)(raw_data(new_data))
    a.len  = length
    a.cap  = length
    return nil
}


shrink :: proc(a: ^Dyn_Array($T), new_cap: uint, loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    return _shrink(a, size_of(T), align_of(T), new_cap, loc)
}

_shrink :: proc(a: ^Dyn_Array, size_of_elem, align_of_elem: uint, new_cap: uint, loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    internal.assert(a.allocator.procedure != nil, "mem.Allocator not defined", loc)

    if new_cap > a.cap {
        return
    }

    old_size := a.cap * size_of_elem
    new_size := new_cap * size_of_elem

    new_data := mem.resize(a.data, old_size, new_size, align_of_elem, a.allocator, loc) or_return

    a.data = raw_data(new_data)
    a.len = min(new_cap, a.len)
    a.cap = new_cap
    return true, nil
}

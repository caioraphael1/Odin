import "base:internal"
import "base:intrinsics"
import "base:mem"

import "base:container/slice"
    // only slice.copy


DEFAULT_DYNAMIC_ARRAY_CAPACITY :: 8

Raw_Dynamic_Array :: struct {
    data:      rawptr,
    len:       uint,
    cap:       uint,
    allocator: mem.Allocator,
}


init :: proc(array: ^$T/[dynamic]$E, allocator: mem.Allocator) {
    array^ = {} // Reset the struct first.
    array.allocator = allocator
}

create :: proc($T: typeid/[dynamic]$E, allocator: mem.Allocator) -> (array: T) {
    array.allocator = allocator
    return
}

// `create_len` allocates and initializes a dynamic array. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
create_len :: proc($T: typeid/[dynamic]$E, len: uint, allocator: mem.Allocator, loc := #caller_location) -> (array: T, err: mem.Allocator_Error) {
    err = _raw_dyn_array_init_len_cap((^Raw_Dynamic_Array)(&array), size_of(E), align_of(E), len, len, allocator, loc)
    return
}

// `create_len_cap` allocates and initializes a dynamic array. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
create_len_cap :: proc($T: typeid/[dynamic]$E, len: uint, cap: uint, allocator: mem.Allocator, loc := #caller_location) -> (array: T, err: mem.Allocator_Error) {
    err = _raw_dyn_array_init_len_cap((^Raw_Dynamic_Array)(&array), size_of(E), align_of(E), len, cap, allocator, loc)
    return
}


_raw_dyn_array_init_len_cap :: proc(array: ^Raw_Dynamic_Array, size_of_elem, align_of_elem: uint, len: uint, cap: uint, allocator: mem.Allocator, loc := #caller_location) -> (err: mem.Allocator_Error) {
    create_error_loc(loc, len, cap)
    internal.assert(cap > 0, "Capacity must be greater than zero")
    array.allocator = allocator // initialize allocator before just in case it fails to allocate any memory
    data := mem.alloc(size_of_elem*cap, align_of_elem, allocator, loc) or_return
    use_zero := data == nil && size_of_elem != 0
    array.data = raw_data(data)
    array.len = 0 if use_zero else len
    array.cap = 0 if use_zero else cap
    return
}


from_slice :: proc(backing: $T/[]$E) -> [dynamic]E {
    return transmute([dynamic]E)Raw_Dynamic_Array{
        data      = raw_data(backing),
        len       = 0,
        cap       = len(backing),
        allocator = {
            procedure = {},
            data      = nil,
        },
    }
}

// `clear` will set the length of a passed dynamic array to `0`
clear :: proc(array: ^$T/[dynamic]$E) {
    if array != nil {
        (^Raw_Dynamic_Array)(array).len = 0
    }
}

// `delete` will try to free the underlying data of the passed dynamic array, with the given `allocator` if the allocator supports this operation.
delete :: proc(array: $T/[dynamic]$E, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free_with_size(raw_data(array), cap(array)*size_of(E), array.allocator, loc)
}

// `append` appends an element to the end of a dynamic array.
append :: proc(array: ^$T/[dynamic]$E, #no_broadcast arg: E, loc := #caller_location) -> (err: mem.Allocator_Error) {
    when size_of(E) == 0 {
        (^Raw_Dynamic_Array)(array).len += 1
        return nil
    } else {
        arg := arg
        return _append((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), &arg, true, loc=loc)
    }
}

// `append_non_zero` appends an element to the end of a dynamic array, without zeroing any reserved memory
append_non_zero :: proc(array: ^$T/[dynamic]$E, #no_broadcast arg: E, loc := #caller_location) -> (err: mem.Allocator_Error) {
    when size_of(E) == 0 {
        (^Raw_Dynamic_Array)(array).len += 1
        return nil
    } else {
        arg := arg
        return _append((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), &arg, false, loc=loc)
    }
}

_append :: #force_no_inline proc(array: ^Raw_Dynamic_Array, size_of_elem, align_of_elem: uint, arg_ptr: rawptr, should_zero: bool, loc := #caller_location) -> (err: mem.Allocator_Error) {
    if array == nil {
        return
    }

    if array.cap < array.len+1 {
        // Same behavior as _append_many but there's only one arg, so we always just add DEFAULT_DYNAMIC_ARRAY_CAPACITY.
        cap := 2 * array.cap + DEFAULT_DYNAMIC_ARRAY_CAPACITY

        // do not 'or_return' here as it could be a partial success
        err = _reserve(array, size_of_elem, align_of_elem, cap, should_zero, loc)
    }
    if array.cap-array.len > 0 {
        data := ([^]byte)(array.data)
        internal.assert(data != nil, loc=loc)
        data = data[array.len*size_of_elem:]
        mem.copy_non_overlapping(data, arg_ptr, size_of_elem)
        array.len += 1
    }
    return
}

// `append_many` appends `args` to the end of a dynamic array.
append_many :: proc(array: ^$T/[dynamic]$E, #no_broadcast args: ..E, loc := #caller_location) -> (err: mem.Allocator_Error) {
    when size_of(E) == 0 {
        a := (^Raw_Dynamic_Array)(array)
        a.len += len(args)
        return nil
    } else {
        return _append_many((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), true, loc, raw_data(args), len(args))
    }
}

// `append_many_non_zero` appends `args` to the end of a dynamic array, without zeroing any reserved memory
append_many_non_zero :: proc(array: ^$T/[dynamic]$E, #no_broadcast args: ..E, loc := #caller_location) -> (err: mem.Allocator_Error) {
    when size_of(E) == 0 {
        a := (^Raw_Dynamic_Array)(array)
        a.len += len(args)
        return nil
    } else {
        return _append_many((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), false, loc, raw_data(args), len(args))
    }
}

_append_many :: #force_no_inline proc(array: ^Raw_Dynamic_Array, size_of_elem, align_of_elem: uint, should_zero: bool, loc := #caller_location, args: rawptr, arg_len: uint) -> (err: mem.Allocator_Error) {
    if array == nil {
        return nil
    }

    if arg_len <= 0 {
        return nil
    }

    if array.cap < array.len+arg_len {
        cap := 2 * array.cap + max(DEFAULT_DYNAMIC_ARRAY_CAPACITY, arg_len)

        // do not 'or_return' here as it could be a partial success
        err = _reserve(array, size_of_elem, align_of_elem, cap, should_zero, loc)
    }
    arg_len := arg_len
    arg_len = min(array.cap - array.len, arg_len)
    if arg_len > 0 {
        data := ([^]byte)(array.data)
        internal.assert(data != nil, loc=loc)
        data = data[array.len*size_of_elem:]
        intrinsics.mem_copy(data, args, size_of_elem * arg_len) // must be mem_copy (overlapping)
        array.len += arg_len
    }
    return err
}

// `append_string` appends a string to the end of a dynamic array of bytes
append_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_string(array, arg, true, loc)
}
// `append_string_non_zero` appends a string to the end of a dynamic array of bytes, without zeroing any reserved memory
append_string_non_zero :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_string(array, arg, false, loc)
}

// The append_many_strings built-in procedure appends multiple strings to the end of a [dynamic]u8 like type
append_many_strings :: proc(array: ^$T/[dynamic]$E/u8, args: ..string, loc := #caller_location) -> (err: mem.Allocator_Error) {
    for arg in args {
        append(array, ..transmute([]E)(arg), loc=loc) or_return
    }
    return
}

// The append_string built-in procedure appends a string to the end of a [dynamic]u8 like type
_append_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, should_zero: bool, loc := #caller_location) -> (err: mem.Allocator_Error) {
    return _append_many((^Raw_Dynamic_Array)(array), 1, 1, should_zero, loc, raw_data(arg), len(arg))
}

// `inject_at` injects an element in a dynamic array at a specified index and moves the previous elements after that index "across"
inject_at :: proc(array: ^$T/[dynamic]$E, #any_int index: uint, #no_broadcast arg: E, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) #no_bounds_check {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(index >= 0, "Index must be positive.", loc)
    }
    if array == nil {
        return
    }
    n := max(len(array), index)
    m :: 1
    new_size := n + m

    resize(array, new_size, loc) or_return
    when size_of(E) != 0 {
        slice.copy(array[index + m:], array[index:])
        array[index] = arg
    }
    ok = true
    return
}

// `inject_many_at` injects multiple elements in a dynamic array at a specified index and moves the previous elements after that index "across"
inject_many_at :: proc(array: ^$T/[dynamic]$E, #any_int index: uint, #no_broadcast args: ..E, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) #no_bounds_check {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(index >= 0, "Index must be positive.", loc)
    }
    if array == nil {
        return
    }
    if len(args) == 0 {
        ok = true
        return
    }

    n := max(len(array), index)
    m := len(args)
    new_size := n + m

    _ = resize(array, new_size, loc) or_return
    when size_of(E) != 0 {
        slice.copy(array[index + m:], array[index:])
        slice.copy(array[index:], args)
    }
    ok = true
    return
}

// `inject_string_at` injects a string into a dynamic array at a specified index and moves the previous elements after that index "across"
inject_string_at :: proc(array: ^$T/[dynamic]$E/u8, #any_int index: uint, arg: string, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) #no_bounds_check {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(index >= 0, "Index must be positive.", loc)
    }
    if array == nil {
        return
    }
    if len(arg) == 0 {
        ok = true
        return
    }

    n := max(len(array), index)
    m := len(arg)
    new_size := n + m

    _ = resize(array, new_size, loc) or_return
    slice.copy(array[index+m:], array[index:])
    slice.copy(array[index:], arg)
    ok = true
    return
}

// `assign_at` assigns a value at a given index. If the requested index is smaller than the current
// size of the dynamic array, it will attempt to `mem.resize` the a new length of `index+1` and then assign as `index`.
assign_at :: proc(array: ^$T/[dynamic]$E, #any_int index: uint, arg: E, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) #no_bounds_check {
    if index < len(array) {
        array[index] = arg
        ok = true
    } else {
        _ = resize(array, index+1, loc) or_return
        array[index] = arg
        ok = true
    }
    return
}

// `assign_many_at` assigns a values at a given index. If the requested index is smaller than the current
// size of the dynamic array, it will attempt to `mem.resize` the a new length of `index+len(args)` and then assign as `index`.
assign_many_at :: proc(array: ^$T/[dynamic]$E, #any_int index: uint, #no_broadcast args: ..E, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) #no_bounds_check {
    new_size := index + len(args)
    if len(args) == 0 {
        ok = true
    } else if new_size < len(array) {
        slice.copy(array[index:], args)
        ok = true
    } else {
        _ = resize(array, new_size, loc) or_return
        slice.copy(array[index:], args)
        ok = true
    }
    return
}

// `assign_string_at` assigns a string at a given index. If the requested index is smaller than the current
// size of the dynamic array, it will attempt to `mem.resize` the a new length of `index+len(arg)` and then assign as `index`.
assign_string_at :: proc(array: ^$T/[dynamic]$E/u8, #any_int index: uint, arg: string, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) #no_bounds_check {
    new_size := index + len(arg)
    if len(arg) == 0 {
        ok = true
    } else if new_size < len(array) {
        slice.copy(array[index:], arg)
        ok = true
    } else {
        _ = resize(array, new_size, loc) or_return
        slice.copy(array[index:], arg)
        ok = true
    }
    return
}

// `unordered_remove` removed the element at the specified `index`. It does so by replacing the current end value
// with the old value, and reducing the length of the dynamic array by 1.
// Note: This is an O(1) operation.
// Note: If you want the elements to remain in their order, use `ordered_remove`.
// Note: If the index is out of bounds, this procedure will panic.
unordered_remove :: proc(array: ^$D/[dynamic]$T, #any_int index: uint, loc := #caller_location) #no_bounds_check {
    internal.bounds_check_error_loc(loc, index, len(array))
    n := len(array) - 1
    if index != n {
        array[index] = array[n]
    }
    (^Raw_Dynamic_Array)(array).len -= 1
}

// `ordered_remove` removed the element at the specified `index` whilst keeping the order of the other elements.
// Note: This is an O(N) operation.
// Note: If the elements do not have to remain in their order, prefer `unordered_remove`.
// Note: If the index is out of bounds, this procedure will panic.
ordered_remove :: proc(array: ^$D/[dynamic]$T, #any_int index: uint, loc := #caller_location) #no_bounds_check {
    internal.bounds_check_error_loc(loc, index, len(array))
    if index+1 < len(array) {
        slice.copy(array[index:], array[index+1:])
    }
    (^Raw_Dynamic_Array)(array).len -= 1
}

// `remove_range` removes a range of elements specified by the range `lo` and `hi`, whilst keeping the order of the other elements.
// Note: This is an O(N) operation.
// Note: If the range is out of bounds, this procedure will panic.
remove_range :: proc(array: ^$D/[dynamic]$T, #any_int lo, hi: uint, loc := #caller_location) #no_bounds_check {
    slice_expr_error_lo_hi_loc(loc, lo, hi, len(array))
    n := max(hi-lo, 0)
    if n > 0 {
        if hi != len(array) {
            slice.copy(array[lo:], array[hi:])
        }
        (^Raw_Dynamic_Array)(array).len -= n
    }
}


// `pop` will remove and return the end value of dynamic array `array` and reduces the length of `array` by 1.
// Note: If the dynamic array has no elements (`len(array) == 0`), this procedure will panic.
@(optional_results)
pop :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
    internal.assert(len(array) > 0, loc=loc)
    _raw_dyn_array_pop(&res, (^Raw_Dynamic_Array)(array), size_of(E))
    return res
}

_raw_dyn_array_pop :: proc(res: rawptr, array: ^Raw_Dynamic_Array, elem_size: uint, loc := #caller_location) {
    end := rawptr(uintptr(array.data) + uintptr(elem_size*(array.len-1)))
    mem.copy_non_overlapping(res, end, elem_size)
    array.len -= 1
}

// `pop_safe` trys to remove and return the end value of dynamic array `array` and reduces the length of `array` by 1.
// If the operation is not possible, it will return false.
pop_safe :: proc(array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
    if len(array) == 0 {
        return
    }
    res, ok = array[len(array)-1], true
    (^Raw_Dynamic_Array)(array).len -= 1
    return
}

// `pop_front` will remove and return the first value of dynamic array `array` and reduces the length of `array` by 1.
// Note: If the dynamic array as no elements (`len(array) == 0`), this procedure will panic.
pop_front :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
    internal.assert(len(array) > 0, loc=loc)
    res = array[0]
    if len(array) > 1 {
        slice.copy(array[0:], array[1:])
    }
    (^Raw_Dynamic_Array)(array).len -= 1
    return res
}

// `pop_front_safe` trys to return and remove the first value of dynamic array `array` and reduces the length of `array` by 1.
// If the operation is not possible, it will return false.
pop_front_safe :: proc(array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
    if len(array) == 0 {
        return
    }
    res, ok = array[0], true
    if len(array) > 1 {
        slice.copy(array[0:], array[1:])
    }
    (^Raw_Dynamic_Array)(array).len -= 1
    return
}


// `reserve` will try to reserve memory of a passed dynamic array or map to the requested element count (setting the `cap`).
// When a memory mem.resize allocation is required, the memory will be asked to be zeroed (i.e. it calls `mem.resize`).
reserve :: proc(array: ^$T/[dynamic]$E, #any_int capacity: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _reserve((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), capacity, true, loc)
}

// `reserve` will try to reserve memory of a passed dynamic array or map to the requested element count (setting the `cap`).
// When a memory mem.resize allocation is required, the memory will be asked to be zeroed (i.e. it calls `mem.resize`).
_reserve :: #force_no_inline proc(a: ^Raw_Dynamic_Array, size_of_elem, align_of_elem: uint, capacity: uint, should_zero: bool, loc := #caller_location) -> mem.Allocator_Error {
    if a == nil {
        return nil
    }

    if capacity <= a.cap {
        return nil
    }

    internal.assert(a.allocator.procedure != nil, "Allocator not defined", loc)

    old_size  := a.cap * size_of_elem
    new_size  := capacity * size_of_elem
    allocator := a.allocator

    new_data: []byte
    if should_zero {
        new_data = mem.resize(a.data, old_size, new_size, align_of_elem, allocator, loc) or_return
    } else {
        new_data = mem.resize_non_zero(a.data, old_size, new_size, align_of_elem, allocator, loc) or_return
    }
    if new_data == nil && new_size > 0 {
        return .Out_Of_Memory
    }

    a.data = raw_data(new_data)
    a.cap = capacity
    return nil
}

// `reserve_non_zero` will try to reserve memory of a passed dynamic array or map to the requested element count (setting the `cap`).
// When a memory mem.resize allocation is required, the memory will be asked to not be zeroed (i.e. it calls `mem.resize_non_zero`).
reserve_non_zero :: proc(array: ^$T/[dynamic]$E, #any_int capacity: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _reserve((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), capacity, false, loc)
}

// `resize` will try to mem.resize memory of a passed dynamic array or map to the requested element count (setting the `len`, and possibly `cap`).
// When a memory mem.resize allocation is required, the memory will be asked to be zeroed (i.e. it calls `mem.resize`).
resize :: proc(array: ^$T/[dynamic]$E, #any_int length: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _resize((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), length, true, loc=loc)
}

// `resize_non_zero` will try to mem.resize memory of a passed dynamic array or map to the requested element count (setting the `len`, and possibly `cap`).
// When a memory mem.resize allocation is required, the memory will be asked to not be zeroed (i.e. it calls `mem.resize_non_zero`).
resize_non_zero :: proc(array: ^$T/[dynamic]$E, #any_int length: uint, loc := #caller_location) -> mem.Allocator_Error {
    return _resize((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), length, false, loc=loc)
}

_resize :: #force_no_inline proc(a: ^Raw_Dynamic_Array, size_of_elem, align_of_elem: uint, length: uint, should_zero: bool, loc := #caller_location) -> mem.Allocator_Error {
    // Invalid pointer
    if a == nil {
        return nil
    }
    
    internal.assert(a.allocator.procedure != nil, "mem.Allocator not defined", loc)

    if should_zero && a.len < length {
        num_reused := min(a.cap, length) - a.len
        mem.zero(([^]byte)(a.data)[a.len*size_of_elem:], num_reused*size_of_elem)
    }

    if length <= a.cap {
        a.len = max(length, 0)
        return nil
    }

    old_size  := a.cap  * size_of_elem
    new_size  := length * size_of_elem
    allocator := a.allocator

    new_data : []byte
    if should_zero {
        new_data = mem.resize(a.data, old_size, new_size, align_of_elem, allocator, loc) or_return
    } else {
        new_data = mem.resize_non_zero(a.data, old_size, new_size, align_of_elem, allocator, loc) or_return
    }
    if new_data == nil && new_size > 0 {
        return .Out_Of_Memory
    }

    a.data = raw_data(new_data)
    a.len = length
    a.cap = length
    return nil
}

// Shrinks the capacity of a dynamic array down to the current length, or the given capacity.
// If `new_cap` is negative, then `len(array)` is used.
// Returns false if `cap(array) < new_cap`, or the allocator report failure.
// If `len(array) < new_cap`, then `len(array)` will be left unchanged.
shrink :: proc(array: ^$T/[dynamic]$E, #any_int new_cap: uint, loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    return _shrink((^Raw_Dynamic_Array)(array), size_of(E), align_of(E), new_cap, loc)
}

_shrink :: proc(a: ^Raw_Dynamic_Array, size_of_elem, align_of_elem: uint, new_cap: uint, loc := #caller_location) -> (did_shrink: bool, err: mem.Allocator_Error) {
    // Invalid pointer
    if a == nil {
        return
    }

    internal.assert(a.allocator.procedure != nil, "mem.Allocator not defined", loc=loc)

    // It's not a shrink
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


//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(disabled=ODIN_NO_BOUNDS_CHECK)
expr_error :: proc(file: string, line, column: i32, low, high, max: int) {
    if 0 <= low && low <= high && high <= max {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(file: string, line, column: i32, low, high, max: int) -> ! {
        internal.print_caller_location(internal.Source_Code_Location{file, line, column, ""})
        internal.print_string(" Invalid dynamic array indices ")
        internal.print_i64(i64(low))
        internal.print_string(":")
        internal.print_i64(i64(high))
        internal.print_string(" is out of range 0..<")
        internal.print_i64(i64(max))
        internal.print_byte('\n')
        internal.bounds_trap()
    }
    handle_error(file, line, column, low, high, max)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
create_error_loc :: #force_inline proc(loc := #caller_location, len, cap: uint) {
    if 0 <= len && len <= cap {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(loc: internal.Source_Code_Location, len, cap: uint)  -> ! {
        internal.print_caller_location(loc)
        internal.print_string(" Invalid dynamic array parameters for make: ")
        internal.print_i64(i64(len))
        internal.print_byte(':')
        internal.print_i64(i64(cap))
        internal.print_byte('\n')
        internal.bounds_trap()
    }
    handle_error(loc, len, cap)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
expr_error_loc :: #force_inline proc(loc := #caller_location, low, high, max: int) {
    expr_error(loc.file_path, loc.line, loc.column, low, high, max)
}



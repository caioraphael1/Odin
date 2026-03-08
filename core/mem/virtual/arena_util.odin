@(require) import "base:internal"

// The `new` procedure allocates memory for a type `T` from a `virtual.Arena`. The second argument is a type,
// not a value, and the value return is a pointer to a newly allocated value of that type using the specified allocator.
new :: proc(arena: ^Arena, $T: typeid, loc := #caller_location) -> (ptr: ^T, err: Allocator_Error) {
    return new_aligned(arena, T, align_of(T), loc)
}

// The `new_aligned` procedure allocates memory for a type `T` from a `virtual.Arena` with a specified `alignment`.
// The second argument is a type, not a value, and the value return is a pointer to a newly allocated value of
// that type using the specified allocator.
new_aligned :: proc(arena: ^Arena, $T: typeid, alignment: uint, loc := #caller_location) -> (ptr: ^T, err: Allocator_Error) {
    data := arena_alloc(arena, size_of(T), alignment, loc) or_return
    ptr = (^T)(raw_data(data))
    return
}

// The `new_clone` procedure allocates memory for a type `T` from a `virtual.Arena`. The second argument is a value that
// is to be copied to the allocated data. The value returned is a pointer to a newly allocated value of that type using the specified allocator.
new_clone :: proc(arena: ^Arena, data: $T, loc := #caller_location) -> (ptr: ^T, err: Allocator_Error) {
    ptr, err = new_aligned(arena, T, align_of(T), loc)
    if ptr != nil && err == nil {
        ptr^ = data
    }
    return
}

// `slice.create` allocates and initializes a slice. Like `new`, the second argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
create :: proc(arena: ^Arena, $T: typeid/[]$E, #any_int len: int, loc := #caller_location) -> (T, Allocator_Error) {
    return create_aligned(arena, T, len, align_of(E), loc)
}

// `slice_create_aligned` allocates and initializes a slice. Like `new`, the second argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
create_aligned :: proc(arena: ^Arena, $T: typeid/[]$E, #any_int len: int, alignment: uint, loc := #caller_location) -> (T, Allocator_Error) {
    internal.slice_create_error_loc(loc, len)
    data, err := arena_alloc(arena, size_of(E)*uint(len), alignment, loc)
    if data == nil && size_of(E) != 0 {
        return nil, err
    }
    s := ([^]E)(raw_data(data))[:len]
    return T(s), err
}


// `multi_pointer_create` allocates and initializes a dynamic array. Like `new`, the second argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
// This is "similar" to doing `raw_data(slice.create([]E, len, allocator))`.
multi_pointer_create :: proc(arena: ^Arena, $T: typeid/[^]$E, #any_int len: int, loc := #caller_location) -> (T, Allocator_Error) {
    internal.slice_create_error_loc(loc, len)
    data, err := arena_alloc(arena, size_of(E)*uint(len), align_of(E), loc)
    if data == nil && size_of(E) != 0 {
        return nil, err
    }
    return (T)(raw_data(data)), err
}

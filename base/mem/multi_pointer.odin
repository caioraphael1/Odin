

// `multi_pointer_create` allocates and initializes a multi-pointer. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
// This is "similar" to doing `raw_data(slice_create([]E, len, allocator))`.
// @(builtin)
multi_pointer_create :: proc($T: typeid/[^]$E, #any_int len: int, allocator: Allocator, loc := #caller_location) -> (mp: T, err: Allocator_Error) {
    slice_create_error_loc(loc, len)
    data := mem_alloc_bytes(size_of(E)*len, align_of(E), allocator, loc) or_return
    if data == nil && size_of(E) != 0 {
        return
    }
    mp = cast(T)raw_data(data)
    return
}

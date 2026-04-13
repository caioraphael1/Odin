import "base:internal"

// `multi_pointer_create` allocates and initializes a multi-pointer. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
// This is "similar" to doing `raw_data(slice.create(E, len, allocator))`.
multi_pointer_create :: proc($T: typeid/[^]$E, len: uint, allocator: Allocator, loc := #caller_location) -> (mp: T, err: Allocator_Error) {
    if len == 0 {
        return
    }
    data := alloc(size_of(E)*len, align_of(E), allocator, loc) or_return
    if data == nil && size_of(E) != 0 {
        return
    }
    mp = cast(T)raw_data(data)
    return
}

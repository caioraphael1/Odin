import "base:mem"
import "base:container/slice"

/*
Default resize procedure.

When allocator does not support resize operation, but supports `.Alloc` and
`.Free`, this procedure is used to implement allocator's default behavior on
_ = resize.

The behavior of the function is as follows:

- If `new_size` is `0`, the function acts like `free()`, freeing the memory
    region of `old_size` bytes located at `old_memory`.
- If `old_memory` is `nil`, the function acts like `alloc()`, allocating
    `new_size` bytes of memory aligned on a boundary specified by `alignment`.
- Otherwise, a new memory region of size `new_size` is allocated, then the
    data from the old memory region is copied and the old memory region is
    freed.
*/
default_resize_align :: proc(
    old_memory: rawptr,
    old_size:  uint,
    new_size:  uint,
    alignment: uint,
    allocator: mem.Allocator,
    loc := #caller_location,
) -> (res: rawptr, err: mem.Allocator_Error) {
    data: []u8
    data, err = default_resize_bytes_align(
        ([^]u8) (old_memory)[:old_size],
        new_size,
        alignment,
        allocator,
        loc,
    )
    res = raw_data(data)
    return
}

/*
Default resize procedure.

When allocator does not support resize operation, but supports
`.Alloc_Non_Zeroed` and `.Free`, this procedure is used to implement allocator's
default behavior on resize.

Unlike `default_resize_align` no new memory is being explicitly
zero-initialized.

The behavior of the function is as follows:

- If `new_size` is `0`, the function acts like `free()`, freeing the memory
    region of `old_size` bytes located at `old_memory`.
- If `old_memory` is `nil`, the function acts like `alloc()`, allocating
    `new_size` bytes of memory aligned on a boundary specified by `alignment`.
- Otherwise, a new memory region of size `new_size` is allocated, then the
    data from the old memory region is copied and the old memory region is
    freed.
*/
default_resize_bytes_align_non_zeroed :: proc(
    old_data:  []u8,
    new_size:  uint,
    alignment: uint,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> ([]u8, mem.Allocator_Error) {
    return _default_resize_bytes_align(old_data, new_size, alignment, false, allocator, loc)
}

/*
Default resize procedure.

When allocator does not support resize operation, but supports `.Alloc` and
`.Free`, this procedure is used to implement allocator's default behavior on
_ = resize.

The behavior of the function is as follows:

- If `new_size` is `0`, the function acts like `free()`, freeing the memory
    region specified by `old_data`.
- If `old_data` is `nil`, the function acts like `alloc()`, allocating
    `new_size` bytes of memory aligned on a boundary specified by `alignment`.
- Otherwise, a new memory region of size `new_size` is allocated, then the
    data from the old memory region is copied and the old memory region is
    freed.
*/
default_resize_bytes_align :: proc(
    old_data:  []u8,
    new_size:  uint,
    alignment: uint,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> ([]u8, mem.Allocator_Error) {
    return _default_resize_bytes_align(old_data, new_size, alignment, true, allocator, loc)
}


_default_resize_bytes_align :: #force_inline proc(
    old_data:  []u8,
    new_size:  uint,
    alignment: uint,
    should_zero: bool,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> ([]u8, mem.Allocator_Error) {
    old_memory := raw_data(old_data)
    old_size := len(old_data)
    if old_memory == nil {
        if should_zero {
            return mem.alloc(new_size, alignment, allocator, loc)
        } else {
            return mem.alloc_non_zeroed(new_size, alignment, allocator, loc)
        }
    }
    if new_size == 0 {
        err := mem.free_bytes(old_data, allocator, loc)
        return nil, err
    }
    if new_size == old_size && mem.is_aligned(old_memory, alignment) {
        return old_data, .None
    }
    new_memory : []u8
    err : mem.Allocator_Error
    if should_zero {
        new_memory, err = mem.alloc(new_size, alignment, allocator, loc)
    } else {
        new_memory, err = mem.alloc_non_zeroed(new_size, alignment, allocator, loc)
    }
    if new_memory == nil || err != nil {
        return nil, err
    }
    slice.copy(new_memory, old_data)
    _ = mem.free_bytes(old_data, allocator, loc)
    return new_memory, err
}

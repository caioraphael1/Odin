import "base:intrinsics"

// The new built-in procedure allocates memory. The first argument is a type, not a value, and the value
// return is a pointer to a newly allocated value of that type using the specified allocator.
@(builtin)
new :: proc($T: typeid, allocator: Allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
    t = (^T)(raw_data(mem_alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return))
    return
}

new_aligned :: proc($T: typeid, alignment: int, allocator: Allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
    t = (^T)(raw_data(mem_alloc_bytes(size_of(T), alignment, allocator, loc) or_return))
    return
}

@(builtin)
new_clone :: proc(data: $T, allocator: Allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
    t = (^T)(raw_data(mem_alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return))
    if t != nil {
        t^ = data
    }
    return
}

@(builtin)
free :: #force_no_inline proc(ptr: rawptr, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    assert(allocator.procedure != nil, loc=loc)
    if ptr == nil {
        return nil
    }
    _, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0, loc)
    return err
}

/*
Free a memory region.

This procedure frees `size` bytes of memory region located at the address,
specified by `ptr`, allocated from the allocator specified by `allocator`.

If the `size` parameter is `0`, this call is equivalent to `free()`.

**Inputs**:
- `ptr`: Pointer to the memory region to free.
- `size`: The size of the memory region to free.
- `allocator`: The allocator to free to.

**Returns**:
- The error, if freeing failed.

**Errors**:
- `None`: When no error has occurred.
- `Invalid_Pointer`: The specified pointer is not owned by the specified allocator,
    or does not point to a valid allocation.
- `Mode_Not_Implemented`: If the specified allocator does not support the `.Free`
mode.
*/
mem_free_with_size :: #force_no_inline proc(ptr: rawptr, byte_count: int, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    assert(allocator.procedure != nil, loc=loc)
    if ptr == nil {
        return nil
    }
    _, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, byte_count, loc)
    return err
}

/*
Free a memory region.

This procedure frees memory region, specified by `bytes`, allocated from the
allocator specified by `allocator`.

If the length of the specified slice is zero, the `.Invalid_Argument` error
is returned.

**Inputs**:
- `bytes`: The memory region to free.
- `allocator`: The allocator to free to.

**Returns**:
- The error, if freeing failed.

**Errors**:
- `None`: When no error has occurred.
- `Invalid_Pointer`: The specified pointer is not owned by the specified allocator,
    or does not point to a valid allocation.
- `Mode_Not_Implemented`: If the specified allocator does not support the `.Free`
mode.
*/
mem_free_bytes :: #force_no_inline proc(bytes: []byte, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    assert(allocator.procedure != nil, loc=loc)
    if bytes == nil {
        return nil
    }
    _, err := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(bytes), len(bytes), loc)
    return err
}

/*
Free all allocations.

This procedure frees all allocations made on the allocator specified by
`allocator` to that allocator, making it available for further allocations.

**Inputs**:
- `allocator`: The allocator to free to.

**Errors**:
- `None`: When no error has occurred.
- `Mode_Not_Implemented`: If the specified allocator does not support the `.Free`
mode.
*/
@(builtin)
free_all :: #force_no_inline proc(allocator: Allocator, loc := #caller_location) -> (err: Allocator_Error) {
    assert(allocator.procedure != nil, loc=loc)
    _, err = allocator.procedure(allocator.data, .Free_All, 0, 0, nil, 0, loc)
    return
}

mem_alloc_bytes :: #force_no_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, "Allocator not defined", loc=loc)
    assert(size > 0, "Size must be greater than zero", loc=loc)
    return allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, loc)
}

/*
Allocate memory.

This function allocates `size` bytes of memory, aligned to a boundary specified
by `alignment` using the allocator specified by `allocator`.

**Inputs**:
- `size`: The desired size of the allocated memory region.
- `alignment`: The desired alignment of the allocated memory region.
- `allocator`: The allocator to allocate from.

**Returns**:
1. Slice of the allocated memory region, or `nil` if allocation failed.
2. Error, if the allocation failed.

**Errors**:
- `None`: If no error occurred.
- `Out_Of_Memory`: Occurs when the allocator runs out of space in any of its
    backing buffers, the backing allocator has ran out of space, or an operating
    system failure occurred.
- `Invalid_Argument`: If the supplied `size` is negative, alignment is not a
    power of two.
*/
mem_alloc :: #force_no_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, loc=loc)
    if size == 0 {
        return nil, nil
    }
    return allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, loc)
}


/*
Allocate non-zeroed memory.

This function allocates `size` bytes of memory, aligned to a boundary specified
by `alignment` using the allocator specified by `allocator`. This procedure
does not explicitly zero-initialize allocated memory region.

**Inputs**:
- `size`: The desired size of the allocated memory region.
- `alignment`: The desired alignment of the allocated memory region.
- `allocator`: The allocator to allocate from.

**Returns**:
1. Slice of the allocated memory region, or `nil` if allocation failed.
2. Error, if the allocation failed.

**Errors**:
- `None`: If no error occurred.
- `Out_Of_Memory`: Occurs when the allocator runs out of space in any of its
    backing buffers, the backing allocator has ran out of space, or an operating
    system failure occurred.
- `Invalid_Argument`: If the supplied `size` is negative, alignment is not a
    power of two.
*/
mem_alloc_non_zeroed :: #force_no_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, loc=loc)
    if size == 0 {
        return nil, nil
    }
    return allocator.procedure(allocator.data, .Alloc_Non_Zeroed, size, alignment, nil, 0, loc)
}

@(private)
byte_slice :: #force_inline proc(data: rawptr, len: int) -> []byte #no_bounds_check {
    return ([^]byte)(data)[:max(len, 0)]
}

is_power_of_two_int :: #force_inline proc(x: int) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}

align_forward_int :: #force_inline proc(ptr, align: int) -> int {
    assert(is_power_of_two_int(align))

    p := ptr
    modulo := p & (align-1)
    if modulo != 0 {
        p += align - modulo
    }
    return p
}

is_power_of_two_uint :: #force_inline proc(x: uint) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}

align_forward_uint :: #force_inline proc(ptr, align: uint) -> uint {
    assert(is_power_of_two_uint(align))

    p := ptr
    modulo := p & (align-1)
    if modulo != 0 {
        p += align - modulo
    }
    return p
}

is_power_of_two_uintptr :: #force_inline proc(x: uintptr) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}

align_forward_uintptr :: #force_inline proc(ptr, align: uintptr) -> uintptr {
    assert(is_power_of_two_uintptr(align))

    p := ptr
    modulo := p & (align-1)
    if modulo != 0 {
        p += align - modulo
    }
    return p
}

@(optional_results)
mem_zero :: proc(data: rawptr, len: int) -> rawptr {
    if data == nil {
        return nil
    }
    if len <= 0 {
        return data
    }
    intrinsics.mem_zero(data, len)
    return data
}

@(optional_results)
mem_copy :: proc(dst, src: rawptr, len: int) -> rawptr {
    if src != nil && dst != src && len > 0 {
        // NOTE(bill): This _must_ be implemented like C's memmove
        intrinsics.mem_copy(dst, src, len)
    }
    return dst
}

@(optional_results)
mem_copy_non_overlapping :: proc(dst, src: rawptr, len: int) -> rawptr {
    if src != nil && dst != src && len > 0 {
        // NOTE(bill): This _must_ be implemented like C's memcpy
        intrinsics.mem_copy_non_overlapping(dst, src, len)
    }
    return dst
}

DEFAULT_ALIGNMENT :: 2*align_of(rawptr)

/*
Resize a memory region.

This procedure resizes a memory region, `old_size` bytes in size, located at
the address specified by `ptr`, such that it has a new size, specified by
`new_size` and and is aligned on a boundary specified by `alignment`.

If the `ptr` parameter is `nil`, `resize_dynamic_array()` acts just like `alloc()`, allocating
`new_size` bytes, aligned on a boundary specified by `alignment`.

If the `new_size` parameter is `0`, `resize_dynamic_array()` acts just like `free()`, freeing
the memory region `old_size` bytes in length, located at the address specified
by `ptr`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

**Inputs**:
- `ptr`: Pointer to the memory region to resize.
- `old_size`: Size of the memory region to resize.
- `new_size`: The desired size of the resized memory region.
- `alignment`: The desired alignment of the resized memory region.
- `allocator`: The owner of the memory region to resize.

**Returns**:
1. The pointer to the resized memory region, if successfull, `nil` otherwise.
2. Error, if resize failed.

**Errors**:
- `None`: No error.
- `Out_Of_Memory`: When the allocator's backing buffer or it's backing
    allocator does not have enough space to fit in an allocation with the new
    size, or an operating system failure occurs.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
    to any of the allocators backing buffers or does not point to a valid start
    of an allocation made in that allocator.
- `Invalid_Argument`: When `size` is negative, alignment is not a power of two,
    or the `old_size` argument is incorrect.
- `Mode_Not_Implemented`: The allocator does not support the `.Realloc` mode.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
mem_resize :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    return _mem_resize(ptr, old_size, new_size, alignment, allocator, true, loc)
}

/*
Resize a memory region without zero-initialization.

This procedure resizes a memory region, `old_size` bytes in size, located at
the address specified by `ptr`, such that it has a new size, specified by
`new_size` and and is aligned on a boundary specified by `alignment`.

If the `ptr` parameter is `nil`, `resize_dynamic_array()` acts just like `alloc()`, allocating
`new_size` bytes, aligned on a boundary specified by `alignment`.

If the `new_size` parameter is `0`, `resize_dynamic_array()` acts just like `free()`, freeing
the memory region `old_size` bytes in length, located at the address specified
by `ptr`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

Unlike `resize_dynamic_array()`, this procedure does not explicitly zero-initialize any new
memory.

**Inputs**:
- `ptr`: Pointer to the memory region to resize.
- `old_size`: Size of the memory region to resize.
- `new_size`: The desired size of the resized memory region.
- `alignment`: The desired alignment of the resized memory region.
- `allocator`: The owner of the memory region to resize.

**Returns**:
1. The pointer to the resized memory region, if successfull, `nil` otherwise.
2. Error, if resize failed.

**Errors**:
- `None`: No error.
- `Out_Of_Memory`: When the allocator's backing buffer or it's backing
    allocator does not have enough space to fit in an allocation with the new
    size, or an operating system failure occurs.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
    to any of the allocators backing buffers or does not point to a valid start
    of an allocation made in that allocator.
- `Invalid_Argument`: When `size` is negative, alignment is not a power of two,
    or the `old_size` argument is incorrect.
- `Mode_Not_Implemented`: The allocator does not support the `.Realloc` mode.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
non_zero_mem_resize :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    return _mem_resize(ptr, old_size, new_size, alignment, allocator, false, loc)
}

_mem_resize :: #force_no_inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, should_zero: bool, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, loc=loc)
    
    if new_size == 0 {
        if ptr != nil {
            _, err = allocator.procedure(allocator.data, .Free, 0, 0, ptr, old_size, loc)
            return
        }
        return
    } else if ptr == nil {
        if should_zero {
            return allocator.procedure(allocator.data, .Alloc, new_size, alignment, nil, 0, loc)
        } else {
            return allocator.procedure(allocator.data, .Alloc_Non_Zeroed, new_size, alignment, nil, 0, loc)
        }
    } else if old_size == new_size && uintptr(ptr) % uintptr(alignment) == 0 {
        data = ([^]byte)(ptr)[:old_size]
        return
    }

    if should_zero {
        data, err = allocator.procedure(allocator.data, .Resize, new_size, alignment, ptr, old_size, loc)
    } else {
        data, err = allocator.procedure(allocator.data, .Resize_Non_Zeroed, new_size, alignment, ptr, old_size, loc)
    }
    if err == .Mode_Not_Implemented {
        if should_zero {
            data, err = allocator.procedure(allocator.data, .Alloc, new_size, alignment, nil, 0, loc)
        } else {
            data, err = allocator.procedure(allocator.data, .Alloc_Non_Zeroed, new_size, alignment, nil, 0, loc)
        }
        if err != nil {
            return
        }
        slice_copy(data, ([^]byte)(ptr)[:old_size])
        _, err = allocator.procedure(allocator.data, .Free, 0, 0, ptr, old_size, loc)
    }
    return
}

conditional_mem_zero :: proc(data: rawptr, n_: int) #no_bounds_check {
    // When acquiring memory from the OS for the first time it's likely that the
    // OS already gives the zero page mapped multiple times for the request. The
    // actual allocation does not have physical pages allocated to it until those
    // pages are written to which causes a page-fault. This is often called COW
    // (Copy on Write)
    //
    // You do not want to actually zero out memory in this case because it would
    // cause a bunch of page faults decreasing the speed of allocations and
    // increase the amount of actual resident physical memory used.
    //
    // Instead a better technique is to check if memory is zerored before zeroing
    // it. This turns out to be an important optimization in practice, saving
    // nearly half (or more) the amount of physical memory used by an application.
    // This is why every implementation of calloc in libc does this optimization.
    //
    // It may seem counter-intuitive but most allocations in an application are
    // wasted and never used. When you consider something like a [dynamic]T which
    // always doubles in capacity on resize but you rarely ever actually use the
    // full capacity of a dynamic array it means you have a lot of resident waste
    // if you actually zeroed the remainder of the memory.
    //
    // Keep in mind the OS is already guaranteed to give you zeroed memory by
    // mapping in this zero page multiple times so in the best case there is no
    // need to actually zero anything. As for testing all this memory for a zero
    // value, it costs nothing because the the same zero page is used for the
    // whole allocation and will exist in L1 cache for the entire zero checking
    // process.

    if n_ <= 0 {
        return
    }
    n := uint(n_)

    n_words := n / size_of(uintptr)
    p_words := ([^]uintptr)(data)[:n_words]
    p_bytes := ([^]byte)(data)[size_of(uintptr) * n_words:n]
    for &p_word in p_words {
        if p_word != 0 {
            p_word = 0
        }
    }
    for &p_byte in p_bytes {
        if p_byte != 0 {
            p_byte = 0
        }
    }
}

memory_equal :: proc(x, y: rawptr, n: int) -> bool {
    switch {
    case n == 0: return true
    case x == y: return true
    }
    a, b := cast([^]byte)x, cast([^]byte)y

    n := uint(n)
    i := uint(0)
    m := uint(0)

    if n >= 8 {
        when HAS_HARDWARE_SIMD {
            // Avoid using 256-bit SIMD on platforms where its emulation is
            // likely to be less than ideal.
            when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
                m = n / 32 * 32
                for /**/; i < m; i += 32 {
                    load_a := intrinsics.unaligned_load(cast(^#simd[32]u8)&a[i])
                    load_b := intrinsics.unaligned_load(cast(^#simd[32]u8)&b[i])
                    ne := intrinsics.simd_lanes_ne(load_a, load_b)
                    if intrinsics.simd_reduce_or(ne) != 0 {
                        return false
                    }
                }
            }
        }

        m = (n-i) / 16 * 16
        for /**/; i < m; i += 16 {
            load_a := intrinsics.unaligned_load(cast(^#simd[16]u8)&a[i])
            load_b := intrinsics.unaligned_load(cast(^#simd[16]u8)&b[i])
            ne := intrinsics.simd_lanes_ne(load_a, load_b)
            if intrinsics.simd_reduce_or(ne) != 0 {
                return false
            }
        }

        m = (n-i) / size_of(uintptr) * size_of(uintptr)
        for /**/; i < m; i += size_of(uintptr) {
            if intrinsics.unaligned_load(cast(^uintptr)&a[i]) != intrinsics.unaligned_load(cast(^uintptr)&b[i]) {
                return false
            }
        }
    }

    for /**/; i < n; i += 1 {
        if a[i] != b[i] {
            return false
        }
    }
    return true
}

/*
Compare two memory ranges defined by byte pointers.

This procedure performs a byte-by-byte comparison between memory ranges of size
`n` located at addresses `a` and `b`, and returns a value, specifying their relative
ordering.

If the return value is:
- Equal to `-1`, then `a` is "smaller" than `b`.
- Equal to `+1`, then `a` is "bigger"  than `b`.
- Equal to `0`, then `a` and `b` are equal.

The comparison is performed as follows:
1. Each byte, upto `n` bytes is compared between `a` and `b`.
    - If the byte in `a` is smaller than a byte in `b`, then comparison stops
      and this procedure returns `-1`.
    - If the byte in `a` is bigger than a byte in `b`, then comparison stops
      and this procedure returns `+1`.
    - Otherwise the comparison continues until `n` bytes are compared.
2. If all the bytes in the range are equal, this procedure returns `0`.
*/
memory_compare :: proc(x, y: rawptr, n: int) -> int #no_bounds_check {
    switch {
    case x == y:   return 0
    case x == nil: return -1
    case y == nil: return +1
    }
    a, b := cast([^]byte)x, cast([^]byte)y
    
    n := uint(n)
    i := uint(0)
    m := uint(0)

    when HAS_HARDWARE_SIMD {
        when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
            m = n / 32 * 32
            for /**/; i < m; i += 32 {
                load_a := intrinsics.unaligned_load(cast(^#simd[32]u8)&a[i])
                load_b := intrinsics.unaligned_load(cast(^#simd[32]u8)&b[i])
                comparison := intrinsics.simd_lanes_ne(load_a, load_b)
                if intrinsics.simd_reduce_or(comparison) != 0 {
                    sentinel: #simd[32]u8 = u8(0xFF)
                    indices := intrinsics.simd_indices(#simd[32]u8)
                    index_select := intrinsics.simd_select(comparison, indices, sentinel)
                    index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
                    return -1 if a[i+index_reduce] < b[i+index_reduce] else +1
                }
            }
        }
    }

    m = (n-i) / 16 * 16
    for /**/; i < m; i += 16 {
        load_a := intrinsics.unaligned_load(cast(^#simd[16]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[16]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[16]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[16]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return -1 if a[i+index_reduce] < b[i+index_reduce] else +1
        }
    }

    // 64-bit SIMD is faster than using a `uintptr` to detect a difference then
    // re-iterating with the byte-by-byte loop, at least on AMD64.
    m = (n-i) / 8 * 8
    for /**/; i < m; i += 8 {
        load_a := intrinsics.unaligned_load(cast(^#simd[8]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[8]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[8]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[8]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return -1 if a[i+index_reduce] < b[i+index_reduce] else +1
        }
    }

    for /**/; i < n; i += 1 {
        if a[i] ~ b[i] != 0 {
            return -1 if int(a[i]) - int(b[i]) < 0 else +1
        }
    }
    return 0
}

memory_compare_zero :: proc(a: rawptr, n: int) -> int #no_bounds_check {
    n := uint(n)
    i := uint(0)
    m := uint(0)

    // Because we're comparing against zero, we never return -1, as that would
    // indicate the compared value is less than zero.
    //
    // Note that a zero return value here means equality.

    bytes := ([^]u8)(a)

    if n >= 8 {
        when HAS_HARDWARE_SIMD {
            when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
                scanner32: #simd[32]u8
                m = n / 32 * 32
                for /**/; i < m; i += 32 {
                    load := intrinsics.unaligned_load(cast(^#simd[32]u8)&bytes[i])
                    ne := intrinsics.simd_lanes_ne(scanner32, load)
                    if intrinsics.simd_reduce_or(ne) > 0 {
                        return 1
                    }
                }
            }
        }

        scanner16: #simd[16]u8
        m = (n-i) / 16 * 16
        for /**/; i < m; i += 16 {
            load := intrinsics.unaligned_load(cast(^#simd[16]u8)&bytes[i])
            ne := intrinsics.simd_lanes_ne(scanner16, load)
            if intrinsics.simd_reduce_or(ne) != 0 {
                return 1
            }
        }

        m = (n-i) / size_of(uintptr) * size_of(uintptr)
        for /**/; i < m; i += size_of(uintptr) {
            if intrinsics.unaligned_load(cast(^uintptr)&bytes[i]) != 0 {
                return 1
            }
        }
    }

    for /**/; i < n; i += 1 {
        if bytes[i] != 0 {
            return 1
        }
    }
    return 0
}

memory_prefix_length :: proc(x, y: rawptr, n: int) -> (idx: int) #no_bounds_check {
    switch {
    case x == y:   return n
    case x == nil: return 0
    case y == nil: return 0
    }
    a, b := cast([^]byte)x, cast([^]byte)y

    n := uint(n)
    i := uint(0)
    m := uint(0)

    when HAS_HARDWARE_SIMD {
        when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
            m = n / 32 * 32
            for /**/; i < m; i += 32 {
                load_a := intrinsics.unaligned_load(cast(^#simd[32]u8)&a[i])
                load_b := intrinsics.unaligned_load(cast(^#simd[32]u8)&b[i])
                comparison := intrinsics.simd_lanes_ne(load_a, load_b)
                if intrinsics.simd_reduce_or(comparison) != 0 {
                    sentinel: #simd[32]u8 = u8(0xFF)
                    indices := intrinsics.simd_indices(#simd[32]u8)
                    index_select := intrinsics.simd_select(comparison, indices, sentinel)
                    index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
                    return int(i + index_reduce)
                }
            }
        }
    }

    m = (n-i) / 16 * 16
    for /**/; i < m; i += 16 {
        load_a := intrinsics.unaligned_load(cast(^#simd[16]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[16]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[16]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[16]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return int(i + index_reduce)
        }
    }

    // 64-bit SIMD is faster than using a `uintptr` to detect a difference then
    // re-iterating with the byte-by-byte loop, at least on AMD64.
    m = (n-i) / 8 * 8
    for /**/; i < m; i += 8 {
        load_a := intrinsics.unaligned_load(cast(^#simd[8]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[8]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[8]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[8]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return int(i + index_reduce)
        }
    }

    for /**/; i < n; i += 1 {
        if a[i] ~ b[i] != 0 {
            return int(i)
        }
    }
    return int(n)
}

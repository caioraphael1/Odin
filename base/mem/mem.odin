import "base:intrinsics"
import "base:internal"


//--------------------------------------------------------------------------------------------------
// Zero
//--------------------------------------------------------------------------------------------------

zero :: intrinsics.mem_zero

/*
Set each u8 of a memory range to zero.

This procedure copies the value `0` into the `len` bytes of a memory range,
starting at address `data`.

This procedure returns the pointer to `data`.

Unlike the `zero()` procedure, which can be optimized away or reordered by the
compiler under certain circumstances, `zero_explicit()` procedure can not be
optimized away or reordered with other memory access operations, and the
compiler assumes volatile semantics of the memory.
*/
@(optional_results)
zero_explicit :: proc(data: rawptr, len: uint) -> rawptr {
    // This routine tries to avoid the compiler optimizing away the call,
    // so that it is always executed.  It is intended to provide
    // equivalent semantics to those provided by the C11 Annex K 3.7.4.1
    // memset_s call.
    intrinsics.mem_zero_volatile(data, int(len)) // Use the volatile mem_zero
    intrinsics.atomic_thread_fence(.Seq_Cst) // Prevent reordering
    return data
}


/* 
When acquiring memory from the OS for the first time it's likely that the
OS already gives the zero page mapped multiple times for the request. The
actual allocation does not have physical pages allocated to it until those
pages are written to which causes a page-fault. This is often called COW
(Copy on Write)

You do not want to actually zero out memory in this case because it would
cause a bunch of page faults decreasing the speed of allocations and
increase the amount of actual resident physical memory used.

Instead a better technique is to check if memory is zerored before zeroing
it. This turns out to be an important optimization in practice, saving
nearly half (or more) the amount of physical memory used by an application.
This is why every implementation of calloc in libc does this optimization.

It may seem counter-intuitive but most allocations in an application are
wasted and never used. When you consider something like a dyn_array.Dyn_Array(T) which
always doubles in capacity on resize but you rarely ever actually use the
full capacity of a dynamic array it means you have a lot of resident waste
if you actually zeroed the remainder of the memory.

Keep in mind the OS is already guaranteed to give you zeroed memory by
mapping in this zero page multiple times so in the best case there is no
need to actually zero anything. As for testing all this memory for a zero
value, it costs nothing because the the same zero page is used for the
whole allocation and will exist in L1 cache for the entire zero checking
process.
*/
zero_conditional :: proc(data: rawptr, n: uint) #no_bounds_check {
    n_words := n / size_of(uintptr)
    p_words := ([^]uintptr)(data)[:n_words]
    p_bytes := ([^]u8)(data)[size_of(uintptr) * n_words:n]
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


//--------------------------------------------------------------------------------------------------
// Copy
//--------------------------------------------------------------------------------------------------

copy                 :: intrinsics.mem_copy
copy_non_overlapping :: intrinsics.mem_copy_non_overlapping


//--------------------------------------------------------------------------------------------------
// Pointer evaluation
//--------------------------------------------------------------------------------------------------

/*
Compare two memory ranges defined by u8 pointers.

This procedure performs a u8-by-u8 comparison between memory ranges of size
`n` located at addresses `a` and `b`, and returns a value, specifying their relative
ordering.

If the return value is:
- Equal to `-1`, then `a` is "smaller" than `b`.
- Equal to `+1`, then `a` is "bigger"  than `b`.
- Equal to `0`, then `a` and `b` are equal.

The comparison is performed as follows:
1. Each u8, upto `n` bytes is compared between `a` and `b`.
    - If the u8 in `a` is smaller than a u8 in `b`, then comparison stops
      and this procedure returns `-1`.
    - If the u8 in `a` is bigger than a u8 in `b`, then comparison stops
      and this procedure returns `+1`.
    - Otherwise the comparison continues until `n` bytes are compared.
2. If all the bytes in the range are equal, this procedure returns `0`.
*/
compare :: internal.__mem_compare
compare_zero :: internal.__mem_compare_zero
equal :: internal.__mem_equal


/*
Check whether two objects are equal on binary level.
This procedure checks whether the memory ranges occupied by objects `a` and `b` are equal.
*/
equal_simple :: proc(a, b: $T) -> bool where intrinsics.type_is_simple_compare(T) {
    a, b := a, b
    return compare((^u8)(&a), (^u8)(&b), size_of(T)) == 0
}

/*
Check if the memory range defined defined by a pointer is zero-filled.

This procedure checks whether each of the `len` bytes, starting at address
`ptr` is zero. If all bytes of this range are zero, this procedure returns
`true`. Otherwise this procedure returns `false`.
*/
is_zero_ptr :: proc(ptr: rawptr, len: uint) -> bool {
    switch {
    case len <= 0:
        return true
    case ptr == nil:
        return true
    }
    switch len {
    case 1: return (^u8)(ptr)^ == 0
    case 2: return intrinsics.unaligned_load((^u16)(ptr)) == 0
    case 4: return intrinsics.unaligned_load((^u32)(ptr)) == 0
    case 8: return intrinsics.unaligned_load((^u64)(ptr)) == 0
    }
    start := uintptr(ptr)
    start_aligned := align_forward_uintptr(start, align_of(uintptr))
    end := start + uintptr(len)
    end_aligned := align_backward_uintptr(end, align_of(uintptr))
    for b in start..<start_aligned {
        if (^u8)(b)^ != 0 {
            return false
        }
    }
    for b := start_aligned; b < end_aligned; b += size_of(uintptr) {
        if (^uintptr)(b)^ != 0 {
            return false
        }
    }
    for b in end_aligned..<end {
        if (^u8)(b)^ != 0 {
            return false
        }
    }
    return true
}

is_power_of_two :: proc(x: uintptr) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}

is_power_of_two_int :: internal.is_power_of_two_int

is_power_of_two_uint :: #force_inline proc(x: uint) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}

is_power_of_two_uintptr :: #force_inline proc(x: uintptr) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}


//--------------------------------------------------------------------------------------------------
// Alignment
//--------------------------------------------------------------------------------------------------

/*
Check if a pointer is aligned.
This procedure checks whether a pointer `x` is aligned to a boundary specified
by `align`, and returns `true` if the pointer is aligned, and false otherwise.
The specified alignment must be a power of 2.
*/
is_aligned :: proc(x: rawptr, align: uint) -> bool {
    p := uintptr(x)
    return (p & (uintptr(align) - 1)) == 0
}

align_forward_int :: #force_inline proc(ptr, align: uint) -> uint {
    internal.assert(is_power_of_two_uint(align))

    p := ptr
    modulo := p & (align-1)
    if modulo != 0 {
        p += align - modulo
    }
    return p
}

/*
This procedure returns the next address after `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.
The specified alignment must be a power of 2.
*/
align_forward_uint :: #force_inline proc(ptr, align: uint) -> uint {
    internal.assert(is_power_of_two_uint(align))

    p := ptr
    modulo := p & (align-1)
    if modulo != 0 {
        p += align - modulo
    }
    return p
}

/*
Align uint forward.
This procedure returns the next address after `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.
The specified alignment must be a power of 2.
*/
align_forward_uint2 :: proc(ptr, align: uint) -> uint {
    return uint(align_forward_uintptr(uintptr(ptr), uintptr(align)))
}

align_forward_uintptr :: #force_inline proc(ptr, align: uintptr) -> uintptr {
    internal.assert(is_power_of_two_uintptr(align))

    p := ptr
    modulo := p & (align-1)
    if modulo != 0 {
        p += align - modulo
    }
    return p
}

/*
Align uintptr forward.

This procedure returns the next address after `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/
align_forward_uintptr2 :: proc(ptr, align: uintptr) -> uintptr {
    internal.assert(is_power_of_two(align))
    return (ptr + align-1) & ~(align-1)
}

/*
Align pointer forward.

This procedure returns the next address after `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/
align_forward :: proc(ptr: rawptr, align: uintptr) -> rawptr {
    return rawptr(align_forward_uintptr(uintptr(ptr), align))
}

/*
Align uintptr backwards.

This procedure returns the previous address before `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/
align_backward_uintptr :: proc(ptr, align: uintptr) -> uintptr {
    internal.assert(is_power_of_two(align))
    return ptr & ~(align-1)
}

/*
Align rawptr backwards.

This procedure returns the previous address before `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/
align_backward :: proc(ptr: rawptr, align: uintptr) -> rawptr {
    return rawptr(align_backward_uintptr(uintptr(ptr), align))
}


/*
Align uint backwards.

This procedure returns the previous address before `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/

align_backward_uint :: proc(ptr, align: uint) -> uint {
    return uint(align_backward_uintptr(uintptr(ptr), uintptr(align)))
}

/*
General-purpose align formula.

This procedure is equivalent to `align_forward`, but it does not require the
alignment to be a power of two.
*/
@(no_sanitize_address)
align_formula_uint :: #force_inline proc(size, align: uint) -> uint {
    result := size + align - 1
    return result - result % align
}



//--------------------------------------------------------------------------------------------------
// Padding
//--------------------------------------------------------------------------------------------------

/*
Calculate the padding for header preceding aligned data.

This procedure returns the padding, following the specified pointer `ptr` that
will be able to fit in a header of the size `header_size`, immediately
preceding the memory region, aligned on a boundary specified by `align`. See
the following diagram for a visual representation.

        header size
        |<------>|
    +---+--------+------------- - - -
        | HEADER |  DATA...
    +---+--------+------------- - - -
    ^            ^
    |<---------->|
    |  padding   |
    ptr          aligned ptr

The function takes in `ptr` and `header_size`, as well as the required
alignment for `DATA`. The return value of the function is the padding between
`ptr` and `aligned_ptr` that will be able to fit the header.
*/
calc_padding_with_header :: proc(ptr: uintptr, align: uintptr, header_size: uint) -> uint {
    p, a := ptr, align
    modulo := p & (a-1)
    padding := uintptr(0)
    if modulo != 0 {
        padding = a - modulo
    }
    needed_space := uintptr(header_size)
    if padding < needed_space {
        needed_space -= padding
        if needed_space & (a-1) > 0 {
            padding += align * (1+(needed_space/align))
        } else {
            padding += align * (needed_space/align)
        }
    }
    return uint(padding)
}


//--------------------------------------------------------------------------------------------------
// Etc
//--------------------------------------------------------------------------------------------------

memory_prefix_length :: proc(x, y: rawptr, n: uint) -> (idx: uint) #no_bounds_check {
    switch {
    case x == y:   return n
    case x == nil: return 0
    case y == nil: return 0
    }
    a, b := cast([^]u8)x, cast([^]u8)y

    i := uint(0)
    m := uint(0)

    when internal.HAS_HARDWARE_SIMD {
        when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
            m = n / 32 * 32
            for ; i < m; i += 32 {
                load_a := intrinsics.unaligned_load(cast(^#simd[32]u8)&a[i])
                load_b := intrinsics.unaligned_load(cast(^#simd[32]u8)&b[i])
                comparison := intrinsics.simd_lanes_ne(load_a, load_b)
                if intrinsics.simd_reduce_or(comparison) != 0 {
                    sentinel: #simd[32]u8 = u8(0xFF)
                    indices := intrinsics.simd_indices(#simd[32]u8)
                    index_select := intrinsics.simd_select(comparison, indices, sentinel)
                    index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
                    return uint(i + index_reduce)
                }
            }
        }
    }

    m = (n-i) / 16 * 16
    for ; i < m; i += 16 {
        load_a := intrinsics.unaligned_load(cast(^#simd[16]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[16]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[16]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[16]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return uint(i + index_reduce)
        }
    }

    // 64-bit SIMD is faster than using a `uintptr` to detect a difference then
    // re-iterating with the u8-by-u8 loop, at least on AMD64.
    m = (n-i) / 8 * 8
    for ; i < m; i += 8 {
        load_a := intrinsics.unaligned_load(cast(^#simd[8]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[8]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[8]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[8]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return uint(i + index_reduce)
        }
    }

    for ; i < n; i += 1 {
        if a[i] ~ b[i] != 0 {
            return uint(i)
        }
    }
    return uint(n)
}


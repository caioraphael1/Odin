import "base:intrinsics"
import "base:mem"
import "base:internal"


Raw_Slice :: struct {
    data: rawptr,
    len:  int,
}


//--------------------------------------------------------------------------------------------------
// Initialization
//--------------------------------------------------------------------------------------------------

create :: proc($T: typeid/[]$E, #any_int len: int, allocator: mem.Allocator, loc := #caller_location) -> (res: T, err: mem.Allocator_Error) {
    err = _init_aligned(&res, size_of(E), len, align_of(E), allocator, loc)
    return
}

create_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator: mem.Allocator, loc := #caller_location) -> (res: T, err: mem.Allocator_Error) {
    err = _init_aligned(&res, size_of(E), len, alignment, allocator, loc)
    return
}

/*
Allocate a new slice with alignment for allocators that might not support the
specified alignment requirement.

This procedure allocates a new slice of type `T` with length `len`, aligned
on a boundary specified by `alignment` from an allocator specified by
`allocator`, and returns the allocated slice.

The user should `_ = delete` the return `original_data` slice not the typed `slice`.
*/
create_over_aligned :: proc(
    $T: typeid/[]$E,
    #any_int len: int,
    alignment: int,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> (slice: T, original_data: []byte, err: mem.Allocator_Error) {
    size := size_of(E)*len + alignment-1
    original_data, err = create([]byte, size, allocator, loc)
    if err == nil {
        ptr := mem.align_forward(raw_data(original_data), uintptr(alignment))
        slice = ([^]E)(ptr)[:len]
    }
    return
}

_init_aligned :: proc(slice: rawptr, elem_size: int, len: int, alignment: int, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    internal.slice_create_error_loc(loc, len)
    if len == 0 {
        return nil
    }
    data, err := mem.alloc(elem_size*len, alignment, allocator, loc)
    if data == nil && elem_size != 0 {
        return err
    }
    (^Raw_Slice)(slice).data = raw_data(data)
    (^Raw_Slice)(slice).len  = len
    return err
}

// `delete` will try to free the underlying data of the passed sliced, with the given `allocator` if the allocator supports this operation.
delete :: proc(array: $T/[]$E, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free_with_size(raw_data(array), len(array)*size_of(E), allocator, loc)
}


zero :: proc(array: $T/[]$E) #no_bounds_check {
    if len(array) > 0 {
        mem.zero(raw_data(array), size_of(E)*len(array))
    }
}

fill :: proc(array: $T/[]$E, value: E) #no_bounds_check {
    if len(array) <= 0 {
        return
    }
    array[0] = value
    for i := 1; i < len(array); i *= 2 {
        copy(array[i:], array[:i])
    }
}

from_ptr :: proc(ptr: ^$T, len: int) -> []T {
    return ([^]T)(ptr)[:len]
}


bytes :: #force_inline proc(ptr: rawptr, #any_int len: int) -> []byte {
    return ([^]byte)(ptr)[:len]
}

bytes_unsafe :: #force_inline proc(data: rawptr, #any_int len: int) -> []byte #no_bounds_check {
    return ([^]byte)(data)[:len]
}

bytes_from_ptr :: proc(ptr: ^$T, len: int) -> []byte {
    return transmute([]byte)Raw_Slice{ptr, len*size_of(T)}
}

bytes_from_slice :: proc(slice: $E/[]$T) -> []byte {
    s := transmute(Raw_Slice)slice
    s.len *= size_of(T)
    return transmute([]byte)s
}

bytes_from_any :: proc(val: any) -> []byte {
    ti := type_info_of(val.id)
    size := ti != nil ? ti.size : 0
    return transmute([]byte)Raw_Slice{val.data, size}
}


concatenate :: proc(a: []$T/[]$E, allocator: mem.Allocator) -> (res: T, err: mem.Allocator_Error) {
    if len(a) == 0 {
        return
    }
    n := 0
    for s in a {
        n += len(s)
    }
    res = make(T, n, allocator) or_return
    i := 0
    for s in a {
        i += copy(res[i:], s)
    }
    return
}

resize :: proc(
    old_data: []byte,
    new_size: int,
    alignment: int = mem.DEFAULT_ALIGNMENT,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> ([]byte, mem.Allocator_Error) {
    return mem.resize(raw_data(old_data), len(old_data), new_size, alignment, allocator, loc)
}

/*
Resize a memory region.

This procedure resizes a memory region, specified by `old_data`, such that it
has a new size, specified by `new_size` and and is aligned on a boundary
specified by `alignment`.

If the `old_data` parameter is `nil`, `resize()` acts just like
`mem.alloc()`, allocating `new_size` bytes, aligned on a boundary specified
by `alignment`.

If the `new_size` parameter is `0`, `resize()` acts just like
`free_bytes()`, freeing the memory region specified by `old_data`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

Unlike `resize()`, this procedure does not explicitly zero-initialize
any new memory.

**Inputs**:
- `old_data`: Pointer to the memory region to mem.resize.
- `new_size`: The desired size of the resized memory region.
- `alignment`: The desired alignment of the resized memory region.
- `allocator`: The owner of the memory region to mem.resize.

**Returns**:
1. The resized memory region, if successfull, `nil` otherwise.
2. Error, if mem.resize failed.

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
resize_non_zeroed :: proc(
    old_data:  []byte,
    new_size:  int,
    alignment: int = mem.DEFAULT_ALIGNMENT,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> ([]byte, mem.Allocator_Error) {
    return mem.resize_non_zero(raw_data(old_data), len(old_data), new_size, alignment, allocator, loc)
}


split_at :: proc(array: $T/[]$E, index: int) -> (a, b: T) {
    return array[:index], array[index:]
}

split_first :: proc(array: $T/[]$E) -> (first: E, rest: T) {
    return array[0], array[1:]
}

split_last :: proc(array: $T/[]$E) -> (rest: T, last: E) {
    n := len(array)-1
    return array[:n], array[n]
}


//--------------------------------------------------------------------------------------------------
// Slice Evaluation
//--------------------------------------------------------------------------------------------------

/*
Check if the memory range defined by a slice is zero-filled.
This procedure checks whether every byte, pointed to by the slice, specified
by the parameter `data`, is zero. If all bytes of the slice are zero, this
procedure returns `true`. Otherwise this procedure returns `false`.
*/
is_zero :: proc(data: []byte) -> bool {
    return mem.is_zero_ptr(raw_data(data), len(data))
}

/*
Compare two memory ranges defined by slices.
This procedure performs a byte-by-byte comparison between memory ranges
specified by slices `a` and `b`, and returns a value, specifying their relative
ordering.
If the return value is:
- Equal to `-1`, then `a` is "smaller" than `b`.
- Equal to `+1`, then `a` is "bigger"  than `b`.
- Equal to `0`, then `a` and `b` are equal.
The comparison is performed as follows:
1. Each byte, upto `min(len(a), len(b))` bytes is compared between `a` and `b`.
    - If the byte in slice `a` is smaller than a byte in slice `b`, then comparison
      stops and this procedure returns `-1`.
    - If the byte in slice `a` is bigger than a byte in slice `b`, then comparison
      stops and this procedure returns `+1`.
    - Otherwise the comparison continues until `min(len(a), len(b))` are compared.
2. If all the bytes in the range are equal, then the lengths of the slices are compared.
    - If the length of slice `a` is smaller than the length of slice `b`, then `-1` is returned.
    - If the length of slice `b` is smaller than the length of slice `b`, then `+1` is returned.
    - Otherwise `0` is returned.
*/
compare :: proc(a, b: []byte) -> int {
    res := mem.compare(cast(^byte)(raw_data(a)), cast(^byte)(raw_data(b)), min(len(a), len(b)))
    if res == 0 && len(a) != len(b) {
        return len(a) <= len(b) ? -1 : +1
    } else if len(a) == 0 && len(b) == 0 {
        return 0
    }
    return res
}

size :: proc(a: $T/[]$E) -> int {
    return len(a) * size_of(E)
}

equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_comparable(E) #no_bounds_check {
    if len(a) != len(b) {
        return false
    }
    when intrinsics.type_is_simple_compare(E) {
        if len(a) == 0 {
            // Empty slices are always equivalent to each other.
            //
            // This check is here in the event that a slice with a `data` of
            // nil is compared against a slice with a non-nil `data` but a
            // length of zero.
            //
            // In that case, `compare` would return -1 or +1 because one
            // of the pointers is nil.
            return true
        }
        return mem.compare(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
    } else {
        for i in 0..<len(a) {
            if a[i] != b[i] {
                return false
            }
        }
        return true
    }
}

equal_simple :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_simple_compare(E) {
    if len(a) != len(b) {
        return false
    }
    return mem.compare(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
}

any_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
    for v in s {
        if v == value {
            return true
        }
    }
    return false
}

none_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
    for v in s {
        if v == value {
            return false
        }
    }
    return true
}

all_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
    if len(s) == 0 {
        return false
    }
    for v in s {
        if v != value {
            return false
        }
    }
    return true
}



//--------------------------------------------------------------------------------------------------
// Copy
//--------------------------------------------------------------------------------------------------

// `copy` is a built-in procedure that copies elements from a source slice `src` to a destination slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
@(optional_results)
copy :: #force_inline proc(dst, src: $T/[]$E) -> int {
    return _rawptr_mem_copy(raw_data(dst), raw_data(src), len(dst), len(src), size_of(E))
}

// `copy_from_string` is a built-in procedure that copies elements from a source string `src` to a destination slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
@(optional_results)
copy_from_string :: #force_inline proc(dst: $T/[]$E/u8, src: $S/string) -> int {
    return _rawptr_mem_copy(raw_data(dst), raw_data(src), len(dst), len(src), 1)
}

// `copy_from_string16` is a built-in procedure that copies elements from a source string `src` to a destination slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
@(optional_results)
copy_from_string16 :: #force_inline proc(dst: $T/[]$E/u16, src: $S/string16) -> int {
    return _rawptr_mem_copy(raw_data(dst), raw_data(src), len(dst), len(src), 2)
}


@(optional_results)
_rawptr_mem_copy :: proc(dst, src: rawptr, dst_len, src_len, elem_size: int) -> int {
    n := min(dst_len, src_len)
    if n > 0 {
        mem.copy(dst, src, n*elem_size)
    }
    return n
}


clone :: proc(a: $T/[]$E, allocator: mem.Allocator, loc := #caller_location) -> ([]E, mem.Allocator_Error) {
    d, err := create([]E, len(a), allocator, loc)
    copy(d[:], a)
    return d, err
}

clone_to_dynamic :: proc(a: $T/[]$E, allocator: mem.Allocator, loc := #caller_location) -> ([dynamic]E, mem.Allocator_Error) {
    d, err := dyn_array.create([dynamic]E, len(a), allocator, loc)
    copy(d[:], a)
    return d, err
}



//--------------------------------------------------------------------------------------------------
// Casting
//--------------------------------------------------------------------------------------------------

/*
Transmute slice to a different type.

This procedure performs an operation similar to transmute, returning a slice of
type `T` that points to the same bytes as the slice specified by `slice`
parameter. Unlike plain transmute operation, this procedure adjusts the length
of the resulting slice, such that the resulting slice points to the correct
amount of objects to cover the memory region pointed to by `slice`.
*/
data_cast :: proc($T: typeid/[]$A, slice: $S/[]$B) -> T {
    when size_of(A) == 0 || size_of(B) == 0 {
        return nil
    } else {
        s := transmute(Raw_Slice)slice
        s.len = (len(slice) * size_of(B)) / size_of(A)
        return transmute(T)s
    }
}

to_type :: proc(buf: []u8, $T: typeid) -> (T, bool) {
    if len(buf) < size_of(T) {
        return {}, false
    }
    return intrinsics.unaligned_load((^T)(raw_data(buf))), true
}

/*
Turn a slice of one type, into a slice of another type.

Only converts the type and length of the slice itself.
The length is rounded down to the nearest whole number of items.

Example:

    import "core:fmt"
    import "base:slice"

    i64s_as_i32s :: proc() {
        large_items := []i64{1, 2, 3, 4}
        small_items := slice.reinterpret([]i32, large_items)
        assert(len(small_items) == 8)
        fmt.println(large_items, "->", small_items)
    }

    bytes_as_i64s :: proc() {
        small_items := [12]byte{}
        small_items[0] = 1
        small_items[8] = 2
        large_items := slice.reinterpret([]i64, small_items[:])
        assert(len(large_items) == 1) // only enough bytes to make 1 x i64; two would need at least 8 bytes.
        fmt.println(small_items, "->", large_items)
    }

    reinterpret_example :: proc() {
        i64s_as_i32s()
        bytes_as_i64s()
    }

Output:
    [1, 2, 3, 4] -> [1, 0, 2, 0, 3, 0, 4, 0]
    [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0] -> [1]

*/
reinterpret :: proc($T: typeid/[]$U, s: []$V) -> []U {
    when size_of(U) == 0 || size_of(V) == 0 {
        return nil
    } else {
        bytes := to_bytes(s)
        n := len(bytes) / size_of(U)
        return ([^]U)(raw_data(bytes))[:n]
    }
}


/*
Obtain data and length of a slice.

This procedure returns the pointer to the start of the memory region pointed to
by slice `slice` and the length of the slice.
*/
to_components :: proc(slice: $E/[]$T) -> (data: ^T, len: int) {
    s := transmute(Raw_Slice)slice
    return (^T)(s.data), s.len
}

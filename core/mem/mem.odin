import "base:runtime"
import "base:intrinsics"


/*
Set each byte of a memory range to zero.

This procedure copies the value `0` into the `len` bytes of a memory range,
starting at address `data`.

This procedure returns the pointer to `data`.

Unlike the `zero()` procedure, which can be optimized away or reordered by the
compiler under certain circumstances, `zero_explicit()` procedure can not be
optimized away or reordered with other memory access operations, and the
compiler assumes volatile semantics of the memory.
*/
@(optional_results)
zero_explicit :: proc(data: rawptr, len: int) -> rawptr {
    // This routine tries to avoid the compiler optimizing away the call,
    // so that it is always executed.  It is intended to provide
    // equivalent semantics to those provided by the C11 Annex K 3.7.4.1
    // memset_s call.
    intrinsics.mem_zero_volatile(data, len) // Use the volatile mem_zero
    intrinsics.atomic_thread_fence(.Seq_Cst) // Prevent reordering
    return data
}

/*
Zero-fill the memory of an object.

This procedure sets each byte of the object pointed to by the pointer `item`
to zero, and returns the pointer to `item`.
*/
zero_item :: proc(item: $P/^$T) -> P {
    intrinsics.mem_zero(item, size_of(T))
    return item
}

/*
Zero-fill the memory of the slice.

This procedure sets each byte of the slice pointed to by the slice `data`
to zero, and returns the slice `data`.
*/
@(optional_results)
zero_slice :: proc(data: $T/[]$E) -> T {
    intrinsics.mem_zero(raw_data(data), size_of(E)*len(data))
    return data
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
    res := runtime.memory_compare(cast(^byte)(raw_data(a)), cast(^byte)(raw_data(b)), min(len(a), len(b)))
    if res == 0 && len(a) != len(b) {
        return len(a) <= len(b) ? -1 : +1
    } else if len(a) == 0 && len(b) == 0 {
        return 0
    }
    return res
}

/*
Check whether two objects are equal on binary level.

This procedure checks whether the memory ranges occupied by objects `a` and
`b` are equal.
*/

simple_equal :: proc(a, b: $T) -> bool where intrinsics.type_is_simple_compare(T) {
    a, b := a, b
    return runtime.memory_compare((^byte)(&a), (^byte)(&b), size_of(T)) == 0
}

/*
Check if the memory range defined by a slice is zero-filled.

This procedure checks whether every byte, pointed to by the slice, specified
by the parameter `data`, is zero. If all bytes of the slice are zero, this
procedure returns `true`. Otherwise this procedure returns `false`.
*/

check_zero :: proc(data: []byte) -> bool {
    return check_zero_ptr(raw_data(data), len(data))
}

/*
Check if the memory range defined defined by a pointer is zero-filled.

This procedure checks whether each of the `len` bytes, starting at address
`ptr` is zero. If all bytes of this range are zero, this procedure returns
`true`. Otherwise this procedure returns `false`.
*/

check_zero_ptr :: proc(ptr: rawptr, len: int) -> bool {
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
        if (^byte)(b)^ != 0 {
            return false
        }
    }
    for b := start_aligned; b < end_aligned; b += size_of(uintptr) {
        if (^uintptr)(b)^ != 0 {
            return false
        }
    }
    for b in end_aligned..<end {
        if (^byte)(b)^ != 0 {
            return false
        }
    }
    return true
}


/*
Construct a slice from pointer and length.

This procedure creates a slice, that points to `len` amount of objects located
at an address, specified by `ptr`.
*/

slice_ptr :: proc(ptr: ^$T, len: int) -> []T {
    return ([^]T)(ptr)[:len]
}

/*
Construct a byte slice from raw pointer and length.

This procedure creates a byte slice, that points to `len` amount of bytes
located at an address specified by `data`.
*/

byte_slice :: #force_inline proc(data: rawptr, #any_int len: int) -> []byte {
    return ([^]u8)(data)[:max(len, 0)]
}

/*
Create a byte slice from pointer and length.

This procedure creates a byte slice, pointing to `len` objects, starting from
the address specified by `ptr`.
*/

ptr_to_bytes :: proc(ptr: ^$T, len := 1) -> []byte {
    return transmute([]byte)Raw_Slice{ptr, len*size_of(T)}
}

/*
Obtain the slice, pointing to the contents of `any`.

This procedure returns the slice, pointing to the contents of the specified
value of the `any` type.
*/

any_to_bytes :: proc(val: any) -> []byte {
    ti := type_info_of(val.id)
    size := ti != nil ? ti.size : 0
    return transmute([]byte)Raw_Slice{val.data, size}
}

/*
Obtain a byte slice from any slice.

This procedure returns a slice, that points to the same bytes as the slice,
specified by `slice` and returns the resulting byte slice.
*/

slice_to_bytes :: proc(slice: $E/[]$T) -> []byte {
    s := transmute(Raw_Slice)slice
    s.len *= size_of(T)
    return transmute([]byte)s
}

/*
Transmute slice to a different type.

This procedure performs an operation similar to transmute, returning a slice of
type `T` that points to the same bytes as the slice specified by `slice`
parameter. Unlike plain transmute operation, this procedure adjusts the length
of the resulting slice, such that the resulting slice points to the correct
amount of objects to cover the memory region pointed to by `slice`.
*/

slice_data_cast :: proc($T: typeid/[]$A, slice: $S/[]$B) -> T {
    when size_of(A) == 0 || size_of(B) == 0 {
        return nil
    } else {
        s := transmute(Raw_Slice)slice
        s.len = (len(slice) * size_of(B)) / size_of(A)
        return transmute(T)s
    }
}

/*
Obtain data and length of a slice.

This procedure returns the pointer to the start of the memory region pointed to
by slice `slice` and the length of the slice.
*/

slice_to_components :: proc(slice: $E/[]$T) -> (data: ^T, len: int) {
    s := transmute(Raw_Slice)slice
    return (^T)(s.data), s.len
}

/*
Create a dynamic array from slice.

This procedure creates a dynamic array, using slice `backing` as the backing
buffer for the dynamic array. The resulting dynamic array can not grow beyond
the size of the specified slice.
*/

buffer_from_slice :: proc(backing: $T/[]$E) -> [dynamic]E {
    return transmute([dynamic]E)Raw_Dynamic_Array{
        data      = raw_data(backing),
        len       = 0,
        cap       = len(backing),
        allocator = Allocator{
            procedure = nil_allocator_proc,
            data = nil,
        },
    }
}

/*
Check whether a number is a power of two.

This procedure checks whether a given pointer-sized unsigned integer contains
a power-of-two value.
*/

is_power_of_two :: proc(x: uintptr) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}

/*
Check if a pointer is aligned.

This procedure checks whether a pointer `x` is aligned to a boundary specified
by `align`, and returns `true` if the pointer is aligned, and false otherwise.

The specified alignment must be a power of 2.
*/
is_aligned :: proc(x: rawptr, align: int) -> bool {
    p := uintptr(x)
    return (p & (uintptr(align) - 1)) == 0
}

/*
Align uintptr forward.

This procedure returns the next address after `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/

align_forward_uintptr :: proc(ptr, align: uintptr) -> uintptr {
    assert(is_power_of_two(align))
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
Align int forward.

This procedure returns the next address after `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/

align_forward_int :: proc(ptr, align: int) -> int {
    return int(align_forward_uintptr(uintptr(ptr), uintptr(align)))
}

/*
Align uint forward.

This procedure returns the next address after `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/

align_forward_uint :: proc(ptr, align: uint) -> uint {
    return uint(align_forward_uintptr(uintptr(ptr), uintptr(align)))
}

/*
Align uintptr backwards.

This procedure returns the previous address before `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/

align_backward_uintptr :: proc(ptr, align: uintptr) -> uintptr {
    assert(is_power_of_two(align))
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
Align int backwards.

This procedure returns the previous address before `ptr`, that is located on the
alignment boundary specified by `align`. If `ptr` is already aligned to `align`
bytes, `ptr` is returned.

The specified alignment must be a power of 2.
*/

align_backward_int :: proc(ptr, align: int) -> int {
    return int(align_backward_uintptr(uintptr(ptr), uintptr(align)))
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
Copy the value from a pointer into a value.

This procedure copies the object of type `T` pointed to by the pointer `ptr`
into a new stack-allocated value and returns that value.
*/

reinterpret_copy :: proc($T: typeid, ptr: rawptr) -> (value: T) {
    slice_copy(&value, ptr, size_of(T))
    return
}

/*
Dynamic array with a fixed capacity buffer.

This type represents dynamic arrays with a fixed-size backing buffer. Upon
allocating memory beyond reaching the maximum capacity, allocations from fixed
byte buffers return `nil` and no error.
*/
Fixed_Byte_Buffer :: distinct [dynamic]byte

/*
Create a fixed byte buffer from a slice.
*/

make_fixed_byte_buffer :: proc(backing: []byte) -> Fixed_Byte_Buffer {
    s := transmute(Raw_Slice)backing
    d: Raw_Dynamic_Array
    d.data = s.data
    d.len = 0
    d.cap = s.len
    d.allocator = Allocator{
        procedure = nil_allocator_proc,
        data = nil,
    }
    return transmute(Fixed_Byte_Buffer)d
}

/*
General-purpose align formula.

This procedure is equivalent to `align_forward`, but it does not require the
alignment to be a power of two.
*/

align_formula :: proc(size, align: int) -> int {
    result := size + align-1
    return result - result%align
}

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

calc_padding_with_header :: proc(ptr: uintptr, align: uintptr, header_size: int) -> int {
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
    return int(padding)
}

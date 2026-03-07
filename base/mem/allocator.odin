import "base:internal"


DEFAULT_ALIGNMENT :: internal.DEFAULT_ALIGNMENT

/*
Default page size.

This value is the default page size for the current platform.
*/
DEFAULT_PAGE_SIZE ::
    64 * 1024 when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 else
    16 * 1024 when ODIN_OS == .Darwin && ODIN_ARCH == .arm64 else
    4 * 1024


/*
Allocator.

This type represents generic interface for all allocators. Currently this type
is defined as follows:

    Allocator :: struct {
        procedure: Allocator_Proc,
        data: rawptr,
    }

- `procedure`: Pointer to the allocation procedure.
- `data`: Pointer to the allocator data.
*/
Allocator :: internal.Allocator

/*
A request to allocator procedure.

This type represents a type of allocation request made to an allocator
procedure. There is one allocator procedure per allocator, and this value is
used to discriminate between different functions of the allocator.

The type is defined as follows:

    Allocator_Mode :: enum byte {
        Alloc,
        Alloc_Non_Zeroed,
        Free,
        Free_All,
        Resize,
        Resize_Non_Zeroed,
        Query_Features,
    }

Depending on which value is used, the allocator procedure will perform different
functions:

- `Alloc`: Allocates a memory region with a given `size` and `alignment`.
- `Alloc_Non_Zeroed`: Same as `Alloc` without explicit zero-initialization of
    the memory region.
- `Free`: Free a memory region located at address `ptr` with a given `size`.
- `Free_All`: Free all memory allocated using this allocator.
- `Resize`: Resize a memory region located at address `old_ptr` with size
    `old_size` to be `size` bytes in length and have the specified `alignment`,
    in case a re-alllocation occurs.
- `Resize_Non_Zeroed`: Same as `Resize`, without explicit zero-initialization.
*/
Allocator_Mode :: internal.Allocator_Mode

/*
A set of allocator features.

This type represents values that contain a set of features an allocator has.
Currently the type is defined as follows:

    Allocator_Mode_Set :: distinct bit_set[Allocator_Mode];
*/
Allocator_Mode_Set :: distinct bit_set[Allocator_Mode]

/*
Allocator information.

This type represents information about a given allocator at a specific point
in time. Currently the type is defined as follows:

    Allocator_Query_Info :: struct {
        pointer:   rawptr,
        size:      Maybe(int),
        alignment: Maybe(int),
    }

- `pointer`: Pointer to a backing buffer.
- `size`: Size of the backing buffer.
- `alignment`: The allocator's alignment.

If not applicable, any of these fields may be `nil`.
*/
Allocator_Query_Info :: struct {
    pointer:   rawptr,
    size:      Maybe(int),
    alignment: Maybe(int),
}


/*
An allocation request error.

This type represents error values the allocators may return upon requests.

    Allocator_Error :: enum byte {
        None                 = 0,
        Out_Of_Memory        = 1,
        Invalid_Pointer      = 2,
        Invalid_Argument     = 3,
        Mode_Not_Implemented = 4,
    }

The meaning of the errors is as follows:

- `None`: No error.
- `Out_Of_Memory`: Either:
    1. The allocator has ran out of the backing buffer, or the requested
        allocation size is too large to fit into a backing buffer.
    2. The operating system error during memory allocation.
    3. The backing allocator was used to allocate a new backing buffer and the
        backing allocator returned Out_Of_Memory.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
    to any of the allocators backing buffers or does not point to a valid start
    of an allocation made in that allocator.
- `Invalid_Argument`: Can occur if one of the arguments makes it impossible to
    satisfy a request (i.e. having alignment larger than the backing buffer
    of the allocation).
- `Mode_Not_Implemented`: The allocator does not support the specified
    operation. For example, an arena does not support freeing individual
    allocations.
*/
Allocator_Error :: internal.Allocator_Error


/*
The allocator procedure.

This type represents allocation procedures. An allocation procedure is a single
procedure, implementing all allocator functions such as allocating the memory,
freeing the memory, etc.

Currently the type is defined as follows:

    Allocator_Proc :: #type proc(
        allocator_data: rawptr,
        mode: Allocator_Mode,
        size: int,
        alignment: int,
        old_memory: rawptr,
        old_size: int,
        location: Source_Code_Location = #caller_location,
    ) -> ([]byte, Allocator_Error);

The function of this procedure and the meaning of parameters depends on the
value of the `mode` parameter. For any operation the following constraints
apply:

- The `alignment` must be a power of two.
- The `size` must be a positive integer.

## 1. `.Alloc`, `.Alloc_Non_Zeroed`

Allocates a memory region of size `size`, aligned on a boundary specified by
`alignment`.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Alloc` or `.Alloc_Non_Zeroed`.
- `size`: The desired size of the memory region.
- `alignment`: The desired alignmnet of the allocation.
- `old_memory`: Unused, should  be `nil`.
- `old_size`: Unused, should be 0.

**Returns**:
1. The memory region, if allocated successfully, or `nil` otherwise.
2. An error, if allocation failed.

**Note**: The nil allocator may return `nil`, even if no error is returned.
Always check both the error and the allocated buffer.

**Note**: The `.Alloc` mode is required to be implemented for an allocator
and can not return a `.Mode_Not_Implemented` error.

## 2. `Free`

Frees a memory region located at the address specified by `old_memory`. If the
allocator does not track sizes of allocations, the size should be specified in
the `old_size` parameter.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Free`.
- `size`: Unused, should be 0.
- `alignment`: Unused, should be 0.
- `old_memory`: Pointer to the memory region to free.
- `old_size`: The size of the memory region to free. This parameter is optional
    if the allocator keeps track of the sizes of allocations.

**Returns**:
1. `nil`
2. Error, if freeing failed.

## 3. `Free_All`

Frees all allocations, associated with the allocator, making it available for
further allocations using the same backing buffers.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Free_All`.
- `size`: Unused, should be 0.
- `alignment`: Unused, should be 0.
- `old_memory`: Unused, should be `nil`.
- `old_size`: Unused, should be `0`.

**Returns**:
1. `nil`.
2. Error, if freeing failed.

## 4. `Resize`, `Resize_Non_Zeroed`

Resizes the memory region, of the size `old_size` located at the address
specified by `old_memory` to have the new size `size`. The slice of the new
memory region is returned from the procedure. The allocator may attempt to
keep the new memory region at the same address as the previous allocation,
however no such guarantee is made. Do not assume the new memory region will
be at the same address as the old memory region.

If `old_memory` pointer is `nil`, this function acts just like `.Alloc` or
`.Alloc_Non_Zeroed`, using `size` and `alignment` to allocate a new memory
region.

If `new_size` is `nil`, the procedure acts just like `.Free`, freeing the
memory region `old_size` bytes in length, located at the address specified by
`old_memory`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Resize` or `.Resize_All`.
- `size`: The desired new size of the memory region.
- `alignment`: The alignment of the new memory region, if its allocated
- `old_memory`: The pointer to the memory region to resize.
- `old_size`: The size of the memory region to resize. If the allocator
    keeps track of the sizes of allocations, this parameter is optional.

**Returns**:
1. The slice of the  memory region after resize operation, if successfull,
    `nil` otherwise.
2. An error, if the resize failed.

**Note**: Some allocators may return `nil`, even if no error is returned.
Always check both the error and the allocated buffer.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
Allocator_Proc :: internal.Allocator_Proc


// @(builtin)
new :: proc($T: typeid, allocator: Allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
    t = (^T)(raw_data(mem_alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return))
    return
}

new_aligned :: proc($T: typeid, alignment: int, allocator: Allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
    t = (^T)(raw_data(mem_alloc_bytes(size_of(T), alignment, allocator, loc) or_return))
    return
}

// @(builtin)
new_clone :: proc(data: $T, allocator: Allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
    t = (^T)(raw_data(mem_alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return))
    if t != nil {
        t^ = data
    }
    return
}

// @(builtin)
free :: #force_no_inline proc(ptr: rawptr, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    assert(allocator.procedure != nil, loc=loc)
    if ptr == nil {
        return nil
    }
    _, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0, loc)
    return err
}

free_with_size :: internal.mem_free_with_size


free_bytes :: #force_no_inline proc(bytes: []byte, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    assert(allocator.procedure != nil, loc=loc)
    if bytes == nil {
        return nil
    }
    _, err := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(bytes), len(bytes), loc)
    return err
}

// @(builtin)
free_all :: #force_no_inline proc(allocator: Allocator, loc := #caller_location) -> (err: Allocator_Error) {
    assert(allocator.procedure != nil, loc=loc)
    _, err = allocator.procedure(allocator.data, .Free_All, 0, 0, nil, 0, loc)
    return
}

alloc :: #force_no_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, "Allocator not defined", loc)
    assert(size > 0, "Size must be greater than zero", loc)
    return allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0, loc)
}

alloc_raw :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> (rawptr, Allocator_Error) {
    data, err := alloc(size, alignment, allocator, loc)
    return raw_data(data), err
}

alloc_non_zeroed :: internal.mem_alloc_non_zeroed


resize          :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, "Allocator not defined", loc)
    return _resize(ptr, old_size, new_size, alignment, allocator, true, loc)
}

resize_non_zero :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, "Allocator not defined", loc)
    return _resize(ptr, old_size, new_size, alignment, allocator, false, loc)
}

_resize :: #force_no_inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, should_zero: bool, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
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
        // slice.copy(data, ([^]byte)(ptr)[:old_size])
            // (2026-03-06) Replaced by:
        copy(raw_data(data), ptr, old_size)

        _, err = allocator.procedure(allocator.data, .Free, 0, 0, ptr, old_size, loc)
    }
    return
}


/*
Query allocator features.
*/
query_features :: proc(allocator: Allocator, loc := #caller_location) -> (set: Allocator_Mode_Set) {
    if allocator.procedure != nil {
        _, _ = allocator.procedure(allocator.data, .Query_Features, 0, 0, &set, 0, loc)
        return set
    }
    return nil
}

/*
Query allocator information.
*/
query_info :: proc(
    pointer: rawptr,
    allocator: Allocator,
    loc := #caller_location,
) -> (props: Allocator_Query_Info) {
    props.pointer = pointer
    if allocator.procedure != nil {
        _, _ = allocator.procedure(allocator.data, .Query_Info, 0, 0, &props, 0, loc)
    }
    return
}

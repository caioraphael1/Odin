import "base:internal"
import "base:mem"
import "base:container/slice"
import "base:bytes"

/*
Allocation header of the small stack allocator.
*/
Small_Stack_Allocation_Header :: struct {
    padding: u8,
}

/*
Small stack allocator data.
*/
Small_Stack :: struct {
    data:      []byte,
    offset:    uint,
    peak_used: uint,
}

/*
Initialize a small stack allocator.

This procedure initializes the small stack allocator with `data` as its backing
buffer.
*/
small_stack_init :: proc(s: ^Small_Stack, data: []byte) {
    s.data      = data
    s.offset    = 0
    s.peak_used = 0
    // sanitizer.address_poison(data)
}

/*
Small stack allocator.

The small stack allocator is just like a `Stack` allocator, with the only
difference being an extremely small header size. Unlike the stack allocator,
the small stack allows out-of order freeing of memory, with the stipulation
that all allocations made after the freed allocation will become invalidated
upon following allocations as they will begin to overwrite the memory formerly
used by the freed allocation.

The memory is allocated in the backing buffer linearly, from start to end.
Each subsequent allocation will get the next adjacent memory region.

The metadata is stored in the allocation headers, that are located before the
start of each allocated memory region. Each header contains the amount of
padding bytes between that header and end of the previous allocation.
*/

small_stack_allocator :: proc(stack: ^Small_Stack) -> mem.Allocator {
    return mem.Allocator{
        procedure = small_stack_allocator_proc,
        data      = stack,
    }
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is zero-initialized. This procedure
returns a pointer to the allocated memory region.
*/

small_stack_alloc :: proc(
    s:         ^Small_Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc        := #caller_location,
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := small_stack_alloc_bytes(s, size, alignment, loc)
    return raw_data(bytes), err
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is zero-initialized. This procedure
returns a slice of the allocated memory region.
*/

small_stack_alloc_bytes :: proc(
    s:         ^Small_Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc        := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    bytes, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    if bytes != nil {
        slice.zero(bytes)
    }
    return bytes, err
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is not explicitly zero-initialized. This
procedure returns a pointer to the allocated memory region.
*/

small_stack_alloc_non_zeroed :: proc(
    s:         ^Small_Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc        := #caller_location,
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    return raw_data(bytes), err
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is not explicitly zero-initialized. This
procedure returns a slice of the allocated memory region.
*/
@(no_sanitize_address)
small_stack_alloc_bytes_non_zeroed :: proc(
    s:         ^Small_Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc        := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    if s.data == nil {
        internal.panic("Allocation on an uninitialized Small Stack allocator.", loc)
    }
    alignment := alignment
    alignment = clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)
    curr_addr := uintptr(raw_data(s.data)) + uintptr(s.offset)
    padding := mem.calc_padding_with_header(curr_addr, uintptr(alignment), size_of(Small_Stack_Allocation_Header))
    if s.offset + padding + size > len(s.data) {
        return nil, .Out_Of_Memory
    }
    s.offset += padding
    next_addr := curr_addr + uintptr(padding)
    header := (^Small_Stack_Allocation_Header)(next_addr - size_of(Small_Stack_Allocation_Header))
    header.padding = cast(u8)padding
    // We must poison the header, no matter what its state is, because there
    // may have been an out-of-order free before this point.
    // sanitizer.address_poison(header)
    s.offset += size
    s.peak_used = max(s.peak_used, s.offset)
    result := bytes.bytes(rawptr(next_addr), size)
    // NOTE: We cannot ensure the poison state of this allocation, because this
    // allocator allows out-of-order frees with overwriting.
    // sanitizer.address_unpoison(result)
    return result, nil
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is not explicitly zero-initialized. This
procedure returns a slice of the allocated memory region.
*/
small_stack_free :: proc(
    s:          ^Small_Stack,
    old_memory: rawptr,
    loc         := #caller_location,
) -> mem.Allocator_Error {
    if s.data == nil {
        internal.panic("Free on an uninitialized Small Stack allocator.", loc)
    }
    if old_memory == nil {
        return nil
    }
    start := uintptr(raw_data(s.data))
    end := start + uintptr(len(s.data))
    curr_addr := uintptr(old_memory)
    if !(start <= curr_addr && curr_addr < end) {
        internal.panic("Out of bounds memory address passed to Small Stack allocator. (free)", loc)
    }
    if curr_addr >= start+uintptr(s.offset) {
        // NOTE(bill): Allow double frees
        return nil
    }
    header := (^Small_Stack_Allocation_Header)(curr_addr - size_of(Small_Stack_Allocation_Header))
    old_offset := uint(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))
    // sanitizer.address_poison(s.data[old_offset:s.offset])
    s.offset = old_offset
    return nil
}

/*
Free all memory back to the small stack allocator.
*/
small_stack_free_all :: proc(s: ^Small_Stack) {
    s.offset = 0
    // sanitizer.address_poison(s.data)
}

/*
Resize an allocation owned by a small stack allocator.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/

small_stack_resize :: proc(
    s:          ^Small_Stack,
    old_memory: rawptr,
    old_size:   uint,
    size:       uint,
    alignment:  uint = mem.DEFAULT_ALIGNMENT,
    loc         := #caller_location,
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := small_stack_resize_bytes(s, bytes.bytes(old_memory, old_size), size, alignment, loc)
    return raw_data(bytes), err
}

/*
Resize an allocation owned by a small stack allocator.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is
zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/

small_stack_resize_bytes :: proc(
    s:         ^Small_Stack,
    old_data:  []byte,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc        := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    bytes, err := small_stack_resize_bytes_non_zeroed(s, old_data, size, alignment, loc)
    if bytes != nil {
        if old_data == nil {
            slice.zero(bytes)
        } else if size > len(old_data) {
            slice.zero(bytes[len(old_data):])
        }
    }
    return bytes, err
}

/*
Resize an allocation owned by a small stack allocator, without zero-initialization.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is not explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/

small_stack_resize_non_zeroed :: proc(
    s:          ^Small_Stack,
    old_memory: rawptr,
    old_size:   uint,
    size:       uint,
    alignment:  uint = mem.DEFAULT_ALIGNMENT,
    loc         := #caller_location,
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := small_stack_resize_bytes_non_zeroed(s, bytes.bytes(old_memory, old_size), size, alignment, loc)
    return raw_data(bytes), err
}

/*
Resize an allocation owned by a small stack allocator, without zero-initialization.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is not
explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/

small_stack_resize_bytes_non_zeroed :: proc(
    s:         ^Small_Stack,
    old_data:  []byte,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc        := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    if s.data == nil {
        internal.panic("Resize on an uninitialized Small Stack allocator.", loc)
    }
    old_memory := raw_data(old_data)
    old_size   := len(old_data)
    alignment  := alignment
    alignment = clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)
    if old_memory == nil {
        return small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    }
    if size == 0 {
        return nil, small_stack_free(s, old_memory, loc)
    }
    start     := uintptr(raw_data(s.data))
    end       := start + uintptr(len(s.data))
    curr_addr := uintptr(old_memory)
    if !(start <= curr_addr && curr_addr < end) {
        internal.panic("Out of bounds memory address passed to Small Stack allocator. (resize)", loc)
    }
    if curr_addr >= start+uintptr(s.offset) {
        // NOTE(bill): Treat as a double free
        return nil, nil
    }
    if uintptr(old_memory) & uintptr(alignment-1) != 0 {
        // A different alignment has been requested and the current address
        // does not satisfy it.
        data, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
        if err == nil {
            slice.copy(data, bytes.bytes(old_memory, old_size))
            // sanitizer.address_poison(old_memory)
        }
        return data, err
    }
    if old_size == size {
        result := bytes.bytes(old_memory, size)
        // sanitizer.address_unpoison(result)
        return result, nil
    }
    data, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    if err == nil {
        slice.copy(data, bytes.bytes(old_memory, old_size))
    }
    return data, err

}

small_stack_allocator_proc :: proc(
    allocator_data:  rawptr,
    mode:            mem.Allocator_Mode,
    size, alignment: uint,
    old_memory:      rawptr,
    old_size:        uint,
    loc := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    s := cast(^Small_Stack)allocator_data
    if s.data == nil {
        return nil, .Invalid_Argument
    }
    switch mode {
    case .Alloc:
        return small_stack_alloc_bytes(s, size, alignment, loc)
    case .Alloc_Non_Zeroed:
        return small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    case .Free:
        return nil, small_stack_free(s, old_memory, loc)
    case .Free_All:
        small_stack_free_all(s)
    case .Resize:
        return small_stack_resize_bytes(s, bytes.bytes(old_memory, old_size), size, alignment, loc)
    case .Resize_Non_Zeroed:
        return small_stack_resize_bytes_non_zeroed(s, bytes.bytes(old_memory, old_size), size, alignment, loc)
    case .Query_Features:
        set := (^mem.Allocator_Mode_Set)(old_memory)
        if set != nil {
            set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
        }
        return nil, nil
    case .Query_Info:
        return nil, .Mode_Not_Implemented
    }
    return nil, nil
}

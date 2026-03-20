import "base:internal"
import "base:mem"
import "base:container/slice"
import "base:bytes"

/*
Stack allocator data.
*/
Stack :: struct {
    data:        []byte,
    prev_offset: uint,
    curr_offset: uint,
    peak_used:   uint,
}

/*
Header of a stack allocation.
*/
Stack_Allocation_Header :: struct {
    prev_offset: uint,
    padding:     uint,
}

/*
Stack allocator.

The stack allocator is an allocator that allocates data in the backing buffer
linearly, from start to end. Each subsequent allocation will get the next
adjacent memory region.

Unlike arena allocator, the stack allocator saves allocation metadata and has
a strict freeing order. Only the last allocated element can be freed. After the
last allocated element is freed, the next previous allocated element becomes
available for freeing.

The metadata is stored in the allocation headers, that are located before the
start of each allocated memory region. Each header points to the start of the
previous allocation header.
*/

stack_allocator :: proc(stack: ^Stack) -> mem.Allocator {
    return mem.Allocator{
        procedure = stack_allocator_proc,
        data      = stack,
    }
}

/*
Initialize a stack allocator.

This procedure initializes the stack allocator with a backing buffer specified
by `data` parameter.
*/
stack_init :: proc(s: ^Stack, data: []byte) {
    s.data        = data
    s.prev_offset = 0
    s.curr_offset = 0
    s.peak_used   = 0
    // sanitizer.address_poison(data)
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is zero-initialized. This
procedure returns the pointer to the allocated memory.
*/

stack_alloc :: proc(
    s:         ^Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := stack_alloc_bytes(s, size, alignment, loc)
    return raw_data(bytes), err
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is zero-initialized. This
procedure returns the slice of the allocated memory.
*/

stack_alloc_bytes :: proc(
    s:         ^Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location
) -> ([]byte, mem.Allocator_Error) {
    bytes, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    if bytes != nil {
        slice.zero(bytes)
    }
    return bytes, err
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is not explicitly
zero-initialized. This procedure returns the pointer to the allocated memory.
*/

stack_alloc_non_zeroed :: proc(
    s:         ^Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    return raw_data(bytes), err
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is not explicitly
zero-initialized. This procedure returns the slice of the allocated memory.
*/
@(no_sanitize_address)
stack_alloc_bytes_non_zeroed :: proc(
    s:         ^Stack,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location
) -> ([]byte, mem.Allocator_Error) {
    if s.data == nil {
        internal.panic("Allocation on an uninitialized Stack allocator.", loc)
    }
    curr_addr := uintptr(raw_data(s.data)) + uintptr(s.curr_offset)
    padding := mem.calc_padding_with_header(
        curr_addr,
        uintptr(alignment),
        size_of(Stack_Allocation_Header),
    )
    if s.curr_offset + padding + size > len(s.data) {
        return nil, .Out_Of_Memory
    }
    old_offset := s.prev_offset
    s.prev_offset = s.curr_offset
    s.curr_offset += padding
    next_addr := curr_addr + uintptr(padding)
    header := (^Stack_Allocation_Header)(next_addr - size_of(Stack_Allocation_Header))
    header.padding = padding
    header.prev_offset = old_offset
    s.curr_offset += size
    s.peak_used = max(s.peak_used, s.curr_offset)
    result := bytes.bytes(rawptr(next_addr), size)
    // ensure_poisoned(result)
    // sanitizer.address_unpoison(result)
    return result, nil
}

/*
Free memory back to the stack allocator.

This procedure frees the memory region starting at `old_memory` to the stack.
If the freeing is an out of order freeing, the `.Invalid_Pointer` error
is returned.
*/
stack_free :: proc(
    s:          ^Stack,
    old_memory: rawptr,
    loc := #caller_location,
) -> (mem.Allocator_Error) {
    if s.data == nil {
        internal.panic("Free on an uninitialized Stack allocator.", loc)
    }
    if old_memory == nil {
        return nil
    }
    start := uintptr(raw_data(s.data))
    end := start + uintptr(len(s.data))
    curr_addr := uintptr(old_memory)
    if !(start <= curr_addr && curr_addr < end) {
        internal.panic("Out of bounds memory address passed to Stack allocator. (free)", loc)
    }
    if curr_addr >= start+uintptr(s.curr_offset) {
        // NOTE(bill): Allow double frees
        return nil
    }
    header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header))
    old_offset := uint(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))
    if old_offset != s.prev_offset {
        return .Invalid_Pointer
    }

    s.prev_offset = header.prev_offset
    // sanitizer.address_poison(s.data[old_offset:s.curr_offset])
    s.curr_offset = old_offset

    return nil
}

/*
Free all memory back to the stack allocator.
*/
stack_free_all :: proc(s: ^Stack, loc := #caller_location) {
    s.prev_offset = 0
    s.curr_offset = 0
    // sanitizer.address_poison(s.data)
}

/*
Resize an allocation owned by a stack allocator.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/

stack_resize :: proc(
    s:          ^Stack,
    old_memory: rawptr,
    old_size:   uint,
    size:       uint,
    alignment:  uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location,
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := stack_resize_bytes(s, bytes.bytes(old_memory, old_size), size, alignment)
    return raw_data(bytes), err
}

/*
Resize an allocation owned by a stack allocator.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is
zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/

stack_resize_bytes :: proc(
    s:         ^Stack,
    old_data:  []byte,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc        := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    bytes, err := stack_resize_bytes_non_zeroed(s, old_data, size, alignment, loc)
    if err == nil {
        if old_data == nil {
            slice.zero(bytes)
        } else if size > len(old_data) {
            slice.zero(bytes[len(old_data):])
        }
    }
    return bytes, err
}

/*
Resize an allocation owned by a stack allocator, without zero-initialization.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is not explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/

stack_resize_non_zeroed :: proc(
    s:          ^Stack,
    old_memory: rawptr,
    old_size:   uint,
    size:       uint,
    alignment:  uint = mem.DEFAULT_ALIGNMENT,
    loc         := #caller_location,
) -> (rawptr, mem.Allocator_Error) {
    bytes, err := stack_resize_bytes_non_zeroed(s, bytes.bytes(old_memory, old_size), size, alignment)
    return raw_data(bytes), err
}

/*
Resize an allocation owned by a stack allocator, without zero-initialization.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is not
explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/

stack_resize_bytes_non_zeroed :: proc(
    s:         ^Stack,
    old_data:  []byte,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    old_memory := raw_data(old_data)
    old_size := len(old_data)
    if s.data == nil {
        internal.panic("Resize on an uninitialized Stack allocator.", loc)
    }
    if old_memory == nil {
        return stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    }
    if size == 0 {
        return nil, stack_free(s, old_memory, loc)
    }
    start     := uintptr(raw_data(s.data))
    end       := start + uintptr(len(s.data))
    curr_addr := uintptr(old_memory)
    if !(start <= curr_addr && curr_addr < end) {
        internal.panic("Out of bounds memory address passed to Stack allocator. (resize)")
    }
    if curr_addr >= start+uintptr(s.curr_offset) {
        // NOTE(bill): Allow double frees
        return nil, nil
    }
    if uintptr(old_memory) & uintptr(alignment-1) != 0 {
        // A different alignment has been requested and the current address
        // does not satisfy it.
        data, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
        if err == nil {
            slice.copy(data, bytes.bytes(old_memory, old_size))
            // sanitizer.address_poison(old_memory)
        }
        return data, err
    }
    if old_size == size {
        return bytes.bytes(old_memory, size), nil
    }
    header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header))
    old_offset := uint(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))
    if old_offset != header.prev_offset {
        data, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
        if err == nil {
            slice.copy(data, bytes.bytes(old_memory, old_size))
            // sanitizer.address_poison(old_memory)
        }
        return data, err
    }
    old_memory_size := uintptr(s.curr_offset) - (curr_addr - start)
    internal.assert(old_memory_size == uintptr(old_size))
    diff := size - old_size
    s.curr_offset += diff // works for smaller sizes too
    if diff > 0 {
        mem.zero(rawptr(curr_addr + uintptr(diff)), diff)
    } else {
        // sanitizer.address_poison(old_data[size:])
    }
    result := bytes.bytes(old_memory, size)
    // ensure_poisoned(result)
    // sanitizer.address_unpoison(result)
    return result, nil
}

stack_allocator_proc :: proc(
    allocator_data: rawptr,
    mode:           mem.Allocator_Mode,
    size:           uint,
    alignment:      uint,
    old_memory:     rawptr,
    old_size:       uint,
    loc := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
    s := cast(^Stack)allocator_data
    if s.data == nil {
        return nil, .Invalid_Argument
    }
    switch mode {
    case .Alloc:
        return stack_alloc_bytes(s, size, alignment, loc)
    case .Alloc_Non_Zeroed:
        return stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
    case .Free:
        return nil, stack_free(s, old_memory, loc)
    case .Free_All:
        stack_free_all(s, loc)
    case .Resize:
        return stack_resize_bytes(s, bytes.bytes(old_memory, old_size), size, alignment, loc)
    case .Resize_Non_Zeroed:
        return stack_resize_bytes_non_zeroed(s, bytes.bytes(old_memory, old_size), size, alignment, loc)
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


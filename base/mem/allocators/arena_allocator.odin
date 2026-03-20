import "base:internal"
import "base:intrinsics"
import "base:mem"
import "base:container/slice"
import "base:bytes"


/*
Arena allocator data.
*/
Arena :: struct {
    data:       []byte,
    offset:     uint,
    peak_used:  uint,
    temp_count: uint,
}

/*
Arena allocator.

The arena allocator (also known as a linear allocator, bump allocator,
region allocator) is an allocator that uses a single backing buffer for
allocations.

The buffer is used contiguously, from start to end. Each subsequent allocation
occupies the next adjacent region of memory in the buffer. Since the arena
allocator does not keep track of any metadata associated with the allocations
and their locations, it is impossible to free individual allocations.

The arena allocator can be used for temporary allocations in frame-based memory
management. Games are one example of such applications. A global arena can be
used for any temporary memory allocations, and at the end of each frame all
temporary allocations are freed. Since no temporary object is going to live
longer than a frame, no lifetimes are violated.
*/
arena_allocator :: proc(arena: ^Arena) -> mem.Allocator {
    return {
        procedure = arena_allocator_proc,
        data = arena,
    }
}

/*
Initialize an arena.

This procedure initializes the arena `a` with memory region `data` as its
backing buffer.
*/
arena_init :: proc(a: ^Arena, data: []byte) {
    a.data       = data
    a.offset     = 0
    a.peak_used  = 0
    a.temp_count = 0
    // sanitizer.address_poison(a.data)
}

/*
Allocate memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is zero-initialized.
This procedure returns a pointer to the newly allocated memory region.
*/
arena_alloc :: proc(
    a:         ^Arena,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location,
    ) -> (rawptr, mem.Allocator_Error) {
    bytes, err := arena_alloc_bytes(a, size, alignment, loc)
    return raw_data(bytes), err
}

/*
Allocate memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is zero-initialized.
This procedure returns a slice of the newly allocated memory region.
*/
arena_alloc_bytes :: proc(
    a:         ^Arena,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location,
    ) -> ([]byte, mem.Allocator_Error) {
    bytes, err := arena_alloc_bytes_non_zeroed(a, size, alignment, loc)
    if bytes != nil {
        slice.zero(bytes)
    }
    return bytes, err
}

/*
Allocate non-initialized memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is not explicitly
zero-initialized. This procedure returns a pointer to the newly allocated
memory region.
*/
arena_alloc_non_zeroed :: proc(
    a:         ^Arena,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location,
    ) -> (rawptr, mem.Allocator_Error) {
    bytes, err := arena_alloc_bytes_non_zeroed(a, size, alignment, loc)
    return raw_data(bytes), err
}

/*
Allocate non-initialized memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is not explicitly
zero-initialized. This procedure returns a slice of the newly allocated
memory region.
*/
arena_alloc_bytes_non_zeroed :: proc(
    a:         ^Arena,
    size:      uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    loc       := #caller_location
    ) -> ([]byte, mem.Allocator_Error) {
    if a.data == nil {
        internal.panic("Allocation on uninitialized Arena allocator.", loc)
    }
    #no_bounds_check end := &a.data[a.offset]
    ptr := mem.align_forward(end, uintptr(alignment))
    total_size := size + uint(intrinsics.ptr_sub((^byte)(ptr), (^byte)(end)))
    if a.offset + total_size > len(a.data) {
        return nil, .Out_Of_Memory
    }
    a.offset += total_size
    a.peak_used = max(a.peak_used, a.offset)
    result := bytes.bytes(ptr, size)
    // ensure_poisoned(result)
    // sanitizer.address_unpoison(result)
    return result, nil
}

/*
Free all memory back to the arena allocator.
*/
arena_free_all :: proc(a: ^Arena) {
    a.offset = 0
    // sanitizer.address_poison(a.data)
}

arena_allocator_proc :: proc(
    allocator_data: rawptr,
    mode:           mem.Allocator_Mode,
    size:           uint,
    alignment:      uint,
    old_memory:     rawptr,
    old_size:       uint,
    loc := #caller_location,
    ) -> ([]byte, mem.Allocator_Error)  {
    arena := cast(^Arena)allocator_data
    switch mode {
    case .Alloc:
        return arena_alloc_bytes(arena, size, alignment, loc)
    case .Alloc_Non_Zeroed:
        return arena_alloc_bytes_non_zeroed(arena, size, alignment, loc)
    case .Free:
        return nil, .Mode_Not_Implemented
    case .Free_All:
        arena_free_all(arena)
    case .Resize:
        return default_resize_bytes_align(bytes.bytes(old_memory, old_size), size, alignment, arena_allocator(arena), loc)
    case .Resize_Non_Zeroed:
        return default_resize_bytes_align_non_zeroed(bytes.bytes(old_memory, old_size), size, alignment, arena_allocator(arena), loc)
    case .Query_Features:
        set := (^mem.Allocator_Mode_Set)(old_memory)
        if set != nil {
            set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
        }
        return nil, nil
    case .Query_Info:
        return nil, .Mode_Not_Implemented
    }
    return nil, nil
}

/*
Temporary memory region of an `Arena` allocator.

Temporary memory regions of an arena act as "save-points" for the allocator.
When one is created, the subsequent allocations are done inside the temporary
memory region. When `end_arena_temp_memory` is called, the arena is rolled
back, and all of the memory that was allocated from the arena will be freed.

Multiple temporary memory regions can exist at the same time for an arena.
*/
Arena_Temp_Memory :: struct {
    arena:       ^Arena,
    prev_offset: uint,
}

/*
Start a temporary memory region.

This procedure creates a temporary memory region. After a temporary memory
region is created, all allocations are said to be *inside* the temporary memory
region, until `end_arena_temp_memory` is called.
*/

begin_arena_temp_memory :: proc(a: ^Arena) -> Arena_Temp_Memory {
    tmp: Arena_Temp_Memory
    tmp.arena = a
    tmp.prev_offset = a.offset
    a.temp_count += 1
    return tmp
}

/*
End a temporary memory region.

This procedure ends the temporary memory region for an arena. All of the
allocations *inside* the temporary memory region will be freed to the arena.
*/
end_arena_temp_memory :: proc(tmp: Arena_Temp_Memory) {
    internal.assert(tmp.arena.offset >= tmp.prev_offset)
    internal.assert(tmp.arena.temp_count > 0)
    // sanitizer.address_poison(tmp.arena.data[tmp.prev_offset:tmp.arena.offset])
    tmp.arena.offset = tmp.prev_offset
    tmp.arena.temp_count -= 1
}


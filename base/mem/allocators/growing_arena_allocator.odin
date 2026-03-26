import "base:mem"
import "base:intrinsics"
import "base:internal"
import "base:container/slice"
// import "base:sanitizer"

DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE: uint : #config(DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE, 4 * mem.Megabyte)

Growing_Arena_Memory_Block :: struct {
    prev:      ^Growing_Arena_Memory_Block,
    allocator: mem.Allocator,
    base:      [^]u8,
    used:      uint,
    capacity:  uint,
}

Growing_Arena :: struct {
    backing_allocator:  mem.Allocator,

    curr_block:         ^Growing_Arena_Memory_Block,

    total_used:         uint,
    total_capacity:     uint,

    minimum_block_size: uint,

    temp_count:         uint,
}


growing_arena_memory_block_alloc :: proc(allocator: mem.Allocator, capacity, alignment: uint, loc := #caller_location) -> (block: ^Growing_Arena_Memory_Block, err: mem.Allocator_Error) {
    total_size  := uint(capacity + max(alignment, size_of(Growing_Arena_Memory_Block)))
    base_offset := uintptr(max(alignment, size_of(Growing_Arena_Memory_Block)))

    min_alignment: uint = max(16, align_of(Growing_Arena_Memory_Block), alignment)
    data := mem.alloc(total_size, min_alignment, allocator, loc) or_return
    block = (^Growing_Arena_Memory_Block)(raw_data(data))
    end := uintptr(raw_data(data)[len(data):])

    block.allocator = allocator
    block.base = ([^]u8)(uintptr(block) + base_offset)
    block.capacity = uint(end - uintptr(block.base))

    // sanitizer.address_poison(block.base, block.capacity)

    // Should be zeroed
    internal.assert(block.used == 0)
    internal.assert(block.prev == nil)
    return
}


growing_arena_memory_block_dealloc :: proc(block_to_free: ^Growing_Arena_Memory_Block, loc := #caller_location) {
    if block_to_free != nil {

        allocator := block_to_free.allocator
        // sanitizer.address_unpoison(block_to_free.base, block_to_free.capacity)
        _ = mem.free(block_to_free, allocator, loc)
    }
}


growing_arena_alloc_from_memory_block :: proc(block: ^Growing_Arena_Memory_Block, min_size, alignment: uint) -> (data: []u8, err: mem.Allocator_Error) {
    calc_alignment_offset :: proc(block: ^Growing_Arena_Memory_Block, alignment: uintptr) -> uint {
        alignment_offset := uint(0)
        ptr := uintptr(block.base[block.used:])
        mask := alignment-1
        if ptr & mask != 0 {
            alignment_offset = uint(alignment - (ptr & mask))
        }
        return alignment_offset

    }
    if block == nil {
        return nil, .Out_Of_Memory
    }
    alignment_offset := calc_alignment_offset(block, uintptr(alignment))
    size, size_ok := _safe_add(min_size, alignment_offset)
    if !size_ok {
        err = .Out_Of_Memory
        return
    }

    if to_be_used, ok := _safe_add(block.used, size); !ok || to_be_used > block.capacity {
        err = .Out_Of_Memory
        return
    }
    data = block.base[block.used+alignment_offset:][:min_size]
    // sanitizer.address_unpoison(block.base[block.used:block.used+size])
    block.used += size
    return
}


growing_arena_alloc :: proc(arena: ^Growing_Arena, size, alignment: uint, loc := #caller_location) -> (data: []u8, err: mem.Allocator_Error) {
    align_forward_uint :: proc(ptr, align: uint) -> uint {
        p := ptr
        modulo := p & (align-1)
        if modulo != 0 {
            p += align - modulo
        }
        return p
    }

    internal.assert(alignment & (alignment-1) == 0, "non-power of two alignment", loc)

    size := size
    if size == 0 {
        return
    }

    prev_used := 0 if arena.curr_block == nil else arena.curr_block.used
    data, err = growing_arena_alloc_from_memory_block(arena.curr_block, size, alignment)
    if err == .Out_Of_Memory {
        if arena.minimum_block_size == 0 {
            arena.minimum_block_size = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE
        }

        needed := align_forward_uint(size, alignment)
        block_size := max(needed, arena.minimum_block_size)

        internal.assert(arena.backing_allocator.procedure != nil, 
            "mem.Allocator not initialized. Use allocators.growing_arena_init(arena, size, backing_allocator)")

        new_block := growing_arena_memory_block_alloc(arena.backing_allocator, block_size, alignment, loc) or_return
        new_block.prev = arena.curr_block
        arena.curr_block = new_block
        arena.total_capacity += new_block.capacity
        prev_used = 0
        data, err = growing_arena_alloc_from_memory_block(arena.curr_block, size, alignment)
    }
    arena.total_used += arena.curr_block.used - prev_used
    return
}

// `growing_arena_init` will initialize the arena with a usable block.
// This procedure is not necessary to use the Growing_Arena as the default zero as `growing_arena_alloc` will set things up if necessary
growing_arena_init :: proc(arena: ^Growing_Arena, size: uint, backing_allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    arena^ = {}
    arena.backing_allocator = backing_allocator
    arena.minimum_block_size = max(size, 1<<12) // minimum block size of 4 KiB
    new_block := growing_arena_memory_block_alloc(arena.backing_allocator, arena.minimum_block_size, 0, loc) or_return
    arena.curr_block = new_block
    arena.total_capacity += new_block.capacity
    return nil
}


growing_arena_free_last_memory_block :: proc(arena: ^Growing_Arena, loc := #caller_location) {
    if free_block := arena.curr_block; free_block != nil {
        arena.curr_block = free_block.prev

        arena.total_capacity -= free_block.capacity
        growing_arena_memory_block_dealloc(free_block, loc)
    }
}

// `growing_arena_free_all` will mem.free all but the first memory block, and then reset the memory block
growing_arena_free_all :: proc(arena: ^Growing_Arena, loc := #caller_location) {
    for arena.curr_block != nil && arena.curr_block.prev != nil {
        growing_arena_free_last_memory_block(arena, loc)
    }

    if arena.curr_block != nil {
        mem.zero(arena.curr_block.base, arena.curr_block.used)
        arena.curr_block.used = 0
        // sanitizer.address_poison(arena.curr_block.base, arena.curr_block.capacity)
    }
    arena.total_used = 0
}

growing_arena_destroy :: proc(arena: ^Growing_Arena, loc := #caller_location) {
    for arena.curr_block != nil {
        free_block := arena.curr_block
        arena.curr_block = free_block.prev

        arena.total_capacity -= free_block.capacity
        growing_arena_memory_block_dealloc(free_block, loc)
    }
    arena.total_used = 0
    arena.total_capacity = 0
}


growing_arena_allocator :: proc(arena: ^Growing_Arena) -> mem.Allocator {
    return {
        procedure = growing_arena_allocator_proc, 
        data      = arena,
    }
}


growing_arena_allocator_proc :: proc(
    allocator_data:  rawptr,
    mode:            mem.Allocator_Mode,
    size, alignment: uint,
    old_memory:      rawptr,
    old_size:        uint,
    loc              := #caller_location,
    ) -> (data: []u8, err: mem.Allocator_Error) {
    arena := (^Growing_Arena)(allocator_data)

    switch mode {
    case .Alloc, .Alloc_Non_Zeroed:
        return growing_arena_alloc(arena, size, alignment, loc)
    case .Free:
        err = .Mode_Not_Implemented
    case .Free_All:
        growing_arena_free_all(arena, loc)
    case .Resize, .Resize_Non_Zeroed:
        old_data := ([^]u8)(old_memory)

        switch {
        case old_data == nil:
            return growing_arena_alloc(arena, size, alignment, loc)
        case size == old_size:
            // return old memory
            data = old_data[:size]
            return
        case size == 0:
            err = .Mode_Not_Implemented
            return
        case uintptr(old_data) & uintptr(alignment-1) == 0:
            if size < old_size {
                // shrink data in-place
                data = old_data[:size]
                return
            }

            if block := arena.curr_block; block != nil {
                start := uint(uintptr(old_memory)) - uint(uintptr(block.base))
                old_end := start + old_size
                new_end := start + size
                if start < old_end && old_end == block.used && new_end <= block.capacity {
                    // grow data in-place, adjusting next allocation
                    block.used = uint(new_end)
                    data = block.base[start:new_end]
                    // sanitizer.address_unpoison(data)
                    return
                }
            }
        }

        new_memory := growing_arena_alloc(arena, size, alignment, loc) or_return
        if new_memory == nil {
            return
        }
        slice.copy(new_memory, old_data[:old_size])
        return new_memory, nil
    case .Query_Features:
        set := (^mem.Allocator_Mode_Set)(old_memory)
        if set != nil {
            set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Query_Features}
        }
    case .Query_Info:
        err = .Mode_Not_Implemented
    }

    return
}



Growing_Arena_Temp :: struct {
    arena: ^Growing_Arena,
    block: ^Growing_Arena_Memory_Block,
    used:  uint,
}

@(deferred_out=growing_arena_temp_end, optional_results)
ARENA_TEMP_GUARD :: #force_inline proc(arena: ^Growing_Arena, ignore := false, loc := #caller_location) -> (Growing_Arena_Temp, internal.Source_Code_Location) {
    if ignore {
        return {}, loc
    }
    return growing_arena_temp_begin(arena, loc), loc
}


growing_arena_temp_begin :: proc(arena: ^Growing_Arena, loc := #caller_location) -> (arena_temp: Growing_Arena_Temp) {
    internal.assert(arena != nil, "nil arena", loc)

    arena_temp.arena = arena
    arena_temp.block = arena.curr_block
    if arena.curr_block != nil {
        arena_temp.used = arena.curr_block.used
    }
    arena.temp_count += 1
    return
}

growing_arena_temp_end :: proc(arena_temp: Growing_Arena_Temp, loc := #caller_location) {
    if arena_temp.arena == nil {
        internal.assert(arena_temp.block == nil)
        internal.assert(arena_temp.used == 0)
        return
    }
    arena := arena_temp.arena

    if arena_temp.block != nil {
        memory_block_found := false
        for block := arena.curr_block; block != nil; block = block.prev {
            if block == arena_temp.block {
                memory_block_found = true
                break
            }
        }
        if !memory_block_found {
            internal.assert(arena.curr_block == arena_temp.block, "memory block stored within Growing_Arena_Temp not owned by Growing_Arena", loc)
        }

        for arena.curr_block != arena_temp.block {
            growing_arena_free_last_memory_block(arena)
        }

        if block := arena.curr_block; block != nil {
            internal.assert(block.used >= arena_temp.used, "out of order use of growing_arena_temp_end", loc)
            amount_to_zero := block.used-arena_temp.used
            mem.zero(block.base[arena_temp.used:], amount_to_zero)
            // sanitizer.address_poison(block.base[arena_temp.used:block.capacity])
            block.used = arena_temp.used
            arena.total_used -= amount_to_zero
        }
    }

    internal.assert(arena.temp_count > 0, "double-use of growing_arena_temp_end", loc)
    arena.temp_count -= 1
}

growing_arena_temp_ignore :: proc(arena_temp: Growing_Arena_Temp, loc := #caller_location) {
    internal.assert(arena_temp.arena != nil, "nil arena", loc)
    arena := arena_temp.arena

    internal.assert(arena.temp_count > 0, "double-use of growing_arena_temp_end", loc)
    arena.temp_count -= 1
}

growing_arena_check_temp :: proc(arena: ^Growing_Arena, loc := #caller_location) {
    internal.assert(arena.temp_count == 0, "Growing_Arena_Temp not been ended", loc)
}


@(private)
_safe_add :: #force_inline proc(x, y: uint) -> (uint, bool) {
    z, did_overflow := intrinsics.overflow_add(x, y)
    return z, !did_overflow
}

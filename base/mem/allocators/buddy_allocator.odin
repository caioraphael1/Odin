import "base:internal"
import "base:mem"
import "base:intrinsics"
import "base:container/slice"
import "base:bytes"

/*
Header of the buddy block.
*/
Buddy_Block :: struct #align(align_of(uint)) {
    size:    uint,
    is_free: bool,
}

/*
Obtain the next buddy block.
*/
@(no_sanitize_address)
buddy_block_next :: proc(block: ^Buddy_Block) -> ^Buddy_Block {
    return (^Buddy_Block)(([^]u8)(block)[block.size:])
}

/*
Split the block into two, by truncating the given block to a given size.
*/
@(no_sanitize_address)
buddy_block_split :: proc(block: ^Buddy_Block, size: uint) -> ^Buddy_Block {
    block := block
    if block != nil && size != 0 {
        // Recursive Split
        for size < block.size {
            sz := block.size >> 1
            block.size = sz
            block = buddy_block_next(block)
            block.size = sz
            block.is_free = true
        }
        if size <= block.size {
            return block
        }
    }
    // Block cannot fit the requested allocation size
    return nil
}

/*
Coalesce contiguous blocks in a range of blocks into one.
*/
@(no_sanitize_address)
buddy_block_coalescence :: proc(head, tail: ^Buddy_Block) {
    for {
        // Keep looping until there are no more buddies to coalesce
        block := head
        buddy := buddy_block_next(block)
        no_coalescence := true
        for block < tail && buddy < tail { // make sure the buddies are within the range
            if block.is_free && buddy.is_free && block.size == buddy.size {
                // Coalesce buddies into one
                block.size <<= 1
                block = buddy_block_next(block)
                if block < tail {
                    buddy = buddy_block_next(block)
                    no_coalescence = false
                }
            } else if block.size < buddy.size {
                // The buddy block is split into smaller blocks
                block = buddy
                buddy = buddy_block_next(buddy)
            } else {
                block = buddy_block_next(buddy)
                if block < tail {
                    // Leave the buddy block for the next iteration
                    buddy = buddy_block_next(block)
                }
            }
        }
        if no_coalescence {
            return
        }
    }
}

/*
Find the best block for storing a given size in a range of blocks.
*/
@(no_sanitize_address)
buddy_block_find_best :: proc(head, tail: ^Buddy_Block, size: uint) -> ^Buddy_Block {
    internal.assert(size != 0)
    best_block: ^Buddy_Block
    block := head                    // left
    buddy := buddy_block_next(block) // right
    // The entire memory section between head and tail is free,
    // just call 'buddy_block_split' to get the allocation
    if buddy == tail && block.is_free {
        return buddy_block_split(block, size)
    }
    // Find the block which is the 'best_block' to requested allocation sized
    for block < tail && buddy < tail { // make sure the buddies are within the range
        // If both buddies are free, coalesce them together
        // NOTE: this is an optimization to reduce fragmentation
        //       this could be completely ignored
        if block.is_free && buddy.is_free && block.size == buddy.size {
            block.size <<= 1
            if size <= block.size && (best_block == nil || block.size <= best_block.size) {
                best_block = block
            }
            block = buddy_block_next(buddy)
            if block < tail {
                // Delay the buddy block for the next iteration
                buddy = buddy_block_next(block)
            }
            continue
        }
        if block.is_free && size <= block.size &&
           (best_block == nil || block.size <= best_block.size) {
            best_block = block
        }
        if buddy.is_free && size <= buddy.size &&
           (best_block == nil || buddy.size < best_block.size) {
            // If each buddy are the same size, then it makes more sense
            // to pick the buddy as it "bounces around" less
            best_block = buddy
        }
        if block.size <= buddy.size {
            block = buddy_block_next(buddy)
            if (block < tail) {
                // Delay the buddy block for the next iteration
                buddy = buddy_block_next(block)
            }
        } else {
            // Buddy was split into smaller blocks
            block = buddy
            buddy = buddy_block_next(buddy)
        }
    }
    if best_block != nil {
        // This will handle the case if the 'best_block' is also the perfect fit
        return buddy_block_split(best_block, size)
    }
    // Maybe out of memory
    return nil
}

/*
The buddy allocator data.
*/
Buddy_Allocator :: struct {
    head:      ^Buddy_Block,
    tail:      ^Buddy_Block `fmt:"-"`,
    alignment: uint,
}

/*
Buddy allocator.

The buddy allocator is a type of allocator that splits the backing buffer into
multiple regions called buddy blocks. Initially, the allocator only has one
block with the size of the backing buffer. Upon each allocation, the allocator
finds the smallest block that can fit the size of requested memory region, and
splits the block according to the allocation size. If no block can be found,
the contiguous free blocks are coalesced and the search is performed again.
*/

buddy_allocator :: proc(b: ^Buddy_Allocator) -> mem.Allocator {
    return mem.Allocator{
        procedure = buddy_allocator_proc,
        data      = b,
    }
}

/*
Initialize a buddy allocator.

This procedure initializes the buddy allocator `b` with a backing buffer `data`
and block alignment specified by `alignment`.

`alignment` may be any power of two, but the backing buffer must be aligned to
at least `size_of(Buddy_Block)`.
*/
buddy_allocator_init :: proc(b: ^Buddy_Allocator, data: []u8, alignment: uint, loc := #caller_location) {
    internal.assert(data != nil)
    internal.assert(mem.is_power_of_two(uintptr(len(data))), "Size of the backing buffer must be power of two", loc)
    internal.assert(mem.is_power_of_two(uintptr(alignment)), "Alignment must be a power of two", loc)
    alignment := alignment
    if alignment < size_of(Buddy_Block) {
        alignment = size_of(Buddy_Block)
    }
    ptr := raw_data(data)
    internal.assert(uintptr(ptr) % uintptr(alignment) == 0, "The data is not aligned to the minimum alignment, which must be at least `size_of(Buddy_Block)`.", loc)
    b.head = (^Buddy_Block)(ptr)
    b.head.size = len(data)
    b.head.is_free = true
    b.tail = buddy_block_next(b.head)
    b.alignment = alignment
    internal.assert(uint(len(data)) >= 2 * buddy_block_size_required(b, 1), "The size of the backing buffer must be large enough to hold at least two 1-u8 allocations given the alignment requirements, otherwise it cannot split.", loc)
    // sanitizer.address_poison(data)
}

/*
Get required block size to fit in the allocation as well as the alignment padding.
*/

buddy_block_size_required :: proc(b: ^Buddy_Allocator, size: uint) -> uint {
    internal.assert(size > 0)
    // NOTE: `size_of(Buddy_Block)` will be accounted for in `b.alignment`.
    // This calculation is also previously guarded against being given a `size`
    // 0 by `buddy_allocator_alloc_bytes_non_zeroed` checking for that.
    actual_size := b.alignment + size
    if intrinsics.count_ones(actual_size) != 1 {
        // We're not a power of two. Let's fix that.
        actual_size = 1 << (size_of(uint) * 8 - intrinsics.count_leading_zeros(actual_size))
    }
    return actual_size
}

/*
Allocate memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is zero-initialized. This procedure returns a pointer to the allocated
memory region.
*/
@(no_sanitize_address)
buddy_allocator_alloc :: proc(b: ^Buddy_Allocator, size: uint) -> (rawptr, mem.Allocator_Error) {
    bytes, err := buddy_allocator_alloc_bytes(b, size)
    return raw_data(bytes), err
}

/*
Allocate memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is zero-initialized. This procedure returns a slice of the allocated
memory region.
*/
@(no_sanitize_address)
buddy_allocator_alloc_bytes :: proc(b: ^Buddy_Allocator, size: uint) -> ([]u8, mem.Allocator_Error) {
    bytes, err := buddy_allocator_alloc_bytes_non_zeroed(b, size)
    if bytes != nil {
        slice.zero(bytes)
    }
    return bytes, err
}

/*
Allocate non-initialized memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is not explicitly zero-initialized. This procedure returns a pointer to
the allocated memory region.
*/
@(no_sanitize_address)
buddy_allocator_alloc_non_zeroed :: proc(b: ^Buddy_Allocator, size: uint) -> (rawptr, mem.Allocator_Error) {
    bytes, err := buddy_allocator_alloc_bytes_non_zeroed(b, size)
    return raw_data(bytes), err
}

/*
Allocate non-initialized memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is not explicitly zero-initialized. This procedure returns a slice of
the allocated memory region.
*/
@(no_sanitize_address)
buddy_allocator_alloc_bytes_non_zeroed :: proc(b: ^Buddy_Allocator, size: uint) -> ([]u8, mem.Allocator_Error) {
    if size != 0 {
        actual_size := buddy_block_size_required(b, size)
        found := buddy_block_find_best(b.head, b.tail, actual_size)
        if found == nil {
            // Try to coalesce all the free buddy blocks and then search again
            buddy_block_coalescence(b.head, b.tail)
            found = buddy_block_find_best(b.head, b.tail, actual_size)
        }
        if found == nil {
            return nil, .Out_Of_Memory
        }
        found.is_free = false
        data := ([^]u8)(found)[b.alignment:][:size]
        internal.assert(cast(uintptr)raw_data(data)+cast(uintptr)(size-1) < cast(uintptr)buddy_block_next(found), "Buddy_Allocator has made an allocation which overlaps a block header.")
        // ensure_poisoned(data)
        // sanitizer.address_unpoison(data)
        return data, nil
    }
    return nil, nil
}

/*
Free memory back to the buddy allocator.

This procedure frees the memory region allocated at pointer `ptr`.

If `ptr` is not the latest allocation and is not a leaked allocation, this
operation is a no-op.
*/
@(no_sanitize_address)
buddy_allocator_free :: proc(b: ^Buddy_Allocator, ptr: rawptr) -> mem.Allocator_Error {
    if ptr != nil {
        if !(b.head <= ptr && ptr <= b.tail) {
            return .Invalid_Pointer
        }
        block := (^Buddy_Block)(([^]u8)(ptr)[-b.alignment:])
        // sanitizer.address_poison(ptr, block.size)
        block.is_free = true
        buddy_block_coalescence(b.head, b.tail)
    }
    return nil
}

/*
Free all memory back to the buddy allocator.
*/
@(no_sanitize_address)
buddy_allocator_free_all :: proc(b: ^Buddy_Allocator) {
    alignment := b.alignment
    head := ([^]u8)(b.head)
    tail := ([^]u8)(b.tail)
    data := head[:intrinsics.ptr_sub(tail, head)]
    buddy_allocator_init(b, data, alignment)
}

@(no_sanitize_address)
buddy_allocator_proc :: proc(
    allocator_data:  rawptr,
    mode:            mem.Allocator_Mode,
    size, alignment: uint,
    old_memory:      rawptr,
    old_size:        uint,
    loc := #caller_location,
) -> ([]u8, mem.Allocator_Error) {
    b := (^Buddy_Allocator)(allocator_data)
    switch mode {
    case .Alloc:
        return buddy_allocator_alloc_bytes(b, uint(size))
    case .Alloc_Non_Zeroed:
        return buddy_allocator_alloc_bytes_non_zeroed(b, uint(size))
    case .Resize:
        return default_resize_bytes_align(bytes.bytes(old_memory, old_size), size, alignment, buddy_allocator(b), loc)
    case .Resize_Non_Zeroed:
        return default_resize_bytes_align_non_zeroed(bytes.bytes(old_memory, old_size), size, alignment, buddy_allocator(b), loc)
    case .Free:
        return nil, buddy_allocator_free(b, old_memory)
    case .Free_All:
        buddy_allocator_free_all(b)
    case .Query_Features:
        set := (^mem.Allocator_Mode_Set)(old_memory)
        if set != nil {
            set^ = {.Query_Features, .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed, .Free, .Free_All, .Query_Info}
        }
        return nil, nil
    case .Query_Info:
        info := (^mem.Allocator_Query_Info)(old_memory)
        if info != nil && info.pointer != nil {
            ptr := info.pointer
            if !(b.head <= ptr && ptr <= b.tail) {
                return nil, .Invalid_Pointer
            }
            block := (^Buddy_Block)(([^]u8)(ptr)[-b.alignment:])
            info.size = uint(block.size)
            info.alignment = uint(b.alignment)
            return bytes.bytes(info, size_of(info^)), nil
        }
        return nil, nil
    }
    return nil, nil
}

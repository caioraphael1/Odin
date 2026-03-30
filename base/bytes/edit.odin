import "base:internal"
import "base:mem"
import "base:container/slice"
import "base:unicode/utf8"


bytes_truncate_to_byte :: proc(str: []u8, b: u8) -> []u8 {
    n, found := index_byte(str, b)
    if !found {
        n = len(str)
    }
    return str[:n]
}

bytes_truncate_to_rune :: proc(str: []u8, r: rune) -> []u8 {
    n, found := index_rune(str, r)
    if !found {
        n = len(str)
    }
    return str[:n]
}

resize :: proc(
    old_data:  []u8,
    new_size:  uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> ([]u8, mem.Allocator_Error) {
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
    old_data:  []u8,
    new_size:  uint,
    alignment: uint = mem.DEFAULT_ALIGNMENT,
    allocator: mem.Allocator,
    loc := #caller_location,
    ) -> ([]u8, mem.Allocator_Error) {
    return mem.resize_non_zero(raw_data(old_data), len(old_data), new_size, alignment, allocator, loc)
}

reverse :: proc(s: []u8, allocator: mem.Allocator, loc := #caller_location) -> []u8 {
    str := s
    n := len(str)
    buf, _ := slice.create(u8, n, allocator)
    i := n

    for len(str) > 0 {
        _, w := utf8.rune_from_bytes(str)
        i -= w
        slice.copy(buf[i:], str[:w])
        str = str[w:]
    }
    return buf
}

repeat :: proc(s: []u8, count: uint, allocator: mem.Allocator, loc := #caller_location) -> []u8 {
    if count < 0 {
        internal.panic("bytes: negative repeat count")
    } else if count > 0 && (len(s) * count)/count != len(s) {
        internal.panic("bytes: repeat count will cause an overflow")
    }

    b, _ := slice.create(u8, len(s)*count, allocator)
    i := slice.copy(b, s)
    for i < len(b) { // 2^N trick to reduce the need to copy
        slice.copy(b[i:], b[:i])
        i *= 2
    }
    return b
}

replace_all :: proc(s, old, new: []u8, allocator: mem.Allocator, loc := #caller_location) -> (output: []u8, was_allocation: bool) {
    return replace(s, old, new, count(s, old), allocator, loc)
}

// if n < 0, no limit on the number of replacements
replace :: proc(s, old, new: []u8, n: uint, allocator: mem.Allocator, loc := #caller_location) -> (output: []u8, was_allocation: bool) {
    if string(old) == string(new) || n == 0 {
        was_allocation = false
        output = s
        return
    }
    byte_count := n
    if m := count(s, old); m == 0 {
        was_allocation = false
        output = s
        return
    } else if m < n {
        byte_count = m
    }


    t, _ := slice.create(u8, len(s) + byte_count*(len(new) - len(old)), allocator)
    was_allocation = true

    w: uint
    start: uint
    for i: uint = 0; i < byte_count; i += 1 {
        j := start
        if len(old) == 0 {
            if i > 0 {
                _, width := utf8.rune_from_bytes(s[start:])
                j += width
            }
        } else {
            iii, found := index_bytes(s[start:], old)
            if found {
                j += iii
            } else {
                j -= 1 // I guess
            }
        }
        w += slice.copy(t[w:], s[start:j])
        w += slice.copy(t[w:], new)
        start = j + len(old)
    }
    w += slice.copy(t[w:], s[start:])
    output = t[0:w]
    return
}

remove :: proc(s, key: []u8, n: uint, allocator: mem.Allocator, loc := #caller_location) -> (output: []u8, was_allocation: bool) {
    return replace(s, key, {}, n, allocator, loc)
}

remove_all :: proc(s, key: []u8, allocator: mem.Allocator, loc := #caller_location) -> (output: []u8, was_allocation: bool) {
    return remove(s, key, count(s, key), allocator, loc)
}

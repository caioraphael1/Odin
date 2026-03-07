import "base:intrinsics"

ptr_add :: proc(p: $P/^$T, x: int) -> ^T {
    return ([^]T)(p)[x:]
}


ptr_sub :: proc(p: $P/^$T, x: int) -> ^T {
    return ([^]T)(p)[-x:]
}

ptr_swap_non_overlapping :: proc(x, y: rawptr, len: int) {
    if len <= 0 {
        return
    }
    if x == y { // Ignore pointers that are the same
        return
    }

    Block :: distinct [4]u64
    BLOCK_SIZE :: size_of(Block)

    i := 0
    t := &Block{}
    for ; i + BLOCK_SIZE <= len; i += BLOCK_SIZE {
        a := rawptr(uintptr(x) + uintptr(i))
        b := rawptr(uintptr(y) + uintptr(i))

        intrinsics.mem_copy(t, a, BLOCK_SIZE)
        intrinsics.mem_copy(a, b, BLOCK_SIZE)
        intrinsics.mem_copy(b, t, BLOCK_SIZE)
    }

    if i < len {
        rem := len - i

        a := rawptr(uintptr(x) + uintptr(i))
        b := rawptr(uintptr(y) + uintptr(i))

        intrinsics.mem_copy(t, a, rem)
        intrinsics.mem_copy(a, b, rem)
        intrinsics.mem_copy(b, t, rem)
    }
}

ptr_swap_overlapping :: proc(x, y: rawptr, len: int) {
    if len <= 0 {
        return
    }
    if x == y {
        return
    }
    
    N :: 512
    buffer: [N]byte = ---
    
    a, b := ([^]byte)(x), ([^]byte)(y)
    
    for n := len; n > 0; n -= N {
        m := min(n, N)
        intrinsics.mem_copy(&buffer, a, m)
        intrinsics.mem_copy(a, b, m)
        intrinsics.mem_copy(b, &buffer, m)
        
        a, b = a[N:], b[N:]
    }
}

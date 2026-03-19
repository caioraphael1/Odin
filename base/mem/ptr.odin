
ptr_add :: proc(p: $P/^$T, x: int) -> ^T {
    return ([^]T)(p)[x:]
}


ptr_sub :: proc(p: $P/^$T, x: int) -> ^T {
    return ([^]T)(p)[-x:]
}

ptr_swap_non_overlapping :: proc(x, y: rawptr, len: uint) {
    if len <= 0 {
        return
    }
    if x == y { // Ignore pointers that are the same
        return
    }

    Block :: distinct [4]u64
    BLOCK_SIZE :: size_of(Block)

    i: uint
    t := &Block{}
    for ; i + BLOCK_SIZE <= len; i += BLOCK_SIZE {
        a := rawptr(uintptr(x) + uintptr(i))
        b := rawptr(uintptr(y) + uintptr(i))

        copy(t, a, BLOCK_SIZE)
        copy(a, b, BLOCK_SIZE)
        copy(b, t, BLOCK_SIZE)
    }

    if i < len {
        rem := len - i

        a := rawptr(uintptr(x) + uintptr(i))
        b := rawptr(uintptr(y) + uintptr(i))

        copy(t, a, rem)
        copy(a, b, rem)
        copy(b, t, rem)
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
        copy(&buffer, a, m)
        copy(a, b, m)
        copy(b, &buffer, m)
        
        a, b = a[N:], b[N:]
    }
}

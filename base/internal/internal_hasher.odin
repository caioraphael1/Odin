
INITIAL_HASH_SEED :: 0xcbf29ce484222325


__default_hasher :: #force_inline proc(data: rawptr, seed: uintptr, N: uint) -> uintptr {
    h := u64(seed) + INITIAL_HASH_SEED
    p := ([^]u8)(data)
    for _ in 0..<N {
        h = (h ~ u64(p[0])) * 0x100000001b3
        p = p[1:]
    }
    h &= HASH_MASK
    return uintptr(h) | uintptr(uintptr(h) == 0)
}

__default_hasher_string :: proc(data: rawptr, seed: uintptr) -> uintptr {
    str := (^[]u8)(data)
    return __default_hasher(raw_data(str^), seed, len(str))
}

__default_hasher_cstring :: proc(data: rawptr, seed: uintptr) -> uintptr {
    h := u64(seed) + INITIAL_HASH_SEED
    if ptr := (^[^]u8)(data)^; ptr != nil {
        for ptr[0] != 0 {
            h = (h ~ u64(ptr[0])) * 0x100000001b3
            ptr = ptr[1:]
        }
    }
    h &= HASH_MASK
    return uintptr(h) | uintptr(uintptr(h) == 0)
}

__default_hasher_f64 :: proc(f: f64, seed: uintptr) -> uintptr {
    f := f
    buf: [size_of(f)]u8
    if f == 0 {
        return __default_hasher(&buf, seed, size_of(buf))
    }
    if f != f {
        // TODO(bill): What should the logic be for NaNs?
        return __default_hasher(&f, seed, size_of(f))
    }
    return __default_hasher(&f, seed, size_of(f))
}

__default_hasher_complex128 :: proc(x, y: f64, seed: uintptr) -> uintptr {
    seed := seed
    seed = __default_hasher_f64(x, seed)
    seed = __default_hasher_f64(y, seed)
    return seed
}

__default_hasher_quaternion256 :: proc(x, y, z, w: f64, seed: uintptr) -> uintptr {
    seed := seed
    seed = __default_hasher_f64(x, seed)
    seed = __default_hasher_f64(y, seed)
    seed = __default_hasher_f64(z, seed)
    seed = __default_hasher_f64(w, seed)
    return seed
}

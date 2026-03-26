#+no-instrumentation

import "base:intrinsics"

__mem_compare :: proc(x, y: rawptr, n: uint) -> int #no_bounds_check {
    switch {
    case x == y:   return 0
    case x == nil: return -1
    case y == nil: return +1
    }
    a, b := cast([^]u8)x, cast([^]u8)y
    
    i: uint
    m: uint

    when HAS_HARDWARE_SIMD {
        when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
            m = n / 32 * 32
            for ; i < m; i += 32 {
                load_a := intrinsics.unaligned_load(cast(^#simd[32]u8)&a[i])
                load_b := intrinsics.unaligned_load(cast(^#simd[32]u8)&b[i])
                comparison := intrinsics.simd_lanes_ne(load_a, load_b)
                if intrinsics.simd_reduce_or(comparison) != 0 {
                    sentinel: #simd[32]u8 = u8(0xFF)
                    indices := intrinsics.simd_indices(#simd[32]u8)
                    index_select := intrinsics.simd_select(comparison, indices, sentinel)
                    index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
                    return -1 if a[i+index_reduce] < b[i+index_reduce] else +1
                }
            }
        }
    }

    m = (n-i) / 16 * 16
    for ; i < m; i += 16 {
        load_a := intrinsics.unaligned_load(cast(^#simd[16]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[16]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[16]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[16]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return -1 if a[i+index_reduce] < b[i+index_reduce] else +1
        }
    }

    // 64-bit SIMD is faster than using a `uintptr` to detect a difference then
    // re-iterating with the u8-by-u8 loop, at least on AMD64.
    m = (n-i) / 8 * 8
    for ; i < m; i += 8 {
        load_a := intrinsics.unaligned_load(cast(^#simd[8]u8)&a[i])
        load_b := intrinsics.unaligned_load(cast(^#simd[8]u8)&b[i])
        comparison := intrinsics.simd_lanes_ne(load_a, load_b)
        if intrinsics.simd_reduce_or(comparison) != 0 {
            sentinel: #simd[8]u8 = u8(0xFF)
            indices := intrinsics.simd_indices(#simd[8]u8)
            index_select := intrinsics.simd_select(comparison, indices, sentinel)
            index_reduce := cast(uint)intrinsics.simd_reduce_min(index_select)
            return -1 if a[i+index_reduce] < b[i+index_reduce] else +1
        }
    }

    for ; i < n; i += 1 {
        if a[i] ~ b[i] != 0 {
            return -1 if int(a[i]) - int(b[i]) < 0 else +1
        }
    }
    return 0
}


__mem_compare_zero :: proc(a: rawptr, n: int) -> int #no_bounds_check {
    n := uint(n)
    i := uint(0)
    m := uint(0)

    // Because we're comparing against zero, we never return -1, as that would
    // indicate the compared value is less than zero.
    //
    // Note that a zero return value here means equality.

    bytes := ([^]u8)(a)

    if n >= 8 {
        when HAS_HARDWARE_SIMD {
            when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
                scanner32: #simd[32]u8
                m = n / 32 * 32
                for ; i < m; i += 32 {
                    load := intrinsics.unaligned_load(cast(^#simd[32]u8)&bytes[i])
                    ne := intrinsics.simd_lanes_ne(scanner32, load)
                    if intrinsics.simd_reduce_or(ne) > 0 {
                        return 1
                    }
                }
            }
        }

        scanner16: #simd[16]u8
        m = (n-i) / 16 * 16
        for ; i < m; i += 16 {
            load := intrinsics.unaligned_load(cast(^#simd[16]u8)&bytes[i])
            ne := intrinsics.simd_lanes_ne(scanner16, load)
            if intrinsics.simd_reduce_or(ne) != 0 {
                return 1
            }
        }

        m = (n-i) / size_of(uintptr) * size_of(uintptr)
        for ; i < m; i += size_of(uintptr) {
            if intrinsics.unaligned_load(cast(^uintptr)&bytes[i]) != 0 {
                return 1
            }
        }
    }

    for ; i < n; i += 1 {
        if bytes[i] != 0 {
            return 1
        }
    }
    return 0
}


__mem_equal :: proc(x, y: rawptr, n: uint) -> bool {
    switch {
    case n == 0: return true
    case x == y: return true
    }
    a, b := cast([^]u8)x, cast([^]u8)y

    i := uint(0)
    m := uint(0)

    if n >= 8 {
        when HAS_HARDWARE_SIMD {
            // Avoid using 256-bit SIMD on platforms where its emulation is
            // likely to be less than ideal.
            when ODIN_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
                m = n / 32 * 32
                for ; i < m; i += 32 {
                    load_a := intrinsics.unaligned_load(cast(^#simd[32]u8)&a[i])
                    load_b := intrinsics.unaligned_load(cast(^#simd[32]u8)&b[i])
                    ne := intrinsics.simd_lanes_ne(load_a, load_b)
                    if intrinsics.simd_reduce_or(ne) != 0 {
                        return false
                    }
                }
            }
        }

        m = (n-i) / 16 * 16
        for ; i < m; i += 16 {
            load_a := intrinsics.unaligned_load(cast(^#simd[16]u8)&a[i])
            load_b := intrinsics.unaligned_load(cast(^#simd[16]u8)&b[i])
            ne := intrinsics.simd_lanes_ne(load_a, load_b)
            if intrinsics.simd_reduce_or(ne) != 0 {
                return false
            }
        }

        m = (n-i) / size_of(uintptr) * size_of(uintptr)
        for ; i < m; i += size_of(uintptr) {
            if intrinsics.unaligned_load(cast(^uintptr)&a[i]) != intrinsics.unaligned_load(cast(^uintptr)&b[i]) {
                return false
            }
        }
    }

    for ; i < n; i += 1 {
        if a[i] != b[i] {
            return false
        }
    }
    return true
}


is_power_of_two_int :: #force_inline proc(x: int) -> bool {
    if x <= 0 {
        return false
    }
    return (x & (x-1)) == 0
}

is_power_of_two_uint :: #force_inline proc(x: uint) -> bool {
    return (x & (x-1)) == 0
}

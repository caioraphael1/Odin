import "base:mem"
import "base:intrinsics"
import "base:simd"
import "base:unicode/utf8"


when DUSK_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
    @(private) SCANNER_INDICES_256: simd.u8x32 : {
        0,  1,  2,  3,  4,  5,  6,  7,
        8,  9, 10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31,
    }
    @(private) SCANNER_SENTINEL_MAX_256: simd.u8x32 : u8(0x00)
    @(private) SCANNER_SENTINEL_MIN_256: simd.u8x32 : u8(0xff)
    @(private) SIMD_REG_SIZE_256 :: 32
}
@(private) SCANNER_INDICES_128: simd.u8x16 : {
    0,  1,  2,  3,  4,  5,  6,  7,
    8,  9, 10, 11, 12, 13, 14, 15,
}
@(private) SCANNER_SENTINEL_MAX_128: simd.u8x16 : u8(0x00)
@(private) SCANNER_SENTINEL_MIN_128: simd.u8x16 : u8(0xff)
@(private) SIMD_REG_SIZE_128 :: 16
@(private) PRIME_RABIN_KARP  :: 16777619

equal_fold :: proc(u, v: []u8) -> bool {
    return utf8.string_equal_fold(string(u), string(v))
}

count :: proc(s, substr: []u8) -> uint {
    if len(substr) == 0 { // special case
        return utf8.bytes_rune_count(s) + 1
    }
    if len(substr) == 1 {
        c := substr[0]
        switch len(s) {
        case 0:
            return 0
        case 1:
            return uint(s[0] == c)
        }
        n: uint
        for i: uint = 0; i < len(s); i += 1 {
            if s[i] == c {
                n += 1
            }
        }
        return n
    }

    // TODO(bill): Use a non-brute for approach
    n: uint
    str := s
    for {
        i, found := index_bytes(str, substr)
        if !found {
            return n
        }
        n += 1
        str = str[i+len(substr):]
    }
    return n
}


has_prefix :: proc(s, prefix: []u8) -> bool {
    return len(s) >= len(prefix) && string(s[0:len(prefix)]) == string(prefix)
}

has_suffix :: proc(s, suffix: []u8) -> bool {
    return len(s) >= len(suffix) && string(s[len(s)-len(suffix):]) == string(suffix)
}

// Returns true if a and b have a non-zero length, and any part of a overlaps with b.
overlap :: proc(a, b: []u8) -> bool {
    a_len, b_len := len(a), len(b)
    if a_len == 0 || b_len == 0 {
        return false
    }

    a_start, b_start := uintptr(raw_data(a)), uintptr(raw_data(b))
    a_end, b_end := a_start + uintptr(a_len-1), b_start + uintptr(b_len-1)

    return a_start <= b_end && b_start <= a_end
}

// bytes_overlap_but_not_equal returns true iffa and b have a non-zero length,
// the base pointer of a and b are NOT equal, and any part of a overlaps
// with b (ie: `bytes_overlap(a, b)` with an exception that returns false for
// `a == b`, `b = a[:len(a)-69]` and similar conditions).
overlap_but_not_equal :: proc(a, b: []u8) -> bool {
    if raw_data(a) == raw_data(b) {
        return false
    }
    return overlap(a, b)
}

/*
Compare two memory ranges defined by slices.
This procedure performs a u8-by-u8 comparison between memory ranges
specified by slices `a` and `b`, and returns a value, specifying their relative
ordering.
If the return value is:
- Equal to `-1`, then `a` is "smaller" than `b`.
- Equal to `+1`, then `a` is "bigger"  than `b`.
- Equal to `0`, then `a` and `b` are equal.
The comparison is performed as follows:
1. Each u8, upto `min(len(a), len(b))` bytes is compared between `a` and `b`.
    - If the u8 in slice `a` is smaller than a u8 in slice `b`, then comparison
      stops and this procedure returns `-1`.
    - If the u8 in slice `a` is bigger than a u8 in slice `b`, then comparison
      stops and this procedure returns `+1`.
    - Otherwise the comparison continues until `min(len(a), len(b))` are compared.
2. If all the bytes in the range are equal, then the lengths of the slices are compared.
    - If the length of slice `a` is smaller than the length of slice `b`, then `-1` is returned.
    - If the length of slice `b` is smaller than the length of slice `b`, then `+1` is returned.
    - Otherwise `0` is returned.
*/
compare :: proc(a, b: []u8) -> int {
    res := mem.compare(cast(^u8)(raw_data(a)), cast(^u8)(raw_data(b)), min(len(a), len(b)))
    if res == 0 && len(a) != len(b) {
        return len(a) <= len(b) ? -1 : +1
    } else if len(a) == 0 && len(b) == 0 {
        return 0
    }
    return res
}


contain_bytes :: proc(s, substr: []u8) -> bool {
    _, found := index_bytes(s, substr)
    return found
}

contain_bytes_any :: proc(s, chars: []u8) -> bool {
    _, found := index_bytes_any(s, chars)
    return found
}


index_byte :: proc(s: []u8, c: u8) -> (idx: uint, found: bool) #no_bounds_check {
    i: uint = 0 
    l := len(s)

    // Guard against small strings.  On modern systems, it is ALWAYS
    // worth vectorizing assuming there is a hardware vector unit, and
    // the data size is large enough.
    if l < SIMD_REG_SIZE_128 {
        for /**/; i < l; i += 1 {
            if s[i] == c {
                return i, true
            }
        }
        return 0, false
    }

    c_vec: simd.u8x16 = c
    when simd.HAS_HARDWARE_SIMD {
        // Note: While this is something that could also logically take
        // advantage of AVX512, the various downclocking and power
        // consumption related woes make premature to have a dedicated
        // code path.
        when DUSK_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
            c_vec_256: simd.u8x32 = c

            s_vecs: [4]simd.u8x32 = ---
            c_vecs: [4]simd.u8x32 = ---
            m_vec: [4]u8 = ---

            // Scan 128-u8 chunks, using 256-bit SIMD.
            for nr_blocks := l / (4 * SIMD_REG_SIZE_256); nr_blocks > 0; nr_blocks -= 1 {
                #unroll for j in 0..<4 {
                    s_vecs[j] = intrinsics.unaligned_load(cast(^simd.u8x32)raw_data(s[i+j*SIMD_REG_SIZE_256:]))
                    c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec_256)
                    m_vec[j] = simd.reduce_or(c_vecs[j])
                }
                if m_vec[0] | m_vec[1] | m_vec[2] | m_vec[3] > 0 {
                    #unroll for j in 0..<4 {
                        if m_vec[j] > 0 {
                            sel := simd.select(c_vecs[j], SCANNER_INDICES_256, SCANNER_SENTINEL_MIN_256)
                            off := simd.reduce_min(sel)
                            return i + j * SIMD_REG_SIZE_256 + int(off), true
                        }
                    }
                }

                i += 4 * SIMD_REG_SIZE_256
            }

            // Scan 64-u8 chunks, using 256-bit SIMD.
            for nr_blocks := (l - i) / (2 * SIMD_REG_SIZE_256); nr_blocks > 0; nr_blocks -= 1 {
                #unroll for j in 0..<2 {
                    s_vecs[j] = intrinsics.unaligned_load(cast(^simd.u8x32)raw_data(s[i+j*SIMD_REG_SIZE_256:]))
                    c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec_256)
                    m_vec[j] = simd.reduce_or(c_vecs[j])
                }
                if m_vec[0] | m_vec[1] > 0 {
                    #unroll for j in 0..<2 {
                        if m_vec[j] > 0 {
                            sel := simd.select(c_vecs[j], SCANNER_INDICES_256, SCANNER_SENTINEL_MIN_256)
                            off := simd.reduce_min(sel)
                            return i + j * SIMD_REG_SIZE_256 + int(off), true
                        }
                    }
                }

                i += 2 * SIMD_REG_SIZE_256
            }
        } else {
            s_vecs: [4]simd.u8x16 = ---
            c_vecs: [4]simd.u8x16 = ---
            m_vecs: [4]u8 = ---

            // Scan 64-u8 chunks, using 128-bit SIMD.
            for nr_blocks := l / (4 * SIMD_REG_SIZE_128); nr_blocks > 0; nr_blocks -= 1 {
                #unroll for j in 0..<4 {
                    s_vecs[j]= intrinsics.unaligned_load(cast(^simd.u8x16)raw_data(s[i + j*SIMD_REG_SIZE_128:]))
                    c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec)
                    m_vecs[j] = simd.reduce_or(c_vecs[j])
                }
                if m_vecs[0] | m_vecs[1] | m_vecs[2] | m_vecs[3] > 0 {
                    #unroll for j in 0..<4 {
                        if m_vecs[j] > 0 {
                            sel := simd.select(c_vecs[j], SCANNER_INDICES_128, SCANNER_SENTINEL_MIN_128)
                            off := simd.reduce_min(sel)
                            return i + j * SIMD_REG_SIZE_128 + uint(off), true
                        }
                    }
                }

                i += 4 * SIMD_REG_SIZE_128
            }
        }
    }

    // Scan the remaining SIMD register sized chunks.
    //
    // Apparently LLVM does ok with 128-bit SWAR, so this path is also taken
    // on potato targets.  Scanning more at a time when LLVM is emulating SIMD
    // likely does not buy much, as all that does is increase GP register
    // pressure.
    for nr_blocks := (l - i) / SIMD_REG_SIZE_128; nr_blocks > 0; nr_blocks -= 1 {
        s0 := intrinsics.unaligned_load(cast(^simd.u8x16)raw_data(s[i:]))
        c0 := simd.lanes_eq(s0, c_vec)
        if simd.reduce_or(c0) > 0 {
            sel := simd.select(c0, SCANNER_INDICES_128, SCANNER_SENTINEL_MIN_128)
            off := simd.reduce_min(sel)
            return i + uint(off), true
        }

        i += SIMD_REG_SIZE_128
    }

    // Scan serially for the remainder.
    for /**/; i < l; i += 1 {
        if s[i] == c {
            return i, true
        }
    }

    return 0, false
}

last_index_byte :: proc(s: []u8, c: u8) -> (idx: uint, found: bool) #no_bounds_check {
    i := len(s)

    // Guard against small strings.  On modern systems, it is ALWAYS
    // worth vectorizing assuming there is a hardware vector unit, and
    // the data size is large enough.
    if i < SIMD_REG_SIZE_128 {
        #reverse for ch, j in s {
            if ch == c {
                return j, true
            }
        }
        return 0, false
    }

    c_vec: simd.u8x16 = c
    when simd.HAS_HARDWARE_SIMD {
        // Note: While this is something that could also logically take
        // advantage of AVX512, the various downclocking and power
        // consumption related woes make premature to have a dedicated
        // code path.
        when DUSK_ARCH == .amd64 && intrinsics.has_target_feature("avx2") {
            c_vec_256: simd.u8x32 = c

            s_vecs: [4]simd.u8x32 = ---
            c_vecs: [4]simd.u8x32 = ---
            m_vec: [4]u8 = ---

            // Scan 128-u8 chunks, using 256-bit SIMD.
            for i >= 4 * SIMD_REG_SIZE_256 {
                i -= 4 * SIMD_REG_SIZE_256

                #unroll for j in 0..<4 {
                    s_vecs[j] = intrinsics.unaligned_load(cast(^simd.u8x32)raw_data(s[i+j*SIMD_REG_SIZE_256:]))
                    c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec_256)
                    m_vec[j] = simd.reduce_or(c_vecs[j])
                }
                if m_vec[0] | m_vec[1] | m_vec[2] | m_vec[3] > 0 {
                    #unroll for j in 0..<4 {
                        if m_vec[3-j] > 0 {
                            sel := simd.select(c_vecs[3-j], SCANNER_INDICES_256, SCANNER_SENTINEL_MAX_256)
                            off := simd.reduce_max(sel)
                            return i + (3-j) * SIMD_REG_SIZE_256 + int(off), true
                        }
                    }
                }
            }

            // Scan 64-u8 chunks, using 256-bit SIMD.
            for i >= 2 * SIMD_REG_SIZE_256 {
                i -= 2 * SIMD_REG_SIZE_256

                #unroll for j in 0..<2 {
                    s_vecs[j] = intrinsics.unaligned_load(cast(^simd.u8x32)raw_data(s[i+j*SIMD_REG_SIZE_256:]))
                    c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec_256)
                    m_vec[j] = simd.reduce_or(c_vecs[j])
                }
                if m_vec[0] | m_vec[1] > 0 {
                    #unroll for j in 0..<2 {
                        if m_vec[1-j] > 0 {
                            sel := simd.select(c_vecs[1-j], SCANNER_INDICES_256, SCANNER_SENTINEL_MAX_256)
                            off := simd.reduce_max(sel)
                            return i + (1-j) * SIMD_REG_SIZE_256 + int(off), true
                        }
                    }
                }
            }
        } else {
            s_vecs: [4]simd.u8x16 = ---
            c_vecs: [4]simd.u8x16 = ---
            m_vecs: [4]u8 = ---

            // Scan 64-u8 chunks, using 128-bit SIMD.
            for i >= 4 * SIMD_REG_SIZE_128 {
                i -= 4 * SIMD_REG_SIZE_128

                #unroll for j in 0..<4 {
                    s_vecs[j] = intrinsics.unaligned_load(cast(^simd.u8x16)raw_data(s[i + j*SIMD_REG_SIZE_128:]))
                    c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec)
                    m_vecs[j] = simd.reduce_or(c_vecs[j])
                }
                if m_vecs[0] | m_vecs[1] | m_vecs[2] | m_vecs[3] > 0 {
                    #unroll for j in 0..<4 {
                        if m_vecs[3-j] > 0 {
                            sel := simd.select(c_vecs[3-j], SCANNER_INDICES_128, SCANNER_SENTINEL_MAX_128)
                            off := simd.reduce_max(sel)
                            return i + (3-j) * SIMD_REG_SIZE_128 + uint(off), true
                        }
                    }
                }
            }
        }
    }

    // Scan the remaining SIMD register sized chunks.
    //
    // Apparently LLVM does ok with 128-bit SWAR, so this path is also taken
    // on potato targets.  Scanning more at a time when LLVM is emulating SIMD
    // likely does not buy much, as all that does is increase GP register
    // pressure.
    for i >= SIMD_REG_SIZE_128 {
        i -= SIMD_REG_SIZE_128

        s0 := intrinsics.unaligned_load(cast(^simd.u8x16)raw_data(s[i:]))
        c0 := simd.lanes_eq(s0, c_vec)
        if simd.reduce_or(c0) > 0 {
            sel := simd.select(c0, SCANNER_INDICES_128, SCANNER_SENTINEL_MAX_128)
            off := simd.reduce_max(sel)
            return i + uint(off), true
        }
    }

    // Scan serially for the remainder.
    for i > 0 {
        i -= 1
        if s[i] == c {
            return i, true
        }
    }

    return 0, false
}


index_bytes :: proc(s, substr: []u8) -> (idx: uint, found: bool) {
    hash_str_rabin_karp :: proc(s: []u8) -> (hash: u32 = 0, pow: u32 = 1) {
        for i: uint = 0; i < len(s); i += 1 {
            hash = hash*PRIME_RABIN_KARP + u32(s[i])
        }
        sq := u32(PRIME_RABIN_KARP)
        for i := len(s); i > 0; i >>= 1 {
            if (i & 1) != 0 {
                pow *= sq
            }
            sq *= sq
        }
        return
    }

    n := len(substr)
    switch {
    case n == 0:
        return 0, true
    case n == 1:
        return index_byte(s, substr[0])
    case n == len(s):
        if string(s) == string(substr) {
            return 0, true
        }
        return 0, false
    case n > len(s):
        return 0, false
    }

    hash, pow := hash_str_rabin_karp(substr)
    h: u32
    for i: uint = 0; i < n; i += 1 {
        h = h*PRIME_RABIN_KARP + u32(s[i])
    }
    if h == hash && string(s[:n]) == string(substr) {
        return 0, true
    }
    for i := n; i < len(s); /**/ {
        h *= PRIME_RABIN_KARP
        h += u32(s[i])
        h -= pow * u32(s[i-n])
        i += 1
        if h == hash && string(s[i-n:i]) == string(substr) {
            return i - n, true
        }
    }
    return 0, false
}

index_bytes_any :: proc(s, chars: []u8) -> (idx: uint, found: bool) {
    if chars == nil {
        return 0, false
    }

    // TODO(bill): Optimize
    for r, i in s {
        for c in chars {
            if r == c {
                return i, true
            }
        }
    }
    return 0, false
}

last_index_bytes :: proc(s, substr: []u8) -> (idx: uint, found: bool) {
    hash_str_rabin_karp_reverse :: proc(s: []u8) -> (hash: u32 = 0, pow: u32 = 1) {
        for i := int(len(s)) - 1; i >= 0; i -= 1 {
            hash = hash*PRIME_RABIN_KARP + u32(s[i])
        }
        sq := u32(PRIME_RABIN_KARP)
        for i := int(len(s)); i > 0; i >>= 1 {
            if (i & 1) != 0 {
                pow *= sq
            }
            sq *= sq
        }
        return
    }

    n := len(substr)
    switch {
    case n == 0:
        return len(s), true
    case n == 1:
        return last_index_byte(s, substr[0])
    case n == len(s):
        return 0, string(substr) == string(s)
    case n > len(s):
        return 0, false
    }

    hash, pow := hash_str_rabin_karp_reverse(substr)
    last := len(s) - n
    h: u32
    for i := len(s)-1; i >= last; i -= 1 {
        h = h*PRIME_RABIN_KARP + u32(s[i])
    }
    if h == hash && string(s[last:]) == string(substr) {
        return last, true
    }

    for i := int(last) - 1; i >= 0; i -= 1 {
        h *= PRIME_RABIN_KARP
        h += u32(s[i])
        h -= pow * u32(s[uint(i) + n])
        if h == hash && string(s[uint(i) : uint(i) + n]) == string(substr) {
            return uint(i), true
        }
    }
    return 0, false
}


last_index_any :: proc(s, chars: []u8) -> (idx: uint, found: bool) {
    if chars == nil {
        return 0, false
    }

    for i := len(s); i > 0;  {
        r, w := utf8.last_rune_in_bytes(s[:i])
        i -= w
        for c in string(chars) {
            if r == c {
                return i, true
            }
        }
    }
    return 0, false
}


last_index_proc :: proc(s: []u8, p: proc(rune) -> bool, truth := true) -> (idx: uint, found: bool) {
    // TODO(bill): Probably use Rabin-Karp Search
    for i := len(s); i > 0; {
        r, size := utf8.last_rune_in_bytes(s[:i])
        i -= size
        if p(r) == truth {
            return i, true
        }
    }
    return 0, false
}

index_proc_with_state :: proc(s: []u8, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (idx: uint, found: bool) {
    for r, i in string(s) {
        if p(state, r) == truth {
            return i, true
        }
    }
    return 0, false
}

last_index_proc_with_state :: proc(s: []u8, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (idx: uint, found: bool) {
    // TODO(bill): Probably use Rabin-Karp Search
    for i := len(s); i > 0; {
        r, size := utf8.last_rune_in_bytes(s[:i])
        i -= size
        if p(state, r) == truth {
            return i, true
        }
    }
    return 0, false
}

index_rune :: proc(s: []u8, r: rune) -> (idx: uint, valid: bool) {
    switch {
    case u32(r) < utf8.RUNE_SELF:
        return index_byte(s, u8(r))

    case r == utf8.RUNE_ERROR:
        for c, i in string(s) {
            if c == utf8.RUNE_ERROR {
                return i, true
            }
        }
        return 0, false

    case !utf8.rune_is_valid(r):
        return 0, false
    }

    b, w := utf8.bytes_from_rune(r)
    return index_bytes(s, b[:w])
}

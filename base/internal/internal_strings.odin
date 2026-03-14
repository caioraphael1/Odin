#+no-instrumentation

//--------------------------------------------------------------------------------------------------
// String
//--------------------------------------------------------------------------------------------------

Raw_String :: struct {
    data: [^]byte,
    len:  int,
}

__string_cmp :: proc(a, b: string) -> int {
    x := transmute(Raw_String)a
    y := transmute(Raw_String)b

    ret := __mem_compare(x.data, y.data, min(x.len, y.len))
    if ret == 0 && x.len != y.len {
        return -1 if x.len < y.len else +1
    }
    return ret
}

__string_eq :: proc(lhs, rhs: string) -> bool {
    x := transmute(Raw_String)lhs
    y := transmute(Raw_String)rhs
    if x.len != y.len {
        return false
    }
    return #force_inline __mem_equal(x.data, y.data, x.len)
}
__string_ne :: #force_inline proc(a, b: string) -> bool { return !__string_eq(a, b) }
__string_lt :: #force_inline proc(a, b: string) -> bool { return __string_cmp(a, b) < 0 }
__string_gt :: #force_inline proc(a, b: string) -> bool { return __string_cmp(a, b) > 0 }
__string_le :: #force_inline proc(a, b: string) -> bool { return __string_cmp(a, b) <= 0 }
__string_ge :: #force_inline proc(a, b: string) -> bool { return __string_cmp(a, b) >= 0 }

__string_decode_rune :: proc(s: string) -> (rune, int) {
    // NOTE(bill): Duplicated here to remove dependency on package unicode/utf8

    @(static, rodata) accept_sizes := [256]u8{
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x00-0x0f
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x10-0x1f
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x20-0x2f
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x30-0x3f
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x40-0x4f
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x50-0x5f
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x60-0x6f
        0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x70-0x7f

        0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x80-0x8f
        0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x90-0x9f
        0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xa0-0xaf
        0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xb0-0xbf
        0xf1, 0xf1, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xc0-0xcf
        0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xd0-0xdf
        0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x23, 0x03, 0x03, // 0xe0-0xef
        0x34, 0x04, 0x04, 0x04, 0x44, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xf0-0xff
    }
    Accept_Range :: struct {lo, hi: u8}

    @(static, rodata) accept_ranges := [5]Accept_Range{
        {0x80, 0xbf},
        {0xa0, 0xbf},
        {0x80, 0x9f},
        {0x90, 0xbf},
        {0x80, 0x8f},
    }

    MASKX :: 0b0011_1111
    MASK2 :: 0b0001_1111
    MASK3 :: 0b0000_1111
    MASK4 :: 0b0000_0111

    LOCB :: 0b1000_0000
    HICB :: 0b1011_1111


    RUNE_ERROR :: '\ufffd'

    n := len(s)
    if n < 1 {
        return RUNE_ERROR, 0
    }
    s0 := s[0]
    x := accept_sizes[s0]
    if x >= 0xF0 {
        mask := rune(x) << 31 >> 31 // NOTE(bill): Create 0x0000 or 0xffff.
        return rune(s[0])&~mask | RUNE_ERROR&mask, 1
    }
    sz := x & 7
    accept := accept_ranges[x>>4]
    if n < int(sz) {
        return RUNE_ERROR, 1
    }
    b1 := s[1]
    if b1 < accept.lo || accept.hi < b1 {
        return RUNE_ERROR, 1
    }
    if sz == 2 {
        return rune(s0&MASK2)<<6 | rune(b1&MASKX), 2
    }
    b2 := s[2]
    if b2 < LOCB || HICB < b2 {
        return RUNE_ERROR, 1
    }
    if sz == 3 {
        return rune(s0&MASK3)<<12 | rune(b1&MASKX)<<6 | rune(b2&MASKX), 3
    }
    b3 := s[3]
    if b3 < LOCB || HICB < b3 {
        return RUNE_ERROR, 1
    }
    return rune(s0&MASK4)<<18 | rune(b1&MASKX)<<12 | rune(b2&MASKX)<<6 | rune(b3&MASKX), 4
}

__string_decode_last_rune :: proc(s: string) -> (rune, int) {
    RUNE_ERROR :: '\ufffd'
    RUNE_SELF  :: 0x80
    UTF_MAX    :: 4

    r: rune
    size: int
    start, end, limit: int

    end = len(s)
    if end == 0 {
        return RUNE_ERROR, 0
    }
    start = end-1
    r = rune(s[start])
    if r < RUNE_SELF {
        return r, 1
    }

    limit = max(end - UTF_MAX, 0)

    for start-=1; start >= limit; start-=1 {
        if (s[start] & 0xc0) != RUNE_SELF {
            break
        }
    }

    start = max(start, 0)
    r, size = __string_decode_rune(s[start:end])
    if start+size != end {
        return RUNE_ERROR, 1
    }
    return r, size
}


//--------------------------------------------------------------------------------------------------
// String16
//--------------------------------------------------------------------------------------------------

Raw_String16 :: struct {
    data: [^]u16,
    len:  int,
}


__string16_eq :: proc(lhs, rhs: string16) -> bool {
    x := transmute(Raw_String16)lhs
    y := transmute(Raw_String16)rhs
    if x.len != y.len {
        return false
    }
    return #force_inline __mem_equal(x.data, y.data, x.len*size_of(u16))
}
__string16_ne :: #force_inline proc(a, b: string16) -> bool { return !__string16_eq(a, b) }
__string16_lt :: #force_inline proc(a, b: string16) -> bool { return string16_cmp(a, b) < 0 }
__string16_gt :: #force_inline proc(a, b: string16) -> bool { return string16_cmp(a, b) > 0 }
__string16_le :: #force_inline proc(a, b: string16) -> bool { return string16_cmp(a, b) <= 0 }
__string16_ge :: #force_inline proc(a, b: string16) -> bool { return string16_cmp(a, b) >= 0 }
string16_cmp :: proc(a, b: string16) -> int {
    x := transmute(Raw_String16)a
    y := transmute(Raw_String16)b

    ret := __mem_compare(x.data, y.data, min(x.len, y.len)*size_of(u16))
    if ret == 0 && x.len != y.len {
        return -1 if x.len < y.len else +1
    }
    return ret
}


//--------------------------------------------------------------------------------------------------
// CString
//--------------------------------------------------------------------------------------------------

Raw_Cstring :: struct {
    data: [^]byte,
}
#assert(size_of(Raw_Cstring) == size_of(cstring))


__cstring_len :: proc(s: cstring) -> int {
    p0 := uintptr((^byte)(s))
    p := p0
    for p != 0 && (^byte)(p)^ != 0 {
        p += 1
    }
    return int(p - p0)
}


__cstring_to_string :: proc(s: cstring) -> string {
    if s == nil {
        return ""
    }
    ptr := (^byte)(s)
    n := __cstring_len(s)
    return transmute(string)Raw_String{ptr, n}
}


__cstring_eq :: proc(lhs, rhs: cstring) -> bool {
    x := ([^]byte)(lhs)
    y := ([^]byte)(rhs)
    if x == y {
        return true
    }
    if (x == nil) ~ (y == nil) {
        return false
    }
    xn := __cstring_len(lhs)
    yn := __cstring_len(rhs)
    if xn != yn {
        return false
    }
    return #force_inline __mem_equal(x, y, xn)
}
__cstring_ne :: #force_inline proc(a, b: cstring) -> bool { return !__cstring_eq(a, b) }
__cstring_lt :: #force_inline proc(a, b: cstring) -> bool { return cstring_cmp(a, b) < 0 }
__cstring_gt :: #force_inline proc(a, b: cstring) -> bool { return cstring_cmp(a, b) > 0 }
__cstring_le :: #force_inline proc(a, b: cstring) -> bool { return cstring_cmp(a, b) <= 0 }
__cstring_ge :: #force_inline proc(a, b: cstring) -> bool { return cstring_cmp(a, b) >= 0 }
cstring_cmp :: proc(lhs, rhs: cstring) -> int {
    x := ([^]byte)(lhs)
    y := ([^]byte)(rhs)
    if x == y {
        return 0
    }
    if (x == nil) ~ (y == nil) {
        return -1 if x == nil else +1
    }
    xn := __cstring_len(lhs)
    yn := __cstring_len(rhs)
    ret := __mem_compare(x, y, min(xn, yn))
    if ret == 0 && xn != yn {
        return -1 if xn < yn else +1
    }
    return ret
}


//--------------------------------------------------------------------------------------------------
// CString16
//--------------------------------------------------------------------------------------------------

Raw_Cstring16 :: struct {
    data: [^]u16,
}
#assert(size_of(Raw_Cstring16) == size_of(cstring16))

__cstring16_len :: proc(s: cstring16) -> int {
    p := ([^]u16)(s)
    n := 0
    for p != nil && p[0] != 0 {
        p = p[1:]
        n += 1
    }
    return n
}


__cstring16_to_string16 :: proc(s: cstring16) -> string16 {
    if s == nil {
        return ""
    }
    ptr := (^u16)(s)
    n := __cstring16_len(s)
    return transmute(string16)Raw_String16{ptr, n}
}


__cstring16_eq :: proc(lhs, rhs: cstring16) -> bool {
    x := ([^]u16)(lhs)
    y := ([^]u16)(rhs)
    if x == y {
        return true
    }
    if (x == nil) ~ (y == nil) {
        return false
    }
    xn := __cstring16_len(lhs)
    yn := __cstring16_len(rhs)
    if xn != yn {
        return false
    }
    return #force_inline __mem_equal(x, y, xn*size_of(u16))
}
__cstring16_ne :: #force_inline proc(a, b: cstring16) -> bool { return !__cstring16_eq(a, b) }
__cstring16_lt :: #force_inline proc(a, b: cstring16) -> bool { return cstring16_cmp(a, b) < 0 }
__cstring16_gt :: #force_inline proc(a, b: cstring16) -> bool { return cstring16_cmp(a, b) > 0 }
__cstring16_le :: #force_inline proc(a, b: cstring16) -> bool { return cstring16_cmp(a, b) <= 0 }
__cstring16_ge :: #force_inline proc(a, b: cstring16) -> bool { return cstring16_cmp(a, b) >= 0 }
cstring16_cmp :: proc(lhs, rhs: cstring16) -> int {
    x := ([^]u16)(lhs)
    y := ([^]u16)(rhs)
    if x == y {
        return 0
    }
    if (x == nil) ~ (y == nil) {
        return -1 if x == nil else +1
    }
    xn := __cstring16_len(lhs)
    yn := __cstring16_len(rhs)
    ret := __mem_compare(x, y, min(xn, yn)*size_of(u16))
    if ret == 0 && xn != yn {
        return -1 if xn < yn else +1
    }
    return ret
}

__string16_decode_rune :: proc(s: string16) -> (rune, int) {
    REPLACEMENT_CHAR :: '\ufffd'
    _surr1           :: 0xd800
    _surr2           :: 0xdc00
    _surr3           :: 0xe000
    _surr_self       :: 0x10000

    r := rune(REPLACEMENT_CHAR)

    if len(s) < 1 {
        return r, 0
    }

    w := 1
    switch c := s[0]; {
    case c < _surr1, _surr3 <= c:
        r = rune(c)
    case _surr1 <= c && c < _surr2 && 1 < len(s) &&
        _surr2 <= s[1] && s[1] < _surr3:
        r1, r2 := rune(c), rune(s[1])
        if _surr1 <= r1 && r1 < _surr2 && _surr2 <= r2 && r2 < _surr3 {
            r = (r1-_surr1)<<10 | (r2 - _surr2) + _surr_self
        }
        w += 1
    }
    return r, w
}

__string16_decode_last_rune :: proc(s: string16) -> (rune, int) {
    REPLACEMENT_CHAR :: '\ufffd'
    _surr1           :: 0xd800
    _surr2           :: 0xdc00
    _surr3           :: 0xe000
    _surr_self       :: 0x10000

    r := rune(REPLACEMENT_CHAR)

    if len(s) < 1 {
        return r, 0
    }

    n := len(s)-1
    c := s[n]
    w := 1
    if _surr2 <= c && c < _surr3 {
        if n >= 1 {
            r1 := rune(s[n-1])
            r2 := rune(c)
            if _surr1 <= r1 && r1 < _surr2 {
                r = (r1-_surr1)<<10 | (r2 - _surr2) + _surr_self
            }
            w = 2
        }
    } else if c < _surr1 || _surr3 <= c {
        r = rune(c)
    }
    return r, w
}

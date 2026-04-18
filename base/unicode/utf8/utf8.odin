// Procedures and constants to support text-encoding in the `UTF-8` character encoding.
import "base:mem"
import "base:container/slice"

import unicode ".."

RUNE_ERROR :: '\ufffd'
RUNE_SELF  :: 0x80
RUNE_BOM   :: 0xfeff
RUNE_EOF   :: ~rune(0)
MAX_RUNE   :: '\U0010ffff'
UTF_MAX    :: 4

SURROGATE_MIN :: 0xd800
SURROGATE_MAX :: 0xdfff

// A high/leading surrogate is in range SURROGATE_MIN..SURROGATE_HIGH_MAX,
// A low/trailing surrogate is in range SURROGATE_LOW_MIN..SURROGATE_MAX.
SURROGATE_HIGH_MAX :: 0xdbff
SURROGATE_LOW_MIN  :: 0xdc00

T1 :: 0b0000_0000
TX :: 0b1000_0000
T2 :: 0b1100_0000
T3 :: 0b1110_0000
T4 :: 0b1111_0000
T5 :: 0b1111_1000

MASKX :: 0b0011_1111
MASK2 :: 0b0001_1111
MASK3 :: 0b0000_1111
MASK4 :: 0b0000_0111

RUNE1_MAX :: 1<<7 - 1
RUNE2_MAX :: 1<<11 - 1
RUNE3_MAX :: 1<<16 - 1

// The default lowest and highest continuation u8.
LOCB :: 0b1000_0000
HICB :: 0b1011_1111

Accept_Range :: struct { lo, hi: u8 }

accept_ranges := [5]Accept_Range{
    {0x80, 0xbf},
    {0xa0, 0xbf},
    {0x80, 0x9f},
    {0x90, 0xbf},
    {0x80, 0x8f},
}

accept_sizes :=  [256]u8{
    0x00..=0x7f = 0xf0, // ascii,    size 1
    0x80..=0xc1 = 0xf1, // invalid,  size 1
    0xc2..=0xdf = 0x02, // accept 1, size 2
    0xe0        = 0x13, // accept 1, size 3
    0xe1..=0xec = 0x03, // accept 0, size 3
    0xed        = 0x23, // accept 2, size 3
    0xee..=0xef = 0x03, // accept 0, size 3
    0xf0        = 0x34, // accept 3, size 4
    0xf1..=0xf3 = 0x04, // accept 0, size 4
    0xf4        = 0x44, // accept 4, size 4
    0xf5..=0xff = 0xf1, // ascii,    size 1
}


rune_from_string :: #force_inline proc(s: string) -> (r: rune, bytes_used: uint) {
    return rune_from_bytes(transmute([]u8)s)
}

runes_from_string :: proc(s: string, allocator: mem.Allocator) -> (runes: []rune) {
    n := string_rune_count(s)

    runes, _ = slice.create(rune, n, allocator)
    i := 0
    for r in s {
        runes[i] = r
        i += 1
    }
    return
}

rune_from_bytes :: proc(s: []u8) -> (r: rune, bytes_used: uint) {
    n := len(s)
    if n < 1 {
        return RUNE_ERROR, 0
    }
    #no_bounds_check s0 := s[0]
    x := accept_sizes[s0]
    if x >= 0xF0 {
        mask := rune(x) << 31 >> 31 // NOTE(bill): Create 0x0000 or 0xffff.
        return rune(s[0])&~mask | RUNE_ERROR&mask, 1
    }
    sz := x & 7
    accept := accept_ranges[x>>4]
    if n < uint(sz) {
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

last_rune_in_string :: #force_inline proc(s: string) -> (rune, uint) {
    return last_rune_in_bytes(transmute([]u8)s)
}

last_rune_in_bytes :: proc(s: []u8) -> (rune, uint) {
    end: uint = len(s)
    if end == 0 {
        return RUNE_ERROR, 0
    }

    start := end - 1
    r := rune(s[start])
    if r < RUNE_SELF {
        return r, 1
    }

    limit := max(end - UTF_MAX, 0)

    for start -= 1; start >= limit; start -= 1 {
        if rune_is_start(s[start]) {
            break
        }
    }

    start = max(start, 0)
    size: uint
    r, size = rune_from_bytes(s[start:end])
    if start + size != end {
        return RUNE_ERROR, 1
    }
    return r, size
}


rune_at_pos :: proc(s: string, pos: uint) -> rune {
    i: uint
    for r in s {
        if i == pos {
            return r
        }
        i += 1
    }
    return RUNE_ERROR
}

rune_string_at_pos :: proc(s: string, pos: uint) -> string {
    i: uint
    for c, offset in s {
        if i == pos {
            w := rune_size(c)
            return s[offset:][:w]
        }
        i += 1
    }
    return ""
}

rune_at :: proc(s: string, byte_index: int) -> rune {
    r, _ := rune_from_string(s[byte_index:])
    return r
}

// Returns the u8 position of rune at position pos in s with an optional start u8 position.
// Returns -1 if it runs out of the string.
rune_offset :: proc(s: string, pos: uint, start: uint = 0) -> int {
    i: uint
    for _, offset in s[start:] {
        if i == pos {
            return int(offset + start)
        }
        i += 1
    }
    return -1
}

rune_size :: proc(r: rune) -> int {
    switch {
    case r < 0:          return -1
    case r <= 1<<7  - 1: return 1
    case r <= 1<<11 - 1: return 2
    case SURROGATE_MIN <= r && r <= SURROGATE_MAX: return -1
    case r <= 1<<16 - 1: return 3
    case r <= MAX_RUNE:  return 4
    }
    return -1
}

rune_is_valid :: proc(r: rune) -> bool {
    if r < 0 {
        return false
    } else if SURROGATE_MIN <= r && r <= SURROGATE_MAX {
        return false
    } else if r > MAX_RUNE {
        return false
    }
    return true
}

/* 
| Byte type           |     Binary pattern    | Meaning       |
| ------------------- | --------------------- | ------------- |
| 1-u8 (ASCII)      |        `0xxxxxxx`     | Start of rune |
| Start of multi-u8 | (0xc0) `11xxxxxx`     | Start of rune |
| Continuation u8   | (0x80) `10xxxxxx`     | NOT a start   |
*/
rune_is_start :: #force_inline proc(b: u8) -> bool {
    return b & 0xc0 != 0x80
        /*
        b & 0xc0: This extracts the top two bits of the u8
        then, check if it's different than "Continuation u8 (0x80) `10xxxxxx`"
        */
}


bytes_from_rune :: proc(c: rune) -> (buf: [4]u8, width: uint) {
    r := c

    i := u32(r)
    mask :: u8(0x3f)
    if i <= 1<<7-1 {
        buf[0] = u8(r)
        return buf, 1
    }
    if i <= 1<<11-1 {
        buf[0] = 0xc0 | u8(r>>6)
        buf[1] = 0x80 | u8(r) & mask
        return buf, 2
    }

    // Invalid or Surrogate range
    if i > 0x0010ffff ||
       (0xd800 <= i && i <= 0xdfff) {
        r = 0xfffd
    }

    if i <= 1<<16-1 {
        buf[0] = 0xe0 | u8(r>>12)
        buf[1] = 0x80 | u8(r>>6) & mask
        buf[2] = 0x80 | u8(r)    & mask
        return buf, 3
    }

    buf[0] = 0xf0 | u8(r>>18)
    buf[1] = 0x80 | u8(r>>12) & mask
    buf[2] = 0x80 | u8(r>>6)  & mask
    buf[3] = 0x80 | u8(r)     & mask
    return buf, 4
}

bytes_rune_count :: proc(s: []u8) -> uint {
    count: uint
    n := len(s)

    for i: uint = 0; i < n; {
        defer count += 1
        si := s[i]
        if si < RUNE_SELF { // ascii
            i += 1
            continue
        }
        x := accept_sizes[si]
        if x == 0xf1 {
            i += 1
            continue
        }
        size := uint(x & 7)
        if i + size > n {
            i += 1
            continue
        }
        ar := accept_ranges[x>>4]
        if b := s[i+1]; b < ar.lo || ar.hi < b {
            size = 1
        } else if size == 2 {
            // Okay
        } else if c := s[i+2]; c < 0x80 || 0xbf < c {
            size = 1
        } else if size == 3 {
            // Okay
        } else if d := s[i+3]; d < 0x80 || 0xbf < d {
            size = 1
        }
        i += size
    }
    return count
}

// bytes_has_full_rune reports if the bytes in b begin with a full utf-8 encoding of a rune or not
// An invalid encoding is considered a full rune since it will convert as an error rune of width 1 (RUNE_ERROR)
bytes_has_full_rune :: proc(b: []u8) -> bool {
    n := len(b)
    if n == 0 {
        return false
    }
    x := accept_sizes[b[0]]
    if n >= uint(x & 7) {
        return true
    }
    accept := accept_ranges[x>>4]
    if n > 1 && (b[1] < accept.lo || accept.hi < b[1]) {
        return true
    } else if n > 2 && (b[2] < LOCB || HICB < b[2]) {
        return true
    }
    return false
}


string_rune_count :: #force_inline proc(s: string) -> uint {
    return bytes_rune_count(transmute([]u8)s)
}

// string_has_full_rune reports if the bytes in s begin with a full utf-8 encoding of a rune or not
// An invalid encoding is considered a full rune since it will convert as an error rune of width 1 (RUNE_ERROR)
string_has_full_rune :: proc(s: string) -> bool {
    return bytes_has_full_rune(transmute([]u8)s)
}

string_is_valid :: proc(s: string) -> bool {
    n := len(s)
    for i: uint = 0; i < n; {
        si := s[i]
        if si < RUNE_SELF { // ascii
            i += 1
            continue
        }
        x := accept_sizes[si]
        if x == 0xf1 {
            return false
        }
        size := uint(x & 7)
        if i + size > n {
            return false
        }
        ar := accept_ranges[x>>4]
        if b := s[i+1]; b < ar.lo || ar.hi < b {
            return false
        } else if size == 2 {
            // Okay
        } else if c := s[i+2]; c < 0x80 || 0xbf < c {
            return false
        } else if size == 3 {
            // Okay
        } else if d := s[i+3]; b < 0x80 || 0xbf < d {
            return false
        }
        i += size
    }
    return true
}

string_from_runes :: proc(runes: []rune, allocator: mem.Allocator) -> string {
    byte_count: uint
    for r in runes {
        _, w := bytes_from_rune(r)
        byte_count += w
    }

    bytes, _ := slice.create(u8, byte_count, allocator)
    offset: uint
    for r in runes {
        b, w := bytes_from_rune(r)
        slice.copy(bytes[offset:], b[:w])
        offset += w
    }

    return string(bytes)
}

/*
Returns whether the strings `u` and `v` are the same alpha characters, ignoring different casings
Works with UTF-8 string content

Example:
    fmt.println(utf8.string_equal_fold("test", "test"))
    fmt.println(utf8.string_equal_fold("Test", "test"))
    fmt.println(utf8.string_equal_fold("Test", "tEsT"))
    fmt.println(utf8.string_equal_fold("test", "tes"))
Output:
    true
    true
    true
    false
*/
string_equal_fold :: proc(u, v: string) -> (res: bool) {
    s, t := u, v
    loop: for s != "" && t != "" {
        sr, tr: rune
        if s[0] < RUNE_SELF {
            sr, s = rune(s[0]), s[1:]
        } else {
            r, size := rune_from_string(s)
            sr, s = r, s[size:]
        }
        if t[0] < RUNE_SELF {
            tr, t = rune(t[0]), t[1:]
        } else {
            r, size := rune_from_string(t)
            tr, t = r, t[size:]
        }

        if tr == sr { // easy case
            continue loop
        }

        if tr < sr {
            tr, sr = sr, tr
        }

        if tr < RUNE_SELF {
            switch sr {
            case 'A'..='Z':
                if tr == (sr+'a')-'A' {
                    continue loop
                }
            }
            return false
        }

        r := unicode.simple_fold(sr)
        for r != sr && r < tr {
            r = unicode.simple_fold(sr)
        }
        if r == tr {
            continue loop
        }
        return false
    }

    return s == t
}


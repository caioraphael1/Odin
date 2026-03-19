// A convenient and efficient way to index strings by `Unicode` code point (`rune`) rather than byte.
import "base:internal"
import "base:builtin"

import utf8 ".."

String :: struct {
    contents:   string,
    rune_count: uint,

    // cached information
    non_ascii:  uint, // index to non-ascii code points
    width:      uint, // 0 if ascii
    byte_pos:   uint,
    rune_pos:   uint,
}

@(private)
_len :: builtin.len // helper procedure

init :: proc(s: ^String, contents: string) -> ^String {
    s.contents = contents
    s.byte_pos = 0
    s.rune_pos = 0

    for i in 0..<_len(contents) {
        if contents[i] >= utf8.RUNE_SELF {
            s.rune_count = utf8.string_rune_count(contents)
            _, s.width = utf8.rune_from_string(contents)
            s.non_ascii = i
            return s
        }
    }

    s.rune_count = _len(contents)
    s.width = 0
    s.non_ascii = _len(contents)
    return s
}

to_string :: proc(s: ^String) -> string {
    return s.contents
}

len :: proc(s: ^String) -> uint {
    return s.rune_count
}


is_ascii :: proc(s: ^String) -> bool {
    return s.width == 0
}

at :: proc(s: ^String, i: uint, loc := #caller_location) -> (r: rune) {
    internal.bounds_check_error_loc(loc, i, s.rune_count)

    if i < s.non_ascii {
        return rune(s.contents[i])
    }

    switch i {
    case 0:
        r, s.width = utf8.rune_from_string(s.contents)
        s.rune_pos = 0
        s.byte_pos = 0
        return

    case s.rune_count - 1:
        r, s.width = utf8.last_rune_in_bytes(transmute([]byte)s.contents)
        s.rune_pos = i
        s.byte_pos = _len(s.contents) - s.width
        return

    case s.rune_pos-1:
        r, s.width = utf8.rune_from_string(s.contents[0:s.byte_pos])
        s.rune_pos = i
        s.byte_pos -= s.width
        return

    case s.rune_pos+1:
        s.rune_pos = i
        s.byte_pos += s.width
        fallthrough
    case s.rune_pos:
        r, s.width = utf8.rune_from_string(s.contents[s.byte_pos:])
        return
    }

    // Linear scan
    scan_forward := true
    if i < s.rune_pos {
        if i < (s.rune_pos-s.non_ascii)/2 {
            s.byte_pos, s.rune_pos = s.non_ascii, s.non_ascii
        } else {
            scan_forward = false
        }
    } else if i-s.rune_pos < (s.rune_count-s.rune_pos)/2 {
        // scan_forward = true
    } else {
        s.byte_pos, s.rune_pos = _len(s.contents), s.rune_count
        scan_forward = false
    }

    if scan_forward {
        for {
            r, s.width = utf8.rune_from_string(s.contents[s.byte_pos:])
            if s.rune_pos == i {
                return
            }
            s.rune_pos += 1
            s.byte_pos += s.width

        }
    } else {
        for {
            r, s.width = utf8.last_rune_in_string(s.contents[:s.byte_pos])
            s.rune_pos -= 1
            s.byte_pos -= s.width
            if s.rune_pos == i {
                return
            }
        }
    }
}

slice :: proc(s: ^String, i, j: uint, loc := #caller_location) -> string {
    internal.slice_expr_error_lo_hi_loc(loc, i, j, s.rune_count)

    if j < s.non_ascii {
        return s.contents[i:j]
    }

    if i == j {
        return ""
    }

    lo, hi: uint
    if i < s.non_ascii {
        lo = i
    } else if i == s.rune_count {
        lo = _len(s.contents)
    } else {
        _ = at(s, i, loc)
        lo = s.byte_pos
    }

    if j == s.rune_count {
        hi = _len(s.contents)
    } else {
        _ = at(s, j, loc)
        hi = s.byte_pos
    }

    return s.contents[lo:hi]
}

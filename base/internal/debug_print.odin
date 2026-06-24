@(private="file") INTEGER_DIGITS := "0123456789abcdefghijklmnopqrstuvwxyz"
    // Can't be a constant, as it needs to be indexed.


bytes_from_rune :: proc(c: rune) -> ([4]u8, int) {
    r := c

    buf: [4]u8
    i := u32(r)
    MASK :: u8(0x3f)
    if i <= 1<<7-1 {
        buf[0] = u8(r)
        return buf, 1
    }
    if i <= 1<<11-1 {
        buf[0] = 0xc0 | u8(r>>6)
        buf[1] = 0x80 | u8(r) & MASK
        return buf, 2
    }

    // Invalid or Surrogate range
    if i > 0x0010ffff ||
       (0xd800 <= i && i <= 0xdfff) {
        r = 0xfffd
    }

    if i <= 1<<16-1 {
        buf[0] = 0xe0 | u8(r>>12)
        buf[1] = 0x80 | u8(r>>6) & MASK
        buf[2] = 0x80 | u8(r)    & MASK
        return buf, 3
    }

    buf[0] = 0xf0 | u8(r>>18)
    buf[1] = 0x80 | u8(r>>12) & MASK
    buf[2] = 0x80 | u8(r>>6)  & MASK
    buf[3] = 0x80 | u8(r)     & MASK
    return buf, 4
}

@(optional_results)
print_string :: #force_no_inline proc(str: string) -> (n: int) {
    n, _ = stderr_write(transmute([]u8)str)
    return
}

@(optional_results)
print_strings :: #force_no_inline proc(args: ..string) -> (n: int) {
    for str in args {
        m, err := stderr_write(transmute([]u8)str)
        n += m
        if err != 0 {
            break
        }
    }
    return
}

@(optional_results)
print_byte :: #force_no_inline proc(b: u8) -> (n: int) {
    n, _ = stderr_write([]u8{b})
    return
}

print_encoded_rune :: #force_no_inline proc(r: rune) {
    print_byte('\'')

    switch r {
    case '\a': print_string("\\a")
    case '\b': print_string("\\b")
    case '\e': print_string("\\e")
    case '\f': print_string("\\f")
    case '\n': print_string("\\n")
    case '\r': print_string("\\r")
    case '\t': print_string("\\t")
    case '\v': print_string("\\v")
    case:
        if r <= 0 {
            print_string("\\x00")
        } else if r < 32 {
            n0, n1 := u8(r) >> 4, u8(r) & 0xf
            print_string("\\x")
            print_byte(INTEGER_DIGITS[n0])
            print_byte(INTEGER_DIGITS[n1])
        } else {
            print_rune(r)
        }
    }
    print_byte('\'')
}

@(optional_results)
print_rune :: #force_no_inline proc(r: rune) -> int #no_bounds_check {
    RUNE_SELF :: 0x80

    if r < RUNE_SELF {
        return print_byte(u8(r))
    }

    b, n := bytes_from_rune(r)
    m, _ := stderr_write(b[:n])
    return m
}

print_uint :: proc(x: uint) { 
    print_u64(u64(x))
}

print_uintptr :: proc(x: uintptr) { 
    print_u64(u64(x))
}

print_int :: proc(x: int) { 
    print_i64(i64(x))
}

print_u64 :: #force_no_inline proc(x: u64) #no_bounds_check {
    a: [129]u8
    i := len(a)
    b := u64(10)
    u := x
    for u >= b {
        i -= 1; a[i] = INTEGER_DIGITS[u % b]
        u /= b
    }
    i -= 1; a[i] = INTEGER_DIGITS[u % b]

    _, _ = stderr_write(a[i:])
}

print_i64 :: #force_no_inline proc(x: i64) #no_bounds_check {
    b :: i64(10)

    u := x
    neg := u < 0
    u = abs(u)

    a: [129]u8
    i := len(a)
    for u >= b {
        i -= 1; a[i] = INTEGER_DIGITS[u % b]
        u /= b
    }
    i -= 1; a[i] = INTEGER_DIGITS[u % b]
    if neg {
        i -= 1; a[i] = '-'
    }

    _, _ = stderr_write(a[i:])
}


print_caller_location :: #force_no_inline proc(loc: Source_Code_Location) {
    print_string(loc.file_path)
    when DUSK_ERROR_POS_STYLE == .Default {
        print_byte('(')
        print_u64(u64(loc.line))
        if loc.column != 0 {
            print_byte(':')
            print_u64(u64(loc.column))
        }
        print_byte(')')
    } else when DUSK_ERROR_POS_STYLE == .Unix {
        print_byte(':')
        print_u64(u64(loc.line))
        if loc.column != 0 {
            print_byte(':')
            print_u64(u64(loc.column))
        }
        print_byte(':')
    } else {
        #panic("unhandled DUSK_ERROR_POS_STYLE")
    }
}

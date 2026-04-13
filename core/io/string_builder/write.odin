
import "base:mem"
import "base:container/dyn_array"
import "base:strconv"
import "base:unicode/utf8"

/*
Example:
    builder := string_builder.builder_create()
    string_builder.write_byte(&builder, 'a')        // 1
    string_builder.write_byte(&builder, 'b')        // 1
    fmt.println(string_builder.to_string(builder))  // -> ab
Output:
    ab
*/
write_byte :: proc(b: ^Builder, x: u8, loc := #caller_location) -> (n: uint, err: mem.Allocator_Error) {
    n0 := b.buf.len
    dyn_array.append(&b.buf, x, loc) or_return
    n1 := b.buf.len
    return n1 - n0, nil
}

/*
Example:
    builder := string_builder.builder_create()
    bytes := [?]u8 { 'a', 'b', 'c' }
    string_builder.write_bytes(&builder, bytes[:]) // 3
    fmt.println(string_builder.to_string(builder)) // -> abc
*/
@(optional_results)
write_bytes :: proc(b: ^Builder, x: []u8, loc := #caller_location) -> (n: uint, err: mem.Allocator_Error) {
    n0 := b.buf.len
    dyn_array.append_many(&b.buf, ..x, loc=loc) or_return
    n1 := b.buf.len
    return n1 - n0, nil
}

/*
Appends a single rune to the Builder and returns the number of bytes written
NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.
Example:
    builder := builder_create()
    write_rune(&builder, 'ä')       // 2 None
    write_rune(&builder, 'b')       // 1 None
    fmt.println(to_string(builder)) // -> äb
Output:
    äb
*/
@(optional_results)
write_rune :: proc(b: ^Builder, r: rune, loc := #caller_location) -> (size: uint, err: mem.Allocator_Error) {
    if r < utf8.RUNE_SELF {
        _, err = write_byte(b, u8(r), loc=loc)
        if err == nil {
            size = 1
        }
        return
    }
    buf, w := utf8.bytes_from_rune(r)
    return write_bytes(b, buf[:w], loc)
}




@(private="file") DIGITS_LOWER := "0123456789abcdefx"

/*
Example:
    builder := string_builder.builder_create()
    string_builder.write_string(&builder, "abc")      // 3
    strings.write_quoted_rune(&builder, 'ä') // 4
    string_builder.write_string(&builder, "abc")      // 3
    fmt.println(string_builder.to_string(builder))    // -> abc'ä'abc
Output:
    abc'ä'abc
*/
@(optional_results)
write_quoted_rune :: proc(b: ^Builder, r: rune) -> (n: uint, err: mem.Allocator_Error) {
    quote := u8('\'')
    n += write_byte(b, quote) or_return
    buf, width := utf8.bytes_from_rune(r)
    if width == 1 && r == utf8.RUNE_ERROR {
        n += write_byte(b, '\\') or_return
        n += write_byte(b, 'x') or_return
        n += write_byte(b, DIGITS_LOWER[buf[0]>>4]) or_return
        n += write_byte(b, DIGITS_LOWER[buf[0]&0xf]) or_return
    } else {
        i := write_escaped_rune(b, r, quote) or_return
        n += i
    }
    n += write_byte(b, quote) or_return
    return
}


/*
Example:
    builder := string_builder.builder_create()
    string_builder.write_string(&builder, "a")     // 1
    string_builder.write_string(&builder, "bc")    // 2
    fmt.println(string_builder.to_string(builder)) // -> abc
Output:
    abc
*/
@(optional_results)
write_string :: proc(b: ^Builder, s: string, loc := #caller_location) -> (n: uint, err: mem.Allocator_Error) {
    n0 := b.buf.len
    dyn_array.append_string_to_bytes(&b.buf, s, loc) or_return
    n1 := b.buf.len
    return n1 - n0, nil
}

/*
Inputs:
- b: A pointer to the Builder
- str: The string to be quoted and appended
- quote: The optional quote character (default is double quotes)
Example:
    builder := string_builder.builder_create()
    strings.write_quoted_string(&builder, "a")        // 3
    strings.write_quoted_string(&builder, "bc", '\'') // 4
    strings.write_quoted_string(&builder, "xyz")      // 5
    fmt.println(string_builder.to_string(builder))
Output:
    "a"'bc'"xyz"
*/
@(optional_results)
write_quoted_string :: proc(b: ^Builder, str: string, quote: u8 = '"') -> (n: uint, err: mem.Allocator_Error) {
    n += write_byte(b, quote) or_return
    width: uint
    for s := str; len(s) > 0; s = s[width:] {
        r := rune(s[0])
        width = 1
        if r >= utf8.RUNE_SELF {
            r, width = utf8.rune_from_string(s)
        }
        if width == 1 && r == utf8.RUNE_ERROR {
            n += write_byte(b, '\\')                   or_return
            n += write_byte(b, 'x')                    or_return
            n += write_byte(b, DIGITS_LOWER[s[0]>>4])  or_return
            n += write_byte(b, DIGITS_LOWER[s[0]&0xf]) or_return
            continue
        }

        n += write_escaped_rune(b, r, quote, false) or_return

    }
    n += write_byte(b, quote) or_return
    return
}


/*
Appends a rune to the Builder and returns the number of bytes written
Inputs:
- b: A pointer to the Builder
- r: The rune to be appended
- write_quote: Optional boolean flag to wrap in single-quotes (') (default is true)
Example:
    builder := string_builder.builder_create()
    _, _ = strings.write_encoded_rune(&builder, 'a', false) // 1
    _, _ = strings.write_encoded_rune(&builder, '\"', true) // 3
    _, _ = strings.write_encoded_rune(&builder, 'x', false) // 1
    fmt.println(string_builder.to_string(builder))
Output:
    a'"'x
*/
@(optional_results)
write_encoded_rune :: proc(b: ^Builder, r: rune, write_quote := true) -> (n: uint, err: mem.Allocator_Error) {
    if write_quote {
        n += write_byte(b, '\'') or_return
    }
    switch r {
    case '\a': n += write_string(b, `\a`) or_return
    case '\b': n += write_string(b, `\b`) or_return
    case '\e': n += write_string(b, `\e`) or_return
    case '\f': n += write_string(b, `\f`) or_return
    case '\n': n += write_string(b, `\n`) or_return
    case '\r': n += write_string(b, `\r`) or_return
    case '\t': n += write_string(b, `\t`) or_return
    case '\v': n += write_string(b, `\v`) or_return
    case:
        if r < 32 {
            n += write_string(b, `\x`) or_return
            
            buf: [2]u8
            s := strconv.write_bits(buf[:], u64(r), 16, true, 64, strconv.digits, nil)
            switch len(s) {
            case 0: 
                n += write_string(b, "00") or_return
            case 1: 
                n += write_byte(b, '0') or_return
                fallthrough
            case 2: 
                n += write_string(b, s) or_return
            }
        } else {
            n += write_rune(b, r) or_return
        }

    }
    if write_quote {
        n += write_byte(b, '\'') or_return
    }
    return
}



/*
Appends an escaped rune to the Builder and returns the number of bytes written
Inputs:
- b: A pointer to the Builder
- r: The rune to be appended
- quote: The quote character
- html_safe: Optional boolean flag to encode '<', '>', '&' as digits (default is false)
**Usage**
- '\a' will be written as such
- `r` and `quote` match and `quote` is `\\` - they will be written as two slashes
- `html_safe` flag in case the runes '<', '>', '&' should be encoded as digits e.g. `\u0026`
*/
@(optional_results)
write_escaped_rune :: proc(b: ^Builder, r: rune, quote: u8, html_safe := false) -> (n: uint, err: mem.Allocator_Error) {
    is_printable :: proc(r: rune) -> bool {
        if r <= 0xff {
            switch r {
            case 0x20..=0x7e:
                return true
            case 0xa1..=0xff:
                return r != 0xad
            }
        }

        return false
    }

    if html_safe {
        switch r {
        case '<', '>', '&':
            n += write_byte(b, '\\') or_return
            n += write_byte(b, 'u') or_return
            for s := 12; s >= 0; s -= 4 {
                n += write_byte(b, DIGITS_LOWER[r>>uint(s) & 0xf]) or_return
            }
            return
        }
    }

    if r == rune(quote) || r == '\\' {
        n += write_byte(b, '\\') or_return
        n += write_byte(b, u8(r)) or_return
        return
    } else if is_printable(r) {
        n += write_encoded_rune(b, r, false) or_return
        return
    }

    switch r {
    case '\a': n += write_string(b, `\a`) or_return
    case '\b': n += write_string(b, `\b`) or_return
    case '\e': n += write_string(b, `\e`) or_return
    case '\f': n += write_string(b, `\f`) or_return
    case '\n': n += write_string(b, `\n`) or_return
    case '\r': n += write_string(b, `\r`) or_return
    case '\t': n += write_string(b, `\t`) or_return
    case '\v': n += write_string(b, `\v`) or_return
    case:
        switch c := r; {
        case c < ' ':
            n += write_byte(b, '\\') or_return
            n += write_byte(b, 'x') or_return
            n += write_byte(b, DIGITS_LOWER[u8(c)>>4]) or_return
            n += write_byte(b, DIGITS_LOWER[u8(c)&0xf]) or_return

        case c > utf8.MAX_RUNE:
            c = 0xfffd
            fallthrough
        case c < 0x10000:
            n += write_byte(b, '\\') or_return
            n += write_byte(b, 'u')  or_return
            for s := 12; s >= 0; s -= 4 {
                n += write_byte(b, DIGITS_LOWER[c>>uint(s) & 0xf]) or_return
            }
        case:
            n += write_byte(b, '\\') or_return
            n += write_byte(b, 'U') or_return
            for s := 28; s >= 0; s -= 4 {
                n += write_byte(b, DIGITS_LOWER[c>>uint(s) & 0xf]) or_return
            }
        }
    }
    return
}


@(optional_results)
write_float :: proc(b: ^Builder, f: f64, fmt: u8, prec, bit_size: uint, always_signed := false) -> (n: uint, err: mem.Allocator_Error) {
    buf: [384]u8
    s := strconv.write_float(buf[:], f, fmt, prec, bit_size, false)
    // If the result starts with a `+` then unless we always want signed results,
    // we skip it unless it's followed by an `I` (because of +Inf).
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

@(optional_results)
write_f16 :: proc(b: ^Builder, f: f16, fmt: u8, always_signed := false) -> (n: uint, err: mem.Allocator_Error) {
    buf: [384]u8
    s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f), false)
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

/*
Example:
    builder := string_builder.builder_create()
    strings.write_f32(&builder, 3.14159, 'f') // 6
    string_builder.write_string(&builder, " - ")     // 3
    strings.write_f32(&builder, -0.123, 'e')  // 8
    fmt.println(string_builder.to_string(builder))   // -> 3.14159012 - -1.23000003e-01
Output:
    3.14159012 - -1.23000003e-01
*/
write_f32 :: proc(b: ^Builder, f: f32, fmt: u8, always_signed := false) -> (n: uint, err: mem.Allocator_Error) {
    buf: [384]u8
    s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f), false)
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

write_f64 :: proc(b: ^Builder, f: f64, fmt: u8, always_signed := false) -> (n: uint, err: mem.Allocator_Error) {
    buf: [384]u8
    s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f), false)
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

write_u64 :: proc(b: ^Builder, i: u64, base: uint = 10) -> (n: uint, err: mem.Allocator_Error) {
    buf: [32]u8
    s := strconv.write_bits(buf[:], i, base, false, 64, strconv.digits, nil)
    return write_string(b, s)
}

write_i64 :: proc(b: ^Builder, i: i64, base: uint = 10) -> (n: uint, err: mem.Allocator_Error) {
    buf: [32]u8
    s := strconv.write_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
    return write_string(b, s)
}

write_uint :: proc(b: ^Builder, i: uint, base: uint = 10) -> (n: uint, err: mem.Allocator_Error) {
    return write_u64(b, u64(i), base)
}

write_int :: proc(b: ^Builder, i: int, base: uint = 10) -> (n: uint, err: mem.Allocator_Error) {
    return write_i64(b, i64(i), base)
}

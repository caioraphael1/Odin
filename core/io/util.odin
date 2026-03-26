
import "base:mem"

import "base:strconv"
import "base:unicode/utf8"
import "base:unicode/utf16"

@(private="file")
DIGITS_LOWER := "0123456789abcdefx"


read_ptr :: proc(r: Reader, p: rawptr, byte_size: uint, n_read: ^uint = nil) -> (n: uint, err: Error) {
    return read(r, ([^]u8)(p)[:byte_size], n_read)
}

read_slice :: proc(r: Reader, slice: $S/[]$T, n_read: ^uint = nil) -> (n: uint, err: Error) {
    size := len(slice)*size_of(T)
    return read_ptr(w, raw_data(slice), size, n_read)
}


write_ptr :: proc(w: Writer, p: rawptr, byte_size: uint, n_written: ^uint = nil) -> (n: uint, err: Error) {
    return write(w, ([^]u8)(p)[:byte_size], n_written)
}

read_ptr_at :: proc(r: Reader_At, p: rawptr, byte_size: uint, offset: i64, n_read: ^uint = nil) -> (n: uint, err: Error) {
    return read_at(r, ([^]u8)(p)[:byte_size], offset, n_read)
}

write_ptr_at :: proc(w: Writer_At, p: rawptr, byte_size: uint, offset: i64, n_written: ^uint = nil) -> (n: uint, err: Error) {
    return write_at(w, ([^]u8)(p)[:byte_size], offset, n_written)
}

write_slice :: proc(w: Writer, slice: $S/[]$T, n_written: ^uint = nil) -> (n: uint, err: Error) {
    size := len(slice)*size_of(T)
    return write_ptr(w, raw_data(slice), size, n_written)
}

write_u64 :: proc(w: Writer, i: u64, base: uint = 10, n_written: ^uint = nil) -> (n: uint, err: Error) {
    buf: [64]u8
    s := strconv.write_bits(buf[:], i, base, false, 64, strconv.digits, nil)
    return write_string(w, s, n_written)
}

write_i64 :: proc(w: Writer, i: i64, base: uint = 10, n_written: ^uint = nil) -> (n: uint, err: Error) {
    buf: [65]u8
    s := strconv.write_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
    return write_string(w, s, n_written)
}

write_uint :: proc(w: Writer, i: uint, base: uint = 10, n_written: ^uint = nil) -> (n: uint, err: Error) {
    return write_u64(w, u64(i), base, n_written)
}

write_int :: proc(w: Writer, i: int, base: uint = 10, n_written: ^uint = nil) -> (n: uint, err: Error) {
    return write_i64(w, i64(i), base, n_written)
}

write_u128 :: proc(w: Writer, i: u128, base: uint = 10, n_written: ^uint = nil) -> (n: uint, err: Error) {
    buf: [128]u8
    s := strconv.write_bits_128(buf[:], i, base, false, 128, strconv.digits, nil)
    return write_string(w, s, n_written)
}

write_i128 :: proc(w: Writer, i: i128, base: uint = 10, n_written: ^uint = nil) -> (n: uint, err: Error) {
    buf: [129]u8
    s := strconv.write_bits_128(buf[:], u128(i), base, true, 128, strconv.digits, nil)
    return write_string(w, s, n_written)
}

write_f16 :: proc(w: Writer, val: f16, n_written: ^uint = nil) -> (n: uint, err: Error) {
    buf: [386]u8

    str := strconv.write_float(buf[1:], f64(val), 'f', 2*size_of(val), 8*size_of(val), false)
    s := buf[:len(str)+1]
    if s[1] == '+' || s[1] == '-' {
        s = s[1:]
    } else {
        s[0] = '+'
    }
    if s[0] == '+' {
        s = s[1:]
    }

    return write_string(w, string(s), n_written)
}

write_f32 :: proc(w: Writer, val: f32, n_written: ^uint = nil) -> (n: uint, err: Error) {
    buf: [386]u8

    str := strconv.write_float(buf[1:], f64(val), 'f', 2*size_of(val), 8*size_of(val), false)
    s := buf[:len(str)+1]
    if s[1] == '+' || s[1] == '-' {
        s = s[1:]
    } else {
        s[0] = '+'
    }
    if s[0] == '+' {
        s = s[1:]
    }

    return write_string(w, string(s), n_written)
} 

write_f64 :: proc(w: Writer, val: f64, n_written: ^uint = nil) -> (n: uint, err: Error) {
    buf: [386]u8

    str := strconv.write_float(buf[1:], val, 'f', 2*size_of(val), 8*size_of(val), false)
    s := buf[:len(str)+1]
    if s[1] == '+' || s[1] == '-' {
        s = s[1:]
    } else {
        s[0] = '+'
    }
    if s[0] == '+' {
        s = s[1:]
    }

    return write_string(w, string(s), n_written)
}   



n_wrapper :: proc(n: uint, err: Error, bytes_processed: ^uint) -> Error {
    bytes_processed^ += n
    return err
}


write_encoded_rune :: proc(w: Writer, r: rune, write_quote := true, n_written: ^uint = nil) -> (n: uint, err: Error) {
    defer if n_written != nil {
        n_written^ += n
    }
    if write_quote {
        write_byte(w, '\'', &n) or_return
    }
    switch r {
    case '\a': _ = write_string(w, `\a`, &n) or_return
    case '\b': _ = write_string(w, `\b`, &n) or_return
    case '\e': _ = write_string(w, `\e`, &n) or_return
    case '\f': _ = write_string(w, `\f`, &n) or_return
    case '\n': _ = write_string(w, `\n`, &n) or_return
    case '\r': _ = write_string(w, `\r`, &n) or_return
    case '\t': _ = write_string(w, `\t`, &n) or_return
    case '\v': _ = write_string(w, `\v`, &n) or_return
    case:
        if r < 32 {
            _ = write_string(w, `\x`, &n) or_return
            
            buf: [2]u8
            s := strconv.write_bits(buf[:], u64(r), 16, true, 64, strconv.digits, nil)
            switch len(s) {
            case 0: 
                _ = write_string(w, "00", &n) or_return
            case 1: 
                write_byte(w, '0',    &n) or_return
                fallthrough
            case 2: 
                _ = write_string(w, s,    &n) or_return
            }
        } else {
            _ = write_rune(w, r, &n) or_return
        }

    }
    if write_quote {
        write_byte(w, '\'', &n) or_return
    }
    return
}

write_escaped_rune :: proc(w: Writer, r: rune, quote: u8, html_safe := false, n_written: ^uint = nil, for_json := false) -> (n: uint, err: Error) {
    is_printable :: proc(r: rune) -> bool {
        if r <= 0xff {
            switch r {
            case 0x20..=0x7e:
                return true
            case 0xa1..=0xff: // ¡ through ÿ except for the soft hyphen
                return r != 0xad //
            }
        }

        // TODO(bill): A proper unicode library will be needed!
        return false
    }
    defer if n_written != nil {
        n_written^ += n
    }

    if html_safe {
        switch r {
        case '<', '>', '&':
            write_byte(w, '\\', &n) or_return
            write_byte(w, 'u', &n)  or_return
            for s := 12; s >= 0; s -= 4 {
                write_byte(w, DIGITS_LOWER[r>>uint(s) & 0xf], &n) or_return
            }
            return
        }
    }

    if r == rune(quote) || r == '\\' {
        write_byte(w, '\\', &n)    or_return
        write_byte(w, u8(r), &n) or_return
        return
    } else if is_printable(r) {
        _ = write_encoded_rune(w, r, false, &n) or_return
        return
    }
    if r < 32 && for_json {
        switch r {
        case '\b': _ = write_string(w, `\b`, &n) or_return
        case '\f': _ = write_string(w, `\f`, &n) or_return
        case '\n': _ = write_string(w, `\n`, &n) or_return
        case '\r': _ = write_string(w, `\r`, &n) or_return
        case '\t': _ = write_string(w, `\t`, &n) or_return
        case:
            write_byte(w, '\\', &n) or_return
            write_byte(w, 'u', &n)  or_return
            write_byte(w, '0', &n)  or_return
            write_byte(w, '0', &n)  or_return
            write_byte(w, DIGITS_LOWER[r>>4 & 0xf], &n) or_return
            write_byte(w, DIGITS_LOWER[r    & 0xf], &n) or_return
        }
        return
    }
    switch r {
    case '\a': _ = write_string(w, `\a`, &n) or_return
    case '\b': _ = write_string(w, `\b`, &n) or_return
    case '\e': _ = write_string(w, `\e`, &n) or_return
    case '\f': _ = write_string(w, `\f`, &n) or_return
    case '\n': _ = write_string(w, `\n`, &n) or_return
    case '\r': _ = write_string(w, `\r`, &n) or_return
    case '\t': _ = write_string(w, `\t`, &n) or_return
    case '\v': _ = write_string(w, `\v`, &n) or_return
    case:
        switch c := r; {
        case c < ' ':
            write_byte(w, '\\', &n)                      or_return
            write_byte(w, 'x', &n)                       or_return
            write_byte(w, DIGITS_LOWER[u8(c)>>4], &n)  or_return
            write_byte(w, DIGITS_LOWER[u8(c)&0xf], &n) or_return

        case c > utf8.MAX_RUNE:
            c = 0xfffd
            fallthrough
        case c < 0x10000:
            write_byte(w, '\\', &n) or_return
            write_byte(w, 'u', &n)  or_return
            for s := 12; s >= 0; s -= 4 {
                write_byte(w, DIGITS_LOWER[c>>uint(s) & 0xf], &n) or_return
            }
        case:
            if for_json {
                buf: [2]u16
                _ = utf16.encode(buf[:], []rune{c})
                for bc in buf {
                    write_byte(w, '\\', &n) or_return
                    write_byte(w, 'u', &n)  or_return
                    for s := 12; s >= 0; s -= 4 {
                        write_byte(w, DIGITS_LOWER[bc>>uint(s) & 0xf], &n) or_return
                    }
                }
            } else {
                write_byte(w, '\\', &n) or_return
                write_byte(w, 'U', &n)  or_return
                for s := 28; s >= 0; s -= 4 {
                    write_byte(w, DIGITS_LOWER[c>>uint(s) & 0xf], &n) or_return
                }
            }
        }
    }
    return
}

write_quoted_string :: proc(w: Writer, str: string, quote: u8 = '"', n_written: ^uint = nil, for_json := false) -> (n: uint, err: Error) {
    defer if n_written != nil {
        n_written^ += n
    }
    write_byte(w, quote, &n) or_return
    width: uint
    for s := str; len(s) > 0; s = s[width:] {
        r := rune(s[0])
        width = 1
        if r >= utf8.RUNE_SELF {
            r, width = utf8.rune_from_string(s)
        }
        if width == 1 && r == utf8.RUNE_ERROR {
            write_byte(w, '\\', &n)                   or_return
            write_byte(w, 'x', &n)                    or_return
            write_byte(w, DIGITS_LOWER[s[0]>>4], &n)  or_return
            write_byte(w, DIGITS_LOWER[s[0]&0xf], &n) or_return
            continue
        }

        n_wrapper(write_escaped_rune(w, r, quote, false, nil, for_json), &n) or_return

    }
    write_byte(w, quote, &n) or_return
    return
}

write_quoted_string16 :: proc(w: Writer, str: string16, quote: u8 = '"', n_written: ^uint = nil, for_json := false) -> (n: uint, err: Error) {
    defer if n_written != nil {
        n_written^ += n
    }
    write_byte(w, quote, &n) or_return
    for width, s := 0, str; len(s) > 0; s = s[width:] {
        r := rune(s[0])
        width = 1
        if r >= utf8.RUNE_SELF {
            r, width = utf16.rune_from_string(s)
        }
        if width == 1 && r == utf8.RUNE_ERROR {
            write_byte(w, '\\', &n)                   or_return
            write_byte(w, 'x', &n)                    or_return
            write_byte(w, DIGITS_LOWER[s[0]>>4], &n)  or_return
            write_byte(w, DIGITS_LOWER[s[0]&0xf], &n) or_return
            continue
        }

        n_wrapper(write_escaped_rune(w, r, quote, false, nil, for_json), &n) or_return

    }
    write_byte(w, quote, &n) or_return
    return
}


// writer append a quoted rune into the u8 buffer, return the written size
write_quoted_rune :: proc(w: Writer, r: rune) -> (n: uint) {
    _write_byte :: #force_inline proc(w: Writer, c: u8) -> uint {
        err := write_byte(w, c)
        return 1 if err == nil else 0
    }

    quote := u8('\'')
    n += _write_byte(w, quote)
    buf, width := utf8.bytes_from_rune(r)
    if width == 1 && r == utf8.RUNE_ERROR {
        n += _write_byte(w, '\\')
        n += _write_byte(w, 'x')
        n += _write_byte(w, DIGITS_LOWER[buf[0]>>4])
        n += _write_byte(w, DIGITS_LOWER[buf[0]&0xf])
    } else {
        i, _ := write_escaped_rune(w, r, quote)
        n += i
    }
    n += _write_byte(w, quote)
    return
}

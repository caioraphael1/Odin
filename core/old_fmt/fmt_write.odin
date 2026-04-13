#+ignore
import "base:internal"

import "core:io/string_builder"


// Internal data structure that stores the required information for formatted printing
// Info :: struct {
//     using state: Info_State,

//     writer:            string_builder.Builder,
//     arg:               any, // Temporary
//     indirection_level: uint,
//     record_level:      uint,

//     optional_len: internal.Maybe(uint),
//     use_nul_termination: bool,

//     n: uint, // bytes written
// }


/* 
// Prefix
prefix_loop: for ; i < end; i += 1 {
    switch fmt[i] {
    case '+':
        b.plus = true
    case '-':
        b.minus = true
        b.zero = false
    case ' ':
        b.space = true
    case '#':
        b.hash = true
    case '0':
        b.zero = !b.minus
    case:
        break prefix_loop
    }
}
*/
Info_State :: struct {
    minus:         bool,
    plus:          bool,
    space:         bool,
    zero:          bool,
    hash:          bool,


    in_bad:        bool,

    width:         uint,
    prec:          uint,
    indent:        uint,

    parent_struct: any,
}

@(optional_results)
wprint :: proc(b: ^string_builder.Builder, args: ..any, sep := " ") -> (n: uint) {
    for _, i in args {
        if i > 0 {
            _n, _ := string_builder.write_string(b, sep)
            n += _n
        }

        n += fmt_value(b, args[i], 'v')
    }
    return
}

@(optional_results)
wprintln :: proc(b: ^string_builder.Builder, args: ..any, sep := " ", flush := true) -> (n: uint) {
    for _, i in args {
        if i > 0 {
            _n, _ := string_builder.write_string(b, sep)
            n += _n
        }

        n += fmt_value(b, args[i], 'v')
    }
    _n, _ := string_builder.write_byte(b, '\n')
    n += _n
    // if flush {
    //     _ = string_builder.flush(w)
    // }
    return
}

wprintfln :: proc(b: ^string_builder.Builder, format: string, args: ..any, flush := true) -> uint {
    return wprintf(b, format, ..args, flush=flush, newline=true)
}

@(optional_results)
wprintf :: proc(b: ^string_builder.Builder, fmt: string, args: ..any, flush := true, newline := false) -> uint {
    MAX_CHECKED_ARGS :: 64
    internal.assert(len(args) <= MAX_CHECKED_ARGS, "number of args > 64 is unsupported")

    parse_options :: proc(b: ^Info, fmt: string, index, end: uint, unused_args: ^bit_set[uint(0) ..< MAX_CHECKED_ARGS], args: ..any) -> uint {
        i := index

        // Prefix
        prefix_loop: for ; i < end; i += 1 {
            switch fmt[i] {
            case '+':
                b.plus = true
            case '-':
                b.minus = true
                b.zero = false
            case ' ':
                b.space = true
            case '#':
                b.hash = true
            case '0':
                b.zero = !b.minus
            case:
                break prefix_loop
            }
        }

        // Width
        if i < end && fmt[i] == '*' {
            i += 1
            width_index, _, index_ok := _arg_number(fmt, &i, len(args))

            if !index_ok {
                width_index, index_ok = error_check_arg(b, false, unused_args^)
            }

            if index_ok {
                unused_args^ -= {width_index}

                b.width, _, b.width_set = uint_from_arg(args, width_index)
                if !b.width_set {
                    _, _ = string_builder.write_string(b.writer, "%!(BAD WIDTH)", &b.n)
                }

                if b.width < 0 {
                    b.width = -b.width
                    b.minus = true
                    b.zero  = false
                }
            }
        } else {
            b.width, i, b.width_set = _parse_uint(fmt, i)
        }

        // Precision
        if i < end && fmt[i] == '.' {
            i += 1
            if i < end && fmt[i] == '*' {
                i += 1
                precision_index, _, index_ok := _arg_number(fmt, &i, len(args))

                if !index_ok {
                    precision_index, index_ok = error_check_arg(b, false, unused_args^)
                }

                if index_ok {
                    unused_args^ -= {precision_index}
                    b.prec, _, b.prec_set = uint_from_arg(args, precision_index)
                    if b.prec < 0 {
                        b.prec = 0
                        b.prec_set = false
                    }
                    if !b.prec_set {
                        _, _ = string_builder.write_string(b.writer, "%!(BAD PRECISION)", &b.n)
                    }
                }
            } else {
                prev_i := i
                b.prec, i, b.prec_set = _parse_uint(fmt, i)
                if i == prev_i {
                    b.prec = 0
                    b.prec_set = true
                }
            }
        }

        return i
    }

    error_check_arg :: proc(b: ^Info, arg_parsed: bool, unused_args: bit_set[uint(0) ..< MAX_CHECKED_ARGS]) -> (uint, bool) {
        if !arg_parsed {
            for index in unused_args {
                return index, true
            }
            _, _ = string_builder.write_string(b.writer, "%!(MISSING ARGUMENT)", &b.n)
        } else {
            _, _ = string_builder.write_string(b.writer, "%!(BAD ARGUMENT NUMBER)", &b.n)
        }

        return 0, false
    }

    b: Info
    end := len(fmt)
    unused_args: bit_set[uint(0) ..< MAX_CHECKED_ARGS]
    for _, i in args {
        unused_args += {i}
    }

    loop: for i: uint = 0; i < end; /**/ {
        b = Info{writer = w, n = b.n}

        prev_i := i
        for i < end && !(fmt[i] == '%' || fmt[i] == '{' || fmt[i] == '}') {
            i += 1
        }
        if i > prev_i {
            _, _ = string_builder.write_string(b.writer, fmt[prev_i:i], &b.n)
        }
        if i >= end {
            break loop
        }

        char := fmt[i]
        // Process a "char"
        i += 1

        if char == '}' {
            if i < end && fmt[i] == char {
                // Skip extra one
                i += 1
            }
            _ = string_builder.write_byte(b.writer, char, &b.n)
            continue loop
        } else if char == '{' {
            if i < end && fmt[i] == char {
                // Skip extra one
                i += 1
                _ = string_builder.write_byte(b.writer, char, &b.n)
                continue loop
            }
        }

        if char == '%' {
            if i < end && fmt[i] == '%' {
                _ = string_builder.write_byte(b.writer, '%', &b.n)
                i += 1
                continue loop
            }

            i = parse_options(&b, fmt, i, end, &unused_args, ..args)

            arg_index, arg_parsed, index_ok := _arg_number(fmt, &i, len(args))

            if !index_ok {
                arg_index, index_ok = error_check_arg(&b, arg_parsed, unused_args)
            }

            if i >= end {
                _, _ = string_builder.write_string(b.writer, "%!(NO VERB)", &b.n)
                break loop
            } else if fmt[i] == ' ' {
                _, _ = string_builder.write_string(b.writer, "%!(NO VERB)", &b.n)
                continue loop
            }

            verb, w := utf8.rune_from_string(fmt[i:])
            i += w

            if index_ok {
                unused_args -= {arg_index}
                fmt_arg(&b, args[arg_index], verb)
            }


        } else if char == '{' {
            arg_index: uint
            arg_parsed, index_ok: bool

            if i < end && fmt[i] != '}' && fmt[i] != ':' {
                arg_index, i, arg_parsed = _parse_uint(fmt, i)
                if arg_parsed {
                    index_ok = 0 <= arg_index && arg_index < len(args)
                }
            }

            if !index_ok {
                arg_index, index_ok = error_check_arg(&b, arg_parsed, unused_args)
            }

            verb: rune = 'v'

            if i < end && fmt[i] == ':' {
                i += 1
                i = parse_options(&b, fmt, i, end, &unused_args, ..args)

                if i >= end {
                    _, _ = string_builder.write_string(b.writer, "%!(NO VERB)", &b.n)
                    break loop
                } else if fmt[i] == '}' {
                    i += 1
                    _, _ = string_builder.write_string(b.writer, "%!(NO VERB)", &b.n)
                    continue
                }

                w: uint = 1
                verb, w = utf8.rune_from_string(fmt[i:])
                i += w
            }

            if i >= end {
                _, _ = string_builder.write_string(b.writer, "%!(MISSING CLOSE BRACE)", &b.n)
                break loop
            }

            brace, w := utf8.rune_from_string(fmt[i:])
            i += w

            switch {
            case brace != '}':
                _, _ = string_builder.write_string(b.writer, "%!(MISSING CLOSE BRACE)", &b.n)
            case index_ok:
                fmt_arg(&b, args[arg_index], verb)
                unused_args -= {arg_index}
            }
        }
    }

    if unused_args != nil {
        // Use default options when formatting extra arguments.
        extra_fi := Info { writer = b.writer, n = b.n }

        _, _ = string_builder.write_string(extra_fi.writer, "%!(EXTRA ", &extra_fi.n)
        first_printed := false
        for index in unused_args {
            if first_printed {
                _, _ = string_builder.write_string(extra_fi.writer, ", ", &extra_fi.n)
            }

            arg := args[index]
            if arg == nil {
                _, _ = string_builder.write_string(extra_fi.writer, "<nil>", &extra_fi.n)
            } else {
                fmt_arg(&extra_fi, arg, 'v')
            }
            first_printed = true
        }
        _ = string_builder.write_byte(extra_fi.writer, ')', &extra_fi.n)

        b.n = extra_fi.n
    }

    if newline {
        _ = string_builder.write_byte(w, '\n', &b.n)
    }
    if flush {
        _ = string_builder.flush(w)
    }

    return b.n
}


/* 









wprint_type :: proc(b: ^string_builder.Builder, info: ^reflect.Type_Info, flush := true) -> (n: uint, err: string_builder.Error) {
    n, err = reflect.write_type_writer(b, info)
    if flush {
        string_builder.flush(b) or_return
    }
    return n, err
}

wprint_typeid :: proc(w: string_builder.Builder, id: typeid, flush := true) -> (n: uint, err: string_builder.Error) {
    n, err = reflect.write_type_writer(w, type_info_of(id))
    if flush {
        string_builder.flush(w) or_return
    }
    return n, err
}

// Parses an integer from a given string starting at a specified offset
//
// Inputs:
// - s: The string to parse the integer from
// - offset: The position in the string to start parsing the integer
//
// Returns:
// - result: The parsed integer
// - new_offset: The position in the string after parsing the integer
// - ok: A boolean indicating if the parsing was successful
_parse_uint :: proc(s: string, offset: uint) -> (result: uint, new_offset: uint, ok: bool) {
    is_digit :: #force_inline proc(r: u8) -> bool { return '0' <= r && r <= '9' }

    new_offset = offset
    for new_offset < len(s) {
        c := s[new_offset]
        is_digit(c) or_break

        new_offset += 1

        result *= 10
        result += uint(c) - '0'
    }
    ok = new_offset > offset
    return
}

// Retrieves an integer from a list of any type at the specified index
//
// Inputs:
// - args: A list of values of any type
// - arg_index: The index to retrieve the integer from
//
// Returns:
// - int: The integer value at the specified index
// - new_arg_index: The new argument index
// - ok: A boolean indicating if the conversion to integer was successful
uint_from_arg :: proc(args: []any, arg_index: uint) -> (num: uint, new_arg_index: uint, ok: bool) {
    new_arg_index = arg_index
    ok = true
    if arg_index < len(args) {
        num, ok = reflect.as_uint(args[arg_index])
    }

    if ok {
        new_arg_index += 1
    }

    return
}

// Parses an argument number from a format string and determines if it's valid
//
// Inputs:
// - format: The format string to parse
// - offset: A pointer to the current position in the format string
// - arg_count: The total number of arguments
//
// Returns:
// - index: The parsed argument index
// - parsed: A boolean indicating if an argument number was parsed
// - ok: A boolean indicating if the parsed argument number is within arg_count
_arg_number :: proc(format: string, offset: ^uint, arg_count: uint) -> (index: uint, parsed, ok: bool) {
    parse_arg_number :: proc(format: string) -> (uint, uint, bool) {
        if len(format) < 3 {
            return 0, 1, false
        }

        for i in 1..<len(format) {
            if format[i] == ']' {
                value, new_index, ok := _parse_uint(format, 1)
                if !ok || new_index != i {
                    return 0, i+1, false
                }
                return value, i+1, true
            }
        }

        return 0, 1, false
    }

    i := offset^

    if len(format) <= i || format[i] != '[' {
        return 0, false, false
    }

    width: uint
    index, width, parsed = parse_arg_number(format[i:])
    offset^ = i + width
    ok = parsed && 0 <= index && index < arg_count
    return
}

// Writes padding characters for formatting
//
// Inputs:
// - b: A pointer to an Info structure
// - width: The number of padding characters to write
fmt_write_padding :: proc(b: ^Info, width: uint) {
    if width <= 0 {
        return
    }

    pad_byte: u8 = ' '
    if !b.space {
        pad_byte = '0'
    }

    for i: uint = 0; i < width; i += 1 {
        _ = string_builder.write_byte(b.writer, pad_byte, &b.n)
    }
}

// Formats an int128 value based on the provided formatting options.
//
// Inputs:
// - b: A pointer to the Info struct containing formatting options.
// - u: The int128 value to be formatted.
// - base: The base to be used for formatting the integer (e.g. 2, 8, 10, 12, 16).
// - is_signed: Whether the value should be treated as signed or unsigned.
// - bit_size: The number of bits of the value (e.g. 64, 128).
// - digits: A string containing the digit characters to use for the formatted integer.
//
// WARNING: Panics if the formatting options result in a buffer overrun.
_fmt_int_128 :: proc(b: ^Info, u: u128, base: uint, is_signed: bool, bit_size: uint, digits: string) {
    _, neg := strconv.is_integer_negative_128(u, is_signed, bit_size)

    BUF_SIZE :: 256
    if b.width_set || b.prec_set {
        width := b.width + b.prec + 3 // 3 extra bytes for sign and prefix
        if width > BUF_SIZE {
            // TODO(bill):????
            internal.panic("_fmt_int: buffer overrun. Width and precision too big")
        }
    }

    buf: [256]u8
    start := 0

    if b.hash && !is_signed {
        switch base {
        case 2:
            _ = string_builder.write_byte(b.writer, '0', &b.n)
            _ = string_builder.write_byte(b.writer, 'b', &b.n)
            start = 2

        case 8:
            _ = string_builder.write_byte(b.writer, '0', &b.n)
            _ = string_builder.write_byte(b.writer, 'o', &b.n)
            start = 2

        case 12:
            _ = string_builder.write_byte(b.writer, '0', &b.n)
            _ = string_builder.write_byte(b.writer, 'o', &b.n)
            start = 2

        case 16:
            _ = string_builder.write_byte(b.writer, '0', &b.n)
            _ = string_builder.write_byte(b.writer, 'x', &b.n)
            start = 2
        }
    }

    prec: uint
    if b.prec_set {
        prec = b.prec
        if prec == 0 && u == 0 {
            fmt_write_padding(b, b.width)
            return
        }
    } else if b.zero && b.width_set {
        prec = b.width
        if neg || b.plus {
            // There needs to be space for the "sign"
            prec -= 1
        }
    }

    switch base {
    case 2, 8, 10, 12, 16:
        break
    case:
        internal.panic("_fmt_int: unknown base, whoops")
    }

    flags: strconv.Int_Flags
    if b.hash && !b.zero && start == 0 { flags += {.Prefix} }
    if b.plus                           { flags += {.Plus}   }
    s := strconv.write_bits_128(buf[start:], u, base, is_signed, bit_size, digits, flags)

    if b.hash && b.zero && b.indent == 0 {
        c: u8 = 0
        switch base {
        case 2:  c = 'b'
        case 8:  c = 'o'
        case 12: c = 'z'
        case 16: c = 'x'
        }
        if c != 0 {
            _ = string_builder.write_byte(b.writer, '0', &b.n)
            _ = string_builder.write_byte(b.writer, c, &b.n)
        }
    }

    prev_zero := b.zero
    defer b.zero = prev_zero
    b.zero = false
    _pad(b, s)
}

// Units of measurements:
@(rodata) __MEMORY_LOWER := " b kib mib gib tib pib eib"
@(rodata) __MEMORY_UPPER := " B KiB MiB GiB TiB PiB EiB"
// Formats an integer value as bytes with the best representation.
//
// Inputs:
// - b: A pointer to an Info structure
// - u: The integer value to format
// - is_signed: A boolean indicating if the integer is signed
// - bit_size: The bit size of the integer
// - digits: A string containing the digits for formatting
_fmt_memory :: proc(b: ^Info, u: u64, is_signed: bool, bit_size: uint, units: string) {
    abs, neg := strconv.is_integer_negative(u, is_signed, bit_size)

    // Default to a precision of 2, but if less than a kb, 0
    prec := b.prec if (b.prec_set || abs < mem.Kilobyte) else 2

    div := 1
    off: uint = 0
    unit_len: uint = 1
    for n := abs; n >= mem.Kilobyte; n /= mem.Kilobyte {
        div *= mem.Kilobyte
        off += 4

        // First iteration is slightly different because you go from
        // units of length 1 to units of length 2.
        if unit_len == 1 {
            off = 2
            unit_len  = 3
        }
    }

    // If hash, we add a space between the value and the suffix.
    if b.hash {
        unit_len += 1
    } else {
        off += 1
    }

    amt := f64(abs) / f64(div)
    if neg {
        amt = -amt
    }

    buf: [256]u8
    str := strconv.write_float(buf[:], amt, 'f', prec, 64, false)

    // Add the unit at the end.
    slice.copy_from_string(buf[len(str):], units[off:off+unit_len])
    str = string(buf[:len(str) + unit_len])

    if !b.plus {
        // Strip sign from "+<value>" but not "+Inf".
        if str[0] == '+' && str[1] != 'I' {
            str = str[1:]
        }
    }

    _pad(b, str)
}


// Formats a rune value according to the specified formatting verb.
//
// Inputs:
// - b: A pointer to the Info struct containing formatting options.
// - r: The rune value to be formatted.
// - verb: The formatting verb to use (e.g. 'c', 'r', 'v', 'q').
fmt_rune :: proc(b: ^Info, r: rune, verb: rune) {
    switch verb {
    case 'c', 'r', 'v':
        _, _ = string_builder.write_rune(b.writer, r, &b.n)
    case 'q', 'w':
        b.n += string_builder.write_quoted_rune(b.writer, r)
    case:
        fmt_int(b, u64(u32(r)), false, 32, verb)
    }
}

// Formats an integer value according to the specified formatting verb.
//
// Inputs:
// - b: A pointer to the Info struct containing formatting options.
// - u: The integer value to be formatted.
// - is_signed: Whether the value should be treated as signed or unsigned.
// - bit_size: The number of bits of the value (e.g. 32, 64).
// - verb: The formatting verb to use (e.g. 'v', 'b', 'o', 'i', 'd', 'z', 'x', 'X', 'c', 'r', 'U').
fmt_int :: proc(b: ^Info, u: u64, is_signed: bool, bit_size: uint, verb: rune) {
    switch verb {
    case 'v', 'w':
        _fmt_int(b, u, 10, is_signed, bit_size, __DIGITS_LOWER)
    case 'b': _fmt_int(b, u,  2, is_signed, bit_size, __DIGITS_LOWER)
    case 'o': _fmt_int(b, u,  8, is_signed, bit_size, __DIGITS_LOWER)
    case 'i', 'd': _fmt_int(b, u, 10, is_signed, bit_size, __DIGITS_LOWER)
    case 'z': _fmt_int(b, u, 12, is_signed, bit_size, __DIGITS_LOWER)
    case 'x': _fmt_int(b, u, 16, is_signed, bit_size, __DIGITS_LOWER)
    case 'X': _fmt_int(b, u, 16, is_signed, bit_size, __DIGITS_UPPER)
    case 'c', 'r':
        fmt_rune(b, rune(u), verb)
    case 'U':
        r := rune(u)
        if r < 0 || r > utf8.MAX_RUNE {
            fmt_bad_verb(b, verb)
        } else {
            _, _ = string_builder.write_string(b.writer, "U+", &b.n)
            _fmt_int(b, u, 16, false, bit_size, __DIGITS_UPPER)
        }
    case 'm': _fmt_memory(b, u, is_signed, bit_size, __MEMORY_LOWER)
    case 'M': _fmt_memory(b, u, is_signed, bit_size, __MEMORY_UPPER)

    case:
        fmt_bad_verb(b, verb)
    }
}

// Formats an int128 value according to the specified formatting verb.
//
// Inputs:
// - b: A pointer to the Info struct containing formatting options.
// - u: The int128 value to be formatted.
// - is_signed: Whether the value should be treated as signed or unsigned.
// - bit_size: The number of bits of the value (e.g. 64, 128).
// - verb: The formatting verb to use (e.g. 'v', 'b', 'o', 'i', 'd', 'z', 'x', 'X', 'c', 'r', 'U').
fmt_int_128 :: proc(b: ^Info, u: u128, is_signed: bool, bit_size: uint, verb: rune) {
    switch verb {
    case 'v', 'w':
        _fmt_int_128(b, u, 10, is_signed, bit_size, __DIGITS_LOWER)
    case 'b': _fmt_int_128(b, u,  2, is_signed, bit_size, __DIGITS_LOWER)
    case 'o': _fmt_int_128(b, u,  8, is_signed, bit_size, __DIGITS_LOWER)
    case 'i', 'd': _fmt_int_128(b, u, 10, is_signed, bit_size, __DIGITS_LOWER)
    case 'z': _fmt_int_128(b, u, 12, is_signed, bit_size, __DIGITS_LOWER)
    case 'x': _fmt_int_128(b, u, 16, is_signed, bit_size, __DIGITS_LOWER)
    case 'X': _fmt_int_128(b, u, 16, is_signed, bit_size, __DIGITS_UPPER)
    case 'c', 'r':
        fmt_rune(b, rune(u), verb)
    case 'U':
        r := rune(u)
        if r < 0 || r > utf8.MAX_RUNE {
            fmt_bad_verb(b, verb)
        } else {
            _, _ = string_builder.write_string(b.writer, "U+", &b.n)
            _fmt_int_128(b, u, 16, false, bit_size, __DIGITS_UPPER)
        }

    case:
        fmt_bad_verb(b, verb)
    }
}

// Formats a floating-point number with a specific format and precision.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - v: The floating-point number to format.
// - bit_size: The size of the floating-point number in bits (16, 32, or 64).
// - verb: The format specifier character.
// - float_fmt: The u8 format used for formatting the float (either 'f' or 'e').
// - prec: precision
// NOTE: Can return "NaN", "+Inf", "-Inf", "+<value>", or "-<value>".
_fmt_float_as :: proc(b: ^Info, v: f64, bit_size: uint, verb: rune, float_fmt: u8, prec: uint, shortest: bool) {
    prec := prec
    if b.prec_set {
        prec = b.prec
    }

    buf: [386]u8

    // Can return "NaN", "+Inf", "-Inf", "+<value>", "-<value>".
    str := strconv.write_float(buf[:], v, float_fmt, prec, bit_size, shortest)

    if !b.plus {
        // Strip sign from "+<value>" but not "+Inf".
        if str[0] == '+' && str[1] != 'I' {
            str = str[1:]
        }
    }

    _pad(b, str)
}

// Formats a floating-point number with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - v: The floating-point number to format.
// - bit_size: The size of the floating-point number in bits (16, 32, or 64).
// - verb: The format specifier character.
fmt_float :: proc(b: ^Info, v: f64, bit_size: uint, verb: rune) {
    switch verb {
    case 'g', 'G', 'v', 'w':
        _fmt_float_as(b, v, bit_size, verb, 'g', 0, true)
    case 'f', 'F':
        _fmt_float_as(b, v, bit_size, verb, 'f', 3, false)
    case 'e':
        // BUG(): "%.3e" returns "3.000e+00"
        _fmt_float_as(b, v, bit_size, verb, 'e', 6, false)
    case 'E':
        // BUG(): "%.3E" returns "3.000E+00"
        _fmt_float_as(b, v, bit_size, verb, 'E', 6, false)

    case 'h', 'H':
        prev_fi := b^
        defer b^ = prev_fi
        b.hash = false
        b.width = bit_size
        b.zero = true
        b.plus = false

        u: u64
        switch bit_size {
        case 16: u = u64(transmute(u16)f16(v))
        case 32: u = u64(transmute(u32)f32(v))
        case 64: u = transmute(u64)v
        case: internal.panic("Unhandled float size")
        }

        _, _ = string_builder.write_string(b.writer, "0h", &b.n)
        _fmt_int(b, u, 16, false, bit_size, __DIGITS_LOWER if verb == 'h' else __DIGITS_UPPER)


    case:
        fmt_bad_verb(b, verb)
    }
}

// Formats a string with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - s: The string to format.
// - verb: The format specifier character (e.g. 's', 'v', 'q', 'x', 'X').
fmt_string :: proc(b: ^Info, s: string, verb: rune) {
    s, verb := s, verb
    if ol, ok := b.optional_len.?; ok {
        s = s[:clamp(ol, 0, len(s))]
    }
    if !b.in_bad && b.record_level > 0 && verb == 'v' {
        verb = 'q'
    }

    switch verb {
    case 's', 'v':
        if b.width_set {
            if b.width > len(s) {
                if b.minus {
                    _, _ = string_builder.write_string(b.writer, s, &b.n)
                }

                for _ in 0..<b.width - len(s) {
                    _ = string_builder.write_byte(b.writer, ' ', &b.n)
                }

                if !b.minus {
                    _, _ = string_builder.write_string(b.writer, s, &b.n)
                }
            } else {
                _, _ = string_builder.write_string(b.writer, s, &b.n)
            }
        } else {
            _, _ = string_builder.write_string(b.writer, s, &b.n)
        }

    case 'q', 'w': // quoted string
        _, _ = string_builder.write_quoted_string(b.writer, s, '"', &b.n)

    case 'x', 'X':
        space := b.space
        b.space = false
        defer b.space = space

        for i in 0..<len(s) {
            if i > 0 && space {
                _ = string_builder.write_byte(b.writer, ' ', &b.n)
            }
            char_set := __DIGITS_UPPER
            if verb == 'x' {
                char_set = __DIGITS_LOWER
            }
            _fmt_int(b, u64(s[i]), 16, false, 8, char_set)
        }

    case:
        fmt_bad_verb(b, verb)
    }
}

// Formats a C-style string with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - s: The C-style string to format.
// - verb: The format specifier character (Ref fmt_string).
fmt_cstring :: proc(b: ^Info, s: cstring, verb: rune) {
    fmt_string(b, string(s), verb)
}

// Formats a string UTF-16 with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - s: The string to format.
// - verb: The format specifier character (e.g. 's', 'v', 'q', 'x', 'X').
//
fmt_string16 :: proc(b: ^Info, s: string16, verb: rune) {
    s, verb := s, verb
    if ol, ok := b.optional_len.?; ok {
        s = s[:clamp(ol, 0, len(s))]
    }
    if !b.in_bad && b.record_level > 0 && verb == 'v' {
        verb = 'q'
    }

    switch verb {
    case 's', 'v':
        if b.width_set {
            if b.width > len(s) {
                if b.minus {
                    _, _ = string_builder.write_string16(b.writer, s, &b.n)
                }

                for _ in 0..<b.width - len(s) {
                    _ = string_builder.write_byte(b.writer, ' ', &b.n)
                }

                if !b.minus {
                    _, _ = string_builder.write_string16(b.writer, s, &b.n)
                }
            } else {
                _, _ = string_builder.write_string16(b.writer, s, &b.n)
            }
        } else {
            _, _ = string_builder.write_string16(b.writer, s, &b.n)
        }

    case 'q', 'w': // quoted string
        _, _ = string_builder.write_quoted_string16(b.writer, s, '"', &b.n)

    case 'x', 'X':
        space := b.space
        b.space = false
        defer b.space = space

        for i in 0..<len(s) {
            if i > 0 && space {
                _ = string_builder.write_byte(b.writer, ' ', &b.n)
            }
            char_set := __DIGITS_UPPER
            if verb == 'x' {
                char_set = __DIGITS_LOWER
            }
            _fmt_int(b, u64(s[i]), 16, false, bit_size=16, digits=char_set)
        }

    case:
        fmt_bad_verb(b, verb)
    }
}

// Formats a C-style UTF-16 string with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - s: The C-style string to format.
// - verb: The format specifier character (Ref fmt_string).
fmt_cstring16 :: proc(b: ^Info, s: cstring16, verb: rune) {
    fmt_string16(b, string16(s), verb)
}

// Formats a Structure of Arrays (SoA) pointer with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - p: The SoA pointer to format.
// - verb: The format specifier character.
fmt_soa_pointer :: proc(b: ^Info, p: internal.Raw_Soa_Pointer, verb: rune) {
    _, _ = string_builder.write_string(b.writer, "#soa{data=0x", &b.n)
    _fmt_int(b, u64(uintptr(p.data)), 16, false, 8*size_of(rawptr), __DIGITS_UPPER)
    _, _ = string_builder.write_string(b.writer, ", index=", &b.n)
    _fmt_int(b, u64(p.index), 10, false, 8*size_of(rawptr), __DIGITS_UPPER)
    _, _ = string_builder.write_string(b.writer, "}", &b.n)
}

// String representation of an enum value.
//
// Inputs:
// - val: The enum value.
//
// Returns: The string representation of the enum value and a boolean indicating success.
enum_value_to_string :: proc(val: any) -> (string, bool) {
    return reflect.enum_name_from_value_any(val)
}

// Returns the enum value of a string representation.
//
// $T: The typeid of the enum type.
// Inputs:
// - s: The string representation of the enum value.
//
// Returns: The enum value and a boolean indicating success.
string_to_enum_value :: proc($T: typeid, s: string) -> (T, bool) {
    ti := reflect.type_info_base(type_info_of(T))
    if e, ok := ti.variant.(reflect.Type_Info_Enum); ok {
        for str, idx in e.names {
            if s == str {
                // NOTE(bill): Unsafe cast
                ptr := cast(^T)&e.values[idx]
                return ptr^, true
            }
        }
    }
    return T{}, false
}

// Formats an enum value with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - v: The enum value to format.
// - verb: The format specifier character (e.g. 'i','d','f','s','v','q','w').
fmt_enum :: proc(b: ^Info, v: any, verb: rune) {
    if v.id == nil || v.data == nil {
        _, _ = string_builder.write_string(b.writer, "<nil>", &b.n)
        return
    }

    type_info := type_info_of(v.id)
    #partial switch &e in type_info.variant {
    case: fmt_bad_verb(b, verb)
    case reflect.Type_Info_Enum:
        switch verb {
        case: fmt_bad_verb(b, verb)
        case 'i', 'd', 'f':
            fmt_arg(b, any{v.data, reflect.type_info_base(e.base).id}, verb)
        case 's', 'v', 'q':
            if str, ok := enum_value_to_string(v); ok {
                fmt_string(b, str, verb)
            } else {
                _, _ = string_builder.write_string(b.writer, "%!(BAD ENUM VALUE=", &b.n)
                fmt_arg(b, any{v.data, reflect.type_info_base(e.base).id}, 'i')
                _, _ = string_builder.write_string(b.writer, ")", &b.n)
            }
        case 'w':
            if str, ok := enum_value_to_string(v); ok {
                _ = string_builder.write_byte(b.writer, '.', &b.n)
                _, _ = string_builder.write_string(b.writer, str, &b.n)
            } else {
                _, _ = string_builder.write_string(b.writer, "%!(BAD ENUM VALUE=", &b.n)
                fmt_arg(b, any{v.data, reflect.type_info_base(e.base).id}, 'i')
                _, _ = string_builder.write_string(b.writer, ")", &b.n)
            }
        }
    }
}

// Converts a stored enum value to a string representation
//
// Inputs:
// - enum_type: A pointer to the reflect.Type_Info of the enumeration.
// - ev: The reflect.Type_Info_Enum_Value of the stored enum value.
// - offset: An optional integer to adjust the enumeration value (default is 0).
//
// Returns: A tuple containing the string representation of the enum value and a bool indicating success.
stored_enum_value_to_string :: proc(enum_type: ^reflect.Type_Info, ev: reflect.Type_Info_Enum_Value, offset: uint = 0) -> (string, bool) {
    et := reflect.type_info_base(enum_type)
    ev := ev
    ev += reflect.Type_Info_Enum_Value(offset)
    #partial switch &e in et.variant {
    case: return "", false
    case reflect.Type_Info_Enum:
        if reflect.is_string(e.base) {
            for val, idx in e.values {
                if val == ev {
                    return e.names[idx], true
                }
            }
        } else if len(e.values) == 0 {
            return "", true
        } else {
            for val, idx in e.values {
                if val == ev {
                    return e.names[idx], true
                }
            }
        }
        return "", false
    }

    return "", false
}

// Writes the specified number of indents to the provided Info structure
//
// Inputs:
// - b: A pointer to the Info structure where the indents will be written.
fmt_write_indent :: proc(b: ^Info) {
    for _ in 0..<b.indent {
        _ = string_builder.write_byte(b.writer, '\t', &b.n)
    }
}

// Formats an array and writes it to the provided Info structure
//
// Inputs:
// - b: A pointer to the Info structure where the formatted array will be written.
// - array_data: A raw pointer to the array data.
// - count: The number of elements in the array.
// - elem_size: The size of each element in the array.
// - elem_id: The typeid of the array elements.
// - verb: The formatting verb to be used for the array elements.
fmt_write_array :: proc(b: ^Info, array_data: rawptr, count: uint, elem_size: uint, elem_id: typeid, verb: rune) {
    _ = string_builder.write_byte(b.writer, '[' if verb != 'w' else '{', &b.n)
    defer _ = string_builder.write_byte(b.writer, ']' if verb != 'w' else '}', &b.n)

    if count <= 0 {
        return
    }
    b.record_level += 1
    defer b.record_level -= 1

    if b.hash {
        _ = string_builder.write_byte(b.writer, '\n', &b.n)
        defer fmt_write_indent(b)

        indent := b.indent
        b.indent += 1
        defer b.indent = indent

        for i in 0..<count {
            fmt_write_indent(b)

            data := uintptr(array_data) + uintptr(i*elem_size)
            fmt_arg(b, any{rawptr(data), elem_id}, verb)

            _, _ = string_builder.write_string(b.writer, ",\n", &b.n)
        }
    } else {
        for i in 0..<count {
            if i > 0 { _, _ = string_builder.write_string(b.writer, ", ", &b.n) }

            data := uintptr(array_data) + uintptr(i*elem_size)
            fmt_arg(b, any{rawptr(data), elem_id}, verb)
        }
    }
}

// Handles struct tag processing for formatting
//
// Inputs:
// - data: A raw pointer to the data being processed
// - info: Type information about the struct
// - idx: The index of the tag in the struct
// - verb: A mutable pointer to the rune representing the format verb
// - optional_len: A mutable pointer to an integer holding the optional length (if applicable)
// - use_nul_termination: A mutable pointer to a boolean flag indicating if NUL termination is used
//
// Returns: A boolean value indicating whether to continue processing the tag
@(private)
handle_tag :: proc(state: ^Info_State, data: rawptr, info: reflect.Type_Info_Struct, idx: uint, verb: ^rune, optional_len: ^int, use_nul_termination: ^bool) -> (do_continue: bool) {
    handle_optional_len :: proc(data: rawptr, info: reflect.Type_Info_Struct, field_name: string, optional_len: ^int) {
        if optional_len == nil {
            return
        }
        for f, i in info.names[:info.field_count] {
            if f != field_name {
                continue
            }
            ptr := rawptr(uintptr(data) + info.offsets[i])
            field := any{ptr, info.types[i].id}
            if new_len, iok := reflect.as_int(field); iok {
                optional_len^ = max(new_len, 0)
            }
            break
        }
    }

    tag := info.tags[idx]
    if vt, ok := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "fmt"); ok {
        value := strings_tools.trim_space(string(vt))
        switch value {
        case "":  return false
        case "-": return true
        }

        b := state

        head, _, tail := strings_tools.partition(value, ",")

        i: uint
        prefix_loop: for ; i < len(head); i += 1 {
            switch head[i] {
            case '+':
                b.plus = true
            case '-':
                b.minus = true
                b.zero = false
            case ' ':
                b.space = true
            case '#':
                b.hash = true
            case '0':
                b.zero = !b.minus
            case:
                break prefix_loop
            }
        }

        b.width, i, b.width_set = _parse_uint(head, i)
        if i < len(head) && head[i] == '.' {
            i += 1
            prev_i := i
            b.prec, i, b.prec_set = _parse_uint(head, i)
            if i == prev_i {
                b.prec = 0
                b.prec_set = true
            }
        }

        r: rune
        if i >= len(head) || head[i] == ' ' {
            r = 'v'
        } else {
            r, _ = utf8.rune_from_string(head[i:])
        }
        if verb^ == 'w' {
            // TODO(bill): is this a good idea overriding that field tags if 'w' is used?
            switch r {
            case 's': r = 'q'
            case:     r = 'w'
            }
        }
        verb^ = r
        if tail != "" {
            field_name := tail
            if field_name == "0" {
                if use_nul_termination != nil {
                    use_nul_termination^ = true
                }
            } else {
                switch r {
                case 's', 'q':
                    handle_optional_len(data, info, field_name, optional_len)
                case 'v', 'w':
                    #partial switch reflect.type_kind(info.types[idx].id) {
                    case .String, .Multi_Pointer, .Array, .Slice, .Dynamic_Array:
                        handle_optional_len(data, info, field_name, optional_len)
                    }
                }
            }
        }
    }
    return
}


_handle_raw_union_tag :: proc(b: ^Info, v: any, the_verb: rune, info: reflect.Type_Info_Struct, type_name: string) -> (ok: bool) {
    ut := type_info_of(v.id)

    if !reflect.is_raw_union(ut) {
        return false
    }

    tag_name: string
    for tag in info.tags[:info.field_count] {
        rut := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "raw_union_tag") or_continue
        head_tag, match, _ := strings_tools.partition(string(rut), "=")
        if match != "=" {
            continue
        }
        if tag_name == "" {
            tag_name = head_tag
        } else if tag_name != head_tag {
            return false
        }
    }
    if tag_name == "" {
        return false
    }

    tag := reflect.struct_field_value_by_name(b.state.parent_struct, tag_name, true)
    if tag == nil {
        // try the current type just in case the tag is also stored here
        tag = reflect.struct_field_value_by_name(v, tag_name, false)
    }
    if tag == nil {
        return false
    }


    tag_info := reflect.type_info_base(type_info_of(tag.id))
    #partial switch ti in tag_info.variant {
    case reflect.Type_Info_Enum:
        tag_string := reflect.enum_string(tag)

        for tag, index in info.tags[:info.field_count] {
            rut_list := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "raw_union_tag") or_continue

            for rut in strings_tools.split_iterator(&rut_list, ",") {
                head_tag, match, tail_name := strings_tools.partition(string(rut), "=")
                if head_tag != tag_name || match != "=" {
                    continue
                }

                // just ignore the `A.` prefix for `A.B` stuff entirely
                if _, _, try_tail_name := strings_tools.partition(string(rut), "."); try_tail_name != "" {
                    tail_name = try_tail_name
                }

                if tail_name == tag_string {
                    _, _ = string_builder.write_string(b.writer, "#raw_union(.", &b.n)
                    _, _ = string_builder.write_string(b.writer, tag_string, &b.n)
                    _, _ = string_builder.write_string(b.writer, ") ", &b.n)
                    fmt_arg(b, any{v.data, info.types[index].id}, the_verb)
                    return true
                }
            }
        }
    case reflect.Type_Info_Integer:
        tag_value := reflect.as_i64(tag) or_break

        for tag, index in info.tags[:info.field_count] {
            rut_list := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "raw_union_tag") or_continue

            for rut in strings_tools.split_iterator(&rut_list, ",") {
                head_tag, match, tail_name := strings_tools.partition(string(rut), "=")
                if head_tag != tag_name || match != "=" {
                    continue
                }

                // just ignore the `A.` prefix for `A.B` stuff entirely
                if _, _, try_tail_name := strings_tools.partition(string(rut), "."); try_tail_name != "" {
                    tail_name = try_tail_name
                }

                tail_value := strconv.parse_i64_maybe_prefixed(tail_name) or_continue

                if tail_value == tag_value {
                    _, _ = string_builder.write_string(b.writer, "#raw_union(.", &b.n)
                    _, _ = string_builder.write_i64(b.writer, tag_value, 10, &b.n)
                    _, _ = string_builder.write_string(b.writer, ") ", &b.n)
                    fmt_arg(b, any{v.data, info.types[index].id}, the_verb)
                    return true
                }
            }
        }

    case reflect.Type_Info_Boolean:
        tag_value := reflect.as_bool(tag) or_break

        for tag, index in info.tags[:info.field_count] {
            rut_list := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "raw_union_tag") or_continue

            for rut in strings_tools.split_iterator(&rut_list, ",") {
                head_tag, match, tail_name := strings_tools.partition(string(rut), "=")
                if head_tag != tag_name || match != "=" {
                    continue
                }

                // just ignore the `A.` prefix for `A.B` stuff entirely
                if _, _, try_tail_name := strings_tools.partition(string(rut), "."); try_tail_name != "" {
                    tail_name = try_tail_name
                }

                tail_value := strconv.parse_bool(tail_name) or_continue

                if tail_value == tag_value {
                    _, _ = string_builder.write_string(b.writer, "#raw_union(.", &b.n)
                    _, _ = string_builder.write_string(b.writer, "true" if tag_value else "false", &b.n)
                    _, _ = string_builder.write_string(b.writer, ") ", &b.n)
                    fmt_arg(b, any{v.data, info.types[index].id}, the_verb)
                    return true
                }
            }
        }
    }

    return false
}

// Searches for the first NUL-terminated element in a given buffer
//
// Inputs:
// - ptr: The raw pointer to the buffer.
// - elem_size: The size of each element in the buffer.
// - max_n: The maximum number of elements to search (use -1 for no limit).
//
// Returns: The number of elements before the first NUL-terminated element.
@(private)
search_nul_termination :: proc(ptr: rawptr, elem_size: uint, max_n: int) -> (n: uint) {
    for p := uintptr(ptr); max_n < 0 || int(n) < max_n; p += uintptr(elem_size) {
        if mem.is_zero_ptr(rawptr(p), elem_size) {
            break
        }
        n += 1
    }
    return n
}

@(private)
fmt_named_buitlin_custom_formatters :: proc(b: ^Info, v: any, verb: rune, info: reflect.Type_Info_Named) -> bool {
    switch a in v {
    case internal.Source_Code_Location:
        _, _ = string_builder.write_string(b.writer, a.file_path, &b.n)

        when ODIN_ERROR_POS_STYLE == .Default {
            _ = string_builder.write_byte(b.writer, '(', &b.n)
            _, _ = string_builder.write_int(b.writer, int(a.line), 10, &b.n)
            if a.column != 0 {
                _ = string_builder.write_byte(b.writer, ':', &b.n)
                _, _ = string_builder.write_int(b.writer, int(a.column), 10, &b.n)
            }
            _ = string_builder.write_byte(b.writer, ')', &b.n)
        } else when ODIN_ERROR_POS_STYLE == .Unix {
            _ = string_builder.write_byte(b.writer, ':', &b.n)
            _, _ = string_builder.write_int(b.writer, int(a.line), 10, &b.n)
            if a.column != 0 {
                _ = string_builder.write_byte(b.writer, ':', &b.n)
                _, _ = string_builder.write_int(b.writer, int(a.column), 10, &b.n)
            }
            _ = string_builder.write_byte(b.writer, ':', &b.n)
        } else {
            #panic("Unhandled ODIN_ERROR_POS_STYLE")
        }
        return true

    case time.Duration:
        ffrac :: proc(buf: []u8, v: u64, prec: uint) -> (nw: int, nv: u64) {
            v := v
            w := int(len(buf))
            print := false
            for _ in 0..<prec {
                digit := v % 10
                print = print || digit != 0
                if print {
                    w -= 1
                    buf[w] = u8(digit) + '0'
                }
                v /= 10
            }
            if print {
                w -= 1
                buf[w] = '.'
            }
            return w, v
        }
        fint :: proc(buf: []u8, v: u64) -> int {
            v := v
            w := int(len(buf))
            if v == 0 {
                w -= 1
                buf[w] = '0'
            } else {
                for v > 0 {
                    w -= 1
                    buf[w] = u8(v%10) + '0'
                    v /= 10
                }
            }
            return w
        }

        buf: [32]u8
        w := len(buf)
        u := u64(a)
        neg := a < 0
        if neg {
            u = -u
        }

        if u < u64(time.Second) {
            prec: uint
            w -= 1
            buf[w] = 's'
            w -= 1
            switch {
            case u == 0:
                _, _ = string_builder.write_string(b.writer, "0s", &b.n)
                return true
            case u < u64(time.Microsecond):
                prec = 0
                buf[w] = 'n'
            case u < u64(time.Millisecond):
                prec = 3
                // U+00B5 'µ' micro sign == 0xC2 0xB5
                w -= 1 // Need room for two bytes
                    slice.copy_from_string(buf[w:], "µ")
            case:
                prec = 6
                buf[w] = 'm'
            }
            w, u = ffrac(buf[:w], u, prec)
            w = fint(buf[:w], u)
        } else {
            w -= 1
            buf[w] = 's'
            w, u = ffrac(buf[:w], u, 9)
            w = fint(buf[:w], u%60)
            u /= 60
            if u > 0 {
                w -= 1
                buf[w] = 'm'
                w = fint(buf[:w], u%60)
                u /= 60
                if u > 0 {
                    w -= 1
                    buf[w] = 'h'
                    w = fint(buf[:w], u)
                }
            }
        }

        if neg {
            w -= 1
            buf[w] = '-'
        }
        _, _ = string_builder.write_string(b.writer, string(buf[w:]), &b.n)
        return true

    case time.Time:
        write_padded_number :: proc(b: ^Info, i: i64, width: uint) {
            n := width-1
            for x := i; x >= 10; x /= 10 {
                n -= 1
            }
            for _ in 0..<n {
                _ = string_builder.write_byte(b.writer, '0', &b.n)
            }
            _, _ = string_builder.write_i64(b.writer, i, 10, &b.n)
        }


        t := a
        y, mon, d := time.date(t)
            h, min, s := time.clock_from_time(t)
        ns := (t._nsec - (t._nsec/1e9 + time.UNIX_TO_ABSOLUTE)*1e9) % 1e9
        write_padded_number(b, i64(y), 4)
        _ = string_builder.write_byte(b.writer, '-', &b.n)
        write_padded_number(b, i64(mon), 2)
        _ = string_builder.write_byte(b.writer, '-', &b.n)
        write_padded_number(b, i64(d), 2)
        _ = string_builder.write_byte(b.writer, ' ', &b.n)

        write_padded_number(b, i64(h), 2)
        _ = string_builder.write_byte(b.writer, ':', &b.n)
        write_padded_number(b, i64(min), 2)
        _ = string_builder.write_byte(b.writer, ':', &b.n)
        write_padded_number(b, i64(s), 2)
        _ = string_builder.write_byte(b.writer, '.', &b.n)
        write_padded_number(b, i64(ns), 9)
        _, _ = string_builder.write_string(b.writer, " +0000 UTC", &b.n)
        return true
    }

    return false
}

// This proc helps keep some of the code around whether or not to print an
// intermediate plus sign in complexes and quaternions more readable.
@(private)
_cq_should_print_intermediate_plus :: proc(b: ^Info, f: f64) -> bool {
    if !b.plus && f >= 0 {
        #partial switch math.classify_f64(f) {
        case .Neg_Zero, .Inf:
            // These two classes print their own signs.
            return false
        case:
            return true
        }
    }
    return false
}

*/

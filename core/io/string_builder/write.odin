
import "base:container/dyn_array"
import "base:strconv"

import "core:io"


@(private)
_builder_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    b := (^Builder)(stream_data)
    #partial switch mode {
    case .Write:
        n = i64(write_bytes(b, p, loc))
        if n < i64(len(p)) {
            err = .EOF
        }
        return
    case .Size:
        n = i64(len(b.buf))
        return
    case .Destroy:
        builder_destroy(b)
        return
    case .Query:
        return io.query_utility({.Write, .Size, .Destroy, .Query})
    }
    return 0, .Unsupported
}


to_stream :: proc(b: ^Builder) -> (res: io.Stream) {
    return io.Stream{procedure=_builder_stream_proc, data=b}
}

to_writer :: proc(b: ^Builder) -> (res: io.Writer) {
    res, _ = io.to_writer(to_stream(b))
    return 
}


/*
Example:
    builder := strings_tools.builder_create()
    strings_tools.write_byte(&builder, 'a')        // 1
    strings_tools.write_byte(&builder, 'b')        // 1
    fmt.println(strings_tools.to_string(builder))  // -> ab
Output:
    ab
*/
@(optional_results)
write_byte :: proc(b: ^Builder, x: byte, loc := #caller_location) -> (n: uint) {
    n0 := len(b.buf)
    _ = dyn_array.append(&b.buf, x, loc)
    n1 := len(b.buf)
    return n1-n0
}

/*
Example:
    builder := strings_tools.builder_create()
    bytes := [?]byte { 'a', 'b', 'c' }
    strings_tools.write_bytes(&builder, bytes[:]) // 3
    fmt.println(strings_tools.to_string(builder)) // -> abc
*/
@(optional_results)
write_bytes :: proc(b: ^Builder, x: []byte, loc := #caller_location) -> (n: uint) {
    n0 := len(b.buf)
    _ = dyn_array.append_many(&b.buf, ..x, loc=loc)
    n1 := len(b.buf)
    return n1-n0
}

/*
Appends a single rune to the Builder and returns the number of bytes written and an `io.Error`
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
write_rune :: proc(b: ^Builder, r: rune, loc := #caller_location) -> (res: uint, err: io.Error) {
    return io.write_rune(to_writer(b), r, loc=loc)
}

/*
Example:
    builder := strings_tools.builder_create()
    strings_tools.write_string(&builder, "abc")      // 3
    strings.write_quoted_rune(&builder, 'ä') // 4
    strings_tools.write_string(&builder, "abc")      // 3
    fmt.println(strings_tools.to_string(builder))    // -> abc'ä'abc
Output:
    abc'ä'abc
*/
@(optional_results)
write_quoted_rune :: proc(b: ^Builder, r: rune) -> (n: uint) {
    return io.write_quoted_rune(to_writer(b), r)
}

/*
Example:
    builder := strings_tools.builder_create()
    strings_tools.write_string(&builder, "a")     // 1
    strings_tools.write_string(&builder, "bc")    // 2
    fmt.println(strings_tools.to_string(builder)) // -> abc
Output:
    abc
*/
@(optional_results)
write_string :: proc(b: ^Builder, s: string, loc := #caller_location) -> (n: uint) {
    n0 := len(b.buf)
    _ = dyn_array.append_string(&b.buf, s, loc)
    n1 := len(b.buf)
    return n1-n0
}

/*
Inputs:
- b: A pointer to the Builder
- str: The string to be quoted and appended
- quote: The optional quote character (default is double quotes)
Example:
    builder := strings_tools.builder_create()
    strings.write_quoted_string(&builder, "a")        // 3
    strings.write_quoted_string(&builder, "bc", '\'') // 4
    strings.write_quoted_string(&builder, "xyz")      // 5
    fmt.println(strings_tools.to_string(builder))
Output:
    "a"'bc'"xyz"
*/
@(optional_results)
write_quoted_string :: proc(b: ^Builder, str: string, quote: byte = '"') -> (n: uint) {
    n, _ = io.write_quoted_string(to_writer(b), str, quote)
    return
}

/*
Appends a rune to the Builder and returns the number of bytes written
Inputs:
- b: A pointer to the Builder
- r: The rune to be appended
- write_quote: Optional boolean flag to wrap in single-quotes (') (default is true)
Example:
    builder := strings_tools.builder_create()
    _, _ = strings.write_encoded_rune(&builder, 'a', false) // 1
    _, _ = strings.write_encoded_rune(&builder, '\"', true) // 3
    _, _ = strings.write_encoded_rune(&builder, 'x', false) // 1
    fmt.println(strings_tools.to_string(builder))
Output:
    a'"'x
*/
@(optional_results)
write_encoded_rune :: proc(b: ^Builder, r: rune, write_quote := true) -> (n: uint) {
    n, _ = io.write_encoded_rune(to_writer(b), r, write_quote)
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
write_escaped_rune :: proc(b: ^Builder, r: rune, quote: byte, html_safe := false) -> (n: uint) {
    n, _ = io.write_escaped_rune(to_writer(b), r, quote, html_safe)
    return
}

@(optional_results)
write_float :: proc(b: ^Builder, f: f64, fmt: byte, prec, bit_size: uint, always_signed := false) -> (n: uint) {
    buf: [384]byte
    s := strconv.write_float(buf[:], f, fmt, prec, bit_size)
    // If the result starts with a `+` then unless we always want signed results,
    // we skip it unless it's followed by an `I` (because of +Inf).
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

@(optional_results)
write_f16 :: proc(b: ^Builder, f: f16, fmt: byte, always_signed := false) -> (n: uint) {
    buf: [384]byte
    s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

/*
Example:
    builder := strings_tools.builder_create()
    strings.write_f32(&builder, 3.14159, 'f') // 6
    strings_tools.write_string(&builder, " - ")     // 3
    strings.write_f32(&builder, -0.123, 'e')  // 8
    fmt.println(strings_tools.to_string(builder))   // -> 3.14159012 - -1.23000003e-01
Output:
    3.14159012 - -1.23000003e-01
*/
@(optional_results)
write_f32 :: proc(b: ^Builder, f: f32, fmt: byte, always_signed := false) -> (n: uint) {
    buf: [384]byte
    s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

@(optional_results)
write_f64 :: proc(b: ^Builder, f: f64, fmt: byte, always_signed := false) -> (n: uint) {
    buf: [384]byte
    s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
    if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
        s = s[1:]
    }
    return write_string(b, s)
}

@(optional_results)
write_u64 :: proc(b: ^Builder, i: u64, base: uint = 10) -> (n: uint) {
    buf: [32]byte
    s := strconv.write_bits(buf[:], i, base, false, 64, strconv.digits, nil)
    return write_string(b, s)
}

@(optional_results)
write_i64 :: proc(b: ^Builder, i: i64, base: uint = 10) -> (n: uint) {
    buf: [32]byte
    s := strconv.write_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
    return write_string(b, s)
}

@(optional_results)
write_uint :: proc(b: ^Builder, i: uint, base: uint = 10) -> (n: uint) {
    return write_u64(b, u64(i), base)
}

@(optional_results)
write_int :: proc(b: ^Builder, i: int, base: uint = 10) -> (n: uint) {
    return write_i64(b, i64(i), base)
}




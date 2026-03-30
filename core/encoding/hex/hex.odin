// Encoding and decoding of hex-encoded binary, e.g. `0x23` -> `#`.


import "base:internal"
import "base:mem"
import "base:container/strings"
import "base:container/slice"

import "core:io"

/*
Encodes a u8 slice into a lowercase hex sequence

*Allocates Using Provided Allocator*

Inputs:
- src: The `[]u8` to be hex-encoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: The hex-encoded result
- err: An optional allocator error if one occured, `.None` otherwise
*/
encode :: proc(src: []u8, allocator: mem.Allocator, loc := #caller_location) -> (res: []u8, err: mem.Allocator_Error) {
    res, err = slice.create(u8, len(src) * 2, allocator, loc)
    i: uint
    j: uint
    #no_bounds_check for ; i < len(src); i += 1 {
        v := src[i]
        res[j]   = LOWER[v>>4]
        res[j+1] = LOWER[v&0x0f]
        j += 2
    }
    return
}

/*
Encodes a u8 slice as a lowercase hex sequence into an `io.Writer`

Inputs:
- dst: The `io.Writer` to encode into
- src: The `[]u8` to be hex-encoded

Returns:
- err: An `io.Error` if one occured, `.None` otherwise
*/
encode_into_writer :: proc(dst: io.Writer, src: []u8) -> (err: io.Error) {
    for v in src {
        _ = io.write(dst, {LOWER[v>>4], LOWER[v&0x0f]}) or_return
    }
    return
}

/*
Encodes a u8 slice into an uppercase hex sequence

*Allocates Using Provided Allocator*

Inputs:
- src: The `[]u8` to be hex-encoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: The hex-encoded result
- err: An optional allocator error if one occured, `.None` otherwise
*/
encode_upper :: proc(src: []u8, allocator: mem.Allocator, loc := #caller_location) -> (res: []u8, err: mem.Allocator_Error) {
    res, err = slice.create(u8, len(src) * 2, allocator, loc)
    i: uint
    j: uint
    #no_bounds_check for ; i < len(src); i += 1 {
        v := src[i]
        res[j]   = UPPER[v>>4]
        res[j+1] = UPPER[v&0x0f]
        j += 2
    }
    return
}

/*
Encodes a u8 slice as an uppercase hex sequence into an `io.Writer`

Inputs:
- dst: The `io.Writer` to encode into
- src: The `[]u8` to be hex-encoded

Returns:
- err: An `io.Error` if one occured, `.None` otherwise
*/
encode_upper_into_writer :: proc(dst: io.Writer, src: []u8) -> (err: io.Error) {
    for v in src {
        _ = io.write(dst, {UPPER[v>>4], UPPER[v&0x0f]}) or_return
    }
    return
}

/*
Decodes a hex sequence into a u8 slice

*Allocates Using Provided Allocator*

Inputs:
- dst: The hex sequence decoded into bytes
- src: The `[]u8` to be hex-decoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- ok:  A bool, `true` if decoding succeeded, `false` otherwise
*/
decode :: proc(src: []u8, allocator: mem.Allocator, loc := #caller_location) -> (dst: []u8, ok: bool) {
    if len(src) % 2 == 1 {
        return
    }

    dst, _ = slice.create(u8, len(src) / 2, allocator, loc)
    i: uint
    j: uint = 1
    #no_bounds_check for ; j < len(src); j += 2 {
        p := src[j-1]
        q := src[j]

        a := hex_digit(p) or_return
        b := hex_digit(q) or_return

        dst[i] = (a << 4) | b
        i += 1
    }

    return dst, true
}

/*
Decodes the first u8 in a hex sequence to a u8

Inputs:
- str: A hex-encoded `string`, e.g. `"0x23"`

Returns:
- res: The decoded u8, e.g. `'#'`
- ok:  A bool, `true` if decoding succeeded, `false` otherwise
*/
decode_sequence :: proc(str: string) -> (res: u8, ok: bool) {
    str := str
    if strings.string_has_prefix(str, "0x") || strings.string_has_prefix(str, "0X") {
        str = str[2:]
    }

    if len(str) != 2 {
        return 0, false
    }

    upper := hex_digit(str[0]) or_return
    lower := hex_digit(str[1]) or_return

    return upper << 4 | lower, true
}

@(private)
LOWER := [16]u8 {
    '0', '1', '2', '3',
    '4', '5', '6', '7',
    '8', '9', 'a', 'b',
    'c', 'd', 'e', 'f',
}

@(private)
UPPER := [16]u8 {
    '0', '1', '2', '3',
    '4', '5', '6', '7',
    '8', '9', 'A', 'B',
    'C', 'D', 'E', 'F',
}

@(private)
hex_digit :: proc(char: u8) -> (u8, bool) {
    switch char {
    case '0' ..= '9': return char - '0', true
    case 'a' ..= 'f': return char - 'a' + 10, true
    case 'A' ..= 'F': return char - 'A' + 10, true
    case:             return 0, false
    }
}

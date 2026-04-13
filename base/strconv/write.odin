import "base:container/slice"

/*
Writes a boolean value as a string to the given buffer

**Inputs**
- buf: The buffer to write the boolean value to
- b: The boolean value to be written

Example:

    import "core:fmt"
    write_bool_example :: proc() {
        buf: [6]u8
        result := strconv.write_bool(buf[:], true)
        fmt.println(result, buf)
    }

Output:

    true [116, 114, 117, 101, 0, 0]

**Returns**
- The resulting string after writing the boolean value
*/
write_bool :: proc(buf: []u8, b: bool) -> string {
    n: uint
    if b {
        n = slice.copy_from_string(buf, "true")
    } else {
        n = slice.copy_from_string(buf, "false")
    }
    return string(buf[:n])
}

/*
Writes an unsigned integer value as a string to the given buffer with the specified base

**Inputs**
- buf: The buffer to write the unsigned integer value to
- u: The unsigned integer value to be written
- base: The base to use for converting the integer value

Example:

    import "core:fmt"
    write_uint_example :: proc() {
        buf: [4]u8
        result := strconv.write_uint(buf[:], 42, 16)
        fmt.println(result, buf)
    }

Output:

    2a [50, 97, 0, 0]

**Returns**
- The resulting string after writing the unsigned integer value
*/
write_uint :: proc(buf: []u8, u: u64, base: uint) -> string {
    return write_bits(buf, u, base, false, 8*size_of(uint), digits, nil)
}

/*
Writes a signed integer value as a string to the given buffer with the specified base

**Inputs**
- buf: The buffer to write the signed integer value to
- i: The signed integer value to be written
- base: The base to use for converting the integer value

Example:

    import "core:fmt"
    write_int_example :: proc() {
        buf: [4]u8
        result := strconv.write_int(buf[:], -42, 10)
        fmt.println(result, buf)
    }

Output:

    -42 [45, 52, 50, 0]

**Returns**
- The resulting string after writing the signed integer value
*/
write_int :: proc(buf: []u8, i: i64, base: uint) -> string {
    return write_bits(buf, u64(i), base, true, 8*size_of(int), digits, nil)
}

write_u128 :: proc(buf: []u8, u: u128, base: uint) -> string {
    return write_bits_128(buf, u, base, false, 8*size_of(uint), digits, nil)
}

/*
`ftoa` C name deprecated, use `write_float` instead (same procedure)

Writes a float64 value as a string to the given buffer with the specified format and precision

**Inputs**
- buf: The buffer to write the float64 value to
- f: The float64 value to be written
- fmt: The u8 specifying the format to use for the conversion
- prec: The precision to use for the conversion
- bit_size: The size of the float in bits (32 or 64)

Example:

    import "core:fmt"
    write_float_example :: proc() {
        buf: [8]u8
        result := strconv.write_float(buf[:], 3.14159, 'f', 2, 64)
        fmt.println(result, buf)
    }

Output:

    +3.14 [43, 51, 46, 49, 52, 0, 0, 0]

**Returns**
- The resulting string after writing the float
*/
write_float :: proc(buf: []u8, f: f64, fmt: u8, prec, bit_size: uint, shortest: bool) -> string {
    return string(generic_ftoa(buf, f, fmt, prec, bit_size, shortest))
}

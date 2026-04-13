import "base:internal"
import "base:container/slice"

Int_Flag :: enum {
    Prefix,
    Plus,
}
Int_Flags :: bit_set[Int_Flag]


/*
Writes a boolean value as a string to the given buffer

**Inputs**
- buf: The buffer to write the boolean value to
- b: The boolean value to be written

Example:

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


/*
Writes the string representation of an integer to a buffer with specified base, flags, and digit set.

**Inputs**
- buf: The buffer to dyn_array.append the integer representation to
- x: The integer value to convert
- base: The base for the integer representation (2 <= base <= MAX_BASE)
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, or 64)
- digits: The digit set used for the integer representation
- flags: The Int_Flags bit set to control integer formatting

**Returns**
- The string containing the integer representation appended to the buffer
*/
write_bits :: proc(buf: []u8, x: u64, base: uint, is_signed: bool, bit_size: uint, digits: string, flags: Int_Flags) -> string {
    if base < 2 || base > MAX_BASE {
        internal.panic("strconv: illegal base passed to write_bits")
    }

    a: [129]u8
    i := len(a)
    u, neg := is_integer_negative(x, is_signed, bit_size)
    b := u64(base)
    for u >= b {
        i-=1; a[i] = digits[u % b]
        u /= b
    }
    i-=1; a[i] = digits[u % b]

    if .Prefix in flags {
        ok := true
        switch base {
        case  2: i-=1; a[i] = 'b'
        case  8: i-=1; a[i] = 'o'
        // case 10: i-=1; a[i] = 'd';
        case 12: i-=1; a[i] = 'z'
        case 16: i-=1; a[i] = 'x'
        case: ok = false
        }
        if ok {
            i-=1; a[i] = '0'
        }
    }

    switch {
    case neg:
        i-=1; a[i] = '-'
    case .Plus in flags:
        i-=1; a[i] = '+'
    }

    out := a[i:]
    slice.copy(buf, out)
    return string(buf[0:len(out)])
}

/*
Writes the string representation of a 128-bit integer to a buffer with specified base, flags, and digit set.

**Inputs**
- buf: The buffer to dyn_array.append the integer representation to
- x: The 128-bit integer value to convert
- base: The base for the integer representation (2 <= base <= MAX_BASE)
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, 64, or 128)
- digits: The digit set used for the integer representation
- flags: The Int_Flags bit set to control integer formatting

**Returns**
- The string containing the integer representation written to the buffer
*/
write_bits_128 :: proc(buf: []u8, x: u128, base: uint, is_signed: bool, bit_size: uint, digits: string, flags: Int_Flags) -> string {
    if base < 2 || base > MAX_BASE {
        internal.panic("strconv: illegal base passed to write_bits")
    }

    a: [140]u8
    i := len(a)
    u, neg := is_integer_negative_128(x, is_signed, bit_size)
    b := u128(base)
    for u >= b && i >= 0 {
        i-=1
        // rem: u128;
        // u = internal.udivmod128(u, b, &rem);
        // u /= b;
        rem := u % b
        u /= b

        idx := u32(rem)
        a[i] = digits[idx]
    }
    i-=1; a[i] = digits[u64(u % b)]

    if .Prefix in flags {
        ok := true
        switch base {
        case  2: i-=1; a[i] = 'b'
        case  8: i-=1; a[i] = 'o'
        case 10: i-=1; a[i] = 'd'
        case 12: i-=1; a[i] = 'z'
        case 16: i-=1; a[i] = 'x'
        case: ok = false
        }
        if ok {
            i-=1; a[i] = '0'
        }
    }

    switch {
    case neg:
        i-=1; a[i] = '-'
    case .Plus in flags:
        i-=1; a[i] = '+'
    }

    out := a[i:]
    slice.copy(buf, out)
    return string(buf[0:len(out)])
}

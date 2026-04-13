import "base:internal"

import "decimal"

/*
Parses an integer value from the input string in the given base, without a prefix

**Inputs**
- str: The input string to parse the integer value from
- base: The base of the integer value to be parsed (must be between 1 and 16)
- n: An optional pointer to an uint to store the length of the parsed substring (default: nil)

Example:
    n, ok := strconv.parse_i64_of_base("-1234e3", 10)
    fmt.println(n, ok)
Output:
    -1234 false
**Returns**
- value: Parses an integer value from a string, in the given base, without a prefix.
- ok: ok=false if no numeric value of the appropriate base could be found, or if the input string contained more than just the number.
*/
parse_i64_of_base :: proc(str: string, base: uint, n: ^uint = nil) -> (value: i64, ok: bool) {
    internal.assert(base <= 16, "base must be 1-16")

    s := str

    defer if n != nil { n^ = len(str)-len(s) }

    if s == "" {
        return
    }

    neg := false
    if len(s) > 1 {
        switch s[0] {
        case '-':
            neg = true
            s = s[1:]
        case '+':
            s = s[1:]
        }
    }


    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := i64(_digit_value(r))
        if v >= i64(base) {
            break
        }
        value *= i64(base)
        value += v
        i += 1
    }
    s = s[i:]

    if neg {
        value = -value
    }
    ok = len(s) == 0
    return
}

/*
Parses an integer value from the input string in base 10, unless there's a prefix

**Inputs**
- str: The input string to parse the integer value from
- n: An optional pointer to an uint to store the length of the parsed substring (default: nil)

Example:


    parse_i64_maybe_prefixed_example :: proc() {
        n, ok := strconv.parse_i64_maybe_prefixed("1234")
        fmt.println(n,ok)

        n, ok = strconv.parse_i64_maybe_prefixed("0xeeee")
        fmt.println(n,ok)
    }

Output:

    1234 true
    61166 true

**Returns**
- value: The parsed integer value
- ok: ok=false if a valid integer could not be found, or if the input string contained more than just the number.
*/
parse_i64_maybe_prefixed :: proc(str: string, n: ^uint = nil) -> (value: i64, ok: bool) {
    s := str
    defer if n != nil { n^ = len(str)-len(s) }
    if s == "" {
        return
    }

    neg := false
    if len(s) > 1 {
        switch s[0] {
        case '-':
            neg = true
            s = s[1:]
        case '+':
            s = s[1:]
        }
    }


    base: i64 = 10
    if len(s) > 2 && s[0] == '0' {
        switch s[1] {
        case 'b': base =  2;  s = s[2:]
        case 'o': base =  8;  s = s[2:]
        case 'd': base = 10;  s = s[2:]
        case 'z': base = 12;  s = s[2:]
        case 'x': base = 16;  s = s[2:]
        }
    }


    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := i64(_digit_value(r))
        if v >= base {
            break
        }
        value *= base
        value += v
        i += 1
    }
    s = s[i:]

    if neg {
        value = -value
    }
    ok = len(s) == 0
    return
}

/*
Parses an unsigned 64-bit integer value from the input string without a prefix, using the specified base

**Inputs**
- str: The input string to parse
- base: The base of the number system to use for parsing
    - Must be between 1 and 16 (inclusive)
- n: An optional pointer to an uint to store the length of the parsed substring (default: nil)

Example:


    parse_u64_of_base_example :: proc() {
        n, ok := strconv.parse_u64_of_base("1234e3", 10)
        fmt.println(n,ok)

        n, ok = strconv.parse_u64_of_base("5678eee",16)
        fmt.println(n,ok)
    }

Output:

    1234 false
    90672878 true

**Returns**
- value: The parsed uint64 value
- ok: A boolean indicating whether the parsing was successful
*/
parse_u64_of_base :: proc(str: string, base: uint, n: ^uint = nil) -> (value: u64, ok: bool) {
    internal.assert(base <= 16, "base must be 1-16")
    s := str
    defer if n != nil { n^ = len(str)-len(s) }
    if s == "" {
        return
    }

    if len(s) > 1 && s[0] == '+' {
        s = s[1:]
    }

    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := u64(_digit_value(r))
        if v >= u64(base) {
            break
        }
        value *= u64(base)
        value += v
        i += 1
    }
    s = s[i:]

    ok = len(s) == 0
    return
}

/*
Parses an unsigned 64-bit integer value from the input string, using the specified base or inferring the base from a prefix

**Inputs**
- str: The input string to parse
- base: The base of the number system to use for parsing (default: 0)
    - If base is 0, it will be inferred based on the prefix in the input string (e.g. '0x' for hexadecimal)
    - If base is not 0, it will be used for parsing regardless of any prefix in the input string
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:


    parse_u64_maybe_prefixed_example :: proc() {
        n, ok := strconv.parse_u64_maybe_prefixed("1234")
        fmt.println(n,ok)

        n, ok = strconv.parse_u64_maybe_prefixed("0xee")
        fmt.println(n,ok)
    }

Output:

    1234 true
    238 true

**Returns**
- value: The parsed uint64 value
- ok: ok=false if a valid integer could not be found, if the value was negative, or if the input string contained more than just the number.
*/
parse_u64_maybe_prefixed :: proc(str: string, n: ^uint = nil) -> (value: u64, ok: bool) {
    s := str
    defer if n != nil { n^ = len(str) - len(s) }
    if s == "" {
        return
    }

    if len(s) > 1 && s[0] == '+' {
        s = s[1:]
    }


    base := u64(10)
    if len(s) > 2 && s[0] == '0' {
        switch s[1] {
        case 'b': base =  2;  s = s[2:]
        case 'o': base =  8;  s = s[2:]
        case 'd': base = 10;  s = s[2:]
        case 'z': base = 12;  s = s[2:]
        case 'x': base = 16;  s = s[2:]
        }
    }

    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := u64(_digit_value(r))
        if v >= base {
            break
        }
        value *= base
        value += v
        i += 1
    }
    s = s[i:]

    ok = len(s) == 0
    return
}

/*
Parses a signed integer value from the input string, using the specified base or inferring the base from a prefix

**Inputs**
- s: The input string to parse
- base: The base of the number system to use for parsing (default: 0)
    - If base is 0, it will be inferred based on the prefix in the input string (e.g. '0x' for hexadecimal)
    - If base is not 0, it will be used for parsing regardless of any prefix in the input string

Example:


    parse_int_example :: proc() {
        n, ok := strconv.parse_int("1234") // without prefix, inferred base 10
        fmt.println(n,ok)

        n, ok = strconv.parse_int("ffff", 16) // without prefix, explicit base
        fmt.println(n,ok)

        n, ok = strconv.parse_int("0xffff") // with prefix and inferred base
        fmt.println(n,ok)
    }

Output:

    1234 true
    65535 true
    65535 true

**Returns**
- value: The parsed int value
- ok: `false` if no appropriate value could be found, or if the input string contained more than just the number.
*/
parse_int :: proc(s: string, base: uint = 0, n: ^uint = nil) -> (value: int, ok: bool) {
    v: i64 = ---
    switch base {
    case 0:  v, ok = parse_i64_maybe_prefixed(s, n)
    case:    v, ok = parse_i64_of_base(s, base, n)
    }
    value = int(v)
    return
}
/*
Parses an unsigned integer value from the input string, using the specified base or inferring the base from a prefix

**Inputs**
- s: The input string to parse
- base: The base of the number system to use for parsing (default: 0, inferred)
    - If base is 0, it will be inferred based on the prefix in the input string (e.g. '0x' for hexadecimal)
    - If base is not 0, it will be used for parsing regardless of any prefix in the input string

Example:


    parse_uint_example :: proc() {
        n, ok := strconv.parse_uint("1234") // without prefix, inferred base 10
        fmt.println(n,ok)

        n, ok = strconv.parse_uint("ffff", 16) // without prefix, explicit base
        fmt.println(n,ok)

        n, ok = strconv.parse_uint("0xffff") // with prefix and inferred base
        fmt.println(n,ok)
    }

Output:

    1234 true
    65535 true
    65535 true

**Returns**

value: The parsed uint value
ok: `false` if no appropriate value could be found; the value was negative; he input string contained more than just the number
*/
parse_uint :: proc(s: string, base: uint = 0, n: ^uint = nil) -> (value: uint, ok: bool) {
    v: u64 = ---
    switch base {
    case 0:  v, ok = parse_u64_maybe_prefixed(s, n)
    case:    v, ok = parse_u64_of_base(s, base, n)
    }
    value = uint(v)
    return
}
/*
Parses an integer value from a string in the given base, without any prefix

**Inputs**
- str: The input string containing the integer value
- base: The base (radix) to use for parsing the integer (1-16)
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:


    parse_i128_of_base_example :: proc() {
        n, ok := strconv.parse_i128_of_base("-1234eeee", 10)
        fmt.println(n,ok)
    }

Output:

    -1234 false

**Returns**
- value: The parsed i128 value
- ok: false if no numeric value of the appropriate base could be found, or if the input string contained more than just the number.
*/
parse_i128_of_base :: proc(str: string, base: uint, n: ^uint = nil) -> (value: i128, ok: bool) {
    internal.assert(base <= 16, "base must be 1-16")

    s := str
    defer if n != nil { n^ = len(str)-len(s) }
    if s == "" {
        return
    }

    neg := false
    if len(s) > 1 {
        switch s[0] {
        case '-':
            neg = true
            s = s[1:]
        case '+':
            s = s[1:]
        }
    }


    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := i128(_digit_value(r))
        if v >= i128(base) {
            break
        }
        value *= i128(base)
        value += v
        i += 1
    }
    s = s[i:]

    if neg {
        value = -value
    }
    ok = len(s) == 0
    return
}
/*
Parses an integer value from a string in base 10, unless there's a prefix

**Inputs**
- str: The input string containing the integer value
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:


    parse_i128_maybe_prefixed_example :: proc() {
        n, ok := strconv.parse_i128_maybe_prefixed("1234")
        fmt.println(n, ok)

        n, ok = strconv.parse_i128_maybe_prefixed("0xeeee")
        fmt.println(n, ok)
    }

Output:

    1234 true
    61166 true

**Returns**
- value: The parsed i128 value
- ok: `false` if a valid integer could not be found, or if the input string contained more than just the number.
*/
parse_i128_maybe_prefixed :: proc(str: string, n: ^uint = nil) -> (value: i128, ok: bool) {
    s := str
    defer if n != nil { n^ = len(str)-len(s) }
    if s == "" {
        return
    }

    neg := false
    if len(s) > 1 {
        switch s[0] {
        case '-':
            neg = true
            s = s[1:]
        case '+':
            s = s[1:]
        }
    }


    base: i128 = 10
    if len(s) > 2 && s[0] == '0' {
        switch s[1] {
        case 'b': base =  2;  s = s[2:]
        case 'o': base =  8;  s = s[2:]
        case 'd': base = 10;  s = s[2:]
        case 'z': base = 12;  s = s[2:]
        case 'x': base = 16;  s = s[2:]
        }
    }


    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := i128(_digit_value(r))
        if v >= base {
            break
        }
        value *= base
        value += v
        i += 1
    }
    s = s[i:]

    if neg {
        value = -value
    }
    ok = len(s) == 0
    return
}

/*
Parses an unsigned integer value from a string in the given base, without any prefix

**Inputs**
- str: The input string containing the integer value
- base: The base (radix) to use for parsing the integer (1-16)
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:


    parse_u128_of_base_example :: proc() {
        n, ok := strconv.parse_u128_of_base("1234eeee", 10)
        fmt.println(n, ok)

        n, ok = strconv.parse_u128_of_base("5678eeee", 16)
        fmt.println(n, ok)
    }

Output:

    1234 false
    1450766062 true

**Returns**
- value: The parsed u128 value
- ok: `false` if no numeric value of the appropriate base could be found, or if the input string contained more than just the number.
*/
parse_u128_of_base :: proc(str: string, base: uint, n: ^uint = nil) -> (value: u128, ok: bool) {
    internal.assert(base <= 16, "base must be 1-16")
    s := str
    defer if n != nil { n^ = len(str)-len(s) }
    if s == "" {
        return
    }

    if len(s) > 1 && s[0] == '+' {
        s = s[1:]
    }

    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := u128(_digit_value(r))
        if v >= u128(base) {
            break
        }
        value *= u128(base)
        value += v
        i += 1
    }
    s = s[i:]

    ok = len(s) == 0
    return
}
/*
Parses an unsigned integer value from a string in base 10, unless there's a prefix

**Inputs**
- str: The input string containing the integer value
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:


    parse_u128_maybe_prefixed_example :: proc() {
        n, ok := strconv.parse_u128_maybe_prefixed("1234")
        fmt.println(n, ok)

        n, ok = strconv.parse_u128_maybe_prefixed("5678eeee")
        fmt.println(n, ok)
    }

Output:

    1234 true
    5678 false

**Returns**
- value: The parsed u128 value
- ok: false if a valid integer could not be found, if the value was negative, or if the input string contained more than just the number.
*/
parse_u128_maybe_prefixed :: proc(str: string, n: ^uint = nil) -> (value: u128, ok: bool) {
    s := str
    defer if n != nil { n^ = len(str)-len(s) }
    if s == "" {
        return
    }

    if len(s) > 1 && s[0] == '+' {
        s = s[1:]
    }


    base := u128(10)
    if len(s) > 2 && s[0] == '0' {
        switch s[1] {
        case 'b': base =  2;  s = s[2:]
        case 'o': base =  8;  s = s[2:]
        case 'd': base = 10;  s = s[2:]
        case 'z': base = 12;  s = s[2:]
        case 'x': base = 16;  s = s[2:]
        }
    }

    i := 0
    for r in s {
        if r == '_' {
            i += 1
            continue
        }
        v := u128(_digit_value(r))
        if v >= base {
            break
        }
        value *= base
        value += v
        i += 1
    }
    s = s[i:]

    ok = len(s) == 0
    return
}

/*
Converts a u8 to lowercase

**Inputs**
- ch: A u8 character to be converted to lowercase.

**Returns**
- A lowercase u8 character.
*/
@(private)
lower :: #force_inline proc(ch: u8) -> u8 { return ('a' - 'A') | ch }
/*
Parses a 32-bit floating point number from a string

**Inputs**
- s: The input string containing a 32-bit floating point number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_f32_example :: proc() {
        n, ok := strconv.parse_f32("1234eee")
        fmt.printfln("%.3f %v", n, ok)

        n, ok = strconv.parse_f32("5678e2")
        fmt.printfln("%.3f %v", n, ok)
    }

Output:

    0.000 false
    567800.000 true

**Returns**
- value: The parsed 32-bit floating point number.
- ok: `false` if a base 10 float could not be found, or if the input string contained more than just the number.
*/
parse_f32 :: proc(s: string, n: ^uint = nil) -> (value: f32, ok: bool) {
    v: f64 = ---
    v, ok = parse_f64(s, n)
    return f32(v), ok
}
/*
Parses a 64-bit floating point number from a string

**Inputs**
- str: The input string containing a 64-bit floating point number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_f64_example :: proc() {
        n, ok := strconv.parse_f64("1234eee")
        fmt.printfln("%.3f %v", n, ok)

        n, ok = strconv.parse_f64("5678e2")
        fmt.printfln("%.3f %v", n, ok)
    }

Output:

    0.000 false
    567800.000 true

**Returns**
- value: The parsed 64-bit floating point number.
- ok: `false` if a base 10 float could not be found, or if the input string contained more than just the number.
*/
parse_f64 :: proc(str: string, n: ^uint = nil) -> (value: f64, ok: bool) {
    nr: uint
    value, nr, ok = parse_f64_prefix(str)
    if ok && len(str) != nr {
        ok = false
    }
    if n != nil { n^ = nr }
    return
}
/*
Parses a 32-bit floating point number from a string and returns the parsed number, the length of the parsed substring, and a boolean indicating whether the parsing was successful

**Inputs**
- str: The input string containing a 32-bit floating point number.

Example:


    parse_f32_prefix_example :: proc() {
        n, _, ok := strconv.parse_f32_prefix("1234eee")
        fmt.printfln("%.3f %v", n, ok)

        n, _, ok = strconv.parse_f32_prefix("5678e2")
        fmt.printfln("%.3f %v", n, ok)
    }

Output:

    0.000 false
    567800.000 true


**Returns**
- value: The parsed 32-bit floating point number.
- nr: The length of the parsed substring.
- ok: A boolean indicating whether the parsing was successful.
*/
parse_f32_prefix :: proc(str: string) -> (value: f32, nr: uint, ok: bool) {
    f: f64
    f, nr, ok = parse_f64_prefix(str)
    value = f32(f)
    return
}
/*
Parses a 64-bit floating point number from a string and returns the parsed number, the length of the parsed substring, and a boolean indicating whether the parsing was successful

**Inputs**
- str: The input string containing a 64-bit floating point number.

Example:


    parse_f64_prefix_example :: proc() {
        n, _, ok := strconv.parse_f64_prefix("12.34eee")
        fmt.printfln("%.3f %v", n, ok)

        n, _, ok = strconv.parse_f64_prefix("12.34e2")
        fmt.printfln("%.3f %v", n, ok)

        n, _, ok = strconv.parse_f64_prefix("13.37 hellope")
        fmt.printfln("%.3f %v", n, ok)
    }

Output:

    0.000 false
    1234.000 true
    13.370 true

**Returns**
- value: The parsed 64-bit floating point number.
- nr: The length of the parsed substring.
- ok: `false` if a base 10 float could not be found
*/
parse_f64_prefix :: proc(str: string) -> (value: f64, nr: uint, ok: bool) {
    common_prefix_len_ignore_case :: proc(s, prefix: string) -> uint {
        n := len(prefix)
        if n > len(s) {
            n = len(s)
        }
        for i in 0..<n {
            c := s[i]
            if 'A' <= c && c <= 'Z' {
                c += 'a' - 'A'
            }
            if c != prefix[i] {
                return i
            }
        }
        return n
    }
    check_special :: proc(s: string) -> (f: f64, n: uint, ok: bool) {
        s := s
        if len(s) > 0 {
            sign := 1
            nsign: uint
            switch s[0] {
            case '+', '-':
                if s[0] == '-' {
                    sign = -1
                }
                nsign = 1
                s = s[1:]
                fallthrough
            case 'i', 'I':
                m := common_prefix_len_ignore_case(s, "infinity")
                if 3 <= m && m < 9 { // "inf" to "infinity"
                    f = 0h7ff00000_00000000 if sign == 1 else 0hfff00000_00000000
                    if m == 8 {
                        // We only count the entire prefix if it is precisely "infinity".
                        n = nsign + m
                    } else {
                        // The string was either only "inf" or incomplete.
                        n = nsign + 3
                    }
                    ok = true
                    return
                }
            case 'n', 'N':
                if common_prefix_len_ignore_case(s, "nan") == 3 {
                    f = 0h7ff80000_00000001
                    n = nsign + 3
                    ok = true
                    return
                }
            }
        }
        return
    }
    parse_components :: proc(s: string) -> (mantissa: u64, exp: int, neg, trunc, hex: bool, i: uint, ok: bool) {
        if len(s) == 0 {
            return
        }
        switch s[i] {
        case '+': i += 1
        case '-': i += 1; neg = true
        }

        base := u64(10)
        MAX_MANT_DIGITS := 19
        exp_char := u8('e')
        // support stupid 0x1.ABp100 hex floats even if Odin doesn't
        if i + 2 < len(s) && s[i] == '0' && lower(s[i + 1]) == 'x' {
            base = 16
            MAX_MANT_DIGITS = 16
            i += 2
            exp_char = 'p'
            hex = true
        }

        underscores := false
        saw_dot, saw_digits := false, false
        nd := 0
        nd_mant := 0
        decimal_point := 0
        trailing_zeroes_nd := -1
        loop: for ; i < len(s); i += 1 {
            switch c := s[i]; true {
            case c == '_':
                underscores = true
                continue loop
            case c == '.':
                if saw_dot {
                    break loop
                }
                saw_dot = true
                decimal_point = nd
                continue loop

            case '0' <= c && c <= '9':
                saw_digits = true
                if c == '0' {
                    if nd == 0 {
                        decimal_point -= 1
                        continue loop
                    }
                    if trailing_zeroes_nd == -1 {
                        trailing_zeroes_nd = nd
                    }
                } else {
                    trailing_zeroes_nd = -1
                }
                nd += 1
                if nd_mant < MAX_MANT_DIGITS {
                    mantissa *= base
                    mantissa += u64(c - '0')
                    nd_mant += 1
                } else if c != '0' {
                    trunc = true
                }
                continue loop
            case base == 16 && 'a' <= lower(c) && lower(c) <= 'f':
                saw_digits = true
                nd += 1
                if nd_mant < MAX_MANT_DIGITS {
                    mantissa *= 16
                    mantissa += u64(lower(c) - 'a' + 10)
                    nd_mant += 1
                } else {
                    trunc = true
                }
                continue loop
            }
            break loop
        }

        if !saw_digits {
            return
        }
        if !saw_dot {
            decimal_point = nd
        }
        if trailing_zeroes_nd > 0 {
            trailing_zeroes_nd = nd_mant - trailing_zeroes_nd
        }
        for /**/; trailing_zeroes_nd > 0; trailing_zeroes_nd -= 1 {
            mantissa /= base
            nd_mant -= 1
            nd -= 1
        }
        if base == 16 {
            decimal_point *= 4
            nd_mant *= 4
        }

        if i < len(s) && lower(s[i]) == exp_char {
            i += 1
            if i >= len(s) { return }
            exp_sign := 1
            switch s[i] {
            case '+': i += 1
            case '-': i += 1; exp_sign = -1
            }
            if i >= len(s) || s[i] < '0' || s[i] > '9' {
                return
            }
            e := 0
            for ; i < len(s) && ('0' <= s[i] && s[i] <= '9' || s[i] == '_'); i += 1 {
                if s[i] == '_' {
                    underscores = true
                    continue
                }
                if e < 1e5 {
                    e = e*10 + int(s[i]) - '0'
                }
            }
            decimal_point += e * exp_sign
        } else if base == 16 {
            return
        }

        if mantissa != 0 {
            exp = decimal_point - nd_mant
        }
        ok = true
        return
    }

    parse_hex :: proc(s: string, mantissa: u64, exp: int, neg, trunc: bool) -> (f64, bool) {
        info := &_f64_info

        mantissa, exp := mantissa, exp

        MAX_EXP := 1<<info.expbits + info.bias - 2
        MIN_EXP := info.bias + 1
        exp += int(info.mantbits)

        for mantissa != 0 && mantissa >> (info.mantbits+2) == 0 {
            mantissa <<= 1
            exp -= 1
        }
        if trunc {
            mantissa |= 1
        }

        for mantissa != 0 && mantissa >> (info.mantbits+2) == 0 {
            mantissa = mantissa>>1 | mantissa&1
            exp += 1
        }

        // denormalize
        if mantissa > 1 && exp < MIN_EXP-2 {
            mantissa = mantissa>>1 | mantissa&1
            exp += 1
        }

        round := mantissa & 3
        mantissa >>= 2
        round |= mantissa & 1 // round to even
        exp += 2
        if round == 3 {
            mantissa += 1
            if mantissa == 1 << (1 + info.mantbits) {
                mantissa >>= 1
                exp += 1
            }
        }
        if mantissa>>info.mantbits == 0 {
            // zero or denormal
            exp = info.bias
        }

        ok := true
        if exp > MAX_EXP {
            // infinity or invalid
            mantissa = 1<<info.mantbits
            exp = MAX_EXP + 1
            ok = false
        }

        bits := mantissa & (1<<info.mantbits - 1)
        bits |= u64((exp-info.bias) & (1<<info.expbits - 1)) << info.mantbits
        if neg {
            bits |= 1 << info.mantbits << info.expbits
        }
        return transmute(f64)bits, ok
    }

    if len(str) > 2 && str[0] == '0' && str[1] == 'h' {
        nr = 2

        as_int: u64
        digits: uint
        for r in str[2:] {
            if r == '_' {
                nr += 1
                continue
            }
            v := u64(_digit_value(r))
            if v >= 16 {
                break
            }
            as_int *= 16
            as_int += v
            digits += 1
        }
        nr += digits
        ok = len(str) == nr

        switch digits {
        case 4:
            value = cast(f64)transmute(f16)cast(u16)as_int
        case 8:
            value = cast(f64)transmute(f32)cast(u32)as_int
        case 16:
            value = transmute(f64)as_int
        case:
            ok = false
        }
        return
    }

    if value, nr, ok = check_special(str); ok {
        return
    }

    mantissa: u64
    exp:      int
    neg, trunc, hex: bool
    mantissa, exp, neg, trunc, hex, nr = parse_components(str) or_return

    if hex {
        value, ok = parse_hex(str, mantissa, exp, neg, trunc)
        return
    }

    trunc_block: if !trunc {
        @(static, rodata) pow10 := [?]f64{
            1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,  1e8,  1e9,
            1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
            1e20, 1e21, 1e22,
        }

        if mantissa>>_f64_info.mantbits != 0 {
            break trunc_block
        }
        f := f64(mantissa)
        f_abs := f
        if neg {
            f = -f
        }
        switch {
        case exp == 0:
            return f, nr, true
        case exp > 0 && exp <= 15+22:
            if exp > 22 {
                f *= pow10[exp-22]
                exp = 22
            }
            if f_abs > 1e15 || f_abs < 1e-15 {
                break trunc_block
            }
            return f * pow10[exp], nr, true
        case -22 <= exp && exp < 0:
            return f / pow10[-exp], nr, true
        }
    }
    d: decimal.Decimal
    _ = decimal.set(&d, str[:nr])
    b, overflow := decimal_to_float_bits(&d, &_f64_info)
    value = transmute(f64)b
    ok = !overflow
    return
}
/*
Parses a 128-bit complex number from a string

**Inputs**
- str: The input string containing a 128-bit complex number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_complex128_example :: proc() {
        n: int
        c, ok := strconv.parse_complex128("3+1i", &n)
        fmt.printfln("%v %i %t", c, n, ok)

        c, ok = strconv.parse_complex128("5+7i hellope", &n)
        fmt.printfln("%v %i %t", c, n, ok)
    }

Output:

    3+1i 4 true
    5+7i 4 false

**Returns**
- value: The parsed 128-bit complex number.
- ok: `false` if a complex number could not be found, or if the input string contained more than just the number.
*/
parse_complex128 :: proc(str: string, n: ^uint = nil) -> (value: complex128, ok: bool) {
    real_value, imag_value: f64
    nr_r, nr_i: uint

    real_value, nr_r, _ = parse_f64_prefix(str)
    imag_value, nr_i, _ = parse_f64_prefix(str[nr_r:])

    i_parsed := len(str) >= nr_r + nr_i + 1 && str[nr_r + nr_i] == 'i'
    if !i_parsed {
        // No `i` means we refuse to treat the second float we parsed as an
        // imaginary value.
        imag_value = 0
        nr_i = 0
    }

    ok = i_parsed && len(str) == nr_r + nr_i + 1

    if n != nil {
        n^ = nr_r + nr_i + (1 if i_parsed else 0)
    }

    value = complex(real_value, imag_value)
    return
}
/*
Parses a 64-bit complex number from a string

**Inputs**
- str: The input string containing a 64-bit complex number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_complex64_example :: proc() {
        n: int
        c, ok := strconv.parse_complex64("3+1i", &n)
        fmt.printfln("%v %i %t", c, n, ok)

        c, ok = strconv.parse_complex64("5+7i hellope", &n)
        fmt.printfln("%v %i %t", c, n, ok)
    }

Output:

    3+1i 4 true
    5+7i 4 false

**Returns**
- value: The parsed 64-bit complex number.
- ok: `false` if a complex number could not be found, or if the input string contained more than just the number.
*/
parse_complex64 :: proc(str: string, n: ^uint = nil) -> (value: complex64, ok: bool) {
    v: complex128 = ---
    v, ok = parse_complex128(str, n)
    return cast(complex64)v, ok
}
/*
Parses a 32-bit complex number from a string

**Inputs**
- str: The input string containing a 32-bit complex number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_complex32_example :: proc() {
        n: int
        c, ok := strconv.parse_complex32("3+1i", &n)
        fmt.printfln("%v %i %t", c, n, ok)

        c, ok = strconv.parse_complex32("5+7i hellope", &n)
        fmt.printfln("%v %i %t", c, n, ok)
    }

Output:

    3+1i 4 true
    5+7i 4 false

**Returns**
- value: The parsed 32-bit complex number.
- ok: `false` if a complex number could not be found, or if the input string contained more than just the number.
*/
parse_complex32 :: proc(str: string, n: ^uint = nil) -> (value: complex32, ok: bool) {
    v: complex128 = ---
    v, ok = parse_complex128(str, n)
    return cast(complex32)v, ok
}
/*
Parses a 256-bit quaternion from a string

**Inputs**
- str: The input string containing a 256-bit quaternion.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_quaternion256_example :: proc() {
        n: int
        q, ok := strconv.parse_quaternion256("1+2i+3j+4k", &n)
        fmt.printfln("%v %i %t", q, n, ok)

        q, ok = strconv.parse_quaternion256("1+2i+3j+4k hellope", &n)
        fmt.printfln("%v %i %t", q, n, ok)
    }

Output:

    1+2i+3j+4k 10 true
    1+2i+3j+4k 10 false

**Returns**
- value: The parsed 256-bit quaternion.
- ok: `false` if a quaternion could not be found, or if the input string contained more than just the quaternion.
*/
parse_quaternion256 :: proc(str: string, n: ^uint = nil) -> (value: quaternion256, ok: bool) {
    iterate_and_assign :: proc (iter: ^string, terminator: u8, nr_total: ^uint, state: bool) -> (value: f64, ok: bool) {
        if !state {
            return
        }

        nr: uint
        value, nr, _ = parse_f64_prefix(iter^)
        iter^ = iter[nr:]

        if len(iter) > 0 && iter[0] == terminator {
            iter^ = iter[1:]
            nr_total^ += nr + 1
            ok = true
        } else {
            value = 0
        }

        return
    }

    real_value, imag_value, jmag_value, kmag_value: f64
    nr: uint

    real_value, nr, _ = parse_f64_prefix(str)
    iter := str[nr:]

    // Need to have parsed at least something in order to get started.
    ok = nr > 0

    // Quaternion parsing is done this way to honour the rest of the API with
    // regards to partial parsing. Otherwise, we could error out early.
    imag_value, ok = iterate_and_assign(&iter, 'i', &nr, ok)
    jmag_value, ok = iterate_and_assign(&iter, 'j', &nr, ok)
    kmag_value, ok = iterate_and_assign(&iter, 'k', &nr, ok)

    if len(iter) != 0 {
        ok = false
    }

    if n != nil {
        n^ = nr
    }

    value = quaternion(
        real = real_value,
        imag = imag_value,
        jmag = jmag_value,
        kmag = kmag_value)
    return
}
/*
Parses a 128-bit quaternion from a string

**Inputs**
- str: The input string containing a 128-bit quaternion.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_quaternion128_example :: proc() {
        n: int
        q, ok := strconv.parse_quaternion128("1+2i+3j+4k", &n)
        fmt.printfln("%v %i %t", q, n, ok)

        q, ok = strconv.parse_quaternion128("1+2i+3j+4k hellope", &n)
        fmt.printfln("%v %i %t", q, n, ok)
    }

Output:

    1+2i+3j+4k 10 true
    1+2i+3j+4k 10 false

**Returns**
- value: The parsed 128-bit quaternion.
- ok: `false` if a quaternion could not be found, or if the input string contained more than just the quaternion.
*/
parse_quaternion128 :: proc(str: string, n: ^uint = nil) -> (value: quaternion128, ok: bool) {
    v: quaternion256 = ---
    v, ok = parse_quaternion256(str, n)
    return cast(quaternion128)v, ok
}
/*
Parses a 64-bit quaternion from a string

**Inputs**
- str: The input string containing a 64-bit quaternion.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:


    parse_quaternion64_example :: proc() {
        n: int
        q, ok := strconv.parse_quaternion64("1+2i+3j+4k", &n)
        fmt.printfln("%v %i %t", q, n, ok)

        q, ok = strconv.parse_quaternion64("1+2i+3j+4k hellope", &n)
        fmt.printfln("%v %i %t", q, n, ok)
    }

Output:

    1+2i+3j+4k 10 true
    1+2i+3j+4k 10 false

**Returns**
- value: The parsed 64-bit quaternion.
- ok: `false` if a quaternion could not be found, or if the input string contained more than just the quaternion.
*/
parse_quaternion64 :: proc(str: string, n: ^uint = nil) -> (value: quaternion64, ok: bool) {
    v: quaternion256 = ---
    v, ok = parse_quaternion256(str, n)
    return cast(quaternion64)v, ok
}

/*
Parses a boolean value from the input string

**Inputs**
- s: The input string
    - true: "1", "t", "T", "true", "TRUE", "True"
    - false: "0", "f", "F", "false", "FALSE", "False"
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

**Returns**
- result: The parsed boolean value (default: false)
- ok: A boolean indicating whether the parsing was successful
*/
parse_bool :: proc(s: string, n: ^uint = nil) -> (result: bool = false, ok: bool) {
    switch s {
    case "1", "t", "T", "true", "TRUE", "True":
        if n != nil { n^ = len(s) }
        return true, true
    case "0", "f", "F", "false", "FALSE", "False":
        if n != nil { n^ = len(s) }
        return false, true
    }
    return
}

/*
Finds the integer value of the given rune

**Inputs**
- r: The input rune to find the integer value of

**Returns**   The integer value of the given rune
*/
_digit_value :: proc(r: rune) -> int {
    ri := int(r)
    v: int = 16
    switch r {
    case '0'..='9': v = ri-'0'
    case 'a'..='z': v = ri-'a'+10
    case 'A'..='Z': v = ri-'A'+10
    }
    return v
}

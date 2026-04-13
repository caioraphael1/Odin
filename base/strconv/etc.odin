import "base:container/slice"
import "base:mem"
import "base:unicode/utf8"

// Accepts '0'..='9', otherwise returns ok = false
digit_to_int :: proc(r: rune) -> (value: int, ok: bool) {
    if '0' <= r && r <= '9' {
        return int(r - '0'), true
    }
    return -1, false
}

/*
Writes a quoted string representation of the input string to a given u8 slice and returns the result as a string

**Inputs**
- buf: The u8 slice to which the quoted string will be written
- str: The input string to be quoted

!! ISSUE !! NOT EXPECTED -- "\"hello\"" was expected
Example:

    quote_example :: proc() {
        buf: [20]u8
        result := strconv.quote(buf[:], "hello")
        fmt.println(result, buf)
    }
Output:
    "'h''e''l''l''o'" [34, 39, 104, 39, 39, 101, 39, 39, 108, 39, 39, 108, 39, 39, 111, 39, 34, 0, 0, 0]
**Returns**
- The resulting string after writing the quoted string representation
*/
quote :: proc(buf: []u8, str: string) -> string {
    write_byte :: proc(buf: []u8, i: ^uint, bytes: ..u8) {
        if i^ >= len(buf) {
            return
        }
        n := slice.copy(buf[i^:], bytes[:])
        i^ += n
    }

    if buf == nil {
        return ""
    }

    c :: '"'
    i: uint
    s := str

    write_byte(buf, &i, c)
    for width: uint; len(s) > 0; s = s[width:] {
        r := rune(s[0])
        width = 1
        if r >= utf8.RUNE_SELF {
            r, width = utf8.rune_from_string(s)
        }
        if width == 1 && r == utf8.RUNE_ERROR {
            write_byte(buf, &i, '\\', 'x')
            write_byte(buf, &i, digits[s[0]>>4])
            write_byte(buf, &i, digits[s[0]&0xf])
        }
        if i < len(buf) {
            x := quote_rune(buf[i:], r)
            i += len(x)
        }
    }
    write_byte(buf, &i, c)
    return string(buf[:i])
}

/*
Writes a quoted rune representation of the input rune to a given u8 slice and returns the result as a string

**Inputs**
- buf: The u8 slice to which the quoted rune will be written
- r: The input rune to be quoted

Example:


    quote_rune_example :: proc() {
        buf: [4]u8
        result := strconv.quote_rune(buf[:], 'A')
        fmt.println(result, buf)
    }

Output:

    'A' [39, 65, 39, 0]

**Returns**
- The resulting string after writing the quoted rune representation
*/
quote_rune :: proc(buf: []u8, r: rune) -> string {
    write_byte :: proc(buf: []u8, i: ^uint, bytes: ..u8) {
        if i^ < len(buf) {
            n := slice.copy(buf[i^:], bytes[:])
            i^ += n
        }
    }
    write_string :: proc(buf: []u8, i: ^uint, s: string) {
        if i^ < len(buf) {
            n := slice.copy_from_string(buf[i^:], s)
            i^ += n
        }
    }
    write_rune :: proc(buf: []u8, i: ^uint, r: rune) {
        if i^ < len(buf) {
            b, w := utf8.bytes_from_rune(r)
            n := slice.copy(buf[i^:], b[:w])
            i^ += n
        }
    }

    if buf == nil || r < 0 {
        return ""
    }

    i: uint
    write_byte(buf, &i, '\'')

    switch r {
    case '\a': write_string(buf, &i, "\\a")
    case '\b': write_string(buf, &i, "\\b")
    case '\e': write_string(buf, &i, "\\e")
    case '\f': write_string(buf, &i, "\\f")
    case '\n': write_string(buf, &i, "\\n")
    case '\r': write_string(buf, &i, "\\r")
    case '\t': write_string(buf, &i, "\\t")
    case '\v': write_string(buf, &i, "\\v")
    case:
        if r < 32 {
            write_string(buf, &i, "\\x")
            b: [2]u8
            s := write_bits(b[:], u64(r), 16, true, 64, digits, nil)
            switch len(s) {
            case 0: write_string(buf, &i, "00")
            case 1: write_rune(buf, &i, '0')
            case 2: write_string(buf, &i, s)
            }
        } else {
            write_rune(buf, &i, r)
        }
    }
    write_byte(buf, &i, '\'')

    return string(buf[:i])
}

/*
Unquotes a single character from the input string, considering the given quote character

**Inputs**
- str: The input string containing the character to unquote
- quote: The quote character to consider (e.g., '"')

Example:


    unquote_char_example :: proc() {
        src:="\'The\' raven"
        r, multiple_bytes, tail_string, success  := strconv.unquote_char(src,'\'')
        fmt.println("Source:", src)
        fmt.printf("r: <%v>, multiple_bytes:%v, tail_string:<%s>, success:%v\n",r, multiple_bytes, tail_string, success)
    }

Output:

    Source: 'The' raven
    r: <'>, multiple_bytes:false, tail_string:<The' raven>, success:true

**Returns**
- r: The unquoted rune
- multiple_bytes: A boolean indicating if the rune has multiple bytes
- tail_string: The remaining portion of the input string after unquoting the character
- success: A boolean indicating whether the unquoting was successful
*/
unquote_char :: proc(str: string, quote: u8) -> (r: rune, multiple_bytes: bool, tail_string: string, success: bool) {
    hex_to_int :: proc(c: u8) -> int {
        switch c {
        case '0'..='9': return int(c-'0')
        case 'a'..='f': return int(c-'a')+10
        case 'A'..='F': return int(c-'A')+10
        }
        return -1
    }
    w: uint

    if str[0] == quote && quote == '"' {
        return
    } else if str[0] >= 0x80 {
        r, w = utf8.rune_from_string(str)
        return r, true, str[w:], true
    } else if str[0] != '\\' {
        return rune(str[0]), false, str[1:], true
    }

    if len(str) <= 1 {
        return
    }
    s := str
    c := s[1]
    s = s[2:]

    switch c {
    case:
        return

    case 'a':  r = '\a'
    case 'b':  r = '\b'
    case 'f':  r = '\f'
    case 'n':  r = '\n'
    case 'r':  r = '\r'
    case 't':  r = '\t'
    case 'v':  r = '\v'
    case '\\': r = '\\'

    case '"':  r = '"'
    case '\'': r = '\''

    case '0'..='7':
        v := int(c-'0')
        if len(s) < 2 {
            return
        }
        for i in 0..<len(s) {
            d := int(s[i]-'0')
            if d < 0 || d > 7 {
                return
            }
            v = (v<<3) | d
        }
        s = s[2:]
        if v > 0xff {
            return
        }
        r = rune(v)

    case 'x', 'u', 'U':
        count: uint
        switch c {
        case 'x': count = 2
        case 'u': count = 4
        case 'U': count = 8
        }

        if len(s) < count {
            return
        }

        for i in 0..<count {
            d := hex_to_int(s[i])
            if d < 0 {
                return
            }
            r = (r<<4) | rune(d)
        }
        s = s[count:]
        if c == 'x' {
            break
        }
        if r > utf8.MAX_RUNE {
            return
        }
        multiple_bytes = true
    }

    success = true
    tail_string = s
    return
}

/*
Unquotes the input string considering any type of quote character and returns the unquoted string

**Inputs**
- lit: The input string to unquote
- allocator:

WARNING: This procedure gives unexpected results if the quotes are not the first and last characters.

Example:


    unquote_string_example :: proc() {
        src:="\"The raven Huginn is black.\""
        s, allocated, ok := strconv.unquote_string(src)
        fmt.println(src)
        fmt.printf("Unquoted: <%s>, alloc:%v, ok:%v\n\n", s, allocated, ok)

        src="\'The raven Huginn\' is black."
        s, allocated, ok = strconv.unquote_string(src)
        fmt.println(src)
        fmt.printf("Unquoted: <%s>, alloc:%v, ok:%v\n\n", s, allocated, ok)

        src="The raven \'Huginn\' is black."
        s, allocated, ok = strconv.unquote_string(src) // Will produce undesireable results
        fmt.println(src)
        fmt.printf("Unquoted: <%s>, alloc:%v, ok:%v\n", s, allocated, ok)
    }

Output:

    "The raven Huginn is black."
    Unquoted: <The raven Huginn is black.>, alloc:false, ok:true

    'The raven Huginn' is black.
    Unquoted: <The raven Huginn' is black>, alloc:false, ok:true

    The raven 'Huginn' is black.
    Unquoted: <he raven 'Huginn' is black>, alloc:false, ok:true

**Returns**
- res: The resulting unquoted string
- allocated: A boolean indicating if the resulting string was allocated using the provided allocator
- success: A boolean indicating whether the unquoting was successful

NOTE: If unquoting is unsuccessful, the allocated memory for the result will be freed.
*/
unquote_string :: proc(lit: string, allocator: mem.Allocator) -> (res: string, allocated, success: bool) {
    string_contain_rune :: proc(s: string, r: rune) -> (off: uint, found: bool) {
        for c, offset in s {
            if c == r {
                return offset, true
            }
        }
        return 0, false
    }

    if len(lit) < 2 {
        return
    }
    if lit[0] == '`' {
        return lit[1:len(lit)-1], false, true
    }

    s := lit
    quote := '"'

    if s == `""` {
        return "", false, true
    }
    s = s[1:len(s)-1]

    if _, found := string_contain_rune(s, '\n'); found {
        return s, false, false
    }

    _, backslash_found := string_contain_rune(s, '\\')
    _, quote_found := string_contain_rune(s, quote)

    if !backslash_found && !quote_found {
        if quote == '"' {
            return s, false, true
        }
    }

    buf_len := 3 * len(s) / 2
    buf, _ := slice.create(u8, buf_len, allocator)
    offset: uint
    for len(s) > 0 {
        r, multiple_bytes, tail_string, ok := unquote_char(s, u8(quote))
        if !ok {
            _ = slice.delete(buf, allocator)
            return s, false, false
        }
        s = tail_string
        if r < 0x80 || !multiple_bytes {
            buf[offset] = u8(r)
            offset += 1
        } else {
            b, w := utf8.bytes_from_rune(r)
            slice.copy(buf[offset:], b[:w])
            offset += w
        }
    }

    new_string := string(buf[:offset])

    return new_string, true, true
}

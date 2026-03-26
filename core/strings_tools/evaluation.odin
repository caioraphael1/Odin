
import "base:internal"
import "base:mem"
import "base:bytes"
import "base:container/slice"
import "base:unicode"
import "base:unicode/utf8"
import "base:unicode/ascii"


/*
Returns true when the string `substr` is contained inside the string `s`

Example:
    fmt.println(strings_tools.contains("testing", "test"))
    fmt.println(strings_tools.contains("testing", "ing"))
    fmt.println(strings_tools.contains("testing", "text"))
Output:
    true
    true
    false
*/
contains :: proc(s, substr: string) -> (res: bool) {
    _, found := index(s, substr)
    return found
}

/*
Returns `true` when the string `s` contains any of the characters inside the string `chars`

Example:
    fmt.println(strings_tools.contains_any("test", "test"))
    fmt.println(strings_tools.contains_any("test", "ts"))
    fmt.println(strings_tools.contains_any("test", "et"))
    fmt.println(strings_tools.contains_any("test", "a"))
Output:
    true
    true
    true
    false
*/
contains_any :: proc(s, chars: string) -> (res: bool) {
    _, found := index_any(s, chars)
    return found
}

contains_space :: proc(s: string) -> (res: bool) {
    for c in s {
        if unicode.is_space(c) {
            return true
        }
    }
    return false
}

/*
Example:
    index_rune("abcädef", 'x')
    index_rune("abcädef", 'a')
    index_rune("abcädef", 'b')
    index_rune("abcädef", 'c')
    index_rune("abcädef", 'ä')
    index_rune("abcädef", 'd')
    index_rune("abcädef", 'e')
    index_rune("abcädef", 'f')
Output:
    0, false
    0, true
    1, true
    2, true
    3, true
    5, true
    6, true
    7, true
*/
index_rune :: proc(s: string, r: rune) -> (res: uint, found: bool) {
    switch {
    case u32(r) < utf8.RUNE_SELF:
        return index_byte(s, u8(r))

    case r == utf8.RUNE_ERROR:
        for c, i in s {
            if c == utf8.RUNE_ERROR {
                return i, true
            }
        }
        return 0, false

    case !utf8.rune_is_valid(r):
        return 0, false
    }

    b, w := utf8.bytes_from_rune(r)
    return index(s, string(b[:w]))
}


@(private) PRIME_RABIN_KARP :: 16777619

/*
Example:
    index("test", "t")
    index("test", "te")
    index("test", "st")
    index("test", "tt")
Output:
    0, true
    0, true
    2, true
    0, false
*/
index :: proc(s, substr: string) -> (res: uint, found: bool) {
    hash_str_rabin_karp :: proc(s: string) -> (hash: u32, pow: u32) {
        pow = 1
        for i: uint = 0; i < len(s); i += 1 {
            hash = hash*PRIME_RABIN_KARP + u32(s[i])
        }
        sq := u32(PRIME_RABIN_KARP)
        for i := len(s); i > 0; i >>= 1 {
            if (i & 1) != 0 {
                pow *= sq
            }
            sq *= sq
        }
        return
    }

    n := len(substr)
    switch {
    case n == 0:
        return 0, true
    case n == 1:
        return index_byte(s, substr[0])
    case n == len(s):
        if s == substr {
            return 0, true
        }
        return 0, false
    case n > len(s):
        return 0, false
    }

    hash, pow := hash_str_rabin_karp(substr)
    h: u32
    for i: uint = 0; i < n; i += 1 {
        h = h*PRIME_RABIN_KARP + u32(s[i])
    }
    if h == hash && s[:n] == substr {
        return 0, true
    }
    for i := n; i < len(s); /**/ {
        h *= PRIME_RABIN_KARP
        h += u32(s[i])
        h -= pow * u32(s[i-n])
        i += 1
        if h == hash && s[i-n:i] == substr {
            return i - n, true
        }
    }
    return 0, false
}

/*
Example:
    last_index("test", "t")
    last_index("test", "te")
    last_index("test", "st")
    last_index("test", "tt")
Output:
    3, true
    0, true
    2, true
    0, false
*/
last_index :: proc(s, substr: string) -> (res: uint, found: bool) {
    hash_str_rabin_karp_reverse :: proc(s: string) -> (hash: u32, pow: u32) {
        pow = 1
        for i := int(len(s)) - 1; i >= 0; i -= 1 {
            hash = hash*PRIME_RABIN_KARP + u32(s[i])
        }
        sq := u32(PRIME_RABIN_KARP)
        for i := len(s); i > 0; i >>= 1 {
            if (i & 1) != 0 {
                pow *= sq
            }
            sq *= sq
        }
        return
    }

    n := len(substr)
    switch {
    case n == 0:
        return len(s), true
    case n == 1:
        return last_index_byte(s, substr[0])
    case n == len(s):
        return 0, substr == s
    case n > len(s):
        return 0, false
    }

    hash, pow := hash_str_rabin_karp_reverse(substr)
    last := len(s) - n
    h: u32
    for i := len(s)-1; i >= last; i -= 1 {
        h = h*PRIME_RABIN_KARP + u32(s[i])
    }
    if h == hash && s[last:] == substr {
        return last, true
    }

    for i := int(last) - 1; i >= 0; i -= 1 {
        h *= PRIME_RABIN_KARP
        h += u32(s[i])
        h -= pow * u32(s[uint(i) + n])
        if h == hash && s[i:i + int(n)] == substr {
            return uint(i), true
        }
    }
    return 0, false
}

/*
Example:
    index_any("test", "s")
    index_any("test", "se")
    index_any("test", "et")
    index_any("test", "set")
    index_any("test", "x")
Output:
    2, true
    1, true
    0, true
    0, true
    0, false
*/
index_any :: proc(s, chars: string) -> (res: uint, found: bool) {
    if chars == "" {
        return 0, false
    }
    
    if len(chars) == 1 {
        r := rune(chars[0])
        if r >= utf8.RUNE_SELF {
            r = utf8.RUNE_ERROR
        }
        return index_rune(s, r)
    }
    
    if len(s) > 8 {
        if as, ok := ascii.ascii_set_create(chars); ok {
            for i in 0..<len(s) {
                if ascii.ascii_set_contains(as, s[i]) {
                    return i, true
                }
            }
            return 0, false
        }
    }

    for c, i in s {
        _, r_found := index_rune(chars, c)
        if r_found {
            return i, true
        }
    }
    return 0, false
}

/*
Example:
    last_index_any("test", "s")
    last_index_any("test", "se")
    last_index_any("test", "et")
    last_index_any("test", "set")
    last_index_any("test", "x")
Output:
    2, true
    2, true
    3, true
    3, true
    0, false
*/
last_index_any :: proc(s, chars: string) -> (res: uint, found: bool) {
    if chars == "" {
        return 0, false
    }
    
    if len(s) == 1 {
        r := rune(s[0])
        if r >= utf8.RUNE_SELF {
            r = utf8.RUNE_ERROR
        }
        return index_rune(chars, r)
    }
    
    if len(s) > 8 {
        if as, ok := ascii.ascii_set_create(chars); ok {
            for i := int(len(s)) - 1; i >= 0; i -= 1 {
                if ascii.ascii_set_contains(as, s[i]) {
                    return uint(i), true
                }
            }
            return 0, false
        }
    }
    
    if len(chars) == 1 {
        r := rune(chars[0])
        if r >= utf8.RUNE_SELF {
            r = utf8.RUNE_ERROR
        }
        for i := len(s); i > 0; /**/ {
            c, w := utf8.last_rune_in_string(s[:i])
            i -= w
            if c == r {
                return i, true
            }
        }
        return 0, false
    }

    for i := len(s); i > 0; /**/ {
        r, w := utf8.last_rune_in_string(s[:i])
        i -= w
        _, r_found := index_rune(chars, r)
        if r_found {
            return i, true
        }
    }
    return 0, false
}

/*
Finds the first occurrence of any substring in `substrs` within `s`
*/
index_multi :: proc(s: string, substrs: []string) -> (idx: uint, found: bool) {
    if s == "" || len(substrs) <= 0 {
        return
    }
    // disallow "" substr
    for substr in substrs {
        if len(substr) == 0 {
            return
        }
    }

    lowest_index := len(s)
    found = false
    for substr in substrs {
        haystack := s[:min(len(s), lowest_index + len(substr))]
        if i, idx_found := index(haystack, substr); idx_found {
            if i < lowest_index {
                lowest_index = i
                found = true
            }
        }
    }

    if found {
        idx = lowest_index
    }
    return
}
/* 
Returns the u8 offset of the first u8 `c` in the string s it finds, -1 when not found.
NOTE: Can't find UTF-8 based runes.
Example:
    index_byte("test", 't')
    index_byte("test", 'e')
    index_byte("test", 'x')
    index_byte("teäst", 'ä')
Output:
    0
    1
    -1
    -1
*/
index_byte :: proc(s: string, c: u8) -> (res: uint, found: bool) {
    return #force_inline bytes.index_byte(transmute([]u8)s, c)
}

/* 
Returns the u8 offset of the last u8 `c` in the string `s`, -1 when not found.
NOTE: Can't find UTF-8 based runes.
Example:
    last_index_byte("test", 't')
    last_index_byte("test", 'e')
    last_index_byte("test", 'x')
    last_index_byte("teäst", 'ä')
Output:
    3
    1
    -1
    -1
*/
last_index_byte :: proc(s: string, c: u8) -> (res: uint, found: bool) {
    return #force_inline bytes.last_index_byte(transmute([]u8)s, c)
}




/*
Example:
    count("abbccc", "a")
    count("abbccc", "b")
    count("abbccc", "c")
    count("abbccc", "ab")
    count("abbccc", " ")
Output:
    1
    2
    3
    1
    0
*/
count :: proc(s, substr: string) -> (res: uint) {
    if len(substr) == 0 { // special case
        return utf8.string_rune_count(s) + 1
    }
    if len(substr) == 1 {
        c := substr[0]
        switch len(s) {
        case 0:
            return 0
        case 1:
            return uint(s[0] == c)
        }
        n: uint = 0
        for i: uint = 0; i < len(s); i += 1 {
            if s[i] == c {
                n += 1
            }
        }
        return n
    }

    // TODO(bill): Use a non-brute for approach
    n: uint
    str := s
    for {
        i, found := index(str, substr)
        if !found {
            return n
        }
        n += 1
        str = str[i + len(substr):]
    }
    return n
}

/*
Computes the Levenshtein edit distance between two strings
NOTE: Does not perform internal allocation if length of string `b`, in runes, is smaller than 64
NOTE: This implementation is a single-row-version of the Wagner–Fischer algorithm, based on C code by Martin Ettl.
*/
levenshtein_distance :: proc(a, b: string, allocator: mem.Allocator, loc := #caller_location) -> (res: uint, err: mem.Allocator_Error) {
    LEVENSHTEIN_DEFAULT_COSTS: []uint : {
        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,
        10,  11,  12,  13,  14,  15,  16,  17,  18,  19,
        20,  21,  22,  23,  24,  25,  26,  27,  28,  29,
        30,  31,  32,  33,  34,  35,  36,  37,  38,  39,
        40,  41,  42,  43,  44,  45,  46,  47,  48,  49,
        50,  51,  52,  53,  54,  55,  56,  57,  58,  59,
        60,  61,  62,  63,
    }

    m := utf8.string_rune_count(a)
    n := utf8.string_rune_count(b)

    if m == 0 {
        return n, nil
    }
    if n == 0 {
        return m, nil
    }

    costs: []uint

    if n + 1 > len(LEVENSHTEIN_DEFAULT_COSTS) {
        costs = slice.create([]uint, n + 1, allocator, loc) or_return
        for k in 0..=n {
            costs[k] = k
        }
    } else {
        costs = LEVENSHTEIN_DEFAULT_COSTS
    }

    defer if n + 1 > len(LEVENSHTEIN_DEFAULT_COSTS) {
        _ = slice.delete(costs, allocator)
    }

    i: uint
    for c1 in a {
        costs[0] = i + 1
        corner := i
        j: int
        for c2 in b {
            upper := costs[j + 1]
            if c1 == c2 {
                costs[j + 1] = corner
            } else {
                t := upper if upper < corner else corner
                costs[j + 1] = (costs[j] if costs[j] < t else t) + 1
            }

            corner = upper
            j += 1
        }

        i += 1
    }

    return costs[n], nil
}

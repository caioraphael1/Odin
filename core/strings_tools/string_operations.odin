import "base:internal"
import "base:mem"
import "base:dyn_array"
import "base:slice"
import "base:strings"

import "core:io"
import "core:unicode"
import "core:unicode/utf8"



string_from_null_terminated_ptr :: proc(ptr: [^]byte, len: int) -> (res: string) {
    s := string(ptr[:len])
    s = truncate_to_byte(s, 0)
    return s
}

/*
Truncates a string `str` at the first occurrence of char/byte `b`
*/
truncate_to_byte :: proc(str: string, b: byte) -> (res: string) {
    n := index_byte(str, b)
    if n < 0 {
        n = len(str)
    }
    return str[:n]
}

/*
Truncates a string `str` at the first occurrence of rune `r` as a slice of the original, entire string if not found
*/
truncate_to_rune :: proc(str: string, r: rune) -> (res: string) {
    n := index_rune(str, r)
    if n < 0 {
        n = len(str)
    }
    return str[:n]
}


/*
Clones a string from a null-terminated cstring `ptr` and a byte length `len`
NOTE: Truncates at the first null-byte encountered or the byte length.
*/
clone_from_cstring_bounded :: proc(ptr: cstring, len: int, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    s := strings.string_from_ptr((^u8)(ptr), len)
    s = truncate_to_byte(s, 0)
    return strings.string_clone(s, allocator, loc)
}




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
    return index(s, substr) >= 0
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
    return index_any(s, chars) >= 0
}


contains_space :: proc(s: string) -> (res: bool) {
    for c in s {
        if strings.rune_is_space(c) {
            return true
        }
    }
    return false
}

/*
Returns the UTF-8 rune count of the string `s`

Example:
    fmt.println(strings.rune_count("test"))
    fmt.println(strings.rune_count("testö")) // where len("testö") == 6
Output:
    4
    5
*/
rune_count :: proc(s: string) -> (res: int) {
    return utf8.rune_count_in_string(s)
}

/*
Returns whether the strings `u` and `v` are the same alpha characters, ignoring different casings
Works with UTF-8 string content

Example:
    fmt.println(strings_tools.equal_fold("test", "test"))
    fmt.println(strings_tools.equal_fold("Test", "test"))
    fmt.println(strings_tools.equal_fold("Test", "tEsT"))
    fmt.println(strings_tools.equal_fold("test", "tes"))
Output:
    true
    true
    true
    false
*/
equal_fold :: proc(u, v: string) -> (res: bool) {
    s, t := u, v
    loop: for s != "" && t != "" {
        sr, tr: rune
        if s[0] < utf8.RUNE_SELF {
            sr, s = rune(s[0]), s[1:]
        } else {
            r, size := utf8.decode_rune_in_string(s)
            sr, s = r, s[size:]
        }
        if t[0] < utf8.RUNE_SELF {
            tr, t = rune(t[0]), t[1:]
        } else {
            r, size := utf8.decode_rune_in_string(t)
            tr, t = r, t[size:]
        }

        if tr == sr { // easy case
            continue loop
        }

        if tr < sr {
            tr, sr = sr, tr
        }

        if tr < utf8.RUNE_SELF {
            switch sr {
            case 'A'..='Z':
                if tr == (sr+'a')-'A' {
                    continue loop
                }
            }
            return false
        }

        r := unicode.simple_fold(sr)
        for r != sr && r < tr {
            r = unicode.simple_fold(sr)
        }
        if r == tr {
            continue loop
        }
        return false
    }

    return s == t
}


/*
Splits the input string `s` into a slice of substrings separated by the specified `sep` string
NOTE: Allocation occurs for the array, the splits are all views of the original string.
*/
@(private)
_split :: proc(s_, sep: string, sep_save, n_: int, allocator: mem.Allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) {
    s, n := s_, n_

    if n == 0 {
        return nil, nil
    }

    if sep == "" {
        l := utf8.rune_count_in_string(s)
        if n < 0 || n > l {
            n = l
        }

        res = slice.create([]string, n, allocator, loc) or_return
        for i := 0; i < n-1; i += 1 {
            _, w := utf8.decode_rune_in_string(s)
            res[i] = s[:w]
            s = s[w:]
        }
        if n > 0 {
            res[n-1] = s
        }
        return res[:], nil
    }

    if n < 0 {
        n = count(s, sep) + 1
    }

    res = slice.create([]string, n, allocator, loc) or_return

    n -= 1

    i := 0
    for ; i < n; i += 1 {
        m := index(s, sep)
        if m < 0 {
            break
        }
        res[i] = s[:m+sep_save]
        s = s[m+len(sep):]
    }
    res[i] = s

    return res[:i+1], nil
}

/*
Splits a string into parts based on a separator.
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    s := "aaa.bbb.ccc.ddd.eee"    // 5 parts
    ss := strings_tools.split(s, ".")
    fmt.println(ss)
Output:
    ["aaa", "bbb", "ccc", "ddd", "eee"]
*/
split :: proc(s, sep: string, allocator: mem.Allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) {
    return _split(s, sep, 0, -1, allocator, loc)
}

/*
Splits a string into parts based on a separator. If n < count of seperators, the remainder of the string is returned in the last entry.
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    s := "aaa.bbb.ccc.ddd.eee"  // 5 parts present
    ss := strings.split_n(s, ".",3) // total of 3 wanted
    fmt.println(ss)
Output:
    ["aaa", "bbb", "ccc.ddd.eee"]
*/
split_n :: proc(s, sep: string, n: int, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    return _split(s, sep, 0, n, allocator)
}

/*
Splits a string into parts after the separator, retaining it in the substrings.
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    a := "aaa.bbb.ccc.ddd.eee"         // 5 parts
    aa := strings.split_after(a, ".")
    fmt.println(aa)
Output:
    ["aaa.", "bbb.", "ccc.", "ddd.", "eee"]
*/
split_after :: proc(s, sep: string, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    return _split(s, sep, len(sep), -1, allocator)
}

/*
Splits a string into a total of `n` parts after the separator.
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    a := "aaa.bbb.ccc.ddd.eee"
    aa := strings.split_after_n(a, ".", 3)
    fmt.println(aa)
Output:
    ["aaa.", "bbb.", "ccc.ddd.eee"]
*/
split_after_n :: proc(s, sep: string, n: int, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    return _split(s, sep, len(sep), n, allocator)
}

/*
Searches for the first occurrence of `sep` in the given string and returns the substring
up to (but not including) the separator, as well as a boolean indicating success.
*/
@(private)
_split_iterator :: proc(s: ^string, sep: string, sep_save: int) -> (res: string, ok: bool) {
    m: int
    if sep == "" {
        if len(s) == 0 {
            m = -1
        } else {
            _, w := utf8.decode_rune_in_string(s^)
            m = w
        }
    } else {
        m = index(s^, sep)
    }
    if m < 0 {
        // not found
        res = s[:]
        ok = res != ""
        s^ = s[len(s):]
    } else {
        res = s[:m+sep_save]
        ok = true
        s^ = s[m+len(sep):]
    }
    return
}

/*
Splits the input string by the byte separator in an iterator fashion.

Example:
    text := "a.b.c.d.e"
    for str in strings.split_by_byte_iterator(&text, '.') {
        fmt.println(str) // every loop -> a b c d e
    }
Output:
    a
    b
    c
    d
    e
*/
split_by_byte_iterator :: proc(s: ^string, sep: u8) -> (res: string, ok: bool) {
    m := index_byte(s^, sep)
    if m < 0 {
        // not found
        res = s[:]
        ok = res != ""
        s^ = {}
    } else {
        res = s[:m]
        ok = true
        s^ = s[m+1:]
    }
    return
}

/*
Splits the input string by the separator string in an iterator fashion.

Example:
    text := "a.b.c.d.e"
    for str in strings_tools.split_iterator(&text, ".") {
        fmt.println(str)
    }
Output:
    a
    b
    c
    d
    e
*/
split_iterator :: proc(s: ^string, sep: string) -> (res: string, ok: bool) {
    return _split_iterator(s, sep, 0)
}

/*
Splits the input string after every separator string in an iterator fashion.

Example:
    text := "a.b.c.d.e"
    for str in strings.split_after_iterator(&text, ".") {
        fmt.println(str)
    }
Output:
    a.
    b.
    c.
    d.
    e
*/
split_after_iterator :: proc(s: ^string, sep: string) -> (res: string, ok: bool) {
    return _split_iterator(s, sep, len(sep))
}

/*
Trims the carriage return character from the end of the input string.
*/
@(private)
_trim_cr :: proc(s: string) -> (res: string) {
    n := len(s)
    if n > 0 {
        if s[n-1] == '\r' {
            return s[:n-1]
        }
    }
    return s
}

/*
Splits the input string at every line break `\n`.

Example:
    a := "a\nb\nc\nd\ne"
    b := strings.split_lines(a)
    fmt.println(b)
Output:
    ["a", "b", "c", "d", "e"]
*/
split_lines :: proc(s: string, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    sep :: "\n"
    lines := _split(s, sep, 0, -1, allocator) or_return
    for &line in lines {
        line = _trim_cr(line)
    }
    return lines, nil
}

/*
Splits the input string at every line break `\n` for `n` parts.
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    a := "a\nb\nc\nd\ne"
    b := strings.split_lines_n(a, 3)
    fmt.println(b)
Output:
    ["a", "b", "c\nd\ne"]
*/
split_lines_n :: proc(s: string, n: int, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    sep :: "\n"
    lines := _split(s, sep, 0, n, allocator) or_return
    for &line in lines {
        line = _trim_cr(line)
    }
    return lines, nil
}

/*
Splits the input string at every line break `\n` leaving the `\n` in the resulting strings.
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    a := "a\nb\nc\nd\ne"
    b := strings.split_lines_after(a)
    fmt.println(b)
Output:
    ["a\n", "b\n", "c\n", "d\n", "e"]
*/
split_lines_after :: proc(s: string, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    sep :: "\n"
    lines := _split(s, sep, len(sep), -1, allocator) or_return
    for &line in lines {
        line = _trim_cr(line)
    }
    return lines, nil
}

/*
Splits the input string at every line break `\n` leaving the `\n` in the resulting strings.
Only runs for n parts.
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    a := "a\nb\nc\nd\ne"
    b := strings.split_lines_after_n(a, 3)
    fmt.println(b)
Output:
    ["a\n", "b\n", "c\nd\ne"]
*/
split_lines_after_n :: proc(s: string, n: int, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    sep :: "\n"
    lines := _split(s, sep, len(sep), n, allocator) or_return
    for &line in lines {
        line = _trim_cr(line)
    }
    return lines, nil
}

/*
Splits the input string at every line break `\n`.
Returns the current split string every iteration until the string is consumed.

Example:
    text := "a\nb\nc\nd\ne"
    for str in strings.split_lines_iterator(&text) {
        fmt.print(str)    // every loop -> a b c d e
    }
    fmt.print("\n")
Output:
    abcde
*/
split_lines_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
    sep :: "\n"
    line = _split_iterator(s, sep, 0) or_return
    return _trim_cr(line), true
}

/*
Splits the input string at every line break `\n`.
Returns the current split string with line breaks included every iteration until the string is consumed.

Example:
    text := "a\nb\nc\nd\ne\n"
    for str in strings.split_lines_after_iterator(&text) {
        fmt.print(str) // every loop -> a\n b\n c\n d\n e\n
    }
Output:
    a
    b
    c
    d
    e
*/
split_lines_after_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
    sep :: "\n"
    line = _split_iterator(s, sep, len(sep)) or_return
    return _trim_cr(line), true
}


/*
Returns the byte offset of the first rune `r` in the string `s` it finds, -1 when not found.
Invalid runes return -1

Example:
    fmt.println(strings.index_rune("abcädef", 'x'))
    fmt.println(strings.index_rune("abcädef", 'a'))
    fmt.println(strings.index_rune("abcädef", 'b'))
    fmt.println(strings.index_rune("abcädef", 'c'))
    fmt.println(strings.index_rune("abcädef", 'ä'))
    fmt.println(strings.index_rune("abcädef", 'd'))
    fmt.println(strings.index_rune("abcädef", 'e'))
    fmt.println(strings.index_rune("abcädef", 'f'))
Output:
    -1
    0
    1
    2
    3
    5
    6
    7
*/
index_rune :: proc(s: string, r: rune) -> (res: int) {
    switch {
    case u32(r) < utf8.RUNE_SELF:
        return index_byte(s, byte(r))

    case r == utf8.RUNE_ERROR:
        for c, i in s {
            if c == utf8.RUNE_ERROR {
                return i
            }
        }
        return -1

    case !utf8.valid_rune(r):
        return -1
    }

    b, w := utf8.encode_rune(r)
    return index(s, string(b[:w]))
}

@(private) PRIME_RABIN_KARP :: 16777619
/*
Returns the byte offset of the string `substr` in the string `s`, -1 when not found.

Example:
    fmt.println(strings.index("test", "t"))
    fmt.println(strings.index("test", "te"))
    fmt.println(strings.index("test", "st"))
    fmt.println(strings.index("test", "tt"))
Output:
    0
    0
    2
    -1
*/
index :: proc(s, substr: string) -> (res: int) {
    hash_str_rabin_karp :: proc(s: string) -> (hash: u32 = 0, pow: u32 = 1) {
        for i := 0; i < len(s); i += 1 {
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
        return 0
    case n == 1:
        return index_byte(s, substr[0])
    case n == len(s):
        if s == substr {
            return 0
        }
        return -1
    case n > len(s):
        return -1
    }

    hash, pow := hash_str_rabin_karp(substr)
    h: u32
    for i := 0; i < n; i += 1 {
        h = h*PRIME_RABIN_KARP + u32(s[i])
    }
    if h == hash && s[:n] == substr {
        return 0
    }
    for i := n; i < len(s); /**/ {
        h *= PRIME_RABIN_KARP
        h += u32(s[i])
        h -= pow * u32(s[i-n])
        i += 1
        if h == hash && s[i-n:i] == substr {
            return i - n
        }
    }
    return -1
}

/*
Returns the last byte offset of the string `substr` in the string `s`, -1 when not found.

Example:
    fmt.println(strings_tools.last_index("test", "t"))
    fmt.println(strings_tools.last_index("test", "te"))
    fmt.println(strings_tools.last_index("test", "st"))
    fmt.println(strings_tools.last_index("test", "tt"))
Output:
    3
    0
    2
    -1
*/
last_index :: proc(s, substr: string) -> (res: int) {
    hash_str_rabin_karp_reverse :: proc(s: string) -> (hash: u32 = 0, pow: u32 = 1) {
        for i := len(s) - 1; i >= 0; i -= 1 {
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
        return len(s)
    case n == 1:
        return last_index_byte(s, substr[0])
    case n == len(s):
        return 0 if substr == s else -1
    case n > len(s):
        return -1
    }

    hash, pow := hash_str_rabin_karp_reverse(substr)
    last := len(s) - n
    h: u32
    for i := len(s)-1; i >= last; i -= 1 {
        h = h*PRIME_RABIN_KARP + u32(s[i])
    }
    if h == hash && s[last:] == substr {
        return last
    }

    for i := last-1; i >= 0; i -= 1 {
        h *= PRIME_RABIN_KARP
        h += u32(s[i])
        h -= pow * u32(s[i+n])
        if h == hash && s[i:i+n] == substr {
            return i
        }
    }
    return -1
}

/*
Returns the index of any first char of `chars` found in `s`, -1 if not found.

Example:
    fmt.println(strings.index_any("test", "s"))
    fmt.println(strings.index_any("test", "se"))
    fmt.println(strings.index_any("test", "et"))
    fmt.println(strings.index_any("test", "set"))
    fmt.println(strings.index_any("test", "x"))
Output:
    2
    1
    0
    0
    -1
*/
index_any :: proc(s, chars: string) -> (res: int) {
    if chars == "" {
        return -1
    }
    
    if len(chars) == 1 {
        r := rune(chars[0])
        if r >= utf8.RUNE_SELF {
            r = utf8.RUNE_ERROR
        }
        return index_rune(s, r)
    }
    
    if len(s) > 8 {
        if as, ok := ascii_set_make(chars); ok {
            for i in 0..<len(s) {
                if ascii_set_contains(as, s[i]) {
                    return i
                }
            }
            return -1
        }
    }

    for c, i in s {
        if index_rune(chars, c) >= 0 {
            return i
        }
    }
    return -1
}

/*
Finds the last occurrence of any character in `chars` within `s`. Iterates in reverse.

Example:
    fmt.println(strings_tools.last_index_any("test", "s"))
    fmt.println(strings_tools.last_index_any("test", "se"))
    fmt.println(strings_tools.last_index_any("test", "et"))
    fmt.println(strings_tools.last_index_any("test", "set"))
    fmt.println(strings_tools.last_index_any("test", "x"))
Output:
    2
    2
    3
    3
    -1
*/
last_index_any :: proc(s, chars: string) -> (res: int) {
    if chars == "" {
        return -1
    }
    
    if len(s) == 1 {
        r := rune(s[0])
        if r >= utf8.RUNE_SELF {
            r = utf8.RUNE_ERROR
        }
        i := index_rune(chars, r)
        return i if i < 0 else 0
    }
    
    if len(s) > 8 {
        if as, ok := ascii_set_make(chars); ok {
            for i := len(s)-1; i >= 0; i -= 1 {
                if ascii_set_contains(as, s[i]) {
                    return i
                }
            }
            return -1
        }
    }
    
    if len(chars) == 1 {
        r := rune(chars[0])
        if r >= utf8.RUNE_SELF {
            r = utf8.RUNE_ERROR
        }
        for i := len(s); i > 0; /**/ {
            c, w := utf8.decode_last_rune_in_string(s[:i])
            i -= w
            if c == r {
                return i
            }
        }
        return -1
    }

    for i := len(s); i > 0; /**/ {
        r, w := utf8.decode_last_rune_in_string(s[:i])
        i -= w
        if index_rune(chars, r) >= 0 {
            return i
        }
    }
    return -1
}

/*
Finds the first occurrence of any substring in `substrs` within `s`
*/
index_multi :: proc(s: string, substrs: []string) -> (idx: int, width: int) {
    idx = -1
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
    found := false
    for substr in substrs {
        haystack := s[:min(len(s), lowest_index + len(substr))]
        if i := index(haystack, substr); i >= 0 {
            if i < lowest_index {
                lowest_index = i
                width = len(substr)
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
Counts the number of non-overlapping occurrences of `substr` in `s`

Example:
    fmt.println(strings_tools.count("abbccc", "a"))
    fmt.println(strings_tools.count("abbccc", "b"))
    fmt.println(strings_tools.count("abbccc", "c"))
    fmt.println(strings_tools.count("abbccc", "ab"))
    fmt.println(strings_tools.count("abbccc", " "))
Output:
    1
    2
    3
    1
    0
*/
count :: proc(s, substr: string) -> (res: int) {
    if len(substr) == 0 { // special case
        return rune_count(s) + 1
    }
    if len(substr) == 1 {
        c := substr[0]
        switch len(s) {
        case 0:
            return 0
        case 1:
            return int(s[0] == c)
        }
        n := 0
        for i := 0; i < len(s); i += 1 {
            if s[i] == c {
                n += 1
            }
        }
        return n
    }

    // TODO(bill): Use a non-brute for approach
    n := 0
    str := s
    for {
        i := index(str, substr)
        if i == -1 {
            return n
        }
        n += 1
        str = str[i+len(substr):]
    }
    return n
}

/*
Replaces all occurrences of `old` in `s` with `new`

Example:
    fmt.println(strings_tools.replace_all("xyzxyz", "xyz", "abc"))
    fmt.println(strings_tools.replace_all("xyzxyz", "abc", "xyz"))
    fmt.println(strings_tools.replace_all("xyzxyz", "xy", "z"))
Output:
    abcabc true
    xyzxyz false
    zzzz true
*/
replace_all :: proc(s, old, new: string, allocator: mem.Allocator) -> (output: string, was_allocation: bool) {
    return replace(s, old, new, -1, allocator)
}

/*
Replaces n instances of old in the string s with the new string

Example:
    fmt.println(strings.replace("xyzxyz", "xyz", "abc", 2))
    fmt.println(strings.replace("xyzxyz", "xyz", "abc", 1))
    fmt.println(strings.replace("xyzxyz", "abc", "xyz", -1))
    fmt.println(strings.replace("xyzxyz", "xy", "z", -1))
Output:
    abcabc true
    abcxyz true
    xyzxyz false
    zzzz true
*/
replace :: proc(s, old, new: string, n: int, allocator: mem.Allocator, loc := #caller_location) -> (output: string, was_allocation: bool) {
    if old == new || n == 0 {
        was_allocation = false
        output = s
        return
    }
    byte_count := n
    if m := count(s, old); m == 0 {
        was_allocation = false
        output = s
        return
    } else if n < 0 || m < n {
        byte_count = m
    }


    t, err := slice.create([]byte, len(s) + byte_count*(len(new) - len(old)), allocator, loc)
    if err != nil {
        return
    }
    was_allocation = true

    w := 0
    start := 0
    for i := 0; i < byte_count; i += 1 {
        j := start
        if len(old) == 0 {
            if i > 0 {
                _, width := utf8.decode_rune_in_string(s[start:])
                j += width
            }
        } else {
            j += index(s[start:], old)
        }
        w += slice.copy_from_string(t[w:], s[start:j])
        w += slice.copy_from_string(t[w:], new)
        start = j + len(old)
    }
    w += slice.copy_from_string(t[w:], s[start:])
    output = string(t[0:w])
    return
}

/*
Removes the key string `n` times from the `s` string

Example:
    fmt.println(strings.remove("abcabc", "abc", 1))
    fmt.println(strings.remove("abcabc", "abc", -1))
    fmt.println(strings.remove("abcabc", "a", -1))
    fmt.println(strings.remove("abcabc", "x", -1))
Output:
    abc true
     true
    bcbc true
    abcabc false
*/
remove :: proc(s, key: string, n: int, allocator: mem.Allocator) -> (output: string, was_allocation: bool) {
    return replace(s, key, "", n, allocator)
}

/*
Removes all the `key` string instances from the `s` string

Example:
    fmt.println(strings_tools.remove_all("abcabc", "abc"))
    fmt.println(strings_tools.remove_all("abcabc", "a"))
    fmt.println(strings_tools.remove_all("abcabc", "x"))
Output:
     true
    bcbc true
    abcabc false
*/
remove_all :: proc(s, key: string, allocator: mem.Allocator) -> (output: string, was_allocation: bool) {
    return remove(s, key, -1, allocator)
}





/*
Trims the cutset string from the `s` string
*/
trim_left :: proc(s: string, cutset: string) -> (res: string) {
    if s == "" || cutset == "" {
        return s
    }
    state := cutset
    return _trim_left_proc_with_state(s, _is_in_cutset, &state)
}

/*
Trims the cutset string from the `s` string from the right
*/
trim_right :: proc(s: string, cutset: string) -> (res: string) {
    if s == "" || cutset == "" {
        return s
    }
    state := cutset
    return _trim_right_proc_with_state(s, _is_in_cutset, &state)
}

/*
Trims the cutset string from the `s` string, both from left and right
*/
trim :: proc(s: string, cutset: string) -> (res: string) {
    return trim_right(trim_left(s, cutset), cutset)
}

/*
Trims until a valid non-space rune from the left, "\t\txyz\t\t" -> "xyz\t\t"
*/
trim_left_space :: proc(s: string) -> (res: string) {
    return _trim_left_proc(s, strings.rune_is_space)
}

/*
Trims from the right until a valid non-space rune, "\t\txyz\t\t" -> "\t\txyz"
*/
trim_right_space :: proc(s: string) -> (res: string) {
    return _trim_right_proc(s, strings.rune_is_space)
}

/*
Trims from both sides until a valid non-space rune, "\t\txyz\t\t" -> "xyz"
*/
trim_space :: proc(s: string) -> (res: string) {
    return trim_right_space(trim_left_space(s))
}

/*
Trims null runes from the left, "\x00\x00testing\x00\x00" -> "testing\x00\x00"
*/
trim_left_null :: proc(s: string) -> (res: string) {
    return _trim_left_proc(s, strings.rune_is_null)
}

/*
Trims null runes from the right, "\x00\x00testing\x00\x00" -> "\x00\x00testing"
*/
trim_right_null :: proc(s: string) -> (res: string) {
    return _trim_right_proc(s, strings.rune_is_null)
}

/*
Trims null runes from both sides, "\x00\x00testing\x00\x00" -> "testing"
*/
trim_null :: proc(s: string) -> (res: string) {
    return trim_right_null(trim_left_null(s))
}

/*
Trims a `prefix` string from the start of the `s` string and returns the trimmed string

Inputs:
- s: The input string
- prefix: The prefix string to be removed

Returns:
- res: The trimmed string as a slice of original, or the input string if no prefix was found

Example:

    import "core:fmt"
    import "core:strings"

    trim_prefix_example :: proc() {
        fmt.println(strings_tools.trim_prefix("testing", "test"))
        fmt.println(strings_tools.trim_prefix("testing", "abc"))
    }

Output:

    ing
    testing

*/
trim_prefix :: proc(s, prefix: string) -> (res: string) {
    if strings.string_has_prefix(s, prefix) {
        return s[len(prefix):]
    }
    return s
}

/*
Trims a `suffix` string from the end of the `s` string and returns the trimmed string

Inputs:
- s: The input string
- suffix: The suffix string to be removed

Returns:
- res: The trimmed string as a slice of original, or the input string if no suffix was found

Example:

    import "core:fmt"
    import "core:strings"

    trim_suffix_example :: proc() {
        fmt.println(strings.trim_suffix("todo.txt", ".txt"))
        fmt.println(strings.trim_suffix("todo.doc", ".txt"))
    }

Output:

    todo
    todo.doc

*/
trim_suffix :: proc(s, suffix: string) -> (res: string) {
    if strings.string_has_suffix(s, suffix) {
        return s[:len(s)-len(suffix)]
    }
    return s
}


/*
Find the index of the first rune `r` in string `s` for which procedure `p` returns the same as truth, or -1 if no such rune appears.

Example:
    call :: proc(r: rune) -> bool {
        return r == 'a'
    }
    fmt.println(strings._index_proc("abcabc", call))
    fmt.println(strings._index_proc("cbacba", call))
    fmt.println(strings._index_proc("cbacba", call, false))
    fmt.println(strings._index_proc("abcabc", call, false))
    fmt.println(strings._index_proc("xyz", call))
Output:
    0
    2
    0
    1
    -1
*/
@(private)
_index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> (res: int) {
    for r, i in s {
        if p(r) == truth {
            return i
        }
    }
    return -1
}

@(private)
_index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (res: int) {
    for r, i in s {
        if p(state, r) == truth {
            return i
        }
    }
    return -1
}

/*
Trims the input string `s` from the left until the procedure `p` returns false

Example:
    find :: proc(r: rune) -> bool {
        return r == 'x'
    }
    fmt.println(strings._trim_left_proc("xxxxxxtesting", find))
Output:
    testing
*/
@(private)
_trim_left_proc :: proc(s: string, p: proc(rune) -> bool) -> (res: string) {
    i := _index_proc(s, p, false)
    if i == -1 {
        return ""
    }
    return s[i:]
}

/*
Trims the input string `s` from the left until the procedure `p` with state returns false
*/
@(private)
_trim_left_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> (res: string) {
    i := _index_proc_with_state(s, p, state, false)
    if i == -1 {
        return ""
    }
    return s[i:]
}

// Finds the index of the *last* rune in the string s for which the procedure p returns the same value as truth
@(private)
_last_index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> (res: int) {
    // TODO(bill): Probably use Rabin-Karp Search
    for i := len(s); i > 0; {
        r, size := utf8.decode_last_rune_in_string(s[:i])
        i -= size
        if p(r) == truth {
            return i
        }
    }
    return -1
}

// Same as `_index_proc_with_state`, runs through the string in reverse
@(private)
last_index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (res: int) {
    // TODO(bill): Probably use Rabin-Karp Search
    for i := len(s); i > 0; {
        r, size := utf8.decode_last_rune_in_string(s[:i])
        i -= size
        if p(state, r) == truth {
            return i
        }
    }
    return -1
}


/*
Trims the input string `s` from the right until the procedure `p` returns `false`

Example:
    find :: proc(r: rune) -> bool {
        return r != 't'
    }
    fmt.println(strings._trim_right_proc("testing", find))
Output:
    test
*/
@(private)
_trim_right_proc :: proc(s: string, p: proc(rune) -> bool) -> (res: string) {
    i := _last_index_proc(s, p, false)
    if i >= 0 && s[i] >= utf8.RUNE_SELF {
        _, w := utf8.decode_rune_in_string(s[i:])
        i += w
    } else {
        i += 1
    }
    return s[0:i]
}

/*
Trims the input string `s` from the right until the procedure `p` with state returns `false`
*/
@(private)
_trim_right_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> (res: string) {
    i := last_index_proc_with_state(s, p, state, false)
    if i >= 0 && s[i] >= utf8.RUNE_SELF {
        _, w := utf8.decode_rune_in_string(s[i:])
        i += w
    } else {
        i += 1
    }
    return s[0:i]
}


// Procedure for `trim_*_proc` variants, which has a string rawptr cast + rune comparison
@(private)
_is_in_cutset :: proc(state: rawptr, r: rune) -> (res: bool) {
    cutset := (^string)(state)^
    for c in cutset {
        if r == c {
            return true
        }
    }
    return false
}





/*
Splits the input string `s` by all possible `substrs` and returns an allocated array of strings
NOTE: Allocation occurs for the array, the splits are all views of the original string.

Example:
    splits := [?]string { "---", "~~~", ".", "_", "," }
    res := strings.split_multi("testing,this.out_nice---done~~~last", splits[:])
    fmt.println(res) // -> [testing, this, out, nice, done, last]
Output:
    ["testing", "this", "out", "nice", "done", "last"]
*/
split_multi :: proc(s: string, substrs: []string, allocator: mem.Allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) #no_bounds_check {
    if s == "" || len(substrs) <= 0 {
        return nil, nil
    }

    // disallow "" substr
    for substr in substrs {
        if len(substr) == 0 {
            return nil, nil
        }
    }

    // calculate the needed len of `results`
    n := 1
    for it := s; len(it) > 0; {
        i, w := index_multi(it, substrs)
        if i < 0 {
            break
        }
        n += 1
        it = it[i+w:]
    }

    results := dyn_array.create_len_cap([dynamic]string, 0, n, allocator, loc) or_return
    {
        it := s
        for len(it) > 0 {
            i, w := index_multi(it, substrs)
            if i < 0 {
                break
            }
            part := it[:i]
            _ = dyn_array.append(&results, part)
            it = it[i+w:]
        }
        _ = dyn_array.append(&results, it)
    }
    internal.assert(len(results) == n)
    return results[:], nil
}

/*
Splits the input string `s` by all possible `substrs` in an iterator fashion. The full string is returned if no match.

Example:
    it := "testing,this.out_nice---done~~~last"
    splits := [?]string { "---", "~~~", ".", "_", "," }
    for str in strings.split_multi_iterate(&it, splits[:]) {
        fmt.println(str)
    }
Output:
    testing
    this
    out
    nice
    done
    last
*/
split_multi_iterate :: proc(it: ^string, substrs: []string) -> (res: string, ok: bool) #no_bounds_check {
    if len(it) == 0 || len(substrs) <= 0 {
        return
    }

    // disallow "" substr
    for substr in substrs {
        if len(substr) == 0 {
            return
        }
    }

    // calculate the needed len of `results`
    i, w := index_multi(it^, substrs)
    if i >= 0 {
        res = it[:i]
        it^ = it[i+w:]
    } else {
        // last value
        res = it^
        it^ = it[len(it):]
    }
    ok = true
    return
}

/*
Replaces invalid UTF-8 characters in the input string with a specified replacement string. Adjacent invalid bytes are only replaced once.

Example:
    text := "Hello\xC0\x80World"
    fmt.println(strings.scrub(text, "?")) // -> "Hello?World"
Output:
    Hello?
*/
scrub :: proc(s: string, replacement: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    str := s
    b: Builder
    builder_init_len_cap(&b, 0, len(s), allocator) or_return

    has_error := false
    cursor := 0
    origin := str

    for len(str) > 0 {
        r, w := utf8.decode_rune_in_string(str)

        if r == utf8.RUNE_ERROR {
            if !has_error {
                has_error = true
                write_string(&b, origin[:cursor])
            }
        } else if has_error {
            has_error = false
            write_string(&b, replacement)

            origin = origin[cursor:]
            cursor = 0
        }

        cursor += w
        str = str[w:]
    }

    return to_string(b), nil
}

/*
Reverses the input string `s`

Example:
    a := "abcxyz"
    b := strings.reverse(a)
    fmt.println(a, b)
Output:
    abcxyz zyxcba
*/
reverse :: proc(s: string, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    str := s
    n := len(str)
    buf := slice.create([]byte, n, allocator, loc) or_return
    i := n

    for len(str) > 0 {
        _, w := utf8.decode_rune_in_string(str)
        i -= w
        slice.copy_from_string(buf[i:], str[:w])
        str = str[w:]
    }
    return string(buf), nil
}

/*
Expands the input string by replacing tab characters with spaces to align to a specified tab size
WARNING: Panics if tab_size <= 0

Example:
    text := "abc1\tabc2\tabc3"
    fmt.println(strings.expand_tabs(text, 4))
Output:
    abc1    abc2    abc3
*/
expand_tabs :: proc(s: string, tab_size: int, allocator: mem.Allocator) -> (res: string, err: io.Error) {
    if tab_size <= 0 {
        internal.panic("tab size must be positive")
    }

    if s == "" {
        return "", nil
    }

    b: Builder
    builder_init(&b, allocator)
    writer := to_writer(&b)
    str := s
    column: int

    for len(str) > 0 {
        r, w := utf8.decode_rune_in_string(str)

        if r == '\t' {
            expand := tab_size - column%tab_size

            for i := 0; i < expand; i += 1 {
                io.write_byte(writer, ' ') or_return
            }

            column += expand
        } else {
            if r == '\n' {
                column = 0
            } else {
                column += w
            }

            _ = io.write_rune(writer, r) or_return
        }

        str = str[w:]
    }

    return to_string(b), nil
}

/*
Splits the input string `str` by the separator `sep` string and returns 3 parts. The values are slices of the original string.

Example:
    text := "testing this out"
    head, match, tail := strings_tools.partition(text, " this ") // -> head: "testing", match: " this ", tail: "out"
    fmt.println(head, match, tail)
    head, match, tail = strings_tools.partition(text, "hi") // -> head: "testing t", match: "hi", tail: "s out"
    fmt.println(head, match, tail)
    head, match, tail = strings_tools.partition(text, "xyz")    // -> head: "testing this out", match: "", tail: ""
    fmt.println(head)
    fmt.println(match == "")
    fmt.println(tail == "")
Output:
    testing  this  out
    testing t hi s out
    testing this out
    true
    true
*/
partition :: proc(str, sep: string) -> (head, match, tail: string) {
    i := index(str, sep)
    if i == -1 {
        head = str
        return
    }

    head = str[:i]
    match = str[i:i+len(sep)]
    tail = str[i+len(sep):]
    return
}

center_justify :: centre_justify

/*
Centers the input string within a field of specified length by adding pad string on both sides, if its length is less than the target length.
*/
centre_justify :: proc(str: string, length: int, pad: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    n := rune_count(str)
    if n >= length || pad == "" {
        return strings.string_clone(str, allocator)
    }

    remains := length-n
    pad_len := rune_count(pad)

    b: Builder
    builder_init_len_cap(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

    w := to_writer(&b)

    write_pad_string(w, pad, pad_len, remains/2)
    _, _ = io.write_string(w, str)
    write_pad_string(w, pad, pad_len, (remains+1)/2)

    return to_string(b), nil
}

/*
Left-justifies the input string within a field of specified length by adding pad string on the right side, if its length is less than the target length.
*/
left_justify :: proc(str: string, length: int, pad: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    n := rune_count(str)
    if n >= length || pad == "" {
        return strings.string_clone(str, allocator)
    }

    remains := length-n
    pad_len := rune_count(pad)

    b: Builder
    builder_init_len_cap(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

    w := to_writer(&b)

    _, _ = io.write_string(w, str)
    write_pad_string(w, pad, pad_len, remains)

    return to_string(b), nil
}

/*
Right-justifies the input string within a field of specified length by adding pad string on the left side, if its length is less than the target length.
*/
right_justify :: proc(str: string, length: int, pad: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    n := rune_count(str)
    if n >= length || pad == "" {
        return strings.string_clone(str, allocator)
    }

    remains := length-n
    pad_len := rune_count(pad)

    b: Builder
    builder_init_len_cap(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

    w := to_writer(&b)

    write_pad_string(w, pad, pad_len, remains)
    _, _ = io.write_string(w, str)

    return to_string(b), nil
}

/*
Writes a given pad string a specified number of times to an `io.Writer`
- w: The io.Writer to write the pad string to
- pad: The pad string to be written
- pad_len: The length of the pad string, in runes
- remains: The number of times to write the pad string, in runes
*/
@(private)
write_pad_string :: proc(w: io.Writer, pad: string, pad_len, remains: int) {
    repeats := remains / pad_len

    for i := 0; i < repeats; i += 1 {
        _, _ = io.write_string(w, pad)
    }

    n := remains % pad_len
    p := pad

    for i := 0; i < n; i += 1 {
        r, width := utf8.decode_rune_in_string(p)
        _, _ = io.write_rune(w, r)
        p = p[width:]
    }
}

/*
Splits a string into a slice of substrings at each instance of one or more consecutive white space characters, as defined by `unicode.strings.rune_is_space`
*/
fields :: proc(s: string, allocator: mem.Allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) #no_bounds_check {
    n := 0
    was_space := 1
    set_bits := u8(0)

    // check to see
    for i in 0..<len(s) {
        r := s[i]
        set_bits |= r
        is_space := int(_ascii_space[r])
        n += was_space & ~is_space
        was_space = is_space
    }

    if set_bits >= utf8.RUNE_SELF {
        return fields_proc(s, unicode.is_space, allocator)
    }

    if n == 0 {
        return nil, nil
    }

    a := slice.create([]string, n, allocator, loc) or_return
    na := 0
    field_start := 0
    i := 0
    for i < len(s) && _ascii_space[s[i]] {
        i += 1
    }
    field_start = i
    for i < len(s) {
        if !_ascii_space[s[i]] {
            i += 1
            continue
        }
        a[na] = s[field_start : i]
        na += 1
        i += 1
        for i < len(s) && _ascii_space[s[i]] {
            i += 1
        }
        field_start = i
    }
    if field_start < len(s) {
        a[na] = s[field_start:]
    }
    return a, nil
}


// Returns true if is an ASCII space character ('\t', '\n', '\v', '\f', '\r', ' ')
@(private) _ascii_space := [256]bool{'\t' = true, '\n' = true, '\v' = true, '\f' = true, '\r' = true, ' ' = true}

/*
Returns true when the `r` rune is an ASCII whitespace character.

Inputs:
- r: the rune to test

Returns:
-res: `true` if `r` is a whitespace character, `false` if otherwise
*/
rune_is_ascii_space :: proc(r: rune) -> (res: bool) {
    if r < utf8.RUNE_SELF {
        return _ascii_space[u8(r)]
    }
    return false
}

/*
Splits a string into a slice of substrings at each run of unicode code points `r` satisfying the predicate `f(r)`
NOTE: fields_proc makes no guarantee about the order in which it calls `f(r)`, it assumes that `f` always returns the same value for a given `r`
*/
fields_proc :: proc(s: string, f: proc(rune) -> bool, allocator: mem.Allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) #no_bounds_check {
    substrings := dyn_array.create_len_cap([dynamic]string, 0, 32, allocator, loc) or_return

    start, end := -1, -1
    for r, offset in s {
        end = offset
        if f(r) {
            if start >= 0 {
                _ = dyn_array.append(&substrings, s[start : end])
                // -1 could be used, but just speed it up through bitwise not
                // gotta love 2's complement
                start = ~start
            }
        } else {
            if start < 0 {
                start = end
            }
        }
    }

    if start >= 0 {
        _ = dyn_array.append(&substrings, s[start : len(s)])
    }

    return substrings[:], nil
}

/*
Retrieves the first non-space substring from a mutable string reference and advances the reference. `s` is advanced from any space after the substring, or be an empty string if the substring was the remaining characters
*/
fields_iterator :: proc(s: ^string) -> (field: string, ok: bool) {
    start, end := -1, -1
    for r, offset in s {
        end = offset
        if unicode.is_space(r) {
            if start >= 0 {
                field = s[start : end]
                ok = true
                s^ = s[end:]
                return
            }
        } else {
            if start < 0 {
                start = end
            }
        }
    }

    // if either of these are true, the string did not contain any characters
    if end < 0 || start < 0 {
        return "", false
    }

    field = s[start:]
    ok = true
    s^ = s[len(s):]
    return
}

/*
Computes the Levenshtein edit distance between two strings
NOTE: Does not perform internal allocation if length of string `b`, in runes, is smaller than 64
NOTE: This implementation is a single-row-version of the Wagner–Fischer algorithm, based on C code by Martin Ettl.
*/
levenshtein_distance :: proc(a, b: string, allocator: mem.Allocator, loc := #caller_location) -> (res: int, err: mem.Allocator_Error) {
    LEVENSHTEIN_DEFAULT_COSTS: []int : {
        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,
        10,  11,  12,  13,  14,  15,  16,  17,  18,  19,
        20,  21,  22,  23,  24,  25,  26,  27,  28,  29,
        30,  31,  32,  33,  34,  35,  36,  37,  38,  39,
        40,  41,  42,  43,  44,  45,  46,  47,  48,  49,
        50,  51,  52,  53,  54,  55,  56,  57,  58,  59,
        60,  61,  62,  63,
    }

    m, n := utf8.rune_count_in_string(a), utf8.rune_count_in_string(b)

    if m == 0 {
        return n, nil
    }
    if n == 0 {
        return m, nil
    }

    costs: []int

    if n + 1 > len(LEVENSHTEIN_DEFAULT_COSTS) {
        costs = slice.create([]int, n + 1, allocator, loc) or_return
        for k in 0..=n {
            costs[k] = k
        }
    } else {
        costs = LEVENSHTEIN_DEFAULT_COSTS
    }

    defer if n + 1 > len(LEVENSHTEIN_DEFAULT_COSTS) {
        _ = slice.delete(costs, allocator)
    }

    i: int
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

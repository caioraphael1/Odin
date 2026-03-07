import "base:internal"
import "base:mem"
import "base:slice"


Raw_String :: internal.Raw_String

string_from_ptr :: proc(ptr: ^byte, len: int) -> (res: string) {
    return transmute(string)Raw_String{ ptr, len }
}

string_from_null_terminated_bytes :: proc(b: []byte) -> (res: string) {
    s := string(b)
    i := 0
    for ; i < len(s); i += 1 {
        if s[i] == 0 {
            break
        }
    }
    return s[:i]
}

string_clone :: proc(s: string, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    c := slice.create([]byte, len(s), allocator, loc) or_return
    slice.copy_from_string(c, s)
    return string(c), nil
}

/*
Clones a byte array `s` and appends a null-byte
*/
string_clone_from_bytes :: proc(s: []byte, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    c := slice.create([]byte, len(s)+1, allocator, loc) or_return
    slice.copy(c, s)
    c[len(s)] = 0
    return string(c[:len(s)]), nil
}

string_clone_from_cstring :: proc(s: cstring, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    return string_clone(string(s), allocator, loc)
}

string_clone_from_ptr :: proc(ptr: ^byte, len: int, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    s := string_from_ptr(ptr, len)
    return string_clone(s, allocator, loc)
}

string_delete :: proc(str: string, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free_with_size(raw_data(str), len(str), allocator, loc)
}


/*
Returns a combined string from the slice of strings `a` without a separator

Example:
    a := [?]string { "a", "b", "c" }
    fmt.println(strings.string_concatenate(a[:]))
Output:
    abc
*/
string_concatenate :: proc(a: []string, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    if len(a) == 0 {
        return "", nil
    }

    n := 0
    for s in a {
        n += len(s)
    }
    b := slice.create([]byte, n, allocator, loc) or_return
    i := 0
    for s in a {
        i += slice.copy_from_string(b[i:], s)
    }
    return string(b), nil
}


strings_concatenate_from_buffer :: proc(buf: []byte, strings: ..string) -> string {
    n := 0
    for s in strings {
        (n < len(buf)) or_break
        n += slice.copy_from_string(buf[n:], s)
    }
    n = min(len(buf), n)
    return string(buf[:n])
}


/*
Joins a slice of strings `a` with a `sep` string

Example:
    a := [?]string { "a", "b", "c" }
    fmt.println(strings.string_join(a[:], " "))
    fmt.println(strings.string_join(a[:], "-"))
    fmt.println(strings.string_join(a[:], "..."))
Output
    a b c
    a-b-c
    a...b...c
*/
string_join :: proc(a: []string, sep: string, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    if len(a) == 0 {
        return "", nil
    }

    n := len(sep) * (len(a) - 1)
    for s in a {
        n += len(s)
    }

    b := slice.create([]byte, n, allocator, loc) or_return
    i := slice.copy_from_string(b, a[0])
    for s in a[1:] {
        i += slice.copy_from_string(b[i:], sep)
        i += slice.copy_from_string(b[i:], s)
    }
    return string(b), nil
}

/*
Repeats the string `s` `count` times, concatenating the result
WARNING: Panics if count < 0

Example:
    fmt.println(strings.string_repeat("abc", 2))
Output:
    abcabc
*/
string_repeat :: proc(s: string, count: int, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    if count < 0 {
        panic("strings: negative repeat count")
    } else if count > 0 && (len(s)*count)/count != len(s) {
        panic("strings: repeat count will cause an overflow")
    }

    b := slice.create([]byte, len(s)*count, allocator, loc) or_return
    i := slice.copy_from_string(b, s)
    for i < len(b) { // 2^N trick to reduce the need to slice.copy_from_string
        slice.copy(b[i:], b[:i])
        i *= 2
    }
    return string(b), nil
}


/*
Returns a substring of the input string `s` with the specified rune offset and length

Example:
    fmt.println(strings.string_cut("some example text", 0, 4)) // -> "some"
    fmt.println(strings.string_cut("some example text", 2, 2)) // -> "me"
    fmt.println(strings.string_cut("some example text", 5, 7)) // -> "example"
Output:
    some
    me
    example
*/
string_cut :: proc(s: string, rune_offset: int = 0, rune_length: int = 0) -> (res: string) {
    s := s; rune_length := rune_length

    count := 0
    for _, offset in s {
        if count == rune_offset {
            s = s[offset:]
            break
        }
        count += 1
    }

    if rune_length < 1 {
        return s
    }

    count = 0
    for _, offset in s {
        if count == rune_length {
            s = s[:offset]
            break
        }
        count += 1
    }
    return s
}

/*
Compares two strings, returning a value representing which one comes first lexicographically.
Returns`-1` if `lhs` comes first, `1` if `rhs` comes first, or `0` if they are equal
*/
string_compare :: internal.__string_cmp


string_contain_rune :: proc(s: string, r: rune) -> (result: bool) {
    for c in s {
        if c == r {
            return true
        }
    }
    return false
}

/*
Determines if a string `s` starts with a given `prefix`

Example:
    fmt.println(strings.string_has_prefix("testing", "test"))
    fmt.println(strings.string_has_prefix("testing", "te"))
    fmt.println(strings.string_has_prefix("telephone", "te"))
    fmt.println(strings.string_has_prefix("testing", "est"))
Output:
    true
    true
    true
    false
*/
string_has_prefix :: proc(s, prefix: string) -> (result: bool) {
    return len(s) >= len(prefix) && s[0:len(prefix)] == prefix
}

/*
Determines if a string `s` ends with a given `suffix`

Example:
    fmt.println(strings.string_has_suffix("todo.txt", ".txt"))
    fmt.println(strings.string_has_suffix("todo.doc", ".txt"))
    fmt.println(strings.string_has_suffix("todo.doc.txt", ".txt"))
Output:
    true
    false
    true
*/
string_has_suffix :: proc(s, suffix: string) -> (result: bool) {
    return len(s) >= len(suffix) && s[len(s)-len(suffix):] == suffix
}

/*
Returns the prefix length common between strings `a` and `b`

Example:
    fmt.println(strings.string_prefix_length("testing", "test"))
    fmt.println(strings.string_prefix_length("testing", "te"))
    fmt.println(strings.string_prefix_length("telephone", "te"))
    fmt.println(strings.string_prefix_length("testing", "est"))
Output:
    4
    2
    2
    0
*/
string_prefix_length :: proc(a, b: string) -> (n: int) {
    RUNE_ERROR :: '\ufffd'
    UTF_MAX    :: 4

    n    = mem.memory_prefix_length(raw_data(a), raw_data(b), min(len(a), len(b)))
    lim := max(n - UTF_MAX + 1, 0)
    for l := n; l > lim; l -= 1 {
        r, _ := internal.__string_decode_rune(a[l - 1:])
        if r != RUNE_ERROR {
            if l > 0 && (a[l - 1] & 0xc0 == 0xc0) {
                return l - 1
            }
            return l
        }
    }
    return
}

/*
Returns the common prefix between strings `a` and `b`

Example:
    fmt.println(strings.string_common_prefix("testing", "test"))
    fmt.println(strings.string_common_prefix("testing", "te"))
    fmt.println(strings.string_common_prefix("telephone", "te"))
Output:
    test
    te
    te
*/
string_common_prefix :: proc(a, b: string) -> string {
    return a[:string_prefix_length(a, b)]
}


/*
Returns a substring of `s` that starts at rune index `rune_start` and goes up to `rune_end`.

Think of it as slicing `s[rune_start:rune_end]` but rune-wise.
*/
substring :: proc(s: string, rune_start: int, rune_end: int) -> (sub: string, ok: bool) {
    if rune_start < 0 || rune_end < 0 || rune_end < rune_start {
        return
    }

    return _substring(s, rune_start, rune_end)
}

/*
Returns a substring of `s` that starts at rune index `rune_start` and goes up to the end of the string.

Think of it as slicing `s[rune_start:]` but rune-wise.
*/
substring_from :: proc(s: string, rune_start: int) -> (sub: string, ok: bool) {
    if rune_start < 0 {
        return
    }

    return _substring(s, rune_start, -1)
}

/*
Returns a substring of `s` that goes up to rune index `rune_end`.

Think of it as slicing `s[:rune_end]` but rune-wise.
*/
substring_to :: proc(s: string, rune_end: int) -> (sub: string, ok: bool) {
    if rune_end < 0 {
        return
    }

    return _substring(s, -1, rune_end)
}


@(private)
_substring :: proc(s: string, rune_start: int, rune_end: int) -> (sub: string, ok: bool) {
    sub = s
    ok  = true

    rune_i: int

    if rune_start > 0 {
        ok = false
        for _, i in sub {
            if rune_start == rune_i {
                ok = true
                sub = sub[i:]
                break
            }
            rune_i += 1
        }
        if !ok { return }
    }

    if rune_end >= rune_start {
        ok = false
        for _, i in sub {
            if rune_end == rune_i {
                ok = true
                sub = sub[:i]
                break
            }
            rune_i += 1
        }

        if rune_end == rune_i {
            ok = true
        }
    }

    return
}

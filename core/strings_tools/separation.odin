import "base:mem"

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

/*
Splits the input string `s` into a slice of substrings separated by the specified `sep` string
NOTE: Allocation occurs for the array, the splits are all views of the original string.
*/
@(private)
_split :: proc(s_, sep: string, sep_save, n_: uint, allocator: mem.Allocator, loc := #caller_location) -> (res: []string, err: mem.Allocator_Error) {
    s, n := s_, n_

    if n == 0 {
        return nil, nil
    }

    if sep == "" {
        l := utf8.string_rune_count(s)
        if n < 0 || n > l {
            n = l
        }

        res = slice.create([]string, n, allocator, loc) or_return
        for i := 0; i < n-1; i += 1 {
            _, w := utf8.rune_from_string(s)
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
    ss := strings_tools.split_n(s, ".",3) // total of 3 wanted
    fmt.println(ss)
Output:
    ["aaa", "bbb", "ccc.ddd.eee"]
*/
split_n :: proc(s, sep: string, n: uint, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
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
split_after_n :: proc(s, sep: string, n: uint, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
    return _split(s, sep, len(sep), n, allocator)
}

/*
Searches for the first occurrence of `sep` in the given string and returns the substring
up to (but not including) the separator, as well as a boolean indicating success.
*/
@(private)
_split_iterator :: proc(s: ^string, sep: string, sep_save: uint) -> (res: string, ok: bool) {
    m: int
    if sep == "" {
        if len(s) == 0 {
            m = -1
        } else {
            _, w := utf8.rune_from_string(s^)
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
split_lines_n :: proc(s: string, n: uint, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
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
split_lines_after_n :: proc(s: string, n: uint, allocator: mem.Allocator) -> (res: []string, err: mem.Allocator_Error) {
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
    for str in strings_tools.split_lines_iterator(&text) {
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
Splits a string into a slice of substrings at each instance of one or more consecutive white space characters, as defined by `unicode.is_space`
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

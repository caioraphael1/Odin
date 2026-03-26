import "base:internal"
import "base:mem"
import "base:container/strings"
import "base:container/slice"
import "base:unicode"
import "base:unicode/utf8"
import "base:bytes"

import "core:io"
import "core:io/string_builder"


string_from_bytes_null_terminated :: proc(bytes: []u8) -> (res: string) {
    return truncate_to_byte(string(bytes), 0)
}

string_from_string_null_terminated :: proc(str: string) -> (res: string) {
    return truncate_to_byte(str, 0)
}


/*
Truncates a string `str` at the first occurrence of char/u8 `b`
*/
truncate_to_byte :: proc(str: string, b: u8) -> (res: string) {
    n, found := index_byte(str, b)
    if !found {
        n = len(str)
    }
    return str[:n]
}

/*
Truncates a string `str` at the first occurrence of rune `r` as a slice of the original, entire string if not found
*/
truncate_to_rune :: proc(str: string, r: rune) -> (res: string) {
    n, found := index_rune(str, r)
    if !found {
        n = len(str)
    }
    return str[:n]
}




/*
Example:
    replace_all("xyzxyz", "xyz", "abc")
    replace_all("xyzxyz", "abc", "xyz")
    replace_all("xyzxyz", "xy", "z")
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
    byte_count := uint(n)
    if m := count(s, old); m == 0 {
        was_allocation = false
        output = s
        return
    } else if n < 0 || m < uint(n) {
        byte_count = m
    }


    t, err := slice.create([]u8, len(s) + byte_count*(len(new) - len(old)), allocator, loc)
    if err != nil {
        return
    }
    was_allocation = true

    w: uint
    start: uint
    for i: uint = 0; i < byte_count; i += 1 {
        j := start
        if len(old) == 0 {
            if i > 0 {
                _, width := utf8.rune_from_string(s[start:])
                j += width
            }
        } else {
            jjj, found := index(s[start:], old)
            if found {
                j += jjj
            } else {
                j -= 1 // just because this was the logic before...
            }
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
Replaces invalid UTF-8 characters in the input string with a specified replacement string. Adjacent invalid bytes are only replaced once.

Example:
    text := "Hello\xC0\x80World"
    fmt.println(strings.scrub(text, "?")) // -> "Hello?World"
Output:
    Hello?
*/
scrub :: proc(s: string, replacement: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    str := s
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return

    has_error := false
    cursor: uint = 0
    origin := str

    for len(str) > 0 {
        r, w := utf8.rune_from_string(str)

        if r == utf8.RUNE_ERROR {
            if !has_error {
                has_error = true
                string_builder.write_string(&b, origin[:cursor])
            }
        } else if has_error {
            has_error = false
            string_builder.write_string(&b, replacement)

            origin = origin[cursor:]
            cursor = 0
        }

        cursor += w
        str = str[w:]
    }

    return string_builder.to_string(&b), nil
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
    buf := slice.create([]u8, n, allocator, loc) or_return
    i := n

    for len(str) > 0 {
        _, w := utf8.rune_from_string(str)
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
expand_tabs :: proc(s: string, tab_size: uint, allocator: mem.Allocator) -> (res: string, err: io.Error) {
    if tab_size <= 0 {
        internal.panic("tab size must be positive")
    }

    if s == "" {
        return "", nil
    }

    b: string_builder.Builder
    string_builder.builder_init(&b, allocator)
    writer := string_builder.to_writer(&b)
    str := s
    column: uint

    for len(str) > 0 {
        r, w := utf8.rune_from_string(str)

        if r == '\t' {
            expand := tab_size - column % tab_size

            for i: uint = 0; i < expand; i += 1 {
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

    return string_builder.to_string(&b), nil
}



/*
Centers the input string within a field of specified length by adding pad string on both sides, if its length is less than the target length.
*/
center_justify :: centre_justify
centre_justify :: proc(str: string, length: uint, pad: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    n := utf8.string_rune_count(str)
    if n >= length || pad == "" {
        return strings.string_clone(str, allocator)
    }

    remains := length - n
    pad_len := utf8.string_rune_count(pad)

    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

    w := string_builder.to_writer(&b)

    write_pad_string(w, pad, pad_len, remains/2)
    _, _ = io.write_string(w, str)
    write_pad_string(w, pad, pad_len, (remains+1)/2)

    return string_builder.to_string(&b), nil
}

/*
Left-justifies the input string within a field of specified length by adding pad string on the right side, if its length is less than the target length.
*/
left_justify :: proc(str: string, length: uint, pad: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    n := utf8.string_rune_count(str)
    if n >= length || pad == "" {
        return strings.string_clone(str, allocator)
    }

    remains := length-n
    pad_len := utf8.string_rune_count(pad)

    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

    w := string_builder.to_writer(&b)

    _, _ = io.write_string(w, str)
    write_pad_string(w, pad, pad_len, remains)

    return string_builder.to_string(&b), nil
}

/*
Right-justifies the input string within a field of specified length by adding pad string on the left side, if its length is less than the target length.
*/
right_justify :: proc(str: string, length: uint, pad: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    n := utf8.string_rune_count(str)
    if n >= length || pad == "" {
        return strings.string_clone(str, allocator)
    }

    remains := length-n
    pad_len := utf8.string_rune_count(pad)

    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator) or_return

    w := string_builder.to_writer(&b)

    write_pad_string(w, pad, pad_len, remains)
    _, _ = io.write_string(w, str)

    return string_builder.to_string(&b), nil
}

/*
Writes a given pad string a specified number of times to an `io.Writer`
- w: The io.Writer to write the pad string to
- pad: The pad string to be written
- pad_len: The length of the pad string, in runes
- remains: The number of times to write the pad string, in runes
*/
@(private)
write_pad_string :: proc(w: io.Writer, pad: string, pad_len, remains: uint) {
    repeats := remains / pad_len

    for i: uint = 0; i < repeats; i += 1 {
        _, _ = io.write_string(w, pad)
    }

    n := remains % pad_len
    p := pad

    for i: uint = 0; i < n; i += 1 {
        r, width := utf8.rune_from_string(p)
        _, _ = io.write_rune(w, r)
        p = p[width:]
    }
}

/*
Trims the cutset string from the `s` string
*/
trim_left :: proc(s: string, cutset: string) -> (res: string) {
    if s == "" || cutset == "" {
        return s
    }
    state := cutset
    return _trim_left_proc_with_state(s, unicode.is_in_cutset, &state)
}

/*
Trims the cutset string from the `s` string from the right
*/
trim_right :: proc(s: string, cutset: string) -> (res: string) {
    if s == "" || cutset == "" {
        return s
    }
    state := cutset
    return _trim_right_proc_with_state(s, unicode.is_in_cutset, &state)
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
    return _trim_left_proc(s, unicode.is_space)
}

/*
Trims from the right until a valid non-space rune, "\t\txyz\t\t" -> "\t\txyz"
*/
trim_right_space :: proc(s: string) -> (res: string) {
    return _trim_right_proc(s, unicode.is_space)
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
    return _trim_left_proc(s, unicode.is_null)
}

/*
Trims null runes from the right, "\x00\x00testing\x00\x00" -> "\x00\x00testing"
*/
trim_right_null :: proc(s: string) -> (res: string) {
    return _trim_right_proc(s, unicode.is_null)
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


    trim_suffix_example :: proc() {
        fmt.println(strings_tools.trim_suffix("todo.txt", ".txt"))
        fmt.println(strings_tools.trim_suffix("todo.doc", ".txt"))
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
_index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> (res: uint, found: bool) {
    for r, i in s {
        if p(r) == truth {
            return i, true
        }
    }
    return 0, false
}

@(private)
_index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (res: uint, found: bool) {
    for r, i in s {
        if p(state, r) == truth {
            return i, true
        }
    }
    return 0, false
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
    i, found := _index_proc(s, p, false)
    if !found {
        return ""
    }
    return s[i:]
}

/*
Trims the input string `s` from the left until the procedure `p` with state returns false
*/
@(private)
_trim_left_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr) -> (res: string) {
    i, found := _index_proc_with_state(s, p, state, false)
    if !found {
        return ""
    }
    return s[i:]
}

// Finds the index of the *last* rune in the string s for which the procedure p returns the same value as truth
@(private)
_last_index_proc :: proc(s: string, p: proc(rune) -> bool, truth := true) -> (res: uint, found: bool) {
    // TODO(bill): Probably use Rabin-Karp Search
    for i := len(s); i > 0; {
        r, size := utf8.last_rune_in_string(s[:i])
        i -= size
        if p(r) == truth {
            return i, true
        }
    }
    return 0, false
}

// Same as `_index_proc_with_state`, runs through the string in reverse
@(private)
last_index_proc_with_state :: proc(s: string, p: proc(rawptr, rune) -> bool, state: rawptr, truth := true) -> (res: uint, found: bool) {
    // TODO(bill): Probably use Rabin-Karp Search
    for i := len(s); i > 0; {
        r, size := utf8.last_rune_in_string(s[:i])
        i -= size
        if p(state, r) == truth {
            return i, true
        }
    }
    return 0, false
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
    i, found := _last_index_proc(s, p, false)
    if found && s[i] >= utf8.RUNE_SELF {
        _, w := utf8.rune_from_string(s[i:])
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
    i, found := last_index_proc_with_state(s, p, state, false)
    if found && s[i] >= utf8.RUNE_SELF {
        _, w := utf8.rune_from_string(s[i:])
        i += w
    } else {
        i += 1
    }
    return s[0:i]
}



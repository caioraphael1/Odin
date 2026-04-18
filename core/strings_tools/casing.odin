import "base:container/str"
import "base:unicode"

/*
Converts invalid UTF-8 sequences in the input string `s` to the `replacement` string.
Inputs:
- s: Input string that may contain invalid UTF-8 sequences.
- replacement: String to replace invalid UTF-8 sequences with.
Returns:
- res: A valid UTF-8 string with invalid sequences replaced by `replacement`.
- err: An optional allocator error if one occured, `nil` otherwise
*/
/* 
to_valid_utf8 :: proc(s: ^str.String($N), replacement: string) -> (ok: bool) {
    if s.len == 0 {
        return false
    }

    old := s^

    for c, i in str.str(old) {
        if c != utf8.RUNE_ERROR {
            continue
        }

        _, w := utf8.rune_from_string(s[i:])
        if w == 1 {
            str.write(s, old.data[:i]) or_return
            // s = s[i:]
            break
        }
    }

    invalid := false
    for i: uint = 0; i < s.len; {
        c := s[i]
        if c < utf8.RUNE_SELF {
            i += 1
            invalid = false
            str.write_byte(s, c) or_return
            continue
        }

        _, w := utf8.rune_from_string(s[i:])
        if w == 1 {
            i += 1
            if !invalid {
                invalid = true
                str.write_string(s, replacement) or_return
            }
            continue
        }
        invalid = false
        str.write_string(s, s[i:][:w]) or_return
        i += w
    }
    return res, true
}
*/




/*
lowercase
*/
to_lower :: proc(s: ^str.String($N)) {
    for r in str.str(s) {
        _ = str.write_rune(s, unicode.to_lower(r))
    }
}


/*
UPPERCASE
*/
to_upper :: proc(s: ^str.String($N)) {
    for r in str.str(s) {
        _ = str.write_rune(s, unicode.to_upper(r))
    }
}

/*

/*
lowerCamelCase
*/
to_camel_case :: proc(s: ^str.String($N)) {
    s = trim_space(s)

    _string_case_iterator(&s, s, proc(s: ^str.String($N), prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) {
                _, _ = str.write_rune(s, unicode.to_upper(curr))
            } else if unicode.is_lower(prev) {
                _, _ = str.write_rune(s, curr)
            } else {
                _, _ = str.write_rune(s, unicode.to_lower(curr))
            }
        }
    })

    return str.to_string(&s), nil
}

/*
UpperCamelCase (PascalCase)
*/
to_pascal_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    s := s
    s = trim_space(s)
    s: str.String($N)
    str.builder_init_len_cap(&s, 0, len(s), allocator) or_return

    _string_case_iterator(&s, s, proc(s: ^str.String($N), prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) || prev == 0 {
                _, _ = str.write_rune(s, unicode.to_upper(curr))
            } else if unicode.is_lower(prev) {
                _, _ = str.write_rune(s, curr)
            } else {
                _, _ = str.write_rune(s, unicode.to_lower(curr))
            }
        }
    })

    return str.to_string(&s), nil
}

/*
Example:
    strings.to_delimiter_case("Hello World", '_', false)
    strings.to_delimiter_case("Hello World", ' ', true)
    strings.to_delimiter_case("aBC", '_', false)
Output:
    hello_world
    HELLO WORLD
    a_bc
*/
to_delimiter_case :: proc(
    s: string,
    delimiter: rune,
    all_upper_case: bool,
    allocator: mem.Allocator,
    ) -> (res: string, err: mem.Allocator_Error) {
    s := s
    s = trim_space(s)
    s: str.String($N)
    str.builder_init_len_cap(&s, 0, len(s), allocator) or_return

    adjust_case := unicode.to_upper if all_upper_case else unicode.to_lower

    prev, curr: rune

    for next in s {
        if unicode.is_delimiter(curr) {
            if !unicode.is_delimiter(prev) {
                _, _ = str.write_rune(&s, delimiter)
            }
        } else if unicode.is_upper(curr) {
            if unicode.is_lower(prev) || (unicode.is_upper(prev) && unicode.is_lower(next)) {
                _, _ = str.write_rune(&s, delimiter)
            }
            _, _ = str.write_rune(&s, adjust_case(curr))
        } else if curr != 0 {
            _, _ = str.write_rune(&s, adjust_case(curr))
        }

        prev = curr
        curr = next
    }

    if len(s) > 0 {
        if unicode.is_upper(curr) && unicode.is_lower(prev) && prev != 0 {
            _, _ = str.write_rune(&s, delimiter)
        }
        _, _ = str.write_rune(&s, adjust_case(curr))
    }

    return str.to_string(&s), nil
}

/*
snake_case
*/
to_snake_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    return to_delimiter_case(s, '_', false, allocator)
}

/*
UPPER_SNAKE_CASE
*/
to_upper_snake_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    return to_delimiter_case(s, '_', true, allocator)
}

/*
kebab-case
*/
to_kebab_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error)  {
    return to_delimiter_case(s, '-', false, allocator)
}

/*
UPPER-KEBAB-CASE
*/
to_upper_kebab_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error)  {
    return to_delimiter_case(s, '-', true, allocator)
}

/*
Ada_Case
*/
to_ada_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error)  {
    s := s
    s = trim_space(s)
    s: str.String($N)
    str.builder_init_len_cap(&s, 0, len(s), allocator) or_return

    _string_case_iterator(&s, s, proc(s: ^str.String($N), prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) || prev == 0 || (unicode.is_lower(prev) && unicode.is_upper(curr)) {
                if prev != 0 {
                    _, _ = str.write_rune(s, '_')
                }
                _, _ = str.write_rune(s, unicode.to_upper(curr))
            } else {
                _, _ = str.write_rune(s, unicode.to_lower(curr))
            }
        }
    })

    return str.to_string(&s), nil
}

/*
Iterates over a string, calling a callback for each rune with the previous, current, and next runes as arguments.
- w: An io.Writer to be used by the callback for writing output.
- s: The input string to be iterated over.
- callback: A procedure to be called for each rune in the string, with arguments (w: io.Writer, prev, curr, next: rune).
Example:
    my_callback :: proc(w: io.Writer, prev, curr, next: rune) {
        os.println("my_callback", curr) // <-- Custom logic here
    }
    s := "hello"
    s: strings_tools.str.String($N)
    strings.builder_init_len(&s, len(s))
    w := strings_tools.str.to_writer(&s)
    strings._string_case_iterator(w, s, my_callback)
Output:
    my_callback h
    my_callback e
    my_callback l
    my_callback l
    my_callback o
*/
_string_case_iterator :: proc(
    s:        ^str.String($N),
    s:        string,
    callback: proc(s: ^str.String($N), prev, curr, next: rune),
) {
    prev, curr: rune
    for next in s {
        if curr == 0 {
            prev = curr
            curr = next
            continue
        }

        callback(s, prev, curr, next)

        prev = curr
        curr = next
    }

    if len(s) > 0 {
        callback(s, prev, curr, 0)
    }
}


*/

#+ignore

import "base:mem"
import "base:container/str"
import "base:container/strings"
import "base:unicode"
import "base:unicode/utf8"

/*
Converts invalid UTF-8 sequences in the input string `s` to the `replacement` string.
Inputs:
- s: Input string that may contain invalid UTF-8 sequences.
- replacement: String to replace invalid UTF-8 sequences with.
Returns:
- res: A valid UTF-8 string with invalid sequences replaced by `replacement`.
- err: An optional allocator error if one occured, `nil` otherwise
*/
to_valid_utf8 :: proc(s, replacement: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    if len(s) == 0 {
        return "", nil
    }

    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, 0, allocator) or_return

    s := s
    for c, i in s {
        if c != utf8.RUNE_ERROR {
            continue
        }

        _, w := utf8.rune_from_string(s[i:])
        if w == 1 {
            string_builder.builder_grow(&b, len(s) + len(replacement))
            _ = string_builder.write_string(&b, s[:i]) or_return
            s = s[i:]
            break
        }
    }

    if string_builder.builder_cap(b) == 0 {
        return strings.string_clone(s, allocator)
    }

    invalid := false

    for i: uint = 0; i < len(s); {
        c := s[i]
        if c < utf8.RUNE_SELF {
            i += 1
            invalid = false
            _ = string_builder.write_byte(&b, c) or_return
            continue
        }

        _, w := utf8.rune_from_string(s[i:])
        if w == 1 {
            i += 1
            if !invalid {
                invalid = true
                _ = string_builder.write_string(&b, replacement) or_return
            }
            continue
        }
        invalid = false
        _ = string_builder.write_string(&b, s[i:][:w]) or_return
        i += w
    }
    return string_builder.to_string(&b), nil
}




/*
lowercase
*/
to_lower :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return
    for r in s {
        _, _ = string_builder.write_rune(&b, unicode.to_lower(r))
    }
    return string_builder.to_string(&b), nil
}


/*
UPPERCASE
*/
to_upper :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return
    for r in s {
        _, _ = string_builder.write_rune(&b, unicode.to_upper(r))
    }
    return string_builder.to_string(&b), nil
}

/*
lowerCamelCase
*/
to_camel_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    s := s
    s = trim_space(s)
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return

    _string_case_iterator(&b, s, proc(b: ^string_builder.Builder, prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) {
                _, _ = string_builder.write_rune(b, unicode.to_upper(curr))
            } else if unicode.is_lower(prev) {
                _, _ = string_builder.write_rune(b, curr)
            } else {
                _, _ = string_builder.write_rune(b, unicode.to_lower(curr))
            }
        }
    })

    return string_builder.to_string(&b), nil
}

/*
UpperCamelCase (PascalCase)
*/
to_pascal_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    s := s
    s = trim_space(s)
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return

    _string_case_iterator(&b, s, proc(b: ^string_builder.Builder, prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) || prev == 0 {
                _, _ = string_builder.write_rune(b, unicode.to_upper(curr))
            } else if unicode.is_lower(prev) {
                _, _ = string_builder.write_rune(b, curr)
            } else {
                _, _ = string_builder.write_rune(b, unicode.to_lower(curr))
            }
        }
    })

    return string_builder.to_string(&b), nil
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
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return

    adjust_case := unicode.to_upper if all_upper_case else unicode.to_lower

    prev, curr: rune

    for next in s {
        if unicode.is_delimiter(curr) {
            if !unicode.is_delimiter(prev) {
                _, _ = string_builder.write_rune(&b, delimiter)
            }
        } else if unicode.is_upper(curr) {
            if unicode.is_lower(prev) || (unicode.is_upper(prev) && unicode.is_lower(next)) {
                _, _ = string_builder.write_rune(&b, delimiter)
            }
            _, _ = string_builder.write_rune(&b, adjust_case(curr))
        } else if curr != 0 {
            _, _ = string_builder.write_rune(&b, adjust_case(curr))
        }

        prev = curr
        curr = next
    }

    if len(s) > 0 {
        if unicode.is_upper(curr) && unicode.is_lower(prev) && prev != 0 {
            _, _ = string_builder.write_rune(&b, delimiter)
        }
        _, _ = string_builder.write_rune(&b, adjust_case(curr))
    }

    return string_builder.to_string(&b), nil
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
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return

    _string_case_iterator(&b, s, proc(b: ^string_builder.Builder, prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) || prev == 0 || (unicode.is_lower(prev) && unicode.is_upper(curr)) {
                if prev != 0 {
                    _, _ = string_builder.write_rune(b, '_')
                }
                _, _ = string_builder.write_rune(b, unicode.to_upper(curr))
            } else {
                _, _ = string_builder.write_rune(b, unicode.to_lower(curr))
            }
        }
    })

    return string_builder.to_string(&b), nil
}

/*
Iterates over a string, calling a callback for each rune with the previous, current, and next runes as arguments.
- w: An io.Writer to be used by the callback for writing output.
- s: The input string to be iterated over.
- callback: A procedure to be called for each rune in the string, with arguments (w: io.Writer, prev, curr, next: rune).
Example:
    my_callback :: proc(w: io.Writer, prev, curr, next: rune) {
        fmt.println("my_callback", curr) // <-- Custom logic here
    }
    s := "hello"
    b: strings_tools.string_builder.Builder
    strings.builder_init_len(&b, len(s))
    w := strings_tools.string_builder.to_writer(&b)
    strings._string_case_iterator(w, s, my_callback)
Output:
    my_callback h
    my_callback e
    my_callback l
    my_callback l
    my_callback o
*/
_string_case_iterator :: proc(
    b:        ^string_builder.Builder,
    s:        string,
    callback: proc(b: ^string_builder.Builder, prev, curr, next: rune),
) {
    prev, curr: rune
    for next in s {
        if curr == 0 {
            prev = curr
            curr = next
            continue
        }

        callback(b, prev, curr, next)

        prev = curr
        curr = next
    }

    if len(s) > 0 {
        callback(b, prev, curr, 0)
    }
}

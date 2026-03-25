import "base:mem"
import "base:container/strings"
import "base:container/slice"
import "base:unicode"
import "base:unicode/utf8"

import "core:io"
import "core:io/string_builder"

/*
Converts invalid UTF-8 sequences in the input string `s` to the `replacement` string.
Allocation does not occur when len(s) == 0
Inputs:
- s: Input string that may contain invalid UTF-8 sequences.
- replacement: String to replace invalid UTF-8 sequences with.
- allocator: 
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
            string_builder.write_string(&b, s[:i])
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
            string_builder.write_byte(&b, c)
            continue
        }

        _, w := utf8.rune_from_string(s[i:])
        if w == 1 {
            i += 1
            if !invalid {
                invalid = true
                string_builder.write_string(&b, replacement)
            }
            continue
        }
        invalid = false
        string_builder.write_string(&b, s[i:][:w])
        i += w
    }
    return string_builder.to_string(&b), nil
}




/*
Example:
    fmt.println(strings_tools.to_lower("TeST"))
Output:
    test
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
Example:
    fmt.println(strings.to_upper("Test"))
Output:
    TEST
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
Converts the input string `s` to "lowerCamelCase".

*Allocates Using Provided Allocator*

Inputs:
- s: Input string to be converted.
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise
*/
to_camel_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    s := s
    s = trim_space(s)
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return
    w := string_builder.to_writer(&b)

    _string_case_iterator(w, s, proc(w: io.Writer, prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) {
                _, _ = io.write_rune(w, unicode.to_upper(curr))
            } else if unicode.is_lower(prev) {
                _, _ = io.write_rune(w, curr)
            } else {
                _, _ = io.write_rune(w, unicode.to_lower(curr))
            }
        }
    })

    return string_builder.to_string(&b), nil
}

/*
Converts the input string `s` to "UpperCamelCase" (PascalCase).

*Allocates Using Provided Allocator*

Inputs:
- s: Input string to be converted.
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise
*/
to_pascal_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    s := s
    s = trim_space(s)
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return
    w := string_builder.to_writer(&b)

    _string_case_iterator(w, s, proc(w: io.Writer, prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) || prev == 0 {
                _, _ = io.write_rune(w, unicode.to_upper(curr))
            } else if unicode.is_lower(prev) {
                _, _ = io.write_rune(w, curr)
            } else {
                _, _ = io.write_rune(w, unicode.to_lower(curr))
            }
        }
    })

    return string_builder.to_string(&b), nil
}

/*
Returns a string converted to a delimiter-separated case with configurable casing

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to be converted
- delimiter: The rune to be used as the delimiter between words
- all_upper_case: A boolean indicating if the output should be all uppercased (true) or lowercased (false)
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

    to_delimiter_case_example :: proc() {
        fmt.println(strings.to_delimiter_case("Hello World", '_', false))
        fmt.println(strings.to_delimiter_case("Hello World", ' ', true))
        fmt.println(strings.to_delimiter_case("aBC", '_', false))
    }

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
    w := string_builder.to_writer(&b)

    adjust_case := unicode.to_upper if all_upper_case else unicode.to_lower

    prev, curr: rune

    for next in s {
        if unicode.is_delimiter(curr) {
            if !unicode.is_delimiter(prev) {
                _, _ = io.write_rune(w, delimiter)
            }
        } else if unicode.is_upper(curr) {
            if unicode.is_lower(prev) || (unicode.is_upper(prev) && unicode.is_lower(next)) {
                _, _ = io.write_rune(w, delimiter)
            }
            _, _ = io.write_rune(w, adjust_case(curr))
        } else if curr != 0 {
            _, _ = io.write_rune(w, adjust_case(curr))
        }

        prev = curr
        curr = next
    }

    if len(s) > 0 {
        if unicode.is_upper(curr) && unicode.is_lower(prev) && prev != 0 {
            _, _ = io.write_rune(w, delimiter)
        }
        _, _ = io.write_rune(w, adjust_case(curr))
    }

    return string_builder.to_string(&b), nil
}

/*
Converts a string to "snake_case" with all runes lowercased

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to be converted
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

    to_snake_case_example :: proc() {
        fmt.println(strings.to_snake_case("HelloWorld"))
        fmt.println(strings.to_snake_case("Hello World"))
    }

Output:

    hello_world
    hello_world

*/
to_snake_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    return to_delimiter_case(s, '_', false, allocator)
}

/*
Converts a string to "SNAKE_CASE" with all runes uppercased

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to be converted
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

    to_upper_snake_case_example :: proc() {
        fmt.println(strings.to_upper_snake_case("HelloWorld"))
    }

Output:

    HELLO_WORLD

*/
to_upper_snake_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    return to_delimiter_case(s, '_', true, allocator)
}

/*
Converts a string to "kebab-case" with all runes lowercased

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to be converted
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

    to_kebab_case_example :: proc() {
        fmt.println(strings.to_kebab_case("HelloWorld"))
    }

Output:

    hello-world

*/
to_kebab_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error)  {
    return to_delimiter_case(s, '-', false, allocator)
}

/*
Converts a string to "KEBAB-CASE" with all runes uppercased

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to be converted
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

    to_upper_kebab_case_example :: proc() {
        fmt.println(strings.to_upper_kebab_case("HelloWorld"))
    }

Output:

    HELLO-WORLD

*/
to_upper_kebab_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error)  {
    return to_delimiter_case(s, '-', true, allocator)
}

/*
Converts a string to "Ada_Case"

*Allocates Using Provided Allocator*

Inputs:
- s: The input string to be converted
- allocator:

Returns:
- res: The converted string
- err: An optional allocator error if one occured, `nil` otherwise

Example:

    to_ada_case_example :: proc() {
        fmt.println(strings.to_ada_case("HelloWorld"))
    }

Output:

    Hello_World

*/
to_ada_case :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error)  {
    s := s
    s = trim_space(s)
    b: string_builder.Builder
    string_builder.builder_init_len_cap(&b, 0, len(s), allocator) or_return
    w := string_builder.to_writer(&b)

    _string_case_iterator(w, s, proc(w: io.Writer, prev, curr, next: rune) {
        if !unicode.is_delimiter(curr) {
            if unicode.is_delimiter(prev) || prev == 0 || (unicode.is_lower(prev) && unicode.is_upper(curr)) {
                if prev != 0 {
                    _, _ = io.write_rune(w, '_')
                }
                _, _ = io.write_rune(w, unicode.to_upper(curr))
            } else {
                _, _ = io.write_rune(w, unicode.to_lower(curr))
            }
        }
    })

    return string_builder.to_string(&b), nil
}

/*
Iterates over a string, calling a callback for each rune with the previous, current, and next runes as arguments.
Inputs:
- w: An io.Writer to be used by the callback for writing output.
- s: The input string to be iterated over.
- callback: A procedure to be called for each rune in the string, with arguments (w: io.Writer, prev, curr, next: rune).
The callback can utilize the provided io.Writer to write output during the iteration.
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
    w:        io.Writer,
    s:        string,
    callback: proc(w: io.Writer, prev, curr, next: rune),
) {
    prev, curr: rune
    for next in s {
        if curr == 0 {
            prev = curr
            curr = next
            continue
        }

        callback(w, prev, curr, next)

        prev = curr
        curr = next
    }

    if len(s) > 0 {
        callback(w, prev, curr, 0)
    }
}

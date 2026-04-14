import "base:mem"

// `get_env` retrieves the value of the environment variable named by the key
// It returns the value, which will be empty if the variable is not present
// To distinguish between an empty value and an unset value, use lookup_env
// NOTE: the value will be allocated with the supplied allocator
get_env_alloc :: proc(key: string, allocator: mem.Allocator) -> string {
    value, _ := lookup_env_alloc(key, allocator)
    return value
}

// `get_env` retrieves the value of the environment variable named by the key
// It returns the value, which will be empty if the variable is not present
// To distinguish between an empty value and an unset value, use lookup_env
// NOTE: this version takes a backing buffer for the string value
get_env_buf :: proc(buf: []u8, key: string) -> string {
    value, _ := lookup_env_buf(buf, key)
    return value
}

// `lookup_env` gets the value of the environment variable named by the key
// If the variable is found in the environment the value (which can be empty) is returned and the boolean is true
// Otherwise the returned value will be empty and the boolean will be false
// NOTE: the value will be allocated with the supplied allocator
lookup_env_alloc :: proc(key: string, allocator: mem.Allocator) -> (value: string, found: bool) {
    return _lookup_env_alloc(key, allocator)
}

// This version of `lookup_env` doesn't allocate and instead requires the user to provide a buffer.
// Note that it is limited to environment names and values of 512 utf-16 values each
// due to the necessary utf-8 <> utf-16 conversion.

lookup_env_buf :: proc(buf: []u8, key: string) -> (value: string, err: Error) {
    return _lookup_env_buf(buf, key)
}

// set_env sets the value of the environment variable named by the key
// Returns Error on failure
set_env :: proc(key, value: string) -> Error {
    return _set_env(key, value)
}

// unset_env unsets a single environment variable
// Returns true on success, false on failure
unset_env :: proc(key: string) -> bool {
    return _unset_env(key)
}

clear_env :: proc() {
    _clear_env()
}


// environ returns a copy of strings representing the environment, in the form "key=value"
// NOTE: the slice of strings and the strings with be allocated using the supplied allocator

environ :: proc(allocator: mem.Allocator) -> ([]string, Error) {
    return _environ(allocator)
}

// Always allocates for consistency.
/* TODO: (2026-04-14) I just removed string_builder. `res` has to be allocated using string_buffer.
replace_environment_placeholders :: proc(path: string, res: string) {
    path := path

    sb: string_builder.Builder
    string_builder.builder_init(&sb, allocator)

    for len(path) > 0 {
        switch path[0] {
        case '%': // Windows
            when ODIN_OS == .Windows {
                for r, i in path[1:] {
                    if r == '%' {
                        env_key := path[1:i+1]
                        env_val := get_env_alloc(env_key, allocators.temp_allocator)
                        string_builder.write_string(&sb, env_val)
                        path = path[i+1:] // % is part of key, so skip 1 character extra
                    }
                }
            } else {
                string_builder.write_rune(&sb, rune(path[0]))
            }

        case '$': // Posix
            when ODIN_OS != .Windows {
                env_key := ""
                dollar_loop: for r, i in path[1:] {
                    switch r {
                    case 'A'..='Z', 'a'..='z', '0'..='9', '_': // Part of key ident
                    case:
                        env_key = path[1:i+1]
                        break dollar_loop
                    }
                }
                if len(env_key) > 0 {
                    env_val := get_env(env_key, allocators.temp_allocator)
                    string_builder.write_string(&sb, env_val)
                    path = path[len(env_key):]
                }

            } else {
                _, _ = string_builder.write_rune(&sb, rune(path[0]))
            }

        case:
            _, _ = string_builder.write_rune(&sb, rune(path[0]))
        }

        path = path[1:]
    }
    return string_builder.to_string(&sb)
}
*/

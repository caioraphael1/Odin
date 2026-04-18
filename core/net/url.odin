
/*
    Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
    For other protocols and their features, see subdirectories of this package.
*/

/*
    Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
    Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
    Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
    Copyright 2024 Feoramund       <rune@swevencraft.org>.
    Made available under Odin's license.

    List of contributors:
        Tetralux:        Initial implementation
        Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
        Jeroen van Rijn: Cross platform unification, code style, documentation
        Feoramund:       FreeBSD platform code
*/
import "base:mem"
import "base:container/slice"
import "base:container/maps"
import "base:strconv"
import "base:unicode/utf8"

import "core:strings_tools"
import "core:encoding/hex"

split_url :: proc(url: string, allocator: mem.Allocator) -> (scheme, host, path: string, queries: map[string]string, fragment: string) {
    s := url

    i := strings_tools.index(s, "://")
    if i >= 0 {
        scheme = s[:i]
        s = s[i+3:]
    }

    i = strings_tools.index(s, "#")
    if i != -1 {
        fragment = s[i+1:]
        s = s[:i]
    }

    i = strings_tools.index(s, "?")
    if i != -1 {
        query_str := s[i+1:]
        s = s[:i]
        if query_str != "" {
            queries_parts, _ := strings_tools.split(query_str, "&", allocator)
            defer _ = slice.delete(queries_parts, allocator)
            queries, _ = maps.create_cap(map[string]string, len(queries_parts), allocator)
            for q in queries_parts {
                parts, _ := strings_tools.split(q, "=", allocator)
                defer _ = slice.delete(parts, allocator)
                switch len(parts) {
                case 1:  queries[parts[0]] = ""        // NOTE(tetra): Query not set to anything, was but present.
                case 2:  queries[parts[0]] = parts[1]  // NOTE(tetra): Query set to something.
                case:    break
                }
            }
        }
    }

    i = strings_tools.index(s, "/")
    if i == -1 {
        host = s
        path = "/"
    } else {
        host = s[:i]
        path = s[i:]
    }

    return
}

join_url :: proc(scheme, host, path: string, queries: map[string]string, fragment: string, allocator: mem.Allocator) -> string {
    b := string_builder.builder_create(allocator)
    strings_tools.builder_grow(&b, len(scheme) + 3 + len(host) + 1 + len(path))

    string_builder.write_string(&b, scheme)
    string_builder.write_string(&b, "://")
    string_builder.write_string(&b, strings_tools.trim_space(host))

    if path != "" {
        if path[0] != '/' {
            string_builder.write_string(&b, "/")
        }
        string_builder.write_string(&b, strings_tools.trim_space(path))
    }


    query_length := len(queries)
    if query_length > 0 {
        string_builder.write_string(&b, "?")
    }
    i := 0
    for query_name, query_value in queries {
        string_builder.write_string(&b, query_name)
        if query_value != "" {
            string_builder.write_string(&b, "=")
            string_builder.write_string(&b, query_value)
        }
        if i < query_length - 1 {
            string_builder.write_string(&b, "&")
        }
        i += 1
    }

    if fragment != "" {
        if fragment[0] != '#' {
            string_builder.write_string(&b, "#")
        }
        string_builder.write_string(&b, strings_tools.trim_space(fragment))
    }

    return string_builder.to_string(b)
}

percent_encode :: proc(s: string, allocator: mem.Allocator) -> string {
    b := string_builder.builder_create(allocator)
    strings_tools.builder_grow(&b, len(s) + 16) // NOTE(tetra): A reasonable number to allow for the number of things we need to escape.

    for ch in s {
        switch ch {
        case 'A'..='Z', 'a'..='z', '0'..='9', '-', '_', '.', '~':
            _, _ = string_builder.write_rune(&b, ch)
        case:
            bytes, n := utf8.bytes_from_rune(ch)
            for u8 in bytes[:n] {
                buf: [2]u8 = ---
                t := strconv.write_int(buf[:], i64(u8), 16)
                _, _ = string_builder.write_rune(&b, '%')
                string_builder.write_string(&b, t)
            }
        }
    }

    return string_builder.to_string(b)
}

percent_decode :: proc(encoded_string: string, allocator: mem.Allocator) -> (decoded_string: string, ok: bool) {
    b := string_builder.builder_create(allocator)
    strings_tools.builder_grow(&b, len(encoded_string))
    defer if !ok {
        string_builder.builder_destroy(&b)
    }

    s := encoded_string

    for len(s) > 0 {
        i := strings_tools.index_byte(s, '%')
        if i == -1 {
            string_builder.write_string(&b, s) // no '%'s; the string is already decoded
            break
        }

        string_builder.write_string(&b, s[:i])
        s = s[i:]

        if len(s) == 0 {
            return // percent without anything after it
        }
        s = s[1:]

        if s[0] == '%' {
            string_builder.write_byte(&b, '%')
            s = s[1:]
            continue
        }

        if len(s) < 2 {
            return // percent without encoded value
        }

        val := hex.decode_sequence(s[:2]) or_return
        string_builder.write_byte(&b, val)
        s = s[2:]
    }

    ok = true
    decoded_string = string_builder.to_string(b)
    return
}

//
// TODO: encoding/base64 is broken...
//

// // TODO(tetra): The whole "table" stuff in encoding/base64 is too impenetrable for me to
// // make a table for this ... sigh - so this'll do for now.
/*
base64url_encode :: proc(data: []u8, allocator: mem.Allocator) -> string {
    out := transmute([]u8) base64.encode(data, base64.ENC_TABLE, allocator);
    for b, i in out {
        switch b {
        case '+': out[i] = '-';
        case '/': out[i] = '_';
        }
    }
    i := len(out)-1;
    for ; i >= 0; i -= 1 {
        if out[i] != '=' {
            break;
        }
    }
    return string(out[:i+1]);
}

base64url_decode :: proc(s: string, allocator: mem.Allocator) -> []u8 {
    size := len(s);
    padding := 0;
    for size % 4 != 0 {
        size += 1; // TODO: SPEED
        padding += 1;
    }

    temp := slice.create(u8, size, allocators.temp_allocator);
    slice.copy(temp, transmute([]u8) s);

    for b, i in temp {
        switch b {
        case '-': temp[i] = '+';
        case '_': temp[i] = '/';
        }
    }

    for in 0..padding-1 {
        temp[len(temp)-1] = '=';
    }

    return base64.decode(string(temp), base64.DEC_TABLE, allocator);
}
*/

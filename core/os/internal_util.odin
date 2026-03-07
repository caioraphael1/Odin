#+private
import "base:intrinsics"
import "base:internal"
import "base:mem"
import "core:math/rand"


// Splits pattern by the last wildcard "*", if it exists, and returns the prefix and suffix
// parts which are split by the last "*"

_prefix_and_suffix :: proc(pattern: string) -> (prefix, suffix: string, err: Error) {
    for i in 0..<len(pattern) {
        if is_path_separator(pattern[i]) {
            err = .Pattern_Has_Separator
            return
        }
    }
    prefix = pattern
    for i := len(pattern)-1; i >= 0; i -= 1 {
        if pattern[i] == '*' {
            prefix, suffix = pattern[:i], pattern[i+1:]
            break
        }
    }
    return
}


clone_string :: proc(s: string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    buf := slice_create([]byte, len(s), allocator) or_return
    slice_copy_from_string(buf, s)
    return string(buf), nil
}



clone_to_cstring :: proc(s: string, allocator: mem.Allocator) -> (res: cstring, err: mem.Allocator_Error) {
    res = "" // do not use a `nil` cstring
    buf := slice_create([]byte, len(s)+1, allocator) or_return
    slice_copy_from_string(buf, s)
    buf[len(s)] = 0
    return cstring(&buf[0]), nil
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


concatenate_strings_from_buffer :: proc(buf: []byte, strings: ..string) -> string {
    n := 0
    for s in strings {
        (n < len(buf)) or_break
        n += slice_copy_from_string(buf[n:], s)
    }
    n = min(len(buf), n)
    return string(buf[:n])
}


concatenate :: proc(strings: []string, allocator: mem.Allocator) -> (res: string, err: mem.Allocator_Error) {
    n := 0
    for s in strings {
        n += len(s)
    }
    buf := slice_create([]byte, n, allocator) or_return
    n = 0
    for s in strings {
        n += slice_copy_from_string(buf[n:], s)
    }
    return string(buf), nil
}


random_string :: proc(buf: []byte) -> string {
    for i := 0; i < len(buf); i += 16 {
        n := rand.uint64(internal.global_random_generator)
        end := min(i + 16, len(buf))
        for j := i; j < end; j += 1 {
            buf[j] = '0' + u8(n) % 10
            n >>= 4
        }
    }
    return string(buf)
}

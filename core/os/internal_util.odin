#+private
import "base:intrinsics"
import "base:internal"
import "base:mem"
import "base:rand"
import "base:container/slice"


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
    for i := int(len(pattern)) - 1; i >= 0; i -= 1 {
        if pattern[i] == '*' {
            prefix, suffix = pattern[:i], pattern[i+1:]
            break
        }
    }
    return
}

random_string :: proc(buf: []u8) -> string {
    for i: uint = 0; i < len(buf); i += 16 {
        n := rand.uint64(rand.global_random_generator)
        end := min(i + 16, len(buf))
        for j := i; j < end; j += 1 {
            buf[j] = '0' + u8(n) % 10
            n >>= 4
        }
    }
    return string(buf)
}

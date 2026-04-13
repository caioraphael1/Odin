import "base:builtin"
import "base:mem"
import base_slice "base:container/slice"


Fixed_String :: struct($N: u32) where N >= 0 {
    data: [N]u8,
    len:  uint,
}


len :: proc(s: Fixed_String($N)) -> uint {
    return s.len
}

cap :: proc(s: Fixed_String($N)) -> uint {
    return uint(N)
}

store_string :: proc(s: ^Fixed_String($N), str: string) -> (ok: bool) {
    ok = resize(s, builtin.len(str))
    if !ok { return }
    base_slice.copy_from_string(slice(s), str)
    return
}

as_string :: proc(s: ^Fixed_String($N)) -> string {
    return string(slice(s))
}

as_cstring :: proc(s: ^Fixed_String($N)) -> (cs: cstring, ok: bool) {
    if s.len + 1 > uint(N) {
        return nil, false
    }
    s.data[s.len] = 0
    return cstring(&s.data[0]), true
}

slice :: proc(s: ^Fixed_String($N)) -> []u8 {
    return s.data[:s.len]
}

resize :: proc(s: ^Fixed_String($N), length: uint) -> (ok: bool) {
    length := length
    ok = length <= uint(N)
    if !ok {
        length = uint(N)
    }

    prev_len := s.len
    s.len = length
    if s.len > prev_len {
        // Zero only the new region after growth.
        mem.zero(&s.data[prev_len], size_of(u8) * (s.len - prev_len))
    }

    return
}

clear :: proc(s: ^Fixed_String($N)) {
    s.len = 0
}

import "base:mem"


Fixed_String :: struct($N: u32) where N >= 0 {
    len:  uint,
    data: [N]u8,
}

cap :: #force_inline proc(s: Fixed_String($N)) -> uint {
    return uint(N)
}


// temp: the correct thing is converting to a String_Buffer.
str :: #force_inline proc(s: ^Fixed_String($N)) -> string {
    return string(slice(s))
}
cstr :: proc(s: ^Fixed_String($N)) -> (cs: cstring, ok: bool) {
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

clear :: #force_inline proc(s: ^Fixed_String($N)) {
    s.len = 0
}

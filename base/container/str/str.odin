import "base:mem"
import "base:strconv"
import "base:unicode/utf8"


String :: struct($N: u32) where N >= 0 {
    len:  uint,
    data: [N]u8,
}


// temp: the correct thing is converting to a String($N).
str :: #force_inline proc(s: ^String($N)) -> string {
    return string(slice(s))
}
cstr :: proc(s: ^String($N)) -> (cs: cstring, ok: bool) {
    if s.len + 1 > uint(N) {
        return nil, false
    }
    s.data[s.len] = 0
    return cstring(&s.data[0]), true
}
slice :: proc(s: ^String($N)) -> []u8 {
    return s.data[:s.len]
}



cap :: #force_inline proc(s: String($N)) -> uint {
    return uint(N)
}




resize :: proc(s: ^String($N), len: uint) -> (ok: bool) {
    if len > N {
        return false
    }

    s.len = len
    return true
}

clear :: #force_inline proc(s: ^String($N)) {
    s.len = 0
}




remaining_space :: #force_inline proc(s: String($N)) -> uint {
    return uint(N) - s.len
}

ptr_get :: #force_inline proc(ptr: $T, len: uint) -> T {
    return T(uintptr(ptr) + uintptr(len))
}

ptr_set :: #force_inline proc(ptr: $T, index: uint, item: u8) {
    ptr_get(ptr, index)^ = item
}


resize_and_zero :: proc(s: ^String($N), len: uint) -> (ok: bool) {
    if len > s.cap {
        return false
    }

    prev_len := s.len
    s.len = len
    if s.len > prev_len  {
        // Zero only the new region after growth.
        // mem.zero(&s.data[prev_len], size_of(T)*(a.len - prev_len))
            // todo:
    }
    return true
}


zero :: proc(s: ^String($N), len: uint) {
    mem.zero(s.data, len)
}


unordered_remove :: proc(s: ^String($N), index: uint, loc := #caller_location) -> (ok: bool) {
    if uint(index) >= uint(s.len) {
        return false
    }
    n := s.len - 1
    if index != n {
        s.data[index] = s.data[n]
    }
    s.len -= 1
    return true
}

consume :: proc(s: ^String($N), count: uint, loc := #caller_location) -> (ok: bool) {
    if count > s.len || s.len == 0 {
        return false
    }
    s.len -= count
    return true
}






write_byte :: proc(s: ^String($N), x: u8) -> (ok: bool) {
    if s.len >= uint(N) {
        return false
    }
    s.data[s.len] = x
    s.len += 1
    return true
}

write_bytes :: proc(s: ^String($N), bytes: []u8) -> (ok: bool) {
    for x in bytes {
        write_byte(s, x) or_return
    }
    return true
}


write_string :: proc(s: ^String($N), str: string) -> (ok: bool) {
    // not enough available space
    if remaining_space(s^) < len(str) {
        return false
    }

    mem.copy(&s.data[s.len], raw_data(str), len(str))
    s.len += len(str)
    return true
}

// write_string2 :: proc(s: ^u8, cap: uint, len: ^uint, str: string) -> (ok: bool) {
//     // not enough available space
//     if cap - len^ < len(str) {
//         return false
//     }

//     mem.copy(ptr_get(s, len^), raw_data(str), len(str))
//     len^ += len(str)
//     return true
// }

write_rune :: proc(s: ^String($N), r: rune) -> (ok: bool) {
    bytes, width := utf8.bytes_from_rune(r)

    return write_bytes(s, bytes[:width])
}



String_Type :: union {
    string,     // "pointer to a [N]u8"
    String(20), // "the [N]u8"
    String(4),  // "the [N]u8"
}


write :: proc(s: ^String($N), strs: ..String_Type) -> (ok: bool) {
    for str in strs {
        switch &v in str {
            case string:
                write_string(s, v) or_return
            case String(20):
                write_string(s, string(v.data[:v.len])) or_return
            case String(4):
                write_string(s, string(v.data[:v.len])) or_return
            }
    }

    return true
}

writeln :: proc(s: ^String($N), strs: ..String_Type) -> (ok: bool) {
    write(s, ..strs) or_return
    write(s, "\n")   or_return
    return true
}


writef :: proc(s: ^String($N), format: string, strs: ..String_Type) -> (ok: bool) {
    str_i: uint
    i: uint
    loop: for i < len(format) {
        char := format[i]
        switch char {
        case '%':
            switch &v in strs[str_i] {
            case string:
                write_string(s, v) or_return
            case String(20):
                write_string(s, str(&v)) or_return
            case String(4):
                write_string(s, str(&v)) or_return
            }
            str_i += 1
        case:
            write_byte(s, char) or_return
        }
        i += 1
    }
    return true
}

writefln :: proc(s: ^String($N), format: string, strs: ..String_Type) -> (ok: bool) {
    writef(s, format, ..strs) or_return
    write(s, "\n") or_return
    return true
}


set :: proc(s: ^String($N), strs: ..String_Type) -> (ok: bool) {
    clear(s)
    return write(s, ..strs)
}


setf :: proc(s: ^String($N), format: string, strs: ..String_Type) -> (ok: bool) {
    clear(s)
    return writef(s, format, ..strs)
}






from_uint :: proc(num: uint, base: uint = 10) -> (str: String(20)/*the biggest uint requires 20 bytes */) {
    s := strconv.write_uint(str.data[:], u64(num), base)
    str.len += len(s)
    return
}

from_int :: proc(num: int, base: uint = 10) -> (str: String(20)/*the biggest int requires 20 bytes */) {
    s := strconv.write_int(str.data[:], i64(num), base)
    str.len += len(s)
    return
}

from_bool :: proc(b: bool) -> (str: String(4)) {
    s := strconv.write_bool(str.data[:], b)
    str.len += len(s)
    return
}

from_float :: proc(f: f64, prec: uint = 10) -> (str: String(20)) {
    s := strconv.write_float(str.data[:], f, 'f', prec, 64, false)
    str.len += len(s)
    return
}

/* 
This is giving a compiler error:
    e: $T where intrinsics.type_is_enum(T)
*/
from_enum :: proc(#any_int e: uint) -> (str: String(20)) {
    return from_uint(uint(e))
}

// TODO: I don't have a proper way to ptr_get the value under the index.
// type_union_tag_type       :: proc($T: typeid) -> typeid
// type_union_tag_offset     :: proc($T: typeid) -> uintptr
// type_union_base_tag_value :: proc($T: typeid) -> int
// type_union_variant_count  :: proc($T: typeid) -> int
// from_union :: proc($TYPE: typeid) -> (str: String(20)) where intrinsics.type_is_union(T) {
//     return from_uint(intrinsics.type_union_base_tag_value(TYPE))
// }
from_union :: proc(un: $T) -> (str: string) {
    // TODO: placeholder
    return
}


from_ptr :: proc(p: rawptr) -> (str: String(20)) {
    str = from_uint(uint(uintptr(p)))    
    return 
}


import "base:mem"
import fs "base:container/fixed_string"
import "base:strconv"
import "base:unicode/utf8"


String_Buffer :: struct {
    len: uint,
    cap: uint,
    buf: ^u8,
}


create :: proc(buf: ^u8, cap: uint, len: uint) -> String_Buffer {
    return {
        buf = buf,
        cap = cap,
        len = len,
    }
}

from_fs :: #force_inline proc(s: ^fs.Fixed_String($N)) -> String_Buffer {
    return { s.len, N, &s.data[0] }
}


remaining_space :: #force_inline proc(b: String_Buffer) -> uint {
    return b.cap - b.len
}

ptr_get :: #force_inline proc(ptr: $T, len: uint) -> T {
    return T(uintptr(ptr) + uintptr(len))
}

ptr_set :: #force_inline proc(ptr: $T, index: uint, item: u8) {
    ptr_get(ptr, index)^ = item
}

resize :: proc(b: ^String_Buffer, len: uint) -> (ok: bool) {
    if len > b.cap {
        return false
    }

    b.len = len
    return true
}

resize_and_zero :: proc(b: ^String_Buffer, len: uint) -> (ok: bool) {
    if len > b.cap {
        return false
    }

    prev_len := b.len
    b.len = len
    if b.len > prev_len  {
        // Zero only the new region after growth.
        // mem.zero(&b.buf[prev_len], size_of(T)*(a.len - prev_len))
            // todo:
    }
    return true
}


// temp:
slice :: #force_inline proc(b: String_Buffer) -> []u8 {
    return (cast([^]u8)(b.buf))[:b.len]
}
slice_all :: #force_inline proc(b: String_Buffer) -> []u8 {
    return (cast([^]u8)(b.buf))[:b.cap]
}
str :: #force_inline proc(b: String_Buffer) -> string {
    return string((cast([^]u8)(b.buf))[:b.len])
}



zero :: proc(b: ^String_Buffer, len: uint) {
    mem.zero(b.buf, len)
}


unordered_remove :: proc(b: ^String_Buffer, index: uint, loc := #caller_location) -> (ok: bool) {
    if uint(index) >= uint(b.len) {
        return false
    }
    n := b.len - 1
    if index != n {
        ptr_set(b.buf, index, ptr_get(b.buf, n)^)
            // equivalent to b.buf[index] = b.buf[n]
    }
    b.len -= 1
    return true
}

consume :: proc(b: ^String_Buffer, count: uint, loc := #caller_location) -> (ok: bool) {
    if count > b.len || b.len == 0 {
        return false
    }
    b.len -= count
    return true
}


clear :: #force_inline proc(b: ^String_Buffer) {
    b.len = 0
}



write_byte :: proc(b: ^String_Buffer, x: u8) -> (ok: bool) {
    if b.len >= b.cap {
        return false
    }
    ptr := (^u8)(ptr_get(b.buf, b.len))
    ptr^ = x
    b.len += 1
    return true
}

write_bytes :: proc(b: ^String_Buffer, bytes: []u8) -> (ok: bool) {
    for x in bytes {
        write_byte(b, x) or_return
    }
    return true
}


write_string :: proc(b: ^String_Buffer, str: string) -> (ok: bool) {
    // not enough available space
    if remaining_space(b^) < len(str) {
        return false
    }

    mem.copy(ptr_get(b.buf, b.len), raw_data(str), len(str))
    b.len += len(str)
    return true
}

// write_string2 :: proc(buf: ^u8, cap: uint, len: ^uint, str: string) -> (ok: bool) {
//     // not enough available space
//     if cap - len^ < len(str) {
//         return false
//     }

//     mem.copy(ptr_get(buf, len^), raw_data(str), len(str))
//     len^ += len(str)
//     return true
// }

write_rune :: proc(b: ^String_Buffer, r: rune) -> (ok: bool) {
    bytes, width := utf8.bytes_from_rune(r)

    return write_bytes(b, bytes[:width])
}



String_Type :: union {
    string,              // "pointer to a [N]u8"
    fs.Fixed_String(20), // "the [N]u8"
    fs.Fixed_String(4),  // "the [N]u8"
}


write :: proc(buf: ^String_Buffer, strs: ..String_Type) -> (ok: bool) {
    for str in strs {
        switch &v in str {
            case string:
                write_string(buf, v) or_return
            case fs.Fixed_String(20):
                write_string(buf, fs.str(&v)) or_return
            case fs.Fixed_String(4):
                write_string(buf, fs.str(&v)) or_return
            }
    }

    return true
}


writef :: proc(buf: ^String_Buffer, format: string, strs: ..String_Type) -> (ok: bool) {
    str_i: uint
    i: uint
    loop: for i < len(format) {
        char := format[i]
        switch char {
        case '%':
            switch &v in strs[str_i] {
            case string:
                write_string(buf, v) or_return
            case fs.Fixed_String(20):
                write_string(buf, fs.str(&v)) or_return
            case fs.Fixed_String(4):
                write_string(buf, fs.str(&v)) or_return
            }
            str_i += 1
        case:
            write_byte(buf, char) or_return
        }
        i += 1
    }
    return true
}


set :: proc(buf: ^String_Buffer, strs: ..String_Type) -> (ok: bool) {
    clear(buf)
    return write(buf, ..strs)
}


setf :: proc(buf: ^String_Buffer, format: string, strs: ..String_Type) -> (ok: bool) {
    clear(buf)
    return writef(buf, format, ..strs)
}






from_uint :: proc(num: uint, base: uint = 10) -> (str: fs.Fixed_String(20)/*the biggest uint requires 20 bytes */) {
    s := strconv.write_uint(str.data[:], u64(num), base)
    str.len += len(s)
    return
}

from_int :: proc(num: int, base: uint = 10) -> (str: fs.Fixed_String(20)/*the biggest int requires 20 bytes */) {
    s := strconv.write_int(str.data[:], i64(num), base)
    str.len += len(s)
    return
}

from_bool :: proc(b: bool) -> (str: fs.Fixed_String(4)) {
    s := strconv.write_bool(str.data[:], b)
    str.len += len(s)
    return
}

/* 
This is giving a compiler error:
    e: $T where intrinsics.type_is_enum(T)
*/
from_enum :: proc(#any_int e: uint) -> (str: fs.Fixed_String(20)) {
    return from_uint(uint(e))
}

// TODO: I don't have a proper way to ptr_get the value under the index.
// type_union_tag_type       :: proc($T: typeid) -> typeid
// type_union_tag_offset     :: proc($T: typeid) -> uintptr
// type_union_base_tag_value :: proc($T: typeid) -> int
// type_union_variant_count  :: proc($T: typeid) -> int
// from_union :: proc($TYPE: typeid) -> (str: fs.Fixed_String(20)) where intrinsics.type_is_union(T) {
//     return from_uint(intrinsics.type_union_base_tag_value(TYPE))
// }
from_union :: proc(un: $T) -> (str: string) {
    // placeholder
    return
}


from_ptr :: proc(p: rawptr) -> (str: fs.Fixed_String(20)) {
    str = from_uint(uint(uintptr(p)))    
    return 
}

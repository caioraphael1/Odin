import "base:mem"
import fs "base:container/fixed_string"
import "base:strconv"


String_Buffer :: struct {
    buf: ^u8,
    cap: uint,
    len: uint,
}


create :: proc(buf: ^u8, cap: uint, len: uint) -> String_Buffer {
    return {
        buf = buf,
        cap = cap,
        len = len,
    }
}

remaining_space :: #force_inline proc(b: String_Buffer) -> uint {
    return b.cap - b.len
}

get :: #force_inline proc(ptr: $T, len: uint) -> T {
    return T(uintptr(ptr) + uintptr(len))
}

set :: proc(ptr: $T, index: uint, item: u8) {
    get(ptr, index)^ = item
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
slice :: proc(b: String_Buffer) -> []u8 {
    return (cast([^]u8)(b.buf))[:b.len]
}

slice_all :: proc(b: String_Buffer) -> []u8 {
    return (cast([^]u8)(b.buf))[:b.cap]
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
        set(b.buf, index, get(b.buf, n)^)
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


clear :: proc(b: ^String_Buffer) {
    b.len = 0
}






write_byte :: proc(b: ^String_Buffer, x: u8) -> (ok: bool) {
    if b.len >= b.cap {
        return false
    }

    ptr := (^u8)(get(b.buf, b.len))
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

    mem.copy(get(b.buf, b.len), raw_data(str), len(str))
    b.len += len(str)
    return true
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
                write_string(buf, fs.as_string(&v)) or_return
            case fs.Fixed_String(4):
                write_string(buf, fs.as_string(&v)) or_return
            }
    }

    return true
}


write_fmt :: proc(buf: ^String_Buffer, format: string, strs: ..String_Type) -> (ok: bool) {
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
                write_string(buf, fs.as_string(&v)) or_return
            case fs.Fixed_String(4):
                write_string(buf, fs.as_string(&v)) or_return
            }
            str_i += 1
        case:
            write_byte(buf, char) or_return
        }
        i += 1
    }
    return true
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

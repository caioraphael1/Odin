import "base:mem"


Buffer :: struct {
    buf: ^u8,
    cap: uint,
    len: uint,
}


create :: proc(buf: ^u8, cap: uint, len: uint) -> Buffer {
    return {
        buf = buf,
        cap = cap,
        len = len,
    }
}

remaining_space :: #force_inline proc(b: Buffer) -> uint {
    return b.cap - b.len
}

get :: #force_inline proc(ptr: $T, len: uint) -> T {
    return T(uintptr(ptr) + uintptr(len))
}

set :: proc(ptr: $T, index: uint, item: u8) {
    get(ptr, index)^ = item
}

resize :: proc(b: ^Buffer, len: uint) -> (ok: bool) {
    if len > b.cap {
        return false
    }

    // prev_len := b.len
    b.len = len
//    if b.len > prev_len  {
//         // Zero only the new region after growth.
//         mem.zero(&a.data[prev_len], size_of(T)*(a.len - prev_len))
//     }
    return true
}

// temp:
slice :: proc(b: Buffer) -> []u8 {
    return (cast([^]u8)(b.buf))[:b.len]
}

slice_all :: proc(b: Buffer) -> []u8 {
    return (cast([^]u8)(b.buf))[:b.cap]
}


zero :: proc(b: ^Buffer, len: uint) {
    mem.zero(b.buf, len)
}


append :: proc(b: ^Buffer, x: u8) -> bool {
    if b.len >= b.cap {
        return false
    }

    ptr := (^u8)(get(b.buf, b.len))
    ptr^ = x
    b.len += 1
    return true
}

unordered_remove :: proc(b: ^Buffer, index: uint, loc := #caller_location) -> (ok: bool) {
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

consume :: proc(b: ^Buffer, count: uint, loc := #caller_location) -> (ok: bool) {
    if count > b.len || b.len == 0 {
        return false
    }
    b.len -= count
    return true
}


clear :: proc(b: ^Buffer) {
    b.len = 0
}


write_string :: proc(b: ^Buffer, str: string) -> (ok: bool) {
    // not enough available space
    if remaining_space(b^) < len(str) {
        return false
    }

    mem.copy(get(b.buf, b.len), raw_data(str), len(str))
    b.len += len(str)
    return true
}

write_byte :: proc(b: ^Buffer, x: u8) -> (n: uint, ok: bool) {
    return 1, append(b, x)
}




/*
format_ok := fmt.format(a_string_slice_from_fixed_string, "%a - %b", type_a, type_b))


bprintln :: proc(buf: []u8, args: ..any, sep := " ") -> string {
    sb := string_builder.builder_from_bytes(buf)
    return sbprintln(&sb, ..args, sep=sep)
}



b := builder_create()

str.write_string(&b, "hallo")

str.write_string(&b, "world")

str.write_int(12)
*/



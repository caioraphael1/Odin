import "base:container/str"

import "core:io"


// write_padded_hex :: proc(buf: ^str.String($N), #any_int n: int, zeroes: uint) {
write_padded_hex :: proc(w: io.Writer, #any_int n: int, zeroes: uint) {
    // temp, just for measure....
    temp_buf: str.String(32)
    _ = str.write(&temp_buf, str.from_int(n, 0x10))

    // buf
    /* 
    _ = str.write(buf, "0x")
    for _ in 0..<max(0, zeroes - temp_buf.len) {
        _ = str.write_byte(buf, '0')
    }
    _ = str.write(buf, str.from_int(n, 0x10))
    */

    _, _ = io.write_string(w, "0x")
    for _ in 0..<max(0, zeroes - temp_buf.len) {
        _ = io.write_byte(w, '0')
    }
    _, _ = io.write_int(w, n, 0x10)
}


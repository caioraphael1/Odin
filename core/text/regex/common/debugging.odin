import sb "base:container/string_buffer"


write_padded_hex :: proc(buf: ^sb.String_Buffer, #any_int n: int, zeroes: uint) {
    // temp, just for measure....
    temp_backing: [32]u8
    temp_buf := sb.create(raw_data(temp_backing[:]), len(temp_backing), 0)
    _ = sb.write(&temp_buf, sb.from_int(n, 0x10))

    // buf
    _ = sb.write(buf, "0x")
    for _ in 0..<max(0, zeroes - temp_buf.len) {
        _ = sb.write_byte(buf, '0')
    }
    _ = sb.write(buf, sb.from_int(n, 0x10))
}

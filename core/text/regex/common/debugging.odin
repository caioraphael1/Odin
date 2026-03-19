
/*
    (c) Copyright 2024 Feoramund <rune@swevencraft.org>.
    Made available under Odin's license.

    List of contributors:
        Feoramund: Initial implementation.
*/

import "base:mem"
import "base:container/strings"

import "core:io"
import "core:strings_tools"

write_padded_hex :: proc(w: io.Writer, #any_int n, zeroes: int, allocator: mem.Allocator) {
    sb := strings_tools.builder_create(allocator)
    defer strings_tools.builder_destroy(&sb)

    sbw := strings_tools.to_writer(&sb)
    _, _ = io.write_int(sbw, n, 0x10)

    _, _ = io.write_string(w, "0x")
    for _ in 0..<max(0, zeroes - strings_tools.builder_len(sb)) {
        _ = io.write_byte(w, '0')
    }
    _, _ = io.write_int(w, n, 0x10)
}

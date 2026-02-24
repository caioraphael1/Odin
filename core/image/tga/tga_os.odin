#+build !js

import os "core:os/os2"
import "core:bytes"


load_from_file :: proc(filename: string, options := Options{}, allocator: mem.Allocator) -> (img: ^Image, err: Error) {

    data, data_err := os.read_entire_file_from_path(filename, allocator)
    defer _ = delete_slice(data, allocator)

    if data_err == nil {
        return load_from_bytes(data, options)
    } else {
        return nil, .Unable_To_Read_File
    }
}

save_to_file :: proc(output: string, img: ^Image, options := Options{}, allocator: mem.Allocator) -> (err: Error) {

    out := &bytes.Buffer{}
    defer bytes.buffer_destroy(out)

    save_to_buffer(out, img, options) or_return
    write_err := os.write_entire_file_from_string(output, out.buf[:])

    return nil if write_err == nil else .Unable_To_Write_File
}

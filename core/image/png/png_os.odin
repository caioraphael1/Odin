#+build !js
package png

import "core:os"


load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
    context.allocator = allocator

    data, ok := os.read_entire_file(filename)
    defer _ = delete(data)

    if ok {
        return load_from_bytes(data, options)
    } else {
        return nil, .Unable_To_Read_File
    }
}

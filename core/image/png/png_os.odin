#+build !js
import "core:os"


load_from_file :: proc(filename: string, options := Options{}, allocator : mem.Allocator) -> (img: ^Image, err: Error) {


    data, ok := os.read_entire_file(filename)
    defer _ = delete_slice(data)

    if ok {
        return load_from_bytes(data, options)
    } else {
        return nil, .Unable_To_Read_File
    }
}

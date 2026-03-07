#+build !js
import "core:os"


load_from_file :: proc(filename: string, allocator : mem.Allocator) -> (img: ^Image, err: Error) {


    data, ok := os.read_entire_file(filename); defer _ = slice.delete(data)
    if !ok {
        err = .Unable_To_Read_File
        return
    }

    return load_from_bytes(data)
}


save_to_file :: proc(filename: string, img: ^Image, custom_info: Info = {}, allocator : mem.Allocator) -> (err: Error) {


    data: []byte; defer _ = slice.delete(data)
    data = save_to_buffer(img, custom_info) or_return

    if ok := os.write_entire_file(filename, data); !ok {
        return .Unable_To_Write_File
    }

    return Format_Error.None
}

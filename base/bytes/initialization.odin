import "base:container/slice"

bytes :: #force_inline proc(ptr: rawptr, len: uint) -> []u8 {
    return ([^]u8)(ptr)[:len]
}

bytes_unsafe :: #force_inline proc(data: rawptr, len: uint) -> []u8 #no_bounds_check {
    return ([^]u8)(data)[:len]
}

bytes_from_ptr :: proc(ptr: ^$T, len: uint) -> []u8 {
    return transmute([]u8)slice.Raw_Slice{ptr, len * size_of(T)}
}

bytes_to_ptr :: proc(str: []u8) -> ^u8 {
    return raw_data(str)
}

bytes_from_any :: proc(val: any) -> []u8 {
    ti := type_info_of(val.id)
    size := ti != nil ? ti.size : 0
    return transmute([]u8)slice.Raw_Slice{val.data, uint(size)}
}

import "base:container/slice"

bytes :: #force_inline proc(ptr: rawptr, len: uint) -> []byte {
    return ([^]byte)(ptr)[:len]
}

bytes_unsafe :: #force_inline proc(data: rawptr, len: uint) -> []byte #no_bounds_check {
    return ([^]byte)(data)[:len]
}

bytes_from_ptr :: proc(ptr: ^$T, len: uint) -> []byte {
    return transmute([]byte)slice.Raw_Slice{ptr, len * size_of(T)}
}

bytes_to_ptr :: proc(str: []byte) -> ^byte {
    return raw_data(str)
}

bytes_from_slice :: proc(slice: $E/[]$T) -> []byte {
    s := transmute(slice.Raw_Slice)slice
    s.len *= size_of(T)
    return transmute([]byte)s
}

bytes_from_any :: proc(val: any) -> []byte {
    ti := type_info_of(val.id)
    size := ti != nil ? ti.size : 0
    return transmute([]byte)slice.Raw_Slice{val.data, size}
}

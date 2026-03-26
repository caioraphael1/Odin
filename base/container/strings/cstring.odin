import "base:internal"
import "base:mem"
import "base:container/slice"

Raw_Cstring :: internal.Raw_Cstring

cstring_from_string_unsafe :: proc(str: string) -> (res: cstring) {
    d := transmute(Raw_String)str
    return cstring(d.data)
}


cstring_clone_from_string :: proc(s: string, allocator: mem.Allocator, loc := #caller_location) -> (res: cstring, err: mem.Allocator_Error) {
    c := slice.create([]u8, len(s)+1, allocator, loc) or_return
    slice.copy_from_string(c, s)
    c[len(s)] = 0
    return cstring(&c[0]), nil
}

cstring_delete :: proc(str: cstring, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free((^u8)(str), allocator, loc)
}

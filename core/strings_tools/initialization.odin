import "base:mem"

string_from_null_terminated_ptr :: proc(ptr: [^]byte, len: uint) -> (res: string) {
    s := string(ptr[:len])
    s = truncate_to_byte(s, 0)
    return s
}


/*
Clones a string from a null-terminated cstring `ptr` and a byte length `len`
NOTE: Truncates at the first null-byte encountered or the byte length.
*/
clone_from_cstring_bounded :: proc(ptr: cstring, len: uint, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    s := strings.string_from_ptr((^u8)(ptr), len)
    s = truncate_to_byte(s, 0)
    return strings.string_clone(s, allocator, loc)
}

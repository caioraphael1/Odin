import "base:mem"
import "base:container/strings"


string_from_null_terminated_ptr :: proc(ptr: [^]u8, len: uint) -> (res: string) {
    s := string(ptr[:len])
    s = truncate_to_byte(s, 0)
    return s
}


/*
Clones a string from a null-terminated cstring `ptr` and a u8 length `len`
NOTE: Truncates at the first null-u8 encountered or the u8 length.
*/
string_clone_from_cstring_bounded :: proc(ptr: cstring, len: uint, allocator: mem.Allocator, loc := #caller_location) -> (res: string, err: mem.Allocator_Error) {
    s := strings.string_from_ptr((^u8)(ptr), len)
    s = truncate_to_byte(s, 0)
    return strings.string_clone(s, allocator, loc)
}

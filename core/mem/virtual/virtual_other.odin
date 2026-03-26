#+private
#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows


_reserve :: proc(size: uint) -> (data: []u8, err: Allocator_Error) {
    return nil, nil
}

_commit :: proc(data: rawptr, size: uint) -> Allocator_Error {
    return nil
}

_decommit :: proc(data: rawptr, size: uint) {
}

_release :: proc(data: rawptr, size: uint) {
}

_protect :: proc(data: rawptr, size: uint, flags: Protect_Flags) -> bool {
    return false
}

_platform_memory_init :: proc() {

}

_map_file :: proc(f: any, size: i64, flags: Map_File_Flags) -> (data: []u8, error: Map_File_Error) {
    return nil, .Map_Failure
}

_unmap_file :: proc(data: []u8) {

}

#+private

_pipe :: proc(allocator: mem.Allocator) -> (r, w: ^File, err: Error) {
    err = .Unsupported
    return
}


_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
    err = .Unsupported
    return
}

#+build js wasm32, js wasm64p32
#+private


// None of this does anything on js/wasm.
// It's only here so importing `core:os` on wasm panics cleanly,
// without spamming about all sorts of missing procs and types.

_pipe :: proc() -> (r, w: ^File, err: Error) {
    err = .Unsupported
    return
}


_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
    err = .Unsupported
    return
}

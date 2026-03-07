#+build js wasm32, js wasm64p32
#+private


// None of this does anything on js/wasm.
// It's only here so importing `core:os` on wasm panics cleanly,
// without spamming about all sorts of missing procs and types.

import "base:runtime"

build_env :: proc() -> (err: Error) {
    return
}


_lookup_env_alloc :: proc(key: string, allocator: mem.Allocator) -> (value: string, found: bool) {
    return
}

_lookup_env_buf :: proc(buf: []u8, key: string) -> (value: string, error: Error) {
    return "", .Unsupported
}


_set_env :: proc(key, value: string) -> (err: Error) {
    return .Unsupported
}


_unset_env :: proc(key: string) -> bool {
    return true
}

_clear_env :: proc() {

}


_environ :: proc(allocator: mem.Allocator) -> (environ: []string, err: Error) {
    return {}, .Unsupported
}

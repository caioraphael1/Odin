#+build js, wasi, freestanding, essence
#+private

_heap_alloc :: proc(size: uint, zero_memory := true) -> rawptr {
    internal.unimplemented("base:runtime 'heap_alloc' procedure is not supported on this platform")
}

_heap_resize :: proc(ptr: rawptr, new_size: uint) -> rawptr {
    internal.unimplemented("base:runtime 'heap_resize' procedure is not supported on this platform")
}

_heap_free :: proc(ptr: rawptr) {
    internal.unimplemented("base:runtime 'heap_free' procedure is not supported on this platform")
}

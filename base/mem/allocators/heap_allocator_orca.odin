#+build orca
#+private

foreign {
    @(link_name="malloc")   _orca_malloc   :: proc "c" (size: int) -> rawptr ---
    @(link_name="calloc")   _orca_calloc   :: proc "c" (num, size: int) -> rawptr ---
    @(link_name="free")     _orca_free     :: proc "c" (ptr: rawptr) ---
    @(link_name="realloc")  _orca_realloc  :: proc "c" (ptr: rawptr, size: int) -> rawptr ---
}

_heap_alloc :: proc(size: uint, zero_memory := true) -> rawptr {
    if size <= 0 {
        return nil
    }
    if zero_memory {
        return _orca_calloc(1, int(size))
    } else {
        return _orca_malloc(int(size))
    }
}

_heap_resize :: proc(ptr: rawptr, new_size: uint) -> rawptr {
    return _orca_realloc(ptr, int(new_size))
}

_heap_free :: proc(ptr: rawptr) {
    _orca_free(ptr)
}

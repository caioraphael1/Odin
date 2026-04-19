#+private

_temp_dir :: proc(allocator: mem.Allocator) -> (string, mem.Allocator_Error) {
    // NOTE: requires user to add /tmp to their preopen dirs, no standard way exists.
    return strings.string_clone("/tmp", allocator)
}

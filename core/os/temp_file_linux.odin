#+private

_temp_dir :: proc(allocator: mem.Allocator) -> (string, mem.Allocator_Error) {
    allocators.TEMP_ALLOCATOR_TEMP_GUARD(allocator)
    tmpdir := get_env("TMPDIR", allocators.temp_allocator)
    if tmpdir == "" {
        tmpdir = "/tmp"
    }
    return strings.string_clone(tmpdir, allocator)
}

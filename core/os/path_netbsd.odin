import "base:internal"

import "core:sys/posix"

_get_executable_path :: proc(allocator: mem.Allocator) -> (path: string, err: Error) {
    allocators.TEMP_ALLOCATOR_TEMP_GUARD(allocator)

    buf := dyn_array.create([dynamic]byte, 1024, allocators.temp_allocator) or_return
    for {
        n := posix.readlink("/proc/curproc/exe", raw_data(buf), len(buf))
        if n < 0 {
            err = _get_platform_error()
            return
        }

        if n < len(buf) {
            return strings.string_clone(string(buf[:n]), allocator)
        }

        _ = dyn_array.resize(&buf, len(buf)*2) or_return
    }
}

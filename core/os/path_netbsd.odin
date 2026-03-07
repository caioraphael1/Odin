import "base:runtime"

import "core:sys/posix"

_get_executable_path :: proc(allocator: mem.Allocator) -> (path: string, err: Error) {
    runtime.TEMP_ALLOCATOR_TEMP_GUARD(allocator)

    buf := dyn_array_create([dynamic]byte, 1024, runtime.temp_allocator) or_return
    for {
        n := posix.readlink("/proc/curproc/exe", raw_data(buf), len(buf))
        if n < 0 {
            err = _get_platform_error()
            return
        }

        if n < len(buf) {
            return clone_string(string(buf[:n]), allocator)
        }

        _ = dyn_array.resize(&buf, len(buf)*2) or_return
    }
}

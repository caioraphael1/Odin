package os2

import "base:runtime"

import "core:sys/posix"

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
    runtime.TEMP_ALLOCATOR_TEMP_GUARD(allocator)

    buf := make_dynamic_array([dynamic]byte, 1024, runtime.temp_allocator) or_return
    for {
        n := posix.readlink("/proc/curproc/exe", raw_data(buf), len(buf))
        if n < 0 {
            err = _get_platform_error()
            return
        }

        if n < len(buf) {
            return clone_string(string(buf[:n]), allocator)
        }

        _ = resize(&buf, len(buf)*2) or_return
    }
}

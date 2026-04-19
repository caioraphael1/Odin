import "core:sys/darwin"
import "core:sys/posix"

_get_executable_path :: proc(allocator: mem.Allocator) -> (path: string, err: Error) {
    buffer: [darwin.PIDPATHINFO_MAXSIZE]u8 = ---
    ret := darwin.proc_pidpath(posix.getpid(), raw_data(buffer[:]), len(buffer))
    if ret > 0 {
        return strings.string_clone(string(buffer[:ret]), allocator)
    }

    err = _get_platform_error()
    return
}

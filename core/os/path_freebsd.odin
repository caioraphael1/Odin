import "base:internal"

import "core:sys/freebsd"
import "core:sys/posix"

_get_executable_path :: proc(allocator: mem.Allocator) -> (path: string, err: Error) {
    req := []freebsd.MIB_Identifier{.CTL_KERN, .KERN_PROC, .KERN_PROC_PATHNAME, freebsd.MIB_Identifier(-1)}

    size: uint
    if ret := freebsd.sysctl(req, nil, &size, nil, 0); ret != .NONE {
        err = _get_platform_error(posix.Errno(ret))
        return
    }
    internal.assert(size > 0)

    buf := slice.create(u8, size, allocator) or_return
    defer if err != nil { _ = slice.delete(buf, allocator) }

    internal.assert(uint(len(buf)) == size)

    if ret := freebsd.sysctl(req, raw_data(buf), &size, nil, 0); ret != .NONE {
        err = _get_platform_error(posix.Errno(ret))
        return
    }

    return string(buf[:size-1]), nil
}

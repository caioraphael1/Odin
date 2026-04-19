#+private
#+build darwin, netbsd, freebsd, openbsd

@(require)
import "core:sys/posix"

_temp_dir :: proc(allocator: mem.Allocator) -> (string, mem.Allocator_Error) {
    if tmp, ok := _lookup_env("TMPDIR", allocator); ok {
        return tmp, nil
    }

    when #defined(posix.P_tmpdir) {
        return strings.string_clone(posix.P_tmpdir, allocator)
    }

    return strings.string_clone("/tmp/", allocator)
}

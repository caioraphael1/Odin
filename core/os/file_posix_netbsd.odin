#+private
import "base:runtime"

import "core:sys/posix"

_posix_absolute_path :: proc(fd: posix.FD, name: string, allocator: mem.Allocator) -> (path: cstring, err: Error) {
	F_GETPATH :: 15

	buf: [posix.PATH_MAX]byte
	if posix.fcntl(fd, posix.FCNTL_Cmd(F_GETPATH), &buf) != 0 {
		err = _get_platform_error()
		return
	}

	return strings.cstring_clone_from_string(string(cstring(&buf[0])), allocator)
}

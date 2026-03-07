#+private
#+build openbsd
import "base:internal"

import "core:sys/posix"

_posix_absolute_path :: proc(fd: posix.FD, name: string, allocator: mem.Allocator) -> (path: cstring, err: Error) {
	allocators.TEMP_ALLOCATOR_TEMP_GUARD(allocator)
	cname := strings.cstring_clone_from_string(name, allocators.temp_allocator) or_return

	buf: [posix.PATH_MAX]byte
	path = posix.realpath(cname, raw_data(buf[:]))
	if path == nil {
		err = _get_platform_error()
		return
	}

	return strings.cstring_clone_from_string(string(path), allocator)
}

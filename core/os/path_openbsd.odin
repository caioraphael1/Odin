import "base:internal"

import "core:strings"
import "core:sys/posix"

_get_executable_path :: proc(allocator: mem.Allocator) -> (path: string, err: Error) {
	// OpenBSD does not have an API for this, we do our best below.

	if len(internal.args__) <= 0 {
		err = .Invalid_Path
		return
	}

	real :: proc(path: cstring, allocator: mem.Allocator) -> (out: string, err: Error) {
		real := posix.realpath(path)
		if real == nil {
			err = _get_platform_error()
			return
		}
		defer posix.free(real)
		return strings.string_clone(string(real), allocator)
	} 

	arg := internal.args__[0]
	sarg := string(arg)

	if len(sarg) == 0 {
		err = .Invalid_Path
		return
	}

	if sarg[0] == '.' || sarg[0] == '/' {
		return real(arg, allocator)
	}

	allocators.TEMP_ALLOCATOR_TEMP_GUARD(allocator)

	buf := strings_tools.builder_make(allocators.temp_allocator)

	paths := get_env("PATH", allocators.temp_allocator)
	for dir in strings_tools.split_iterator(&paths, ":") {
		strings_tools.builder_reset(&buf)
		strings_tools.write_string(&buf, dir)
		strings_tools.write_string(&buf, "/")
		strings_tools.write_string(&buf, sarg)

		cpath := strings.to_cstring(&buf) or_return
		if posix.access(cpath, {.X_OK}) == .OK {
			return real(cpath, allocator)
		}
	}

	err = .Invalid_Path
	return
}

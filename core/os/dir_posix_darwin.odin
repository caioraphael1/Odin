#+private
import "base:internal"
import "core:sys/darwin"

_copy_directory_all_native :: proc(dst, src: string, dst_perm := Permissions_Default) -> (err: Error) {
	runtime.TEMP_ALLOCATOR_TEMP_GUARD()

	csrc := strings.cstring_clone_from_string(src, allocators.temp_allocator) or_return
	cdst := strings.cstring_clone_from_string(dst, allocators.temp_allocator) or_return

	if darwin.copyfile(csrc, cdst, nil, darwin.COPYFILE_ALL + {.RECURSIVE}) < 0 {
		err = _get_platform_error()
	}

	return
}

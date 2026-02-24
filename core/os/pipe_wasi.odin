#+private
import "base:runtime"

_pipe :: proc(allocator: runtime.Allocator) -> (r, w: ^File, err: Error) {
	err = .Unsupported
	return
}


_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
	err = .Unsupported
	return
}

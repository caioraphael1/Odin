#+private
package os2

import "base:runtime"

_pipe :: proc(allocator: runtime.Allocator) -> (r, w: ^File, err: Error) {
	err = .Unsupported
	return
}

@(require_results)
_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
	err = .Unsupported
	return
}

#+build js wasm32, js wasm64p32
#+private


// None of this does anything on js/wasm.
// It's only here so importing `core:os` on wasm panics cleanly,
// without spamming about all sorts of missing procs and types.

import "base:internal"

_temp_dir :: proc(allocator: mem.Allocator) -> (string, mem.Allocator_Error) {
	return "", .Mode_Not_Implemented
}

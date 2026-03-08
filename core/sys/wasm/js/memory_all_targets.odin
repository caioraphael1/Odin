#+build !js

import "base:internal"

PAGE_SIZE :: 64 * 1024
page_alloc :: proc(page_count: int) -> (data: []byte, err: mem.Allocator_Error) {
	internal.panic("vendor:wasm/js not supported on non-js targets")
}

page_allocator :: proc() -> mem.Allocator {
	internal.panic("vendor:wasm/js not supported on non-js targets")
}



import "base:internal"

g_context: internal.Context

@(private="file", init)
wgpu_init_allocator :: proc() {
    if g_context.allocator.procedure == nil {
        g_context = internal.default_context()
    }
}

@(private="file", export)
wgpu_alloc :: proc(size: i32) -> [^]u8 {
    context = g_context
    bytes, err := mem.alloc(int(size), 16)
    internal.assert(err == nil, "wgpu_alloc failed")
    return raw_data(bytes)
}

@(private="file", export)
wgpu_free :: proc(ptr: rawptr) {
    context = g_context
    err := mem.free(ptr)
    internal.assert(err == nil, "wgpu_free failed")
}

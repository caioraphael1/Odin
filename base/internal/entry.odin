
args__: []cstring


// IMPORTANT NOTE(bill): Do not call this unless you want to explicitly set up the entry point and how it gets called
// This is probably only useful for freestanding targets
foreign {
    @(link_name="__$startup_runtime")
    _startup_runtime :: proc() ---
    @(link_name="__$cleanup_runtime")
    _cleanup_runtime :: proc() ---
}

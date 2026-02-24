#+build essence, haiku


import "base:runtime"

@(private)
_ram_stats :: proc() -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
    return
}

@(private)
_os_version :: proc(allocator: runtime.Allocator, loc := #caller_location) -> (res: OS_Version, ok: bool) {
    return {}, false
}

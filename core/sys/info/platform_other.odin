#+build essence, haiku


import "base:internal"

@(private)
_ram_stats :: proc() -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
    return
}

@(private)
_os_version :: proc(allocator: mem.Allocator, loc := #caller_location) -> (res: OS_Version, ok: bool) {
    return {}, false
}

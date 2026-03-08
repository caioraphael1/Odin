#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows
#+private

import "base:internal"

_Pool_Arena :: internal.Arena

_DEFAULT_BLOCK_SIZE :: mem.Megabyte

_pool_arena_init :: proc(arena: ^Pool_Arena, block_size: uint = DEFAULT_BLOCK_SIZE) -> (err: mem.Allocator_Error) {
    internal.arena_init(arena, block_size, internal.default_allocator()) or_return
    return
}

_pool_arena_allocator :: proc(arena: ^Pool_Arena) -> mem.Allocator {
    return internal.arena_allocator(arena)
}

_pool_arena_destroy :: proc(arena: ^Pool_Arena) {
    internal.arena_destroy(arena)
}

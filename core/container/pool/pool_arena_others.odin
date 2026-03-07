#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows
#+private

import "base:internal"

_Pool_Arena :: runtime.Arena

_DEFAULT_BLOCK_SIZE :: runtime.Megabyte

_pool_arena_init :: proc(arena: ^Pool_Arena, block_size: uint = DEFAULT_BLOCK_SIZE) -> (err: mem.Allocator_Error) {
    runtime.arena_init(arena, block_size, runtime.default_allocator()) or_return
    return
}

_pool_arena_allocator :: proc(arena: ^Pool_Arena) -> mem.Allocator {
    return runtime.arena_allocator(arena)
}

_pool_arena_destroy :: proc(arena: ^Pool_Arena) {
    runtime.arena_destroy(arena)
}

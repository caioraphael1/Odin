import "base:internal"
import "base:mem"
/*
Note:
This allocator needs to be manually initialized by the user.
*/


// Temp Allocator
when DUSK_ARCH == .i386 && DUSK_OS == .Windows {
    // Thread-local storage is problematic on Windows i386
    temp_allocator: mem.Allocator
    temp_allocator_growing_arena: Growing_Arena
} else {
    @(thread_local) temp_allocator: mem.Allocator
    @(thread_local) temp_allocator_growing_arena: Growing_Arena
}

temp_allocator_init :: proc(size: uint, backing_temp_allocator: mem.Allocator) {
    // Temp Allocator Arena, using the Backing Temp Allocator
    err := growing_arena_init(&temp_allocator_growing_arena, size, backing_temp_allocator)
    internal.assert(err == nil, "Failure initializing the arena")

    // Temp Allocator, using the Temp Allocator Arena
    temp_allocator = growing_arena_allocator(&temp_allocator_growing_arena)
}

temp_allocator_destroy :: proc() {
    growing_arena_destroy(&temp_allocator_growing_arena)
}

@(deferred_out=growing_arena_temp_end, optional_results)
TEMP_ALLOCATOR_TEMP_GUARD :: #force_inline proc(collision: mem.Allocator = {}, loc := #caller_location) -> (Growing_Arena_Temp, internal.Source_Code_Location) {
    if collision == temp_allocator {
        return {}, loc
    }
    return growing_arena_temp_begin(&temp_allocator_growing_arena, loc), loc
}

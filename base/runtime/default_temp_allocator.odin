package runtime


DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE: int : #config(DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, 4 * Megabyte)

when ODIN_ARCH == .i386 && ODIN_OS == .Windows {
    // Thread-local storage is problematic on Windows i386
    default_temp_allocator_arena: Arena
} else {
    @thread_local default_temp_allocator_arena: Arena
}


default_temp_allocator :: proc() -> Allocator {
    return {
        procedure = arena_allocator_proc,
        data      = &default_temp_allocator_arena,
    }
}


default_temp_allocator_init :: proc(size: int, backing_allocator: Allocator) -> Allocator_Error {
    return arena_init(&default_temp_allocator_arena, uint(size), backing_allocator)
}

/*
Uses:
    Fini
    threads cleanup
*/
default_temp_allocator_destroy :: proc "contextless" () {
    if default_temp_allocator_arena != {} {
        arena_destroy(&default_temp_allocator_arena)
        default_temp_allocator_arena = {}
    }
}



@(deferred_out=default_temp_allocator_temp_end)
DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD :: #force_inline proc(ignore := false, loc := #caller_location) -> (Arena_Temp, Source_Code_Location) {
	if ignore {
		return {}, loc
	}
    return default_temp_allocator_temp_begin(loc), loc
}

@(require_results)
default_temp_allocator_temp_begin :: proc(loc := #caller_location) -> (arena_temp: Arena_Temp) {
    return arena_temp_begin(&default_temp_allocator_arena, loc)
}

default_temp_allocator_temp_end :: proc(arena_temp: Arena_Temp, loc := #caller_location) {
    arena_temp_end(arena_temp, loc)
}

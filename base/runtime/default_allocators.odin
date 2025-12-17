package runtime



general_allocator: Allocator


when ODIN_ARCH == .i386 && ODIN_OS == .Windows {
    // Thread-local storage is problematic on Windows i386
    temp_allocator:       Allocator
    temp_allocator_arena: Arena
} else {
    @(thread_local) temp_allocator:       Allocator
    @(thread_local) temp_allocator_arena: Arena
}



// TODO: can be removed, using arena_temp_guard in its place.
@(deferred_out=arena_temp_end)
TEMP_ALLOCATOR_GUARD :: #force_inline proc(ignore := false, loc := #caller_location) -> (Arena_Temp, Source_Code_Location) {
	if ignore {
		return {}, loc
	}
    return arena_temp_begin(&temp_allocator_arena, loc), loc
}

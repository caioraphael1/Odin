#+ignore
import "base:mem"

import "core:fmt"
import "core:sync"

import "core:strings_tools"

import "tracy"


/* 
Note: just Telemetry + mutex, without Compat_Allocator internally.
This is a problem, as mem.free doesn't have the information from the old size, so a lot of leaks are falsely accused, as the allocator thinks it's freeing 0 bytes.
*/

/* 
A Tracking_Allocator without internal allocations.
*/
Telemetry_Allocator :: struct {
    name:                     string,

    backing:                  mem.Allocator,
    mutex:                    sync.Mutex,

    total_memory_allocated:   uint,

    total_allocation_count:   uint,
    total_memory_freed:       uint,
    total_free_count:         uint,

    peak_memory_allocated:    uint,
    current_memory_allocated: uint,
}


telemetry_allocator_init :: proc(backing_allocator: ^mem.Allocator, telemetry: ^Telemetry_Allocator, name: string) {
    telemetry.name = name
    telemetry.backing = backing_allocator^
    backing_allocator^ = {
        data      = telemetry,
        procedure = telemetry_allocator_proc,
    }
}


@(no_sanitize_address)
telemetry_allocator_log :: proc(telemetry: Telemetry_Allocator, alias: cstring) {  
    /* 
    allocators.temp_allocator might already be destroyed.
    Log cannot be used, as it uses the allocators.temp_allocator internally.
    */

    SPACING :: "    "
    fmt.printfln("[Telemetry_Allocator: '%v']", alias)

    fmt.printf(SPACING + "Peak memory: ")
    fmt.printf_bytes(telemetry.peak_memory_allocated)
    fmt.printfln("")

    if telemetry.current_memory_allocated != 0 {
        fmt.printf(SPACING + "[ERROR] Leaked ")
        fmt.printf_bytes(telemetry.current_memory_allocated)
        fmt.printfln("")
    } else {
        fmt.printfln(SPACING + "0 leaks.")
    }
}


@(no_sanitize_address)
telemetry_allocator_proc :: proc(
    allocator_data:  rawptr,
    mode:            mem.Allocator_Mode,
    size, alignment: uint,
    old_memory:      rawptr,
    old_size:        uint,
    loc              := #caller_location,
    ) -> (new_memory: []byte, err: mem.Allocator_Error) {
    @(no_sanitize_address)
    track_alloc :: proc(data: ^Telemetry_Allocator, size: uint) {
        data.total_memory_allocated += size
        data.total_allocation_count += 1
        data.current_memory_allocated += size
        if data.current_memory_allocated > data.peak_memory_allocated {
            data.peak_memory_allocated = data.current_memory_allocated
        }
    }

    @(no_sanitize_address)
    track_free :: proc(data: ^Telemetry_Allocator, size: uint) {
        data.total_memory_freed += size
        data.total_free_count += 1
        data.current_memory_allocated -= size
    }

    telemetry_alloc := (^Telemetry_Allocator)(allocator_data)

    sync.mutex_guard(&telemetry_alloc.mutex)

    new_memory, err = telemetry_alloc.backing.procedure(telemetry_alloc.backing.data, mode, size, alignment, old_memory, old_size, loc)
    if err != nil {
        fmt.panicf("[telemetry_allocator_proc] (%v) %v | err '%v'", loc, telemetry_alloc.name, err)
    }

    switch mode {
    case .Alloc, .Alloc_Non_Zeroed:
        // fmt.printfln("[telemetry_allocator_proc] (%v) %v | %p | Alloc '%v' bytes", loc, telemetry_alloc.name, raw_data(new_memory), size)
        track_alloc(telemetry_alloc, size)
    case .Free:
        if old_memory != nil {
            // fmt.printfln("[telemetry_allocator_proc] (%v) %v | %p | Free '%v' bytes", loc, telemetry_alloc.name, old_memory, old_size)
            track_free(telemetry_alloc, old_size)
        }
    case .Free_All:
        // fmt.printfln("[telemetry_allocator_proc] (%v) %v | Free_All '%v' bytes", loc, telemetry_alloc.name, telemetry_alloc.current_memory_allocated)
        telemetry_alloc.current_memory_allocated = 0
    case .Resize, .Resize_Non_Zeroed:
        if old_memory != nil {
            // fmt.printfln("[telemetry_allocator_proc] (%v) %v | %p | Resize Free '%v' bytes", loc, telemetry_alloc.name, old_memory, old_size)
            track_free(telemetry_alloc, old_size)
        }
        // fmt.printfln("[telemetry_allocator_proc] (%v) %v | %p | Resize Alloc '%v' bytes", loc, telemetry_alloc.name, raw_data(new_memory), size)
        track_alloc(telemetry_alloc, size)
    case .Query_Features:
        unreachable()
    case .Query_Info:
        unreachable()
    }

    when tracy.TRACY_ENABLE && TRACK_TOTAL {
        plot_total_memory_stats()
    }

    return
}

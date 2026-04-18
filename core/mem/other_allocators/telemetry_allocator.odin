import "base:internal"
import "base:mem"
import "base:container/str"

import "core:os"
import "core:sync"


/* 
This is basically a Compat_Allocator + Telemetry data + mutex.

An allocator that keeps track of allocation sizes and passes it along to resizes.
This is useful if you are using a library that needs an equivalent of `realloc` but want to use the Odin allocator interface.
You want to wrap your allocator into this one if you are trying to use any allocator that relies on the old size to work.

How it works:
    An extra max(alignment, size_of(Header)) new_memory are allocated for each allocation, storing the size and aligment after the data.
*/

Telemetry_Allocator :: struct {
    name:                     string,

    backing:                  mem.Allocator,
    mutex:                    sync.Mutex,

    // Count
    total_allocation_count:   uint,
    total_free_count:         uint,

    // Memory
    current_memory_allocated: uint,
    peak_memory_allocated:    uint,
    total_memory_allocated:   uint,
    total_memory_freed:       uint,

    // Internal Telemetry Bloat
    telemetry_current_memory_allocated: uint,
    telemetry_peak_memory_allocated:    uint,
    telemetry_total_memory_allocated:   uint,
    telemetry_total_memory_freed:       uint,
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
telemetry_allocator_log :: proc(telemetry: Telemetry_Allocator, alias: string) {  
    /* 
    allocators.temp_allocator might already be destroyed.
    Log cannot be used, as it uses the allocators.temp_allocator internally.
    */

    SPACING :: "    "
    os.printfln("[Telemetry_Allocator: '%v']", alias)

    os.printfln(SPACING + "Peak memory: %", str.from_uint(telemetry.peak_memory_allocated))
    os.printfln(SPACING + "Telemetry Peak bloat memory: %", str.from_uint(telemetry.telemetry_peak_memory_allocated))

    if telemetry.current_memory_allocated != 0 {
        os.printfln(SPACING + "[ERROR] Leaked %", str.from_uint(telemetry.current_memory_allocated))
    } else {
        os.println(SPACING + "0 leaks.")
    }

    if telemetry.telemetry_current_memory_allocated != 0 {
        os.printfln(SPACING + "[ERROR] Telemetry bloat leaked %", str.from_uint(telemetry.telemetry_current_memory_allocated))
    } else {
        os.println(SPACING + "0 telemetry leaks.")
    }
}

telemetry_allocator_proc :: proc(
    allocator_data:  rawptr,
    mode:            mem.Allocator_Mode,
    size, alignment: uint,
    old_memory:      rawptr,
    old_size:        uint,
    loc              := #caller_location,
    ) -> (new_memory: []u8, err: mem.Allocator_Error) {

    Header :: struct {
        size:      uint,
        alignment: uint,
    }

    @(no_sanitize_address)
    get_unpoisoned_header :: #force_inline proc(ptr: rawptr) -> Header {
        header := ([^]Header)(ptr)[-1]
        // a      := max(header.alignment, size_of(Header))
        // sanitizer.address_unpoison(rawptr(uintptr(ptr)-uintptr(a)), a)
        return header
    }

    @(no_sanitize_address)
    track_alloc :: proc(data: ^Telemetry_Allocator, size: uint, telemetry_size: uint) {
        data.total_allocation_count += 1

        // Memory
        data.current_memory_allocated += size
        data.total_memory_allocated   += size
        if data.current_memory_allocated > data.peak_memory_allocated {
            data.peak_memory_allocated = data.current_memory_allocated
        }

        // Telemetry Internal Bloat
        data.telemetry_current_memory_allocated += telemetry_size
        data.telemetry_total_memory_allocated   += telemetry_size
        if data.telemetry_current_memory_allocated > data.telemetry_peak_memory_allocated {
            data.telemetry_peak_memory_allocated = data.telemetry_current_memory_allocated
        }
    }

    @(no_sanitize_address)
    track_free :: proc(data: ^Telemetry_Allocator, size: uint, telemetry_size: uint) {
        data.total_free_count += 1

        // Memory
        data.total_memory_freed       += size
        data.current_memory_allocated -= size

        // Telemetry Internal Bloat
        data.telemetry_total_memory_freed       += telemetry_size
        data.telemetry_current_memory_allocated -= telemetry_size
    }


    telemetry := (^Telemetry_Allocator)(allocator_data)

    sync.mutex_guard(&telemetry.mutex)

    switch mode {
    case .Alloc, .Alloc_Non_Zeroed:
        a        := max(alignment, size_of(Header))
        req_size := size + a
        internal.assert(req_size >= 0, "overflow")

        allocation := telemetry.backing.procedure(telemetry.backing.data, mode, req_size, alignment, old_memory, old_size, loc) or_return
        #no_bounds_check new_memory = allocation[a:]

        ([^]Header)(raw_data(new_memory))[-1] = {
            size      = size,
            alignment = alignment,
        }

        track_alloc(telemetry, size, a)

        // sanitizer.address_poison(raw_data(allocation), a)
        return

    case .Free:
        header    := get_unpoisoned_header(old_memory)
        a         := max(header.alignment, size_of(Header))
        orig_ptr  := rawptr(uintptr(old_memory) - uintptr(a))
        orig_size := header.size + a

        new_memory = telemetry.backing.procedure(telemetry.backing.data, mode, orig_size, header.alignment, orig_ptr, orig_size, loc) or_return

        track_free(telemetry, header.size, a)

        return 

    case .Resize, .Resize_Non_Zeroed:
        header    := get_unpoisoned_header(old_memory)
        orig_a    := max(header.alignment, size_of(Header))
        orig_ptr  := rawptr(uintptr(old_memory)-uintptr(orig_a))
        orig_size := header.size + orig_a

        new_alignment := max(header.alignment, alignment)

        a        := max(new_alignment, size_of(header))
        req_size := size + a
        internal.assert(size >= 0, "overflow")

        allocation := telemetry.backing.procedure(telemetry.backing.data, mode, req_size, new_alignment, orig_ptr, orig_size, loc) or_return
        #no_bounds_check new_memory = allocation[a:]

        ([^]Header)(raw_data(new_memory))[-1] = {
            size      = size,
            alignment = new_alignment,
        }

        if old_memory != nil {
            // os.printfln("[telemetry_allocator_proc] (%v) %v | %p | Resize Free '%v' new_memory", loc, telemetry.name, old_memory, old_size)
            track_free(telemetry, header.size, orig_a)
        }
        // os.printfln("[telemetry_allocator_proc] (%v) %v | %p | Resize Alloc '%v' new_memory", loc, telemetry.name, raw_data(new_memory), size)
        track_alloc(telemetry, size, a)

        // sanitizer.address_poison(raw_data(allocation), a)
        return

    case .Free_All:
        new_memory = telemetry.backing.procedure(telemetry.backing.data, mode, size, alignment, old_memory, old_size, loc) or_return

        // os.printfln("[telemetry_allocator_proc] (%v) %v | Free_All '%v' new_memory", loc, telemetry.name, telemetry.current_memory_allocated)
        telemetry.current_memory_allocated = 0

        return 

    case .Query_Info:
        info := (^mem.Allocator_Query_Info)(old_memory)
        if info != nil && info.pointer != nil {
            header := get_unpoisoned_header(info.pointer)
            info.size      = header.size
            info.alignment = header.alignment
        }
        return

    case .Query_Features:
        new_memory = telemetry.backing.procedure(telemetry.backing.data, mode, size, alignment, old_memory, old_size, loc) or_return
        set := (^mem.Allocator_Mode_Set)(old_memory)
        set^ += {.Query_Info}
        return

    case: unreachable()
    }
}

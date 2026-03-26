import "base:internal"
import "base:mem"

/* 
An allocator that keeps track of allocation sizes and passes it along to resizes.
This is useful if you are using a library that needs an equivalent of `realloc` but want to use the Odin allocator interface.
You want to wrap your allocator into this one if you are trying to use any allocator that relies on the old size to work.

How it works:
    An extra max(alignment, size_of(Header)) new_memory are allocated for each allocation, storing the size and aligment after the data.
*/

Compat_Allocator :: struct {
    backing_allocator: mem.Allocator,
}

compat_allocator_init :: proc(compat_alloc: ^Compat_Allocator, backing_allocator: mem.Allocator) {
    compat_alloc.backing_allocator = backing_allocator
}


compat_allocator :: proc(compat_alloc: ^Compat_Allocator) -> mem.Allocator {
    return mem.Allocator{
        data      = compat_alloc,
        procedure = compat_allocator_proc,
    }
}

compat_allocator_proc :: proc(
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

    compat_alloc := (^Compat_Allocator)(allocator_data)
    switch mode {
    case .Alloc, .Alloc_Non_Zeroed:
        a        := max(alignment, size_of(Header))
        req_size := size + a
        internal.assert(req_size >= 0, "overflow")

        allocation := compat_alloc.backing_allocator.procedure(compat_alloc.backing_allocator.data, mode, req_size, alignment, old_memory, old_size, loc) or_return
        #no_bounds_check new_memory = allocation[a:]

        ([^]Header)(raw_data(new_memory))[-1] = {
            size      = size,
            alignment = alignment,
        }

        // sanitizer.address_poison(raw_data(allocation), a)
        return

    case .Free:
        header    := get_unpoisoned_header(old_memory)
        a         := max(header.alignment, size_of(Header))
        orig_ptr  := rawptr(uintptr(old_memory)-uintptr(a))
        orig_size := header.size + a

        return compat_alloc.backing_allocator.procedure(compat_alloc.backing_allocator.data, mode, orig_size, header.alignment, orig_ptr, orig_size, loc)

    case .Resize, .Resize_Non_Zeroed:
        header    := get_unpoisoned_header(old_memory)
        orig_a    := max(header.alignment, size_of(Header))
        orig_ptr  := rawptr(uintptr(old_memory)-uintptr(orig_a))
        orig_size := header.size + orig_a

        new_alignment := max(header.alignment, alignment)

        a        := max(new_alignment, size_of(header))
        req_size := size + a
        internal.assert(size >= 0, "overflow")

        allocation := compat_alloc.backing_allocator.procedure(compat_alloc.backing_allocator.data, mode, req_size, new_alignment, orig_ptr, orig_size, loc) or_return
        #no_bounds_check new_memory = allocation[a:]

        ([^]Header)(raw_data(new_memory))[-1] = {
            size      = size,
            alignment = new_alignment,
        }

        // sanitizer.address_poison(raw_data(allocation), a)
        return

    case .Free_All:
        return compat_alloc.backing_allocator.procedure(compat_alloc.backing_allocator.data, mode, size, alignment, old_memory, old_size, loc)

    case .Query_Info:
        info := (^mem.Allocator_Query_Info)(old_memory)
        if info != nil && info.pointer != nil {
            header := get_unpoisoned_header(info.pointer)
            info.size      = header.size
            info.alignment = header.alignment
        }
        return

    case .Query_Features:
        new_memory = compat_alloc.backing_allocator.procedure(compat_alloc.backing_allocator.data, mode, size, alignment, old_memory, old_size, loc) or_return
        set := (^mem.Allocator_Mode_Set)(old_memory)
        set^ += {.Query_Info}
        return

    case: unreachable()
    }
}

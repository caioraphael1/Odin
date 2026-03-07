
DEFAULT_ALIGNMENT :: 2 * align_of(rawptr)

Allocator :: struct {
    procedure: Allocator_Proc,
    data:      rawptr,
}
Allocator_Mode :: enum byte {
    Alloc,
    Free,
    Free_All,
    Resize,
    Query_Features,
    Query_Info,
    Alloc_Non_Zeroed,
    Resize_Non_Zeroed,
}
Allocator_Error :: enum byte {
    None                 = 0,
    Out_Of_Memory        = 1,
    Invalid_Pointer      = 2,
    Invalid_Argument     = 3,
    Mode_Not_Implemented = 4,
}
Allocator_Proc :: #type proc(
    allocator_data: rawptr, 
    mode: Allocator_Mode,
    size, alignment: int,
    old_memory: rawptr, old_size: int,
    location: Source_Code_Location = #caller_location
    ) -> ([]byte, Allocator_Error)


mem_free_with_size :: #force_no_inline proc(ptr: rawptr, byte_count: int, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    assert(allocator.procedure != nil, loc=loc)
    if ptr == nil {
        return nil
    }
    _, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, byte_count, loc)
    return err
}


mem_alloc_non_zeroed :: #force_no_inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator: Allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
    assert(is_power_of_two_int(alignment), "Alignment must be a power of two", loc)
    assert(allocator.procedure != nil, "Allocator not defined", loc)
    assert(size > 0, "Size must be greater than zero", loc)
    return allocator.procedure(allocator.data, .Alloc_Non_Zeroed, size, alignment, nil, 0, loc)
}


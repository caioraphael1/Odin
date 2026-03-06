import "base:intrinsics"

@(builtin)
slice_create :: proc($T: typeid/[]$E, #any_int len: int, allocator: Allocator, loc := #caller_location) -> (res: T, err: Allocator_Error) {
    err = _slice_init_aligned(&res, size_of(E), len, align_of(E), allocator, loc)
    return
}

slice_create_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator: Allocator, loc := #caller_location) -> (res: T, err: Allocator_Error) {
    err = _slice_init_aligned(&res, size_of(E), len, alignment, allocator, loc)
    return
}

_slice_init_aligned :: proc(slice: rawptr, elem_size: int, len: int, alignment: int, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    slice_create_error_loc(loc, len)
    if len == 0 {
        return nil
    }
    data, err := mem_alloc_bytes(elem_size*len, alignment, allocator, loc)
    if data == nil && elem_size != 0 {
        return err
    }
    (^Raw_Slice)(slice).data = raw_data(data)
    (^Raw_Slice)(slice).len  = len
    return err
}

// `slice_delete` will try to free the underlying data of the passed sliced, with the given `allocator` if the allocator supports this operation.
@(builtin)
slice_delete :: proc(array: $T/[]$E, allocator: Allocator, loc := #caller_location) -> Allocator_Error {
    return mem_free_with_size(raw_data(array), len(array)*size_of(E), allocator, loc)
}

// `slice_copy` is a built-in procedure that copies elements from a source slice `src` to a destination slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
@(builtin, optional_results)
slice_copy :: #force_inline proc(dst, src: $T/[]$E) -> int {
    return _rawptr_mem_copy(raw_data(dst), raw_data(src), len(dst), len(src), size_of(E))
}

// `slice_copy_from_string` is a built-in procedure that copies elements from a source string `src` to a destination slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
@(builtin, optional_results)
slice_copy_from_string :: #force_inline proc(dst: $T/[]$E/u8, src: $S/string) -> int {
    return _rawptr_mem_copy(raw_data(dst), raw_data(src), len(dst), len(src), 1)
}

// `slice_copy_from_string16` is a built-in procedure that copies elements from a source string `src` to a destination slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
@(builtin, optional_results)
slice_copy_from_string16 :: #force_inline proc(dst: $T/[]$E/u16, src: $S/string16) -> int {
    return _rawptr_mem_copy(raw_data(dst), raw_data(src), len(dst), len(src), 2)
}


@(optional_results)
_rawptr_mem_copy :: proc(dst, src: rawptr, dst_len, src_len, elem_size: int) -> int {
    n := min(dst_len, src_len)
    if n > 0 {
        intrinsics.mem_copy(dst, src, n*elem_size)
    }
    return n
}


//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(no_instrumentation)
slice_handle_error :: proc(file: string, line, column: i32, lo, hi: int, len: int) -> ! {
    print_caller_location(Source_Code_Location{file, line, column, ""})
    print_string(" Invalid slice indices ")
    print_i64(i64(lo))
    print_string(":")
    print_i64(i64(hi))
    print_string(" is out of range 0..<")
    print_i64(i64(len))
    print_byte('\n')
    bounds_trap()
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_hi_loc :: #force_inline proc(loc := #caller_location, hi: int, len: int) {
    slice_expr_error_hi(loc.file_path, loc.line, loc.column, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_lo_hi_loc :: #force_inline proc(loc := #caller_location, lo, hi: int, len: int) {
    slice_expr_error_lo_hi(loc.file_path, loc.line, loc.column, lo, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_hi :: proc(file: string, line, column: i32, hi: int, len: int) {
    if 0 <= hi && hi <= len {
        return
    }
    slice_handle_error(file, line, column, 0, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_lo_hi :: proc(file: string, line, column: i32, lo, hi: int, len: int) {
    if 0 <= lo && lo <= len && lo <= hi && hi <= len {
        return
    }
    slice_handle_error(file, line, column, lo, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_create_error_loc :: #force_inline proc(loc := #caller_location, len: int) {
    if 0 <= len {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(loc: Source_Code_Location, len: int) -> ! {
        print_caller_location(loc)
        print_string(" Invalid slice length for make: ")
        print_i64(i64(len))
        print_byte('\n')
        bounds_trap()
    }
    handle_error(loc, len)
}

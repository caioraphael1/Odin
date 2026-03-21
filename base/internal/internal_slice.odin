#+no-instrumentation
//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(no_instrumentation)
slice_handle_error :: proc(file: string, line, column: i32, lo, hi: uint, len: uint) -> ! {
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
slice_expr_error_hi_loc :: #force_inline proc(loc := #caller_location, hi: uint, len: uint) {
    __slice_expr_error_hi(loc.file_path, loc.line, loc.column, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_expr_error_lo_hi_loc :: #force_inline proc(loc := #caller_location, lo, hi: uint, len: uint) {
    __slice_expr_error_lo_hi(loc.file_path, loc.line, loc.column, lo, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
__slice_expr_error_hi :: proc(file: string, line, column: i32, hi: uint, len: uint) {
    if 0 <= hi && hi <= len {
        return
    }
    slice_handle_error(file, line, column, 0, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
__slice_expr_error_lo_hi :: proc(file: string, line, column: i32, lo, hi: uint, len: uint) {
    if 0 <= lo && lo <= len && lo <= hi && hi <= len {
        return
    }
    slice_handle_error(file, line, column, lo, hi, len)
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
slice_create_error_loc :: #force_inline proc(loc := #caller_location, len: uint) {
    if len >= 0 {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(loc: Source_Code_Location, len: uint) -> ! {
        print_caller_location(loc)
        print_string(" Invalid slice length for create '")
        print_i64(i64(len))
        print_string("'")
        print_byte('\n')
        bounds_trap()
    }
    handle_error(loc, len)
}

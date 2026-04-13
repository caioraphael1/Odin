#+no-instrumentation

//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(private="file", no_instrumentation)
_slice_handle_error :: proc(file: string, line, column: i32, lo, hi: uint, len: uint) -> ! {
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

// lb_emit_slice_bounds_check
@(disabled=ODIN_NO_BOUNDS_CHECK)
__slice_expr_error_hi :: proc(file: string, line, column: i32, hi: uint, len: uint) {
    if 0 <= hi && hi <= len {
        return
    }
    _slice_handle_error(file, line, column, 0, hi, len)
}

// lb_emit_slice_bounds_check
@(disabled=ODIN_NO_BOUNDS_CHECK)
__slice_expr_error_lo_hi :: proc(file: string, line, column: i32, lo, hi: uint, len: uint) {
    if 0 <= lo && lo <= len && lo <= hi && hi <= len {
        return
    }
    _slice_handle_error(file, line, column, lo, hi, len)
}

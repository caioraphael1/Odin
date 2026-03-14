#+no-instrumentation
//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(no_instrumentation)
multi_pointer_slice_handle_error :: proc(file: string, line, column: i32, lo, hi: int) -> ! {
    print_caller_location(Source_Code_Location{file, line, column, ""})
    print_string(" Invalid slice indices ")
    print_i64(i64(lo))
    print_string(":")
    print_i64(i64(hi))
    print_byte('\n')
    bounds_trap()
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
__multi_pointer_slice_expr_error :: proc(file: string, line, column: i32, lo, hi: int) {
    if lo <= hi {
        return
    }
    multi_pointer_slice_handle_error(file, line, column, lo, hi)
}

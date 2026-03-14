#+no-instrumentation
//--------------------------------------------------------------------------------------------------
// Error Checks
//--------------------------------------------------------------------------------------------------

@(disabled=ODIN_NO_BOUNDS_CHECK)
__matrix_bounds_check_error :: proc(file: string, line, column: i32, row_index, column_index, row_count, column_count: int) {
    if uint(row_index) < uint(row_count) &&
       uint(column_index) < uint(column_count) {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(file: string, line, column: i32, row_index, column_index, row_count, column_count: int) -> ! {
        print_caller_location(Source_Code_Location{file, line, column, ""})
        print_string(" Matrix indices [")
        print_i64(i64(row_index))
        print_string(", ")
        print_i64(i64(column_index))
        print_string(" is out of range [0..<")
        print_i64(i64(row_count))
        print_string(", 0..<")
        print_i64(i64(column_count))
        print_string("]")
        print_byte('\n')
        bounds_trap()
    }
    handle_error(file, line, column, row_index, column_index, row_count, column_count)
}

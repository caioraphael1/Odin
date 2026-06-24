import "base:intrinsics"

Maybe :: union($T: typeid) { T }

debug_trap         :: intrinsics.debug_trap
trap               :: intrinsics.trap

Assertion_Failure_Proc :: #type proc(prefix, message: string, loc: Source_Code_Location) -> !
assertion_failure_proc: Assertion_Failure_Proc = default_assertion_failure_proc

// Evaluates the condition and panics the program iff the condition is false.
// This uses the `assertion_failure_proc` to assert.
//
// This routine will be ignored when `DUSK_DISABLE_ASSERT` is true.
@(disabled=DUSK_DISABLE_ASSERT)
assert :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        // NOTE(bill): This is wrapped in a procedure call
        // to improve performance to make the CPU not
        // execute speculatively, making it about an order of
        // magnitude faster
        @(cold)
        internal_assert :: proc(message: string, loc: Source_Code_Location) {
            assertion_failure_proc("runtime assertion", message, loc)
        }
        internal_assert(message, loc)
    }
}

// Evaluates the condition and panics the program iff the condition is false.
// This uses the `assertion_failure_proc` to assert.
// This routine ignores `DUSK_DISABLE_ASSERT`, and will always execute.
ensure :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        @(cold)
        internal_ensure :: proc(message: string, loc: Source_Code_Location) {
            assertion_failure_proc("unsatisfied ensure", message, loc)
        }
        internal_ensure(message, loc)
    }
}

// Panics the program with a message.
// This uses the `assertion_failure_proc` to panic.
panic :: proc(message: string, loc := #caller_location) -> ! {
    assertion_failure_proc("panic", message, loc)
}

// Panics the program with a message to indicate something has yet to be implemented.
// This uses the `assertion_failure_proc` to assert.
unimplemented :: proc(message := "", loc := #caller_location) -> ! {
    assertion_failure_proc("not yet implemented", message, loc)
}


default_assertion_failure_proc :: proc(prefix, message: string, loc: Source_Code_Location) -> ! {
    when DUSK_OS == .Freestanding {
        // Do nothing
    } else {
        when DUSK_OS != .Orca && !DUSK_DISABLE_ASSERT {
            print_caller_location(loc)
            print_string(" ")
        }
        print_string(prefix)
        if len(message) > 0 {
            print_string(": ")
            print_string(message)
        }

        when DUSK_OS == .Orca {
            assert_fail(
                cstring(raw_data(loc.file_path)),
                cstring(raw_data(loc.procedure)),
                loc.line,
                "",
                cstring(raw_data(orca_stderr_buffer[:orca_stderr_buffer_idx])),
            )
        } else {
            print_byte('\n')
        }
    }
    trap()
}


@(no_instrumentation)
bounds_trap :: proc() -> ! {
    when DUSK_OS == .Windows {
        windows_trap_array_bounds()
    } else when DUSK_OS == .Orca {
        abort_ext("", "", 0, "bounds trap")
    } else {
        trap()
    }
}

@(disabled=DUSK_NO_BOUNDS_CHECK)
__bounds_check_error :: proc(file: string, line, column: i32, index, count: int) {
    if uint(index) < uint(count) {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(file: string, line, column: i32, index, count: int) -> ! {
        print_caller_location(Source_Code_Location{file, line, column, ""})
        print_string(" Index ")
        print_i64(i64(index))
        print_string(" is out of range 0..<")
        print_i64(i64(count))
        print_byte('\n')
        bounds_trap()
    }
    handle_error(file, line, column, index, count)
}

@(disabled=DUSK_NO_BOUNDS_CHECK)
bounds_check_error_loc :: #force_inline proc(loc := #caller_location, #any_int index, count: int) {
    __bounds_check_error(loc.file_path, loc.line, loc.column, index, count)
}


@(no_instrumentation)
type_assertion_trap :: proc() -> ! {
    when DUSK_OS == .Windows {
        windows_trap_type_assertion()
    } else when DUSK_OS == .Orca {
        abort_ext("", "", 0, "type assertion trap")
    } else {
        trap()
    }
}

__type_assertion_check :: proc(ok: bool, file: string, line, column: i32) {
    if ok {
        return
    }
    @(cold, no_instrumentation)
    handle_error :: proc(file: string, line, column: i32) -> ! {
        print_caller_location(Source_Code_Location{file, line, column, ""})
        print_string(" Invalid type assertion\n")
        type_assertion_trap()
    }
    handle_error(file, line, column)
}

import "base:intrinsics"

Maybe :: union($T: typeid) { T }

debug_trap         :: intrinsics.debug_trap
trap               :: intrinsics.trap

Assertion_Failure_Proc :: #type proc(prefix, message: string, loc: Source_Code_Location) -> !
assertion_failure_proc: Assertion_Failure_Proc = default_assertion_failure_proc

// Evaluates the condition and panics the program iff the condition is false.
// This uses the `assertion_failure_proc` to assert.
//
// This routine will be ignored when `ODIN_DISABLE_ASSERT` is true.
@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        // NOTE(bill): This is wrapped in a procedure call
        // to improve performance to make the CPU not
        // execute speculatively, making it about an order of
        // magnitude faster
        @(cold)
        internal :: proc(message: string, loc: Source_Code_Location) {
            assertion_failure_proc("runtime assertion", message, loc)
        }
        internal(message, loc)
    }
}

// Evaluates the condition and panics the program iff the condition is false.
// This uses the `assertion_failure_proc` to assert.
// This routine ignores `ODIN_DISABLE_ASSERT`, and will always execute.
ensure :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        @(cold)
        internal :: proc(message: string, loc: Source_Code_Location) {
            assertion_failure_proc("unsatisfied ensure", message, loc)
        }
        internal(message, loc)
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
    when ODIN_OS == .Freestanding {
        // Do nothing
    } else {
        when ODIN_OS != .Orca && !ODIN_DISABLE_ASSERT {
            print_caller_location(loc)
            print_string(" ")
        }
        print_string(prefix)
        if len(message) > 0 {
            print_string(": ")
            print_string(message)
        }

        when ODIN_OS == .Orca {
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
    when ODIN_OS == .Windows {
        windows_trap_array_bounds()
    } else when ODIN_OS == .Orca {
        abort_ext("", "", 0, "bounds trap")
    } else {
        trap()
    }
}

@(disabled=ODIN_NO_BOUNDS_CHECK)
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

@(disabled=ODIN_NO_BOUNDS_CHECK)
bounds_check_error_loc :: #force_inline proc(loc := #caller_location, index, count: int) {
    __bounds_check_error(loc.file_path, loc.line, loc.column, index, count)
}


@(no_instrumentation)
type_assertion_trap :: proc() -> ! {
    when ODIN_OS == .Windows {
        windows_trap_type_assertion()
    } else when ODIN_OS == .Orca {
        abort_ext("", "", 0, "type assertion trap")
    } else {
        trap()
    }
}

when ODIN_NO_RTTI {
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

    __type_assertion_check2 :: proc(ok: bool, file: string, line, column: i32) {
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
} else {
    @(private="file") TYPE_ASSERTION_BUFFER_SIZE :: 1024

    __type_assertion_check :: proc(ok: bool, file: string, line, column: i32, from, to: typeid) {
        if ok {
            return
        }
        @(cold, no_instrumentation)
        handle_error :: proc(file: string, line, column: i32, from, to: typeid) -> ! {
            print_caller_location(Source_Code_Location{file, line, column, ""})
            print_string(" Invalid type assertion from ")
            print_typeid(from)
            print_string(" to ")
            print_typeid(to)
            print_byte('\n')
            type_assertion_trap()
        }
        handle_error(file, line, column, from, to)
    }
    
    __type_assertion_check2 :: proc(ok: bool, file: string, line, column: i32, from, to: typeid, from_data: rawptr) {
        if ok {
            return
        }

        @(cold, no_instrumentation)
        handle_error :: proc(file: string, line, column: i32, from, to: typeid, from_data: rawptr) -> ! {

            actual := type_assertion_variant_type(from, from_data)

            print_caller_location(Source_Code_Location{file, line, column, ""})
            print_string(" Invalid type assertion from ")
            print_typeid(from)
            print_string(" to ")
            print_typeid(to)
            if actual != from {
                print_string(", actual type: ")
                print_typeid(actual)
            }
            print_byte('\n')
            type_assertion_trap()
        }
        handle_error(file, line, column, from, to, from_data)
    }

    @(private="file")
    type_assertion_variant_type :: proc(id: typeid, data: rawptr) -> typeid {
        if id == nil || data == nil {
            return id
        }
        ti := type_info_base(type_info_of(id))
        #partial switch v in ti.variant {
        case Type_Info_Any:
            return (^any)(data).id
        case Type_Info_Union:
            if v.tag_type == nil {
                if (^rawptr)(data)^ == nil {
                    return nil
                }
                return v.variants[0].id

            }

            tag_ptr := uintptr(data) + v.tag_offset
            idx := 0
            switch v.tag_type.size {
            case 1:  idx = int(  (^u8)(tag_ptr)^); if !v.no_nil { idx -= 1 }
            case 2:  idx = int( (^u16)(tag_ptr)^); if !v.no_nil { idx -= 1 }
            case 4:  idx = int( (^u32)(tag_ptr)^); if !v.no_nil { idx -= 1 }
            case 8:  idx = int( (^u64)(tag_ptr)^); if !v.no_nil { idx -= 1 }
            case 16: idx = int((^u128)(tag_ptr)^); if !v.no_nil { idx -= 1 }
            }
            if idx < 0 {
                return nil
            } else if idx < len(v.variants) {
                return v.variants[idx].id
            }
        }
        return id
    }
}


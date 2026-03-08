/*
Stack trace library. Only works when debug symbols are enabled using `-debug`.

Example:
    import "base:internal"
    import "core:debug/trace"

    import "core:fmt"

    global_trace_ctx: trace.Context

    debug_trace_assertion_failure_proc :: proc(prefix, message: string, loc := #caller_location) -> ! {
        internal.print_caller_location(loc)
        internal.print_string(" ")
        internal.print_string(prefix)
        if len(message) > 0 {
            internal.print_string(": ")
            internal.print_string(message)
        }
        internal.print_byte('\n')

        ctx := &global_trace_ctx
        if !trace.in_resolve(ctx) {
            buf: [64]trace.Frame
            internal.print_string("Debug Trace:\n")
            frames := trace.frames(ctx, 1, buf[:])
            for f, i in frames {
                fl := trace.resolve(ctx, f, allocators.temp_allocator)
                if fl.loc.file_path == "" && fl.loc.line == 0 {
                    continue
                }
                internal.print_caller_location(fl.loc)
                internal.print_string(" - frame ")
                internal.print_int(i)
                internal.print_byte('\n')
            }
        }
        internal.trap()
    }

    main :: proc() {
        trace.init(&global_trace_ctx)
        defer trace.destroy(&global_trace_ctx)

        context.assertion_failure_proc = debug_trace_assertion_failure_proc

        ...
    }

*/


import "base:internal"

import "core:fmt"
import "core:terminal"
import "core:os"


default_logger: Logger

@(private) global_subtract_stdout_options: Options
@(private) global_subtract_stderr_options: Options


// @(init)
subtract_terminal_options :: proc() {
    // NOTE(Feoramund): While it is technically possible for these streams to
    // be redirected during the internal of the program, the cost of checking on
    // every single log message is not worth it to support such an
    // uncommonly-used feature.
    if terminal.color_enabled {
        // This is done this way because it's possible that only one of these
        // streams could be redirected to a file.
        if !terminal.is_terminal(os.stdout) {
            global_subtract_stdout_options = { .Terminal_Color }
        }
        if !terminal.is_terminal(os.stderr) {
            global_subtract_stderr_options = { .Terminal_Color }
        }
    } else {
        // Override any terminal coloring.
        global_subtract_stdout_options = { .Terminal_Color }
        global_subtract_stderr_options = { .Terminal_Color }
    }
}


debugf :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(default_logger, .Debug,   fmt_str, ..args, loc=loc)
}
infof  :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(default_logger, .Info,    fmt_str, ..args, loc=loc)
}
warnf  :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(default_logger, .Warning, fmt_str, ..args, loc=loc)
}
errorf :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(default_logger, .Error,   fmt_str, ..args, loc=loc)
}
fatalf :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(default_logger, .Fatal,   fmt_str, ..args, loc=loc)
}

debug :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(default_logger, .Debug,   ..args, sep=sep, loc=loc)
}
info  :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(default_logger, .Info,    ..args, sep=sep, loc=loc)
}
warn  :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(default_logger, .Warning, ..args, sep=sep, loc=loc)
}
error :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(default_logger, .Error,   ..args, sep=sep, loc=loc)
}
fatal :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(default_logger, .Fatal,   ..args, sep=sep, loc=loc)
}

panic :: proc(args: ..any, loc := #caller_location) -> ! {
    log(default_logger, .Fatal, ..args, loc=loc)
    internal.panic("log.panic", loc)
}

panicf :: proc(fmt_str: string, args: ..any, loc := #caller_location) -> ! {
    logf(default_logger, .Fatal, fmt_str, ..args, loc=loc)
    internal.panic("log.panicf", loc)
}

@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        @(cold)
        internal_assert :: proc(message: string, loc: internal.Source_Code_Location) {
            log(default_logger, .Fatal, message, loc=loc)
            internal.assertion_failure_proc("internal assertion", message, loc)
        }
        internal_assert(message, loc)
    }
}

@(disabled=ODIN_DISABLE_ASSERT)
assertf :: proc(condition: bool, fmt_str: string, args: ..any, loc := #caller_location) {
    if !condition {
        // NOTE(dragos): We are using the same trick as in builtin.assert
        // to improve performance to make the CPU not
        // execute speculatively, making it about an order of
        // magnitude faster
        @(cold)
        internal_assertf :: proc(loc: internal.Source_Code_Location, fmt_str: string, args: ..any) {
            message := fmt.tprintf(fmt_str, ..args)
            log(default_logger, .Fatal, message, loc=loc)
            internal.assertion_failure_proc("internal assertion", message, loc)
        }
        internal_assertf(loc, fmt_str, ..args)
    }
}

ensure :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        @(cold)
        internal_ensure :: proc(message: string, loc: internal.Source_Code_Location) {
            log(default_logger, .Fatal, message, loc=loc)
            internal.assertion_failure_proc("unsatisfied ensure", message, loc)
        }
        internal_ensure(message, loc)
    }
}

ensuref :: proc(condition: bool, fmt_str: string, args: ..any, loc := #caller_location) {
    if !condition {
        @(cold)
        internal_ensuref :: proc(loc: internal.Source_Code_Location, fmt_str: string, args: ..any) {
            message := fmt.tprintf(fmt_str, ..args)
            log(default_logger, .Fatal, message, loc=loc)
            internal.assertion_failure_proc("unsatisfied ensure", message, loc)
        }
        internal_ensuref(loc, fmt_str, ..args)
    }
}

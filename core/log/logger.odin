import "base:internal"

// import "core:fmt"
import "core:os"


global_logger: Logger


Logger :: struct {
    procedure:    Logger_Proc,
    
    file_handle:  ^os.File,
    ident:        string,

    lowest_level: Level,
    options:      Options,
}

Logger_Proc :: #type proc(file_handle: ^os.File, ident: string, level: Level, fmt_string: string, args: []any, options: Options, loc := #caller_location)

Level :: enum uint {
    Debug   = 0,
    Info    = 10,
    Warning = 20,
    Error   = 30,
    Fatal   = 40,
}

Option :: enum {
    Level,
    Date,
    Time,
    Short_File_Path,
    Long_File_Path,
    Line,
    Procedure,
    Terminal_Color,
    Thread_Id,
}
Options :: bit_set[Option]


log :: proc(logger: Logger, level: Level, args: ..any, sep := " ", loc := #caller_location) {
    if logger.procedure == nil { return }
    if level < logger.lowest_level { return }

    logger.procedure(logger.file_handle, logger.ident, level, "", args, logger.options, loc)
}

logf :: proc(logger: Logger, level: Level, fmt_str: string, args: ..any, loc := #caller_location) {
    if logger.procedure == nil { return }
    if level < logger.lowest_level { return }

    logger.procedure(logger.file_handle, logger.ident, level, fmt_str, args, logger.options, loc)
}

debugf :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(global_logger, .Debug, fmt_str, ..args, loc=loc)
}

infof  :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(global_logger, .Info, fmt_str, ..args, loc=loc)
}

warnf  :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(global_logger, .Warning, fmt_str, ..args, loc=loc)
}

errorf :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(global_logger, .Error, fmt_str, ..args, loc=loc)
}

fatalf :: proc(fmt_str: string, args: ..any, loc := #caller_location) {
    logf(global_logger, .Fatal, fmt_str, ..args, loc=loc)
}

debug :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(global_logger, .Debug, ..args, sep=sep, loc=loc)
}

info  :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(global_logger, .Info, ..args, sep=sep, loc=loc)
}

warn  :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(global_logger, .Warning, ..args, sep=sep, loc=loc)
}

error :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(global_logger, .Error, ..args, sep=sep, loc=loc)
}

fatal :: proc(args: ..any, sep := " ", loc := #caller_location) {
    log(global_logger, .Fatal, ..args, sep=sep, loc=loc)
}

panic :: proc(args: ..any, loc := #caller_location) -> ! {
    log(global_logger, .Fatal, ..args, loc=loc)
    internal.panic("log.panic", loc)
}

panicf :: proc(fmt_str: string, args: ..any, loc := #caller_location) -> ! {
    logf(global_logger, .Fatal, fmt_str, ..args, loc=loc)
    internal.panic("log.panicf", loc)
}

@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        @(cold)
        internal_assert :: proc(message: string, loc: internal.Source_Code_Location) {
            log(global_logger, .Fatal, message, loc=loc)
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
            log(global_logger, .Fatal, message, loc=loc)
            internal.assertion_failure_proc("internal assertion", message, loc)
        }
        internal_assertf(loc, fmt_str, ..args)
    }
}

ensure :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
    if !condition {
        @(cold)
        internal_ensure :: proc(message: string, loc: internal.Source_Code_Location) {
            log(global_logger, .Fatal, message, loc=loc)
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
            log(global_logger, .Fatal, message, loc=loc)
            internal.assertion_failure_proc("unsatisfied ensure", message, loc)
        }
        internal_ensuref(loc, fmt_str, ..args)
    }
}

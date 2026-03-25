import "core:os"
import "core:terminal"

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


Default_Console_Logger_Opts :: Options{
    .Level,
    .Terminal_Color,
    .Short_File_Path,
    .Line,
    .Procedure,
} | Full_Timestamp_Opts


console_logger_init :: proc(lowest_level := Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> Logger {
    return {
        procedure    = console_logger_proc,
        ident        = ident,
        lowest_level = lowest_level,
        options      = opt
    }
}

console_logger_proc :: proc(file_handle: ^os.File, ident: string, level: Level, fmt_string: string, args: []any, options: Options, loc := #caller_location) {
    options := options
    h: ^os.File = ---
    if level < Level.Error {
        h = os.stdout
        options -= global_subtract_stdout_options
    } else {
        h = os.stderr
        options -= global_subtract_stderr_options
    }
    _file_console_logger_proc(h, ident, level, fmt_string, args, options, loc)
}

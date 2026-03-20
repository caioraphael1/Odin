#+build !freestanding
#+build !orca
#+build !js

import "base:internal"
import "base:mem"
import "base:container/strings"

import "core:fmt"
import "core:os"
import "core:strings_tools"
import "core:terminal/ansi"
import "core:time"
import "core:io/string_builder"

Level_Headers := [?]string{
     0..<10 = "[DEBUG] --- ",
    10..<20 = "[INFO ] --- ",
    20..<30 = "[WARN ] --- ",
    30..<40 = "[ERROR] --- ",
    40..<50 = "[FATAL] --- ",
}

Default_Console_Logger_Opts :: Options{
    .Level,
    .Terminal_Color,
    .Short_File_Path,
    .Line,
    .Procedure,
} | Full_Timestamp_Opts

Default_File_Logger_Opts :: Options{
    .Level,
    .Short_File_Path,
    .Line,
    .Procedure,
} | Full_Timestamp_Opts


File_Console_Logger_Data :: struct {
    file_handle: ^os.File,
    ident: string,
}


create_file_logger :: proc(h: ^os.File, lowest_level := Level.Debug, opt := Default_File_Logger_Opts, ident := "", allocator: mem.Allocator) -> Logger {
    data, _ := mem.new(File_Console_Logger_Data, allocator)
    data.file_handle = h
    data.ident = ident
    return {
        procedure    = file_logger_proc,
        data         = data,
        lowest_level = lowest_level,
        options      = opt
    }
}

destroy_file_logger :: proc(log: Logger, allocator: mem.Allocator) {
    data := cast(^File_Console_Logger_Data)log.data
    if data.file_handle != nil {
        _ = os.close(data.file_handle)
    }
    _ = mem.free(data, allocator)
}

create_console_logger :: proc(lowest_level := Level.Debug, opt := Default_Console_Logger_Opts, ident := "", allocator: mem.Allocator) -> Logger {
    data, _ := mem.new(File_Console_Logger_Data, allocator)
    data.file_handle = nil
    data.ident = ident
    return {
        procedure    = console_logger_proc,
        data         = data,
        lowest_level = lowest_level,
        options      = opt
    }
}

destroy_console_logger :: proc(log: Logger, allocator: mem.Allocator) {
    _ = mem.free(log.data, allocator)
}

@(private)
_file_console_logger_proc :: proc(h: ^os.File, ident: string, level: Level, text: string, options: Options, loc: internal.Source_Code_Location) {
    backing: [1024]byte //NOTE(Hoej): 1024 might be too much for a header backing, unless somebody has really long paths.
    buf := string_builder.builder_from_bytes(backing[:])

    do_level_header(options, &buf, level)

    when time.IS_SUPPORTED {
        do_time_header(options, &buf, time.now())
    }

    do_location_header(options, &buf, loc)

    if .Thread_Id in options {
        fmt.sbprintf(&buf, "[{}] ", os.get_current_thread_id())
    }

    if ident != "" {
        fmt.sbprintf(&buf, "[%s] ", ident)
    }
    //TODO(Hoej): When we have better atomics and such, make this thread-safe
    fmt.fprintf(h, "%s%s\n", string_builder.to_string(buf), text)
}

file_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, loc := #caller_location) {
    data := cast(^File_Console_Logger_Data)logger_data
    _file_console_logger_proc(data.file_handle, data.ident, level, text, options, loc)
}

console_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, loc := #caller_location) {
    options := options
    data := cast(^File_Console_Logger_Data)logger_data
    h: ^os.File = ---
    if level < Level.Error {
        h = os.stdout
        options -= global_subtract_stdout_options
    } else {
        h = os.stderr
        options -= global_subtract_stderr_options
    }
    _file_console_logger_proc(h, data.ident, level, text, options, loc)
}

do_level_header :: proc(opts: Options, str: ^string_builder.Builder, level: Level) {

    RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
    RED       :: ansi.CSI + ansi.FG_RED          + ansi.SGR
    YELLOW    :: ansi.CSI + ansi.FG_YELLOW       + ansi.SGR
    DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR

    col := RESET
    switch level {
    case .Debug:   col = DARK_GREY
    case .Info:    col = RESET
    case .Warning: col = YELLOW
    case .Error, .Fatal: col = RED
    }

    if .Level in opts {
        if .Terminal_Color in opts {
            fmt.sbprint(str, col)
        }
        fmt.sbprint(str, Level_Headers[level])
        if .Terminal_Color in opts {
            fmt.sbprint(str, RESET)
        }
    }
}

do_time_header :: proc(opts: Options, buf: ^string_builder.Builder, t: time.Time) {
    when time.IS_SUPPORTED {
        if Full_Timestamp_Opts & opts != nil {
            fmt.sbprint(buf, "[")
            y, m, d := time.date(t)
            h, min, s := time.clock_from_time(t)
            if .Date in opts {
                fmt.sbprintf(buf, "%d-%02d-%02d", y, m, d)
                if .Time in opts {
                    fmt.sbprint(buf, " ")
                }
            }
            if .Time in opts { fmt.sbprintf(buf, "%02d:%02d:%02d", h, min, s) }
            fmt.sbprint(buf, "] ")
        }
    }
}

do_location_header :: proc(opts: Options, buf: ^string_builder.Builder, loc := #caller_location) {
    if Location_Header_Opts & opts == nil {
        return
    }
    fmt.sbprint(buf, "[")

    file := loc.file_path
    if .Short_File_Path in opts {
        last: uint
        for r, i in loc.file_path {
            if r == '/' {
                last = i+1
            }
        }
        file = loc.file_path[last:]
    }

    if Location_File_Opts & opts != nil {
        fmt.sbprint(buf, file)
    }
    if .Line in opts {
        if Location_File_Opts & opts != nil {
            fmt.sbprint(buf, ":")
        }
        fmt.sbprint(buf, loc.line)
    }

    if .Procedure in opts {
        if (Location_File_Opts | {.Line}) & opts != nil {
            fmt.sbprint(buf, ":")
        }
        fmt.sbprintf(buf, "%s()", loc.procedure)
    }

    fmt.sbprint(buf, "] ")
}

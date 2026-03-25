import "base:internal"

import "core:fmt"
import "core:io/string_builder"
import "core:time"
import "core:os"
import "core:terminal/ansi"


Level_Headers := [?]string{
     0..<10 = "[DEBUG] --- ",
    10..<20 = "[INFO ] --- ",
    20..<30 = "[WARN ] --- ",
    30..<40 = "[ERROR] --- ",
    40..<50 = "[FATAL] --- ",
}

Full_Timestamp_Opts :: Options{
    .Date,
    .Time,
}

Location_Header_Opts :: Options{
    .Short_File_Path,
    .Long_File_Path,
    .Line,
    .Procedure,
}

Location_File_Opts :: Options{
    .Short_File_Path,
    .Long_File_Path,
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


@(private)
_file_console_logger_proc :: proc(h: ^os.File, ident: string, level: Level, fmt_string: string, args: []any, options: Options, loc: internal.Source_Code_Location) {
    backing: [1024]byte
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

    if fmt_string == "" {
        fmt.sbprint(&buf, ..args)
    } else {
        fmt.sbprintf(&buf, fmt_string, ..args)
    }

    // Write to output file.
    fmt.fprintf(h, "%s\n", string_builder.to_string(&buf))
}

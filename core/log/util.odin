import "base:internal"

import "base:container/str"
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


do_level_header :: proc(opts: Options, s: ^str.String($N), level: Level) {

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
            _ = str.write(s, col)
        }
        _ = str.write(s, Level_Headers[level])
        if .Terminal_Color in opts {
            _ = str.write(s, RESET)
        }
    }
}

do_time_header :: proc(opts: Options, s: ^str.String($N), t: time.Time) {
    when time.IS_SUPPORTED {
        if Full_Timestamp_Opts & opts != nil {
            _ = str.write(s, "[")
            y, m, d := time.date(t)
            h, min, sec := time.clock_from_time(t)
            if .Date in opts {
                _ = str.write(s, str.from_int(y), "-", str.from_int(int(m)), "-", str.from_int(d))
                if .Time in opts {
                    _ = str.write(s, " ")
                }
            }
            if .Time in opts { _ = str.write(s, str.from_uint(h), ":", str.from_uint(min), ":", str.from_uint(sec)) }
            _ = str.write(s, "] ")
        }
    }
}

do_location_header :: proc(opts: Options, s: ^str.String($N), loc := #caller_location) {
    if Location_Header_Opts & opts == nil {
        return
    }
    _ = str.write(s, "[")

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
        _ = str.write(s, file)
    }
    if .Line in opts {
        if Location_File_Opts & opts != nil {
            _ = str.write(s, ":")
        }
        _ = str.write(s, str.from_int(int(loc.line)))
    }

    if .Procedure in opts {
        if (Location_File_Opts | {.Line}) & opts != nil {
            _ = str.write(s, ":")
        }
        _ = str.write(s, loc.procedure, "()")
    }

    _ = str.write(s, "] ")
}


@(private)
_file_console_logger_proc :: proc(h: ^os.File, ident: string, level: Level, strs: []str.String_Type, options: Options, loc: internal.Source_Code_Location) {
    s: str.String(1024)


    do_level_header(options, &s, level)

    when time.IS_SUPPORTED {
        do_time_header(options, &s, time.now())
    }

    do_location_header(options, &s, loc)

    if .Thread_Id in options {
        _ = str.write(&s, "[", str.from_uint(os.get_current_thread_id()), "]")
    }

    if ident != "" {
        _ = str.write(&s, "[", ident, "]")
    }

    _ = str.write(&s, ..strs)
    _ = str.write(&s, "\n")

    // Write to output file.
    os.printb(str.slice(&s))
}

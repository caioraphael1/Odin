import "base:internal"

import sb "base:container/string_buffer"
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


do_level_header :: proc(opts: Options, str: ^sb.String_Buffer, level: Level) {

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
            _ = sb.write(str, col)
        }
        _ = sb.write(str, Level_Headers[level])
        if .Terminal_Color in opts {
            _ = sb.write(str, RESET)
        }
    }
}

do_time_header :: proc(opts: Options, buf: ^sb.String_Buffer, t: time.Time) {
    when time.IS_SUPPORTED {
        if Full_Timestamp_Opts & opts != nil {
            _ = sb.write(buf, "[")
            y, m, d := time.date(t)
            h, min, s := time.clock_from_time(t)
            if .Date in opts {
                _ = sb.write(buf, sb.from_int(y), "-", sb.from_int(int(m)), "-", sb.from_int(d))
                if .Time in opts {
                    _ = sb.write(buf, " ")
                }
            }
            if .Time in opts { _ = sb.write(buf, sb.from_uint(h), ":", sb.from_uint(min), ":", sb.from_uint(s)) }
            _ = sb.write(buf, "] ")
        }
    }
}

do_location_header :: proc(opts: Options, buf: ^sb.String_Buffer, loc := #caller_location) {
    if Location_Header_Opts & opts == nil {
        return
    }
    _ = sb.write(buf, "[")

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
        _ = sb.write(buf, file)
    }
    if .Line in opts {
        if Location_File_Opts & opts != nil {
            _ = sb.write(buf, ":")
        }
        _ = sb.write(buf, sb.from_int(int(loc.line)))
    }

    if .Procedure in opts {
        if (Location_File_Opts | {.Line}) & opts != nil {
            _ = sb.write(buf, ":")
        }
        _ = sb.write(buf, loc.procedure, "()")
    }

    _ = sb.write(buf, "] ")
}


@(private)
_file_console_logger_proc :: proc(h: ^os.File, ident: string, level: Level, strs: []sb.String_Type, options: Options, loc: internal.Source_Code_Location) {
    backing: [1024]u8

    buf := sb.create(raw_data(backing[:]), len(backing), 0)


    do_level_header(options, &buf, level)

    when time.IS_SUPPORTED {
        do_time_header(options, &buf, time.now())
    }

    do_location_header(options, &buf, loc)

    if .Thread_Id in options {
        _ = sb.write(&buf, "[", sb.from_uint(os.get_current_thread_id()), "]")
    }

    if ident != "" {
        _ = sb.write(&buf, "[", ident, "]")
    }

    _ = sb.write(&buf, ..strs)
    _ = sb.write(&buf, "\n")

    // Write to output file.
    os.printb(sb.slice(buf))
}

#+build !freestanding
#+build !orca
#+build !js

import "base:container/str"

import "core:os"

Default_File_Logger_Opts :: Options{
    .Level,
    .Short_File_Path,
    .Line,
    .Procedure,
} | Full_Timestamp_Opts


file_logger_init :: proc(h: ^os.File, lowest_level := Level.Debug, opt := Default_File_Logger_Opts, ident := "") -> Logger {
    return {
        procedure    = file_logger_proc,
        file_handle  = h,
        ident        = ident,
        lowest_level = lowest_level,
        options      = opt
    }
}

file_logger_deinit :: proc(log: Logger) {
    if log.file_handle != nil {
        _ = os.close(log.file_handle)
    }
}

file_logger_proc :: proc(file_handle: ^os.File, ident: string, level: Level, strs: []str.String_Type, options: Options, loc := #caller_location) {
    _file_console_logger_proc(file_handle, ident, level, strs, options, loc)
}


import "base:container/str"

import "core:os"


global_logger: Logger


Logger :: struct {
    procedure:    Logger_Proc,
    
    file_handle:  ^os.File,
    ident:        string,

    lowest_level: Level,
    options:      Options,
}

Logger_Proc :: #type proc(file_handle: ^os.File, ident: string, level: Level, strs: []str.String_Type, options: Options, loc := #caller_location)

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


log :: proc(logger: Logger, level: Level, strs: []str.String_Type, loc := #caller_location) {
    if logger.procedure == nil { return }
    if level < logger.lowest_level { return }

    logger.procedure(logger.file_handle, logger.ident, level, strs, logger.options, loc)
}

debug :: proc(strs: ..str.String_Type, loc := #caller_location) {
    log(global_logger, .Debug, strs, loc=loc)
}

info  :: proc(strs: ..str.String_Type, loc := #caller_location) {
    log(global_logger, .Info, strs, loc=loc)
}

warn  :: proc(strs: ..str.String_Type, loc := #caller_location) {
    log(global_logger, .Warning, strs, loc=loc)
}

error :: proc(strs: ..str.String_Type, loc := #caller_location) {
    log(global_logger, .Error, strs, loc=loc)
}

package log


import "base:runtime"


Multi_Logger_Data :: struct {
    loggers: []Logger,
}

create_multi_logger :: proc(logs: []Logger, allocator: runtime.Allocator) -> Logger {
    data, _ := new(Multi_Logger_Data, allocator)
    data.loggers, _ = make_slice([]Logger, len(logs), allocator)
    copy_slice(data.loggers, logs)
    return Logger{multi_logger_proc, data, Level.Debug, nil}
}

destroy_multi_logger :: proc(log: Logger, allocator: runtime.Allocator) {
    data := (^Multi_Logger_Data)(log.data)
    _ = delete_slice(data.loggers, allocator)
    _ = free(data, allocator)
}

multi_logger_proc :: proc(logger_data: rawptr, level: Level, text: string,
                          options: Options, location := #caller_location) {
    data := cast(^Multi_Logger_Data)logger_data
    for log in data.loggers {
        if level < log.lowest_level {
            return
        }
        log.procedure(log.data, level, text, log.options, location)
    }
}

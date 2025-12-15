#+build !freestanding

package log

import "base:runtime"
import "core:fmt"
import "core:sync"


// Log_Allocator is an allocator which calls `logger` on each of its allocations operations.
// The format can be changed by setting the `size_fmt: Log_Allocator_Format` field to either `Bytes` or `Human`.
Log_Allocator :: struct {
    logger:    Logger,
	allocator: runtime.Allocator,
	level:     Level,
	prefix:    string,
	lock:      sync.Mutex,
	size_fmt:  Log_Allocator_Format,
}

Log_Allocator_Format :: enum {
	Bytes, // Actual number of bytes.
	Human, // Bytes in human units like bytes, kibibytes, etc. as appropriate.
}


log_allocator_init :: proc(
    la:        ^Log_Allocator, 
    logger:    Logger, 
    level:     Level, 
    size_fmt   := Log_Allocator_Format.Bytes,
    allocator: runtime.Allocator, 
    prefix     := "",
    ) {
    la.logger    = logger
	la.allocator = allocator
	la.level    = level
	la.prefix   = prefix
	la.lock     = {}
	la.size_fmt = size_fmt
}


log_allocator :: proc(la: ^Log_Allocator) -> runtime.Allocator {
	return runtime.Allocator{
		procedure = log_allocator_proc,
		data = la,
	}
}

log_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, runtime.Allocator_Error)  {
	la := (^Log_Allocator)(allocator_data)

	if la.logger.procedure == nil || la.level < la.logger.lowest_level {
		return la.allocator.procedure(la.allocator.data, mode, size, alignment, old_memory, old_size, location)
	}

	padding := " " if la.prefix != "" else ""

	buf: [256]byte = ---

	sync.lock(&la.lock)
	switch mode {
	case .Alloc:
		format: string
		switch la.size_fmt {
		case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Alloc, size=%d, alignment=%d)"
		case .Human: format = "%s%s>>> ALLOCATOR(mode=.Alloc, size=%m, alignment=%d)"
		}
		str := fmt.bprintf(buf[:], format, la.prefix, padding, size, alignment)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)

	case .Alloc_Non_Zeroed:
		format: string
		switch la.size_fmt {
		case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Alloc_Non_Zeroed, size=%d, alignment=%d)"
		case .Human: format = "%s%s>>> ALLOCATOR(mode=.Alloc_Non_Zeroed, size=%m, alignment=%d)"
		}
		str := fmt.bprintf(buf[:], format, la.prefix, padding, size, alignment)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)

	case .Free:
		if old_size != 0 {
			format: string
			switch la.size_fmt {
			case .Bytes: format = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%d)"
			case .Human: format = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%m)"
			}
			str := fmt.bprintf(buf[:], format, la.prefix, padding, old_memory, old_size)
			la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)
		} else {
			str := fmt.bprintf(buf[:], "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p)", la.prefix, padding, old_memory)
			la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)
		}

	case .Free_All:
		str := fmt.bprintf(buf[:], "%s%s<<< ALLOCATOR(mode=.Free_All)", la.prefix, padding)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)

	case .Resize:
		format: string
		switch la.size_fmt {
		case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%d, size=%d, alignment=%d)"
		case .Human: format = "%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%m, size=%m, alignment=%d)"
		}
		str := fmt.bprintf(buf[:], format, la.prefix, padding, old_memory, old_size, size, alignment)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)

	case .Resize_Non_Zeroed:
		format: string
		switch la.size_fmt {
		case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Resize_Non_Zeroed, ptr=%p, old_size=%d, size=%d, alignment=%d)"
		case .Human: format = "%s%s>>> ALLOCATOR(mode=.Resize_Non_Zeroed, ptr=%p, old_size=%m, size=%m, alignment=%d)"
		}
		str := fmt.bprintf(buf[:], format, la.prefix, padding, old_memory, old_size, size, alignment)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)

	case .Query_Features:
		str := fmt.bprintf(buf[:], "%s%sALLOCATOR(mode=.Query_Features)", la.prefix, padding)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)

	case .Query_Info:
		str := fmt.bprintf(buf[:], "%s%sALLOCATOR(mode=.Query_Info)", la.prefix, padding)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)
	}
	sync.unlock(&la.lock)

	data, err := la.allocator.procedure(la.allocator.data, mode, size, alignment, old_memory, old_size, location)
	if err != nil {
		sync.lock(&la.lock)
		str := fmt.bprintf(buf[:], "%s%sALLOCATOR ERROR=%v", la.prefix, padding, err)
		la.logger.procedure(la.logger.data, la.level, str, la.logger.options, location)
		sync.unlock(&la.lock)
	}
	return data, err
}

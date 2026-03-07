#+build js
#+private
import "core:time/datetime"
import "base:runtime"

local_tz_name :: proc(allocator: mem.Allocator) -> (name: string, success: bool) {
	return
}

_region_load :: proc(_reg_str: string, allocator: mem.Allocator) -> (out_reg: ^datetime.TZ_Region, success: bool) {
	return nil, true
}

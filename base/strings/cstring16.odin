import "base:internal"
import "base:mem"

Raw_Cstring16 :: internal.Raw_Cstring16

cstring16_delete :: proc(str: cstring16, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free((^u16)(str), allocator, loc)
}

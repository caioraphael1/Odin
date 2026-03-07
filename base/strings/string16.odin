import "base:internal"
import "base:mem"

Raw_String16 :: internal.Raw_String16

string16_delete :: proc(str: string16, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free_with_size(raw_data(str), len(str)*size_of(u16), allocator, loc)
}

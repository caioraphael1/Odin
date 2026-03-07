#+private
import "base:mem"
import "base:mem/allocators"
import win32 "core:sys/windows"

_temp_dir :: proc(allocator: mem.Allocator) -> (string, mem.Allocator_Error) {
    n := win32.GetTempPathW(0, nil)
    if n == 0 {
        return "", nil
    }
    allocators.TEMP_ALLOCATOR_TEMP_GUARD(allocator)

    b, _ := slice.create([]u16, max(win32.MAX_PATH, n), allocators.temp_allocator)
    n = win32.GetTempPathW(u32(len(b)), cstring16(raw_data(b)))

    if n == 3 && b[1] == ':' && b[2] == '\\' {

    } else if n > 0 && b[n-1] == '\\' {
        n -= 1
    }
    return win32_utf16_string16_to_utf8(string16(b[:n]), allocator)
}

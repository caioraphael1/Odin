import "base:mem"

//--------------------------------------------------------------------------------------------------
// String
//--------------------------------------------------------------------------------------------------

// @(builtin)
string_delete :: proc(str: string, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free_with_size(raw_data(str), len(str), allocator, loc)
}


//--------------------------------------------------------------------------------------------------
// String16
//--------------------------------------------------------------------------------------------------

// @(builtin)
string16_delete :: proc(str: string16, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free_with_size(raw_data(str), len(str)*size_of(u16), allocator, loc)
}


//--------------------------------------------------------------------------------------------------
// CString
//--------------------------------------------------------------------------------------------------

// @(builtin)
cstring_delete :: proc(str: cstring, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free((^byte)(str), allocator, loc)
}


//--------------------------------------------------------------------------------------------------
// CString16
//--------------------------------------------------------------------------------------------------

// @(builtin)
cstring16_delete :: proc(str: cstring16, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    return mem.free((^u16)(str), allocator, loc)
}

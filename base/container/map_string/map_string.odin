import "base:internal"
import "base:mem"
import "base:container/maps"
import "base:container/slice"
    // copy from string

/*
Map_String is a more memory efficient string map

Uses Specified Allocator for `Map_String_Entry` strings

Fields:
- allocator: The allocator used for the Map_String_Entry strings
- entries: A map of strings to interned string entries
*/
Map_String :: struct {
    allocator: mem.Allocator,
    entries:   map[string]^Map_String_Entry,
}

// Custom string entry struct
Map_String_Entry :: struct {
    len:  uint,
    str:  [1]u8, // string is allocated inline with the entry to keep allocations simple
}

/*
Initializes the entries map and sets the allocator for the string entries

*Allocates Using Provided Allocators*

Inputs:
- m: A pointer to the Map_String struct to be initialized
- allocator: The allocator for the Map_String_Entry strings 
- map_allocator: The allocator for the map of entries 

Returns:
- err: An allocator error if one occured, `nil` otherwise
*/
init :: proc(m: ^Map_String, allocator: mem.Allocator, map_allocator: mem.Allocator, loc := #caller_location) -> (err: mem.Allocator_Error) {
    m^ = {} // Reset the struct first.
    m.allocator = allocator
    m.entries = maps.create_cap(map[string]^Map_String_Entry, 16, map_allocator, loc) or_return
    return nil
}
/*
Frees the map and all its content allocated using the `.allocator`.

Inputs:
- m: A pointer to the Map_String struct to be destroyed
*/
destroy :: proc(m: ^Map_String) {
    for _, value in m.entries {
        _ = mem.free(value, m.allocator)
    }
    _ = maps.delete(m.entries)
}
/*
Returns an interned copy of the given text, adding it to the map if not already present.

*Allocate using the Map_String's Allocator (First time string is seen only)*

Inputs:
- m: A pointer to the Map_String struct
- text: The string to be interned

NOTE: The returned string lives as long as the map entry lives.

Returns:
- str: The interned string
- err: An allocator error if one occured, `nil` otherwise
*/
get :: proc(m: ^Map_String, text: string) -> (str: string, err: mem.Allocator_Error) {
    entry := _get_entry(m, text) or_return
    #no_bounds_check return string(entry.str[:entry.len]), nil
}
/*
Returns an interned copy of the given text as a cstring, adding it to the map if not already present.

*Allocate using the Map_String's Allocator  (First time string is seen only)*

Inputs:
- m: A pointer to the Map_String struct
- text: The string to be interned

NOTE: The returned cstring lives as long as the map entry lives

Returns:
- str: The interned cstring
- err: An allocator error if one occured, `nil` otherwise
*/
get_cstring :: proc(m: ^Map_String, text: string) -> (str: cstring, err: mem.Allocator_Error) {
    entry := _get_entry(m, text) or_return
    return cstring(&entry.str[0]), nil
}

/*
Internal function to lookup whether the text string exists in the map, returns the entry
Sets and allocates the entry if it wasn't set yet

*Allocate using the Map_String's Allocator  (First time string is seen only)*

Inputs:
- m: A pointer to the Map_String struct
- text: The string to be looked up or interned

Returns:
- new_entry: The interned cstring
- err: An allocator error if one occured, `nil` otherwise
*/
_get_entry :: proc(m: ^Map_String, text: string) -> (new_entry: ^Map_String_Entry, err: mem.Allocator_Error) #no_bounds_check {
    internal.assert(m.allocator.procedure != nil)

    key_ptr, val_ptr, inserted := maps.entry(&m.entries, text) or_return
    if !inserted {
        return val_ptr^, nil
    }

    entry_size := uint(offset_of(Map_String_Entry, str)) + len(text) + 1
    bytes := mem.alloc(entry_size, align_of(Map_String_Entry), m.allocator) or_return
    new_entry = (^Map_String_Entry)(raw_data(bytes))

    new_entry.len = len(text)
    slice.copy_from_string(new_entry.str[:new_entry.len], text)
    new_entry.str[new_entry.len] = 0

    key := string(new_entry.str[:new_entry.len])

    key_ptr^ = key
    val_ptr^ = new_entry

    return
}

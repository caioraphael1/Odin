import "base:internal"
import "base:mem"
import "base:container/dyn_array"
import "base:unicode/utf8"

/*
A dynamic byte buffer / string builder with helper procedures
The dynamic array is wrapped inside the struct to be more opaque
You can use `fmt.sbprint*` procedures with a `^string_builder.Builder` directly
*/
Builder :: struct {
    buf: [dynamic]byte,
}


builder_create :: proc(allocator: mem.Allocator) -> (builder: Builder) {
    builder.buf.allocator = allocator
    return
}

builder_create_len :: proc(len: uint, allocator: mem.Allocator, loc := #caller_location) -> (res: Builder, err: mem.Allocator_Error) {
    return { 
        buf = dyn_array.create_len([dynamic]byte, len, allocator, loc) or_return
    }, nil
}

builder_create_len_cap :: proc(len, cap: uint, allocator: mem.Allocator, loc := #caller_location) -> (res: Builder, err: mem.Allocator_Error) {
    return Builder{ 
        buf = dyn_array.create_len_cap([dynamic]byte, len, cap, allocator, loc) or_return
    }, nil
}

builder_init :: proc(b: ^Builder, allocator: mem.Allocator) {
    b^ = {} // Reset the struct first.
    dyn_array.init(&b.buf, allocator)
}

builder_init_len :: proc(b: ^Builder, len: uint, allocator: mem.Allocator, loc := #caller_location) -> (err: mem.Allocator_Error) {
    b^ = {} // Reset the struct first.
    b.buf = dyn_array.create_len([dynamic]byte, len, allocator, loc) or_return
    return nil
}

builder_init_len_cap :: proc(b: ^Builder, len, cap: uint, allocator: mem.Allocator, loc := #caller_location) -> (err: mem.Allocator_Error) {
    b^ = {} // Reset the struct first.
    b.buf = dyn_array.create_len_cap([dynamic]byte, len, cap, allocator, loc) or_return
    return nil
}

builder_from_bytes :: proc(backing: []byte) -> (res: Builder) {
    return Builder{ buf = dyn_array.from_slice(backing) }
}

builder_destroy :: proc(b: ^Builder) {
    _ = dyn_array.delete(b.buf)
    b.buf = nil
}

builder_clear :: proc(b: ^Builder) {
    dyn_array.clear(&b.buf)
}

builder_grow :: proc(b: ^Builder, cap: uint) {
    _ = dyn_array.reserve(&b.buf, cap)
}



builder_len :: proc(b: Builder) -> uint {
    return len(b.buf)
}

builder_cap :: proc(b: Builder) -> uint {
    return cap(b.buf)
}

builder_remaining_space :: proc(b: Builder) -> uint {
    return cap(b.buf) - len(b.buf)
}



to_string :: proc(b: Builder) -> (res: string) {
    return string(b.buf[:])
}

/*
Appends a trailing null byte after the end of the current Builder byte buffer and then casts it to a cstring
*/
to_cstring :: proc(b: ^Builder, loc := #caller_location) -> (res: cstring, err: mem.Allocator_Error) {
    len_before := len(b.buf)
    dyn_array.append(&b.buf, 0, loc) or_return
    if len(b.buf) - len_before != 1 {
        return nil, .Out_Of_Memory
    }
    dyn_array.pop(&b.buf)
    #no_bounds_check {
        internal.assert(b.buf[len(b.buf)] == 0)
    }
    return cstring(raw_data(b.buf)), nil
}

/*
Appends a trailing null byte after the end of the current Builder byte buffer and then casts it to a cstring
NOTE: This procedure will not check if the backing buffer has enough space to include the extra null byte.
*/
unsafe_to_cstring :: proc(b: ^Builder, loc := #caller_location) -> (res: cstring) {
    _ = dyn_array.append(&b.buf, 0, loc)
    dyn_array.pop(&b.buf)
    return cstring(raw_data(b.buf))
}


/*
Pops and returns the last byte in the Builder or 0 when the Builder is empty

Inputs:
- b: A pointer to the Builder

Returns:
- r: The last byte in the Builder or 0 if empty
*/
pop_byte :: proc(b: ^Builder) -> (r: byte) {
    if len(b.buf) == 0 {
        return 0
    }

    r = b.buf[len(b.buf)-1]
    d := (^dyn_array.Raw_Dynamic_Array)(&b.buf)
    d.len = max(d.len-1, 0)
    return
}

/*
Pops the last rune in the Builder and returns the popped rune and its rune width or (0, 0) if empty

Inputs:
- b: A pointer to the Builder

Returns:
- r: The popped rune
- width: The rune width or 0 if the builder was empty
*/
pop_rune :: proc(b: ^Builder) -> (r: rune, width: uint) {
    if len(b.buf) == 0 {
        return 0, 0
    }

    r, width = utf8.last_rune_in_bytes(b.buf[:])
    d := (^dyn_array.Raw_Dynamic_Array)(&b.buf)
    d.len = max(d.len-width, 0)
    return
}

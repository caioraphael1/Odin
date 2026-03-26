#+ignore

import "base:internal"
import "base:mem"
import "base:container/dyn_array"
import "base:container/slice"
import "base:unicode/utf8"

import "core:io"

MIN_READ :: 512

@(private) SMALL_BUFFER_SIZE :: 64

// A Dyn_Buffer is a variable-sized buffer of bytes with a io.Stream interface
// The zero value for Dyn_Buffer is an empty buffer ready to use.
Dyn_Buffer :: struct {
    buf:       dyn_array.Dyn_Array(u8),
    off:       uint,
    last_read: Read_Op,
}

@(private)
Read_Op :: enum i8 {
    Read       = -1,
    Invalid    =  0,
    Read_Rune1 =  1,
    Read_Rune2 =  2,
    Read_Rune3 =  3,
    Read_Rune4 =  4,
}


buffer_init :: proc(b: ^Dyn_Buffer, buf: []u8, loc := #caller_location) {
    _ = dyn_array.resize(&b.buf, len(buf), loc=loc)
    slice.copy(b.buf[:], buf)
}

buffer_init_string :: proc(b: ^Dyn_Buffer, s: string, loc := #caller_location) {
    _ = dyn_array.resize(&b.buf, len(s), loc=loc)
    slice.copy_from_string(b.buf[:], s)
}

buffer_init_allocator :: proc(b: ^Dyn_Buffer, len, cap: uint, allocator: mem.Allocator, loc := #caller_location) {
    if b.buf == nil {
        b.buf, _ = dyn_array.create_len_cap(u8, len, cap, allocator, loc)
        return
    }

    b.buf.allocator = allocator
    _ = dyn_array.reserve(&b.buf, cap)
    _ = dyn_array.resize(&b.buf, len)
}

buffer_destroy :: proc(b: ^Dyn_Buffer) {
    _ = dyn_array.delete(b.buf)
    buffer_reset(b)
}

buffer_to_bytes :: proc(b: ^Dyn_Buffer) -> []u8 {
    return b.buf[b.off:]
}

buffer_to_string :: proc(b: ^Dyn_Buffer) -> string {
    if b == nil {
        return "<nil>"
    }
    return string(b.buf[b.off:])
}

buffer_is_empty :: proc(b: ^Dyn_Buffer) -> bool {
    return len(b.buf) <= b.off
}

buffer_length :: proc(b: ^Dyn_Buffer) -> uint {
    return len(b.buf) - b.off
}

buffer_capacity :: proc(b: ^Dyn_Buffer) -> uint {
    return cap(b.buf)
}

buffer_reset :: proc(b: ^Dyn_Buffer) {
    dyn_array.clear(&b.buf)
    b.off = 0
    b.last_read = .Invalid
}


buffer_truncate :: proc(b: ^Dyn_Buffer, n: uint) {
    if n == 0 {
        buffer_reset(b)
        return
    }
    b.last_read = .Invalid
    if n < 0 || n > buffer_length(b) {
        internal.panic("bytes.truncate: truncation out of range")
    }
    _ = dyn_array.resize(&b.buf, b.off+n)
}

@(private)
_buffer_try_grow :: proc(b: ^Dyn_Buffer, n: uint, loc := #caller_location) -> (uint, bool) {
    if l := len(b.buf); n <= cap(b.buf)-l {
        _ = dyn_array.resize(&b.buf, l+n, loc=loc)
        return l, true
    }
    return 0, false
}

@(private)
_buffer_grow :: proc(b: ^Dyn_Buffer, n: uint, loc := #caller_location) -> uint {
    m := buffer_length(b)
    if m == 0 && b.off != 0 {
        buffer_reset(b)
    }
    if i, ok := _buffer_try_grow(b, n, loc=loc); ok {
        return i
    }

    if b.buf == nil && n <= SMALL_BUFFER_SIZE {
        // Fixes #2756 by preserving allocator if already set on Dyn_Buffer via init_buffer_allocator
        _ = dyn_array.reserve(&b.buf, SMALL_BUFFER_SIZE, loc=loc)
        _ = dyn_array.resize(&b.buf, n, loc=loc)
        return 0
    }

    c := cap(b.buf)
    if n <= c/2 - m {
        slice.copy(b.buf[:], b.buf[b.off:])
    } else if c > max(uint) - c - n {
        internal.panic("bytes.Dyn_Buffer: too large")
    } else {
        _ = dyn_array.resize(&b.buf, 2*c + n, loc=loc)
        slice.copy(b.buf[:], b.buf[b.off:])
    }
    b.off = 0
    _ = dyn_array.resize(&b.buf, m+n, loc=loc)
    return m
}

buffer_grow :: proc(b: ^Dyn_Buffer, n: uint, loc := #caller_location) {
    if n < 0 {
        internal.panic("bytes.buffer_grow: negative count")
    }
    m := _buffer_grow(b, n, loc=loc)
    _ = dyn_array.resize(&b.buf, m, loc=loc)
}

buffer_write_at :: proc(b: ^Dyn_Buffer, p: []u8, offset: uint, loc := #caller_location) -> (n: uint, err: io.Error) {
    if len(p) == 0 {
        return 0, nil
    }
    b.last_read = .Invalid
    if offset < 0 {
        err = .Invalid_Offset
        return
    }
    _, ok := _buffer_try_grow(b, offset+len(p), loc=loc)
    if !ok {
        _ = _buffer_grow(b, offset+len(p), loc=loc)
    }
    if len(b.buf) <= offset {
        return 0, .Short_Write
    }
    return slice.copy(b.buf[offset:], p), nil
}


buffer_write :: proc(b: ^Dyn_Buffer, p: []u8, loc := #caller_location) -> (n: uint, err: io.Error) {
    b.last_read = .Invalid
    m, ok := _buffer_try_grow(b, len(p), loc=loc)
    if !ok {
        m = _buffer_grow(b, len(p), loc=loc)
    }
    return slice.copy(b.buf[m:], p), nil
}

buffer_write_ptr :: proc(b: ^Dyn_Buffer, ptr: rawptr, size: uint, loc := #caller_location) -> (n: uint, err: io.Error) {
    return buffer_write(b, ([^]u8)(ptr)[:size], loc=loc)
}

buffer_write_string :: proc(b: ^Dyn_Buffer, s: string, loc := #caller_location) -> (n: uint, err: io.Error) {
    b.last_read = .Invalid
    m, ok := _buffer_try_grow(b, len(s), loc=loc)
    if !ok {
        m = _buffer_grow(b, len(s), loc=loc)
    }
    return slice.copy_from_string(b.buf[m:], s), nil
}

buffer_write_slice :: proc(b: ^Dyn_Buffer, slice: $S/[]$T, loc := #caller_location) -> (n: uint, err: io.Error) {
    size := len(slice)*size_of(T)
    return buffer_write(b, ([^]u8)(raw_data(slice))[:size], loc=loc)
}

buffer_write_byte :: proc(b: ^Dyn_Buffer, c: u8, loc := #caller_location) -> io.Error {
    b.last_read = .Invalid
    m, ok := _buffer_try_grow(b, 1, loc=loc)
    if !ok {
        m = _buffer_grow(b, 1, loc=loc)
    }
    b.buf[m] = c
    return nil
}

buffer_write_rune :: proc(b: ^Dyn_Buffer, r: rune, loc := #caller_location) -> (n: uint, err: io.Error) {
    if r < utf8.RUNE_SELF {
        buffer_write_byte(b, u8(r), loc=loc) or_return
        return 1, nil
    }
    b.last_read = .Invalid
    m, ok := _buffer_try_grow(b, utf8.UTF_MAX, loc=loc)
    if !ok {
        m = _buffer_grow(b, utf8.UTF_MAX, loc=loc)
    }
    res: [4]u8
    res, n = utf8.bytes_from_rune(r)
    slice.copy(b.buf[m:][:utf8.UTF_MAX], res[:n])
    _ = dyn_array.resize(&b.buf, m+n)
    return
}

buffer_next :: proc(b: ^Dyn_Buffer, n: uint) -> []u8 {
    n := n
    b.last_read = .Invalid
    m := buffer_length(b)
    if n > m {
        n = m
    }
    data := b.buf[b.off : b.off + n]
    b.off += n
    if n > 0 {
        b.last_read = .Read
    }
    return data
}

buffer_read :: proc(b: ^Dyn_Buffer, p: []u8) -> (n: uint, err: io.Error) {
    b.last_read = .Invalid
    if buffer_is_empty(b) {
        buffer_reset(b)
        if len(p) == 0 {
            return 0, nil
        }
        return 0, .EOF
    }
    n = slice.copy(p, b.buf[b.off:])
    b.off += n
    if n > 0 {
        b.last_read = .Read
    }
    return
}

buffer_read_ptr :: proc(b: ^Dyn_Buffer, ptr: rawptr, size: uint) -> (n: uint, err: io.Error) {
    return buffer_read(b, ([^]u8)(ptr)[:size])
}

buffer_read_at :: proc(b: ^Dyn_Buffer, p: []u8, offset: uint) -> (n: uint, err: io.Error) {
    if len(p) == 0 {
        return 0, nil
    }
    b.last_read = .Invalid

    if uint(offset) >= len(b.buf) {
        err = .EOF
        return
    }
    n = slice.copy(p, b.buf[offset:])
    if n > 0 {
        b.last_read = .Read
    }
    return
}


buffer_read_byte :: proc(b: ^Dyn_Buffer) -> (u8, io.Error) {
    if buffer_is_empty(b) {
        buffer_reset(b)
        return 0, .EOF
    }
    c := b.buf[b.off]
    b.off += 1
    b.last_read = .Read
    return c, nil
}

buffer_read_rune :: proc(b: ^Dyn_Buffer) -> (r: rune, size: uint, err: io.Error) {
    if buffer_is_empty(b) {
        buffer_reset(b)
        return 0, 0, .EOF
    }
    c := b.buf[b.off]
    if c < utf8.RUNE_SELF {
        b.off += 1
        b.last_read = .Read_Rune1
        return rune(c), 1, nil
    }
    r, size = utf8.rune_from_bytes(b.buf[b.off:])
    b.off += size
    b.last_read = Read_Op(i8(size))
    return
}

buffer_unread_byte :: proc(b: ^Dyn_Buffer) -> io.Error {
    if b.last_read == .Invalid {
        return .Invalid_Unread
    }
    b.last_read = .Invalid
    if b.off > 0 {
        b.off -= 1
    }
    return nil
}

buffer_unread_rune :: proc(b: ^Dyn_Buffer) -> io.Error {
    if b.last_read <= .Invalid {
        return .Invalid_Unread
    }
    if b.off >= uint(b.last_read) {
        b.off -= uint(i8(b.last_read))
    }
    b.last_read = .Invalid
    return nil
}

buffer_seek :: proc(b: ^Dyn_Buffer, offset: i64, whence: io.Seek_From) -> (i64, io.Error) {
    abs: i64
    switch whence {
    case .Start:
        abs = offset
    case .Current:
        abs = i64(b.off) + offset
    case .End:
        abs = i64(len(b.buf)) + offset
    case:
        return 0, .Invalid_Whence
    }

    abs_int := int(abs)
    if abs_int < 0 {
        return 0, .Invalid_Offset
    }
    b.last_read = .Invalid
    b.off = uint(abs_int)
    return abs, nil
}

buffer_read_bytes :: proc(b: ^Dyn_Buffer, delim: u8) -> (line: []u8, err: io.Error) {
    i, found := index_byte(b.buf[b.off:], delim)
    end := b.off + i + 1
    if !found {
        end = len(b.buf)
        err = .EOF
    }
    line = b.buf[b.off:end]
    b.off = end
    b.last_read = .Read
    return
}

buffer_read_string :: proc(b: ^Dyn_Buffer, delim: u8) -> (line: string, err: io.Error) {
    slice: []u8
    slice, err = buffer_read_bytes(b, delim)
    return string(slice), err
}

buffer_read_slice :: proc(b: ^Dyn_Buffer, slice: $S/[]$T) -> (n: int, err: io.Error) {
    size := len(slice)*size_of(T)
    return buffer_read(b, ([^]u8)(raw_data(slice))[:size])
}

buffer_write_to :: proc(b: ^Dyn_Buffer, w: io.Writer) -> (n: i64, err: io.Error) {
    b.last_read = .Invalid
    if byte_count := buffer_length(b); byte_count > 0 {
        m, e := io.write(w, b.buf[b.off:])
        if m > byte_count {
            internal.panic("bytes.buffer_write_to: invalid io.write count")
        }
        b.off += m
        n = i64(m)
        if e != nil {
            err = e
            return
        }
        if m != byte_count {
            err = .Short_Write
            return
        }
    }
    buffer_reset(b)
    return
}

buffer_read_from :: proc(b: ^Dyn_Buffer, r: io.Reader) -> (n: i64, err: io.Error) #no_bounds_check {
    b.last_read = .Invalid
    for {
        i := _buffer_grow(b, MIN_READ)
        _ = dyn_array.resize(&b.buf, i)
        m, e := io.read(r, b.buf[i:cap(b.buf)])
        if m < 0 {
            err = e if e != nil else .Negative_Read
            return
        }

        _ = dyn_array.resize(&b.buf, i + m)
        n += i64(m)
        if e == .EOF {
            return
        }
        if e != nil {
            err = e
            return
        }
    }
    return
}


buffer_to_stream :: proc(b: ^Dyn_Buffer) -> (s: io.Stream) {
    s.data = b
    s.procedure = _buffer_proc
    return
}


@(private)
_buffer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []u8, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    b := (^Dyn_Buffer)(stream_data)
    n_uint: uint
    #partial switch mode {
    case .Read:
        n_uint, err = buffer_read(b, p)
        n = i64(n_uint)
        return
    case .Read_At:
        n_uint, err = buffer_read_at(b, p, offset)
        n = i64(n_uint)
        return
    case .Write:
        n_uint, err = buffer_write(b, p)
        n = i64(n_uint)
        return
    case .Write_At:
        n_uint, err = buffer_write_at(b, p, offset)
        n = i64(n_uint)
        return
    case .Seek:
        n_uint, err = buffer_seek(b, offset, whence)
        n = i64(n_uint)
        return
    case .Size:
        n_uint, err = buffer_length(b)
        n = i64(n_uint)
        return
    case .Destroy:
        buffer_destroy(b)
        return
    case .Query:
        return io.query_utility({.Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Destroy, .Query})
    }
    return 0, .Unsupported
}








// Scrubs invalid utf-8 characters and replaces them with the replacement string
// Adjacent invalid bytes are only replaced once
scrub :: proc(s: []u8, replacement: []u8, allocator: mem.Allocator, loc := #caller_location) -> []u8 {
    str := s
    b: Dyn_Buffer
    buffer_init_allocator(&b, 0, len(s), allocator, loc)

    has_error := false
    cursor := 0
    origin := str

    for len(str) > 0 {
        r, w := utf8.rune_from_bytes(str)

        if r == utf8.RUNE_ERROR {
            if !has_error {
                has_error = true
                _, _ = buffer_write(&b, origin[:cursor])
            }
        } else if has_error {
            has_error = false
            _, _ = buffer_write(&b, replacement)

            origin = origin[cursor:]
            cursor = 0
        }

        cursor += w
        str = str[w:]
    }

    return buffer_to_bytes(&b)
}


@(private)
write_pad_string :: proc(b: ^Dyn_Buffer, pad: []u8, pad_len, remains: uint, loc := #caller_location) {
    repeats := remains / pad_len

    for i := 0; i < repeats; i += 1 {
        _, _ = buffer_write(b, pad)
    }

    n := remains % pad_len
    p := pad

    for i := 0; i < n; i += 1 {
        r, width := utf8.rune_from_bytes(p)
        _, _ = buffer_write_rune(b, r)
        p = p[width:]
    }
}

expand_tabs :: proc(s: []u8, tab_size: uint, allocator: mem.Allocator, loc := #caller_location) -> []u8 {
    if tab_size <= 0 {
        internal.panic("tab size must be positive")
    }


    if s == nil {
        return nil
    }

    b: Dyn_Buffer
    buffer_init_allocator(&b, 0, len(s), allocator, loc=loc)

    str := s
    column: int

    for len(str) > 0 {
        r, w := utf8.rune_from_bytes(str)

        if r == '\t' {
            expand := tab_size - column%tab_size

            for i := 0; i < expand; i += 1 {
                _ = buffer_write_byte(&b, ' ')
            }

            column += expand
        } else {
            if r == '\n' {
                column = 0
            } else {
                column += w
            }

            _, _ = buffer_write_rune(&b, r)
        }

        str = str[w:]
    }

    return buffer_to_bytes(&b)
}


center_justify :: centre_justify // NOTE(bill): Because Americans exist

// centre_justify returns a u8 slice with a pad u8 slice at boths sides if the str's rune length is smaller than length
centre_justify :: proc(str: []u8, length: uint, pad: []u8, allocator: mem.Allocator, loc := #caller_location) -> []u8 {
    n := rune_count(str)
    if n >= length || pad == nil {
        return clone(str, allocator, loc)
    }

    remains := length - 1
    pad_len := rune_count(pad)

    b: Dyn_Buffer
    buffer_init_allocator(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator, loc)

    write_pad_string(&b, pad, pad_len, remains/2)
    _, _ = buffer_write(&b, str)
    write_pad_string(&b, pad, pad_len, (remains+1)/2)

    return buffer_to_bytes(&b)
}

// left_justify returns a u8 slice with a pad u8 slice at left side if the str's rune length is smaller than length
left_justify :: proc(str: []u8, length: uint, pad: []u8, allocator: mem.Allocator, loc := #caller_location) -> []u8 {
    n := rune_count(str)
    if n >= length || pad == nil {
        return clone(str, allocator, loc)
    }

    remains := length-1
    pad_len := rune_count(pad)

    b: Dyn_Buffer
    buffer_init_allocator(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator, loc)

    _, _ = buffer_write(&b, str)
    write_pad_string(&b, pad, pad_len, remains)

    return buffer_to_bytes(&b)
}

// right_justify returns a u8 slice with a pad u8 slice at right side if the str's rune length is smaller than length
right_justify :: proc(str: []u8, length: uint, pad: []u8, allocator: mem.Allocator, loc := #caller_location) -> []u8 {
    n := rune_count(str)
    if n >= length || pad == nil {
        return clone(str, allocator, loc)
    }

    remains := length-1
    pad_len := rune_count(pad)

    b: Dyn_Buffer
    buffer_init_allocator(&b, 0, len(str) + (remains/pad_len + 1)*len(pad), allocator, loc)

    write_pad_string(&b, pad, pad_len, remains)
    _, _ = buffer_write(&b, str)

    return buffer_to_bytes(&b)
}


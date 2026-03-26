#+ignore

import "base:internal"
import "base:container/slice"
import "base:unicode/utf8"

import "core:io"

Reader :: struct {
    s:         []u8, // read-only buffer
    i:         i64,    // current reading index
    prev_rune: int,    // previous reading index of rune or < 0
}

reader_init :: proc(r: ^Reader, s: []u8) -> io.Stream {
    r.s = s
    r.i = 0
    r.prev_rune = -1
    return reader_to_stream(r)
}

reader_to_stream :: proc(r: ^Reader) -> (s: io.Stream) {
    s.data = r
    s.procedure = _reader_proc
    return
}

reader_length :: proc(r: ^Reader) -> int {
    if r.i >= i64(len(r.s)) {
        return 0
    }
    return int(i64(len(r.s)) - r.i)
}

reader_size :: proc(r: ^Reader) -> i64 {
    return i64(len(r.s))
}

reader_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: io.Error) {
    if len(p) == 0 {
        return 0, nil
    }
    if r.i >= i64(len(r.s)) {
        return 0, .EOF
    }
    r.prev_rune = -1
    n = int(slice.copy(p, r.s[r.i:]))
    r.i += i64(n)
    return
}
reader_read_at :: proc(r: ^Reader, p: []u8, off: i64) -> (n: int, err: io.Error) {
    if len(p) == 0 {
        return 0, nil
    }
    if off < 0 {
        return 0, .Invalid_Offset
    }
    if off >= i64(len(r.s)) {
        return 0, .EOF
    }
    n = int(slice.copy(p, r.s[off:]))
    if n < len(p) {
        err = .EOF
    }
    return
}
reader_read_slice :: proc(r: ^Reader, slice: $T/[]$S) -> (n: int, err: io.Error) {
    b := ([^]u8)(raw_data(slice))[:len(slice)*size_of(S)]
    return reader_read(r, b)
}

reader_read_slice_at :: proc(r: ^Reader, slice: $T/[]$S, off: i64) -> (n: int, err: io.Error) {
    b := ([^]u8)(raw_data(slice))[:len(slice)*size_of(S)]
    return reader_read_at(r, b, off)
}

reader_read_ptr :: proc(r: ^Reader, data: rawptr, len: int) -> (n: int, err: io.Error) {
    b := ([^]u8)(data)[:len]
    return reader_read(r, b)
}

reader_read_ptr_at :: proc(r: ^Reader, data: rawptr, len: int, off: i64) -> (n: int, err: io.Error) {
    b := ([^]u8)(data)[:len]
    return reader_read_at(r, b, off)
}


reader_read_byte :: proc(r: ^Reader) -> (u8, io.Error) {
    r.prev_rune = -1
    if r.i >= i64(len(r.s)) {
        return 0, .EOF
    }
    b := r.s[r.i]
    r.i += 1
    return b, nil
}
reader_unread_byte :: proc(r: ^Reader) -> io.Error {
    if r.i <= 0 {
        return .Invalid_Unread
    }
    r.prev_rune = -1
    r.i -= 1
    return nil
}
reader_read_rune :: proc(r: ^Reader) -> (ch: rune, size: int, err: io.Error) {
    if r.i >= i64(len(r.s)) {
        r.prev_rune = -1
        return 0, 0, .EOF
    }
    r.prev_rune = int(r.i)
    if c := r.s[r.i]; c < utf8.RUNE_SELF {
        r.i += 1
        return rune(c), 1, nil
    }
    ch, size = utf8.rune_from_bytes(r.s[r.i:])
    r.i += i64(size)
    return
}
reader_unread_rune :: proc(r: ^Reader) -> io.Error {
    if r.i <= 0 {
        return .Invalid_Unread
    }
    if r.prev_rune < 0 {
        return .Invalid_Unread
    }
    r.i = i64(r.prev_rune)
    r.prev_rune = -1
    return nil
}
reader_seek :: proc(r: ^Reader, offset: i64, whence: io.Seek_From) -> (i64, io.Error) {
    abs: i64
    switch whence {
    case .Start:
        abs = offset
    case .Current:
        abs = r.i + offset
    case .End:
        abs = i64(len(r.s)) + offset
    case:
        return 0, .Invalid_Whence
    }

    if abs < 0 {
        return 0, .Invalid_Offset
    }
    r.i = abs
    r.prev_rune = -1
    return abs, nil
}
reader_write_to :: proc(r: ^Reader, w: io.Writer) -> (n: i64, err: io.Error) {
    r.prev_rune = -1
    if r.i >= i64(len(r.s)) {
        return 0, nil
    }
    s := r.s[r.i:]
    m: int
    m, err = io.write(w, s)
    if m > len(s) {
        internal.panic("bytes.Reader.write_to: invalid io.write_string count")
    }
    r.i += i64(m)
    n = i64(m)
    if m != len(s) && err == nil {
        err = .Short_Write
    }
    return
}


@(private)
_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []u8, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    r := (^Reader)(stream_data)
    #partial switch mode {
    case .Read:
        n_uint: uint
        n_uint, err = reader_read(r, p)
        n = i64(n_uint)
        return
    case .Read_At:
        n_uint: uint
        n_uint, err = reader_read_at(r, p, offset)
        n = i64(n_uint)
        return
    case .Seek:
        n, err = reader_seek(r, offset, whence)
        return
    case .Size:
        n = reader_size(r)
        return
    case .Query:
        return io.query_utility({.Read, .Read_At, .Seek, .Size, .Query})
    }
    return 0, .Unsupported
}


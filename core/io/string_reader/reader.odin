import "base:internal"
import "base:container/slice"
import "base:unicode/utf8"

import "core:io"

/*
io stream data for a string reader that can read based on bytes or runes
implements the vtable when using the `io.Reader` variants
"read" calls advance the current reading offset `i`
*/
Reader :: struct {
    s:         string, // read-only buffer
    i:         i64,    // current reading index
    prev_rune: int,    // previous reading index of rune or < 0
}

/*
VTable containing implementations for various `io.Stream` methods

This VTable is used by the Reader struct to provide its functionality
as an `io.Stream`.
*/
@(private)
_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    r := (^Reader)(stream_data)
    #partial switch mode {
    case .Size:
        n = reader_size(r)
        return
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
    case .Query:
        return io.query_utility({.Size, .Read, .Read_At, .Seek, .Query})
    }
    return 0, .Unsupported
}


reader_init :: proc(r: ^Reader, s: string) {
    r.s = s
    r.i = 0
    r.prev_rune = -1
}

reader_to_stream :: proc(r: ^Reader) -> (s: io.Stream) {
    s.data = r
    s.procedure = _reader_proc
    return
}

to_reader :: proc(r: ^Reader, s: string) -> (res: io.Reader) {
    reader_init(r, s)
    rr, _ := io.to_reader(reader_to_stream(r))
    return rr
}

to_reader_at :: proc(r: ^Reader, s: string) -> (res: io.Reader_At) {
    reader_init(r, s)
    rr, _ := io.to_reader_at(reader_to_stream(r))
    return rr
}

reader_length :: proc(r: ^Reader) -> (res: uint) {
    if r.i >= i64(len(r.s)) {
        return 0
    }
    return uint(i64(len(r.s)) - r.i)
}

reader_size :: proc(r: ^Reader) -> (res: i64) {
    return i64(len(r.s))
}

reader_read :: proc(r: ^Reader, p: []byte) -> (n: uint, err: io.Error) {
    if r.i >= i64(len(r.s)) {
        return 0, .EOF
    }
    r.prev_rune = -1
    n = slice.copy_from_string(p, r.s[r.i:])
    r.i += i64(n)
    return
}

reader_read_at :: proc(r: ^Reader, p: []byte, off: i64) -> (n: uint, err: io.Error) {
    if off < 0 {
        return 0, .Invalid_Offset
    }
    if off >= i64(len(r.s)) {
        return 0, .EOF
    }
    n = slice.copy_from_string(p, r.s[off:])
    if n < len(p) {
        err = .EOF
    }
    return
}

reader_read_byte :: proc(r: ^Reader) -> (res: byte, err: io.Error) {
    r.prev_rune = -1
    if r.i >= i64(len(r.s)) {
        return 0, .EOF
    }
    b := r.s[r.i]
    r.i += 1
    return b, nil
}

reader_unread_byte :: proc(r: ^Reader) -> (err: io.Error) {
    if r.i <= 0 {
        return .Invalid_Unread
    }
    r.prev_rune = -1
    r.i -= 1
    return nil
}

reader_read_rune :: proc(r: ^Reader) -> (rr: rune, size: uint, err: io.Error) {
    if r.i >= i64(len(r.s)) {
        r.prev_rune = -1
        return 0, 0, .EOF
    }
    r.prev_rune = int(r.i)
    if c := r.s[r.i]; c < utf8.RUNE_SELF {
        r.i += 1
        return rune(c), 1, nil
    }
    rr, size = utf8.rune_from_string(r.s[r.i:])
    r.i += i64(size)
    return
}
/*
Decrements the Reader's index (i) by the size of the last read rune
WARNING: May only be used once and after a valid `read_rune` call
*/
reader_unread_rune :: proc(r: ^Reader) -> (err: io.Error) {
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

/*
Seeks the Reader's index to a new position

Inputs:
- r: A pointer to a Reader struct
- offset: The new offset position
- whence: The reference point for the new position (`.Start`, `.Current`, or `.End`)

Returns:
- The absolute offset after seeking
- err: An `io.Error` if an error occurs while seeking (`.Invalid_Whence`, `.Invalid_Offset`)
*/
reader_seek :: proc(r: ^Reader, offset: i64, whence: io.Seek_From) -> (res: i64, err: io.Error) {
    r.prev_rune = -1
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
    return abs, nil
}

/*
Writes the remaining content of the Reader's string into the provided `io.Writer`

Inputs:
- r: A pointer to a Reader struct
- w: The io.Writer to write the remaining content into

WARNING: Panics if writer writes more bytes than remainig length of string.

Returns:
- n: The number of bytes written
- err: An io.Error if an error occurs while writing (`.Short_Write`)
*/
reader_write_to :: proc(r: ^Reader, w: io.Writer) -> (n: i64, err: io.Error) {
    r.prev_rune = -1
    if r.i >= i64(len(r.s)) {
        return 0, nil
    }
    s := r.s[r.i:]
    m: uint
    m, err = io.write_string(w, s)
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

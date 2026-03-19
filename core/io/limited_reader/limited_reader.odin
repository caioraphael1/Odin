
import "core:io"


// A Limited_Reader reads from r but limits the amount of data returned to just n bytes.
// Each call to read updates n to reflect the new amount remaining.
// read returns EOF when n <= 0 or when the underlying r returns EOF.
Limited_Reader :: struct {
    r: io.Reader, // underlying reader
    n: i64,    // max_bytes
}

limited_reader_init :: proc(l: ^Limited_Reader, r: io.Reader, n: i64) -> io.Reader {
    l.r = r
    l.n = n
    return limited_reader_to_reader(l)
}

limited_reader_to_reader :: proc(l: ^Limited_Reader) -> (r: io.Reader) {
    r.procedure = _limited_reader_proc
    r.data = l
    return
}


// copy_n copies n bytes (or till an error) from src to dst.
// It returns the number of bytes copied and the first error that occurred whilst copying, if any.
// On return, written == n IFF err == nil
copy_n :: proc(dst: io.Writer, src: io.Reader, n: i64) -> (written: i64, err: io.Error) {
    nsrc := limited_reader_init(&Limited_Reader{}, src, n)
    written, err = io.copy(dst, nsrc)
    if written == n {
        return n, nil
    }
    if written < n && err == nil {
        // src stopped early and must have been an EOF
        err = .EOF
    }
    return
}


_limited_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    l := (^Limited_Reader)(stream_data)
    #partial switch mode {
    case .Read:
        if len(p) == 0 {
            return 0, nil
        }
        if l.n <= 0 {
            return 0, .EOF
        }
        p := p
        if i64(len(p)) > l.n {
            p = p[0:l.n]
        }
        n_uint: uint
        n_uint, err = io.read(l.r, p)
        n = i64(n_uint)
        l.n -= n
        return
    case .Query:
        return io.query_utility({.Read, .Query})
    }
    return 0, .Unsupported
}

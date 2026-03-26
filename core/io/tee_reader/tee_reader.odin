
/* 
writes to 'w' what it reads from 'r'
All reads from 'r' performed through it are matched with a corresponding write to 'w'
There is no internal buffering done
The write must complete before th read completes
*/
Tee_Reader :: struct {
    r: Reader,
    w: Writer,
}

tee_reader_init :: proc(t: ^Tee_Reader, r: Reader, w: Writer, allocator: mem.Allocator) -> Reader {
    t.r, t.w = r, w
    return tee_reader_to_reader(t)
}

tee_reader_to_reader :: proc(t: ^Tee_Reader) -> (r: Reader) {
    r.data = t
    r.procedure = _tee_reader_proc
    return
}


@(private)
_tee_reader_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []u8, offset: i64, whence: Seek_From, loc := #caller_location) -> (n: i64, err: Error) {
    t := (^Tee_Reader)(stream_data)
    #partial switch mode {
    case .Read:
        n_uint: uint
        n_uint, err = read(t.r, p)
        n = i64(n_uint)
        if n > 0 {
            if wn, werr := write(t.w, p[:n]); werr != nil {
                return i64(wn), werr
            }
        }
        return
    case .Query:
        return query_utility({.Read, .Query})
    }
    return 0, .Unsupported
}

// Section_Reader implements read, seek, and read_at on a section of an underlying Reader_At
Section_Reader :: struct {
    r:     Reader_At,
    base:  i64,
    off:   i64,
    limit: i64,
}

section_reader_init :: proc(s: ^Section_Reader, r: Reader_At, off: i64, n: i64) -> Reader {
    s.r = r
    s.base = off
    s.off = off
    s.limit = off + n
    return section_reader_to_stream(s)
}
section_reader_to_stream :: proc(s: ^Section_Reader) -> (out: Stream) {
    out.data = s
    out.procedure = _section_reader_proc
    return
}

@(private)
_section_reader_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []u8, offset: i64, whence: Seek_From, loc := #caller_location) -> (n: i64, err: Error) {
    s := (^Section_Reader)(stream_data)
    #partial switch mode {
    case .Read:
        if len(p) == 0 {
            return 0, nil
        }
        if s.off >= s.limit {
            return 0, .EOF
        }
        p := p
        if max := s.limit - s.off; i64(len(p)) > max {
            p = p[0:max]
        }
        n_uint: uint
        n_uint, err = read_at(s.r, p, s.off)
        n = i64(n_uint)
        s.off += n
        return
    case .Read_At:
        if len(p) == 0 {
            return 0, nil
        }
        p, off := p, offset

        if off < 0 || off >= s.limit - s.base {
            return 0, .EOF
        }
        off += s.base
        if max := s.limit - off; i64(len(p)) > max {
            p = p[0:max]

            n_uint: uint
            n_uint, err = read_at(s.r, p, off)
            n = i64(n_uint)
            if err == nil {
                err = .EOF
            }
            return
        }
        n_uint: uint
        n_uint, err = read_at(s.r, p, off)
        n = i64(n_uint)
        return

    case .Seek:
        offset := offset
        switch whence {
        case:
            return 0, .Invalid_Whence
        case .Start:
            offset += s.base
        case .Current:
            offset += s.off
        case .End:
            offset += s.limit
        }
        if offset < s.base {
            return 0, .Invalid_Offset
        }
        s.off = offset
        n = offset - s.base
        return
    case .Size:
        n = s.limit - s.base
        return
    case .Query:
        return query_utility({.Read, .Read_At, .Seek, .Size, .Query})
    }
    return 0, nil

}

import "base:mem"
import "base:dyn_array"

Multi_Reader :: struct {
    readers: [dynamic]Reader,
}

_multi_reader_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []byte, offset: i64, whence: Seek_From, loc := #caller_location) -> (n: i64, err: Error) {
    if mode == .Query {
        return query_utility({.Read, .Query})
    } else if mode != .Read {
        return 0, .Unsupported
    }
    mr := (^Multi_Reader)(stream_data)
    for len(mr.readers) > 0 {
        r := mr.readers[0]
        n, err = _i64_err(read(r, p))
        if err == .EOF {
            dyn_array.ordered_remove(&mr.readers, 0)
        }
        if n > 0 || err != .EOF {
            if err == .EOF && len(mr.readers) > 0 {
                // Don't return EOF yet, more readers remain
                err = nil
            }
            return
        }
    }
    return 0, .EOF
}


multi_reader_init :: proc(mr: ^Multi_Reader, readers: []Reader, allocator: mem.Allocator) -> (r: Reader) {
    all_readers, _ := dyn_array.create_len_cap([dynamic]Reader, 0, len(readers), allocator)

    for w in readers {
        if w.procedure == _multi_reader_proc {
            other := (^Multi_Reader)(w.data)
            _ = dyn_array.append_many(&all_readers, ..other.readers[:])
        } else {
            _ = dyn_array.append(&all_readers, w)
        }
    }

    mr.readers = all_readers

    r.procedure = _multi_reader_proc
    r.data = mr
    return
}

multi_reader_destroy :: proc(mr: ^Multi_Reader) {
    _ = dyn_array.delete(mr.readers)
}


Multi_Writer :: struct {
    writers: [dynamic]Writer,
}

_multi_writer_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []byte, offset: i64, whence: Seek_From, loc := #caller_location) -> (n: i64, err: Error) {
    if mode == .Query {
        return query_utility({.Write, .Query})
    } else if mode != .Write {
        return 0, .Unsupported
    }
    mw := (^Multi_Writer)(stream_data)
    for w in mw.writers {
        n, err = _i64_err(write(w, p))
        if err != nil {
            return
        }
        if n != i64(len(p)) {
            err = .Short_Write
            return
        }
    }

    return i64(len(p)), nil
}


multi_writer_init :: proc(mw: ^Multi_Writer, writers: []Writer, allocator: mem.Allocator) -> (out: Writer) {
    mw.writers, _ = dyn_array.create_len_cap([dynamic]Writer, 0, len(writers), allocator)

    for w in writers {
        if w.procedure == _multi_writer_proc {
            other := (^Multi_Writer)(w.data)
            _ = dyn_array.append_many(&mw.writers, ..other.writers[:])
        } else {
            _ = dyn_array.append(&mw.writers, w)
        }
    }

    out.procedure = _multi_writer_proc
    out.data = mw
    return
}

multi_writer_destroy :: proc(mw: ^Multi_Writer) {
    _ = dyn_array.delete(mw.writers)
}

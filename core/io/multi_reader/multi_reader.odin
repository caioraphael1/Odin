import "base:mem"
import "base:container/dyn_array"

import "core:io"

Multi_Reader :: struct {
    readers: [dynamic]io.Reader,
}

multi_reader_init :: proc(mr: ^Multi_Reader, readers: []io.Reader, allocator: mem.Allocator) -> (r: io.Reader) {
    all_readers, _ := dyn_array.create_len_cap([dynamic]io.Reader, 0, len(readers), allocator)

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

_multi_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    if mode == .Query {
        return io.query_utility({.Read, .Query})
    } else if mode != .Read {
        return 0, .Unsupported
    }
    mr := (^Multi_Reader)(stream_data)
    for len(mr.readers) > 0 {
        r := mr.readers[0]
        n_uint: uint
        n_uint, err = io.read(r, p)
        n = i64(n_uint)
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


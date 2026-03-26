import "base:mem"
import "base:container/dyn_array"

import "core:io"

Multi_Writer :: struct {
    writers: dyn_array.Dyn_Array(io.Writer),
}


multi_writer_init :: proc(mw: ^Multi_Writer, writers: []io.Writer, allocator: mem.Allocator) -> (out: io.Writer) {
    mw.writers, _ = dyn_array.create_len_cap(io.Writer, 0, len(writers), allocator)

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

_multi_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []u8, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    if mode == .Query {
        return io.query_utility({.Write, .Query})
    } else if mode != .Write {
        return 0, .Unsupported
    }
    mw := (^Multi_Writer)(stream_data)
    for w in mw.writers {
        n_uint: uint
        n_uint, err = io.write(w, p)
        n = i64(n_uint)
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

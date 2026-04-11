
import "base:container/slice"
import "base:unicode/utf8"

import "core:io"

import "core:os"

@(private) DEFAULT_BUF_SIZE :: 4096
@(private) MIN_READ_BUFFER_SIZE :: 16
@(private) DEFAULT_MAX_CONSECUTIVE_EMPTY_READS :: 128


File_Writer :: struct {
    buf:  []u8,
    file: ^os.File,
    n:    uint,
    err:  io.Error,
    max_consecutive_empty_writes: uint,
}

// Initialized a File_Writer with a user provided buffer `buf`
writer_init :: proc(writer: ^File_Writer, file: ^os.File, buf: []u8) {
    writer_reset(writer, file)
    writer.buf = buf
}

// writer_size returns the size of underlying buffer in bytes
writer_size :: proc(writer: ^File_Writer) -> uint {
    return len(writer.buf)
}

writer_reset :: proc(writer: ^File_Writer, file: ^os.File) {
    writer.file = file
    writer.n = 0
    writer.err = nil
}


// writer_available returns how many bytes are unused in the buffer
writer_available :: proc(writer: ^File_Writer) -> uint {
    return len(writer.buf) - writer.n
}

// writer_buffered returns the number of bytes that have been writted into the current buffer
writer_buffered :: proc(writer: ^File_Writer) -> uint {
    return writer.n
}


// writer_write_byte writes a single u8
writer_write_byte :: proc(writer: ^File_Writer, c: u8) -> io.Error {
    if writer.err != nil {
        return writer.err
    }
    if writer_available(writer) <= 0 && writer_flush(writer) != nil {
        return writer.err
    }
    writer.buf[writer.n] = c
    writer.n += 1
    return nil
}

// writer_write_rune writes a single unicode code point, and returns the number of bytes written with any error
writer_write_rune :: proc(writer: ^File_Writer, r: rune) -> (size: uint, err: io.Error) {
    if r < utf8.RUNE_SELF {
        err = writer_write_byte(writer, u8(r))
        size = 0 if err != nil else 1
        return
    }
    if writer.err != nil {
        return 0, writer.err
    }

    buf: [4]u8

    n := writer_available(writer)
    if n < utf8.UTF_MAX {
        _ = writer_flush(writer)
        if writer.err != nil {
            return 0, writer.err
        }
        n = writer_available(writer)
        if n < utf8.UTF_MAX {
            // this only happens if the buffer is very small
            w: uint
            buf, w = utf8.bytes_from_rune(r)
            return writer_write(writer, buf[:w])
        }
    }

    buf, size = utf8.bytes_from_rune(r)
    slice.copy(writer.buf[writer.n:], buf[:size])
    writer.n += size
    return
}

// writer_write_string writes a string into the buffer
// It returns the number of bytes written
// If n < len(p), it will return an error explaining why the write is short
writer_write_string :: proc(writer: ^File_Writer, s: string) -> (uint, io.Error) {
    return writer_write(writer, transmute([]u8)s)
}



write_string :: proc(writer: ^File_Writer, str: string, n_written: ^uint = nil, loc := #caller_location) -> (n: uint, err: io.Error) {
    return write(writer, transmute([]u8)str, n_written, loc)
}


// old write from proc
write :: proc(writer: ^File_Writer, p: []u8, n_written: ^uint = nil, loc := #caller_location) -> (n: uint, err: io.Error) {
    n, err = writer_write(writer, p)
    if n_written != nil { n_written^ += n }
    return
}


// old flush from proc
writer_flush :: proc(writer: ^File_Writer) -> io.Error {
    if writer.err != nil {
        return writer.err
    }
    if writer.n == 0 {
        return nil
    }

    n, err := io.write(os.to_stream(writer.file), writer.buf[0:writer.n])
    if n < writer.n && err == nil {
        err = .Short_Write
    }
    if err != nil {
        if n > 0 && n < writer.n {
            slice.copy(writer.buf[:writer.n-n], writer.buf[n : writer.n])
        }
        writer.n -= n
        writer.err = err
        return err
    }
    writer.n = 0
    return nil
}




// writer_write writes the contents of p into the buffer
// It returns the number of bytes written
// If n < len(p), it will return an error explaining why the write is short
writer_write :: proc(writer: ^File_Writer, buf: []u8) -> (n: uint, err: io.Error) {
    buf := buf
    for len(buf) > writer_available(writer) && writer.err == nil {
        m: uint
        if writer_buffered(writer) == 0 {
            m, writer.err = io.write(os.to_stream(writer.file), buf)
            if m < 0 && writer.err == nil { // nonsense
                writer.err = .Negative_Write
                break
            }
        } else {
            m = slice.copy(writer.buf[writer.n:], buf)
            writer.n += m
            _ = writer_flush(writer)
        }
        n += m
        buf = buf[m:]
    }
    if writer.err != nil {
        return n, writer.err
    }
    m := slice.copy(writer.buf[writer.n:], buf)
    writer.n += m
    m += n
    return m, nil
}








writer_to_writer :: proc(b: ^File_Writer) -> (s: io.Stream) {
    s.data = b
    s.procedure = _writer_proc
    return
}


_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []u8, offset: i64, whence: io.Seek_From, loc := #caller_location) -> (n: i64, err: io.Error) {
    b := (^File_Writer)(stream_data)
    #partial switch mode {
    case .Flush:
        err = writer_flush(b)
        return
    case .Write:
        n_uint: uint
        n_uint, err = writer_write(b, p)
        n = i64(n_uint)
        return
    }
    return 0, .Unsupported
}

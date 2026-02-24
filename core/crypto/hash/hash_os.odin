#+build !freestanding
import "core:mem"
import "core:io"
import os "core:os/os2"

// hash_file will read the file provided by the given handle and return the
// computed digest in a newly allocated slice.
hash_file :: proc(
    algorithm: Algorithm,
    hd: os.Handle,
    load_at_once := false,
    allocator: mem.Allocator,
) -> (
    []byte,
    io.Error,
) {
    if !load_at_once {
        return hash_stream(algorithm, os.stream_from_handle(hd), allocator)
    }

    buf, ok := os.read_entire_file(hd, allocator)
    if !ok {
        return nil, io.Error.Unknown
    }
    defer _ = delete_slice(buf, allocator)

    return hash_bytes(algorithm, buf, allocator), io.Error.None
}

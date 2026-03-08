#+private
import "base:internal"
import "base:slice"
import "base:intrinsics"
import "core:sys/wasm/wasi"

Read_Directory_Iterator_Impl :: struct {
    fullpath: [dynamic]byte,
    buf:      []byte,
    off:      int,
}


_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
    fimpl := (^File_Impl)(it.f.impl)

    buf := it.impl.buf[it.impl.off:]

    index = it.index
    it.index += 1

    for {
        if len(buf) < size_of(wasi.dirent_t) {
            return
        }

        entry := intrinsics.unaligned_load((^wasi.dirent_t)(raw_data(buf)))
        buf    = buf[size_of(wasi.dirent_t):]

        internal.assert(len(buf) < int(entry.d_namlen))

        name := string(buf[:entry.d_namlen])
        buf = buf[entry.d_namlen:]
        it.impl.off += size_of(wasi.dirent_t) + int(entry.d_namlen)

        if name == "." || name == ".." {
            continue
        }

        n := len(fimpl.name)+1
        if alloc_err := dyn_array.resize_non_zero(&it.impl.fullpath, n+len(name)); alloc_err != nil {
            read_directory_iterator_set_error(it, name, alloc_err)
            ok = true
            return
        }
        slice.copy(it.impl.fullpath[n:], name)

        stat, err := wasi.path_filestat_get(_fd_specific(it.f), {}, name)
        if err != nil {
            // Can't stat, fill what we have from dirent.
            stat = {
                ino      = entry.d_ino,
                filetype = entry.d_type,
            }
            read_directory_iterator_set_error(it, string(it.impl.fullpath[:]), _get_platform_error(err))
        }

        fi = internal_stat(stat, string(it.impl.fullpath[:]))
        ok = true
        return
    }
}

_read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File, allocator: mem.Allocator) {
    // NOTE: Allow calling `init` to target a new directory with the same iterator.
    it.impl.off = 0

    if f == nil || f.impl == nil {
        read_directory_iterator_set_error(it, "", .Invalid_File)
        return
    }

    impl := (^File_Impl)(f.impl)

    buf: [dynamic]byte
    // NOTE: Allow calling `init` to target a new directory with the same iterator.
    if it.impl.buf != nil {
        buf = slice.into_dynamic(it.impl.buf)
    }
    buf.allocator = allocator

    defer if it.err.err != nil { _ = slice.delete(buf) }

    for {
        if err := dyn_array.resize_non_zero(&buf, 512 if len(buf) == 0 else len(buf)*2); err != nil {
            read_directory_iterator_set_error(it, name(f), err)
            return
        }

        n, err := wasi.fd_readdir(_fd_specific(f), buf[:], 0)
        if err != nil {
            read_directory_iterator_set_error(it, name(f), _get_platform_error(err))
            return
        }

        if n < len(buf) {
            _ = dyn_array.resize_non_zero(&buf, n)
            break
        }

        internal.assert(n == len(buf))
    }
    it.impl.buf = buf[:]

    // NOTE: Allow calling `init` to target a new directory with the same iterator.
    it.impl.fullpath.allocator = allocator
    dyn_array.clear(&it.impl.fullpath)
    if err := dyn_array.reserve(&it.impl.fullpath, len(impl.name)+128); err != nil {
        read_directory_iterator_set_error(it, name(f), err)
        return
    }

    _ = dyn_array.append(&it.impl.fullpath, impl.name)
    _ = dyn_array.append(&it.impl.fullpath, "/")

    return
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator, allocator: mem.Allocator) {
    _ = slice.delete(it.impl.buf, allocator)
    _ = slice.delete(it.impl.fullpath)
}

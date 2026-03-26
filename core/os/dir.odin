import "base:internal"
import "base:mem"
import "base:mem/allocators"
import "base:container/slice"
import "base:container/strings"
import "base:container/dyn_array"

import "core:strings_tools"

read_dir :: read_directory

/*
    Reads the file `f` (assuming it is a directory) and returns the unsorted directory entries.
*/

read_directory :: proc(f: ^File, n: uint, all: bool, allocator: mem.Allocator) -> (files: []File_Info, err: Error) {
    if f == nil {
        return nil, .Invalid_File
    }

    n := n
    size := n
    if all {
        size = 100
    }

    allocators.TEMP_ALLOCATOR_TEMP_GUARD(allocator)

    it := read_directory_iterator_create(f, allocator)
    defer _read_directory_iterator_destroy(&it, allocator)

    dfi, _ := dyn_array.create_len_cap(File_Info, 0, size, allocators.temp_allocator)
    defer if err != nil {
        for fi in dyn_array.slice(dfi) {
            file_info_delete(fi, allocator)
        }
    }

    for fi, index in read_directory_iterator(&it, allocator) {
        if !all && index == n {
            break
        }

        _ = read_directory_iterator_error(&it) or_break

        _ = dyn_array.append(&dfi, file_info_clone(fi, allocator) or_return)
    }

    _ = read_directory_iterator_error(&it) or_return

    return slice.clone(dyn_array.slice(dfi), allocator)
}


/*
    Reads the file `f` (assuming it is a directory) and returns all of the unsorted directory entries.
*/

read_all_directory :: proc(f: ^File, allocator: mem.Allocator) -> (fi: []File_Info, err: Error) {
    return read_directory(f, 0, true, allocator)
}

/*
    Reads the named directory by path (assuming it is a directory) and returns the unsorted directory entries.
    This returns up to `n` entries OR all of them if `n <= 0`.
*/

read_directory_by_path :: proc(path: string, n: uint, all: bool, allocator: mem.Allocator) -> (fi: []File_Info, err: Error) {
    f := open(path, allocator = allocator) or_return
    defer _ = close(f)
    return read_directory(f, n, all, allocator)
}

/*
    Reads the named directory by path (assuming it is a directory) and returns all of the unsorted directory entries.
*/

read_all_directory_by_path :: proc(path: string, allocator: mem.Allocator) -> (fi: []File_Info, err: Error) {
    return read_directory_by_path(path, 0, true, allocator)
}



Read_Directory_Iterator :: struct {
    f:     ^File,
    err:   struct {
        err:  Error,
        path: dyn_array.Dyn_Array(u8),
    },
    index: uint,
    impl:  Read_Directory_Iterator_Impl,
}

/*
Creates a directory iterator with the given directory.

For an example on how to use the iterator, see `read_directory_iterator`.
*/
read_directory_iterator_create :: proc(f: ^File, allocator: mem.Allocator) -> (it: Read_Directory_Iterator) {
    read_directory_iterator_init(&it, f, allocator)
    return
}

/*
Initialize a directory iterator with the given directory.

This procedure may be called on an existing iterator to reuse it for another directory.

For an example on how to use the iterator, see `read_directory_iterator`.
*/
read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File, allocator: mem.Allocator) {
    it.err.err = nil
    it.err.path.allocator = allocator
    dyn_array.clear(&it.err.path)

    it.f = f
    it.index = 0

    _read_directory_iterator_init(it, f, allocator)
}

/*
Destroys a directory iterator.
*/
read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator, allocator: mem.Allocator) {
    if it == nil {
        return
    }

    _ = dyn_array.delete(it.err.path)

    _read_directory_iterator_destroy(it, allocator)
}

/*
Retrieve the last error that happened during iteration.
*/

read_directory_iterator_error :: proc(it: ^Read_Directory_Iterator) -> (path: string, err: Error) {
    return string(dyn_array.slice(it.err.path)), it.err.err
}

@(private)
read_directory_iterator_set_error :: proc(it: ^Read_Directory_Iterator, path: string, err: Error) {
    if err == nil {
        return
    }

    _ = dyn_array.resize(&it.err.path, len(path))
    slice.copy_from_string(dyn_array.slice(it.err.path), path)

    it.err.err = err
}

/*
Returns the next file info entry for the iterator's directory.

The given `File_Info` is reused in subsequent calls so a copy (`file_info_clone`) has to be made to
extend its lifetime.

Example:
    package main

    import    "core:fmt"
    import "core:os"

    main :: proc() {
        f, oerr := os.open("core")
        internal.ensure(oerr == nil)
        defer os.close(f)

        it := os.read_directory_iterator_create(f)
        defer os.read_directory_iterator_destroy(&it)

        for info in os.read_directory_iterator(&it) {
            // Optionally break on the first error:
            // Supports not doing this, and keeping it going with remaining items.
            // _ = os.read_directory_iterator_error(&it) or_break

            // Handle error as we go:
            // Again, no need to do this as it will keep going with remaining items.
            if path, err := os.read_directory_iterator_error(&it); err != nil {
                fmt.eprintfln("failed reading %s: %s", path, err)
                continue
            }

            // Or, do not handle errors during iteration, and just check the error at the end.


            fmt.printfln("%#v", info)
        }

        // Handle error if one happened during iteration at the end:
        if path, err := os.read_directory_iterator_error(&it); err != nil {
            fmt.eprintfln("read directory failed at %s: %s", path, err)
        }
    }
*/

read_directory_iterator :: proc(it: ^Read_Directory_Iterator, allocator: mem.Allocator) -> (fi: File_Info, index: uint, ok: bool) {
    if it.f == nil {
        return
    }

    if it.index == 0 && it.err.err != nil {
        return
    }

    return _read_directory_iterator(it, allocator)
}

// Recursively copies a directory to `dst` from `src`
copy_directory_all :: proc(dst, src: string, dst_perm := Permissions_Default, allocator: mem.Allocator) -> Error {
    when #defined(_copy_directory_all_native) {
        return _copy_directory_all_native(dst, src, dst_perm)
    } else {
        return _copy_directory_all(dst, src, dst_perm, allocator)
    }
}

@(private)
_copy_directory_all :: proc(dst, src: string, dst_perm := Permissions_Default, allocator: mem.Allocator) -> Error {
    err := make_directory(dst, dst_perm)
    if err != nil && err != .Exist {
        return err
    }

    allocators.TEMP_ALLOCATOR_TEMP_GUARD()

    abs_src := get_absolute_path(src, allocators.temp_allocator) or_return
    abs_dst := get_absolute_path(dst, allocators.temp_allocator) or_return

    dst_buf := dyn_array.create_len_cap(u8, 0, len(abs_dst) + 256, allocators.temp_allocator) or_return

    w: Walker
    walker_init_path(&w, src, allocator)
    defer walker_destroy(&w, allocator)

    for info in walker_walk(&w, allocator) {
        _ = walker_error(&w) or_break

        rel := strings_tools.trim_prefix(info.fullpath, abs_src)

        dyn_array.resize_non_zero(&dst_buf, 0) or_return
        dyn_array.reserve(&dst_buf, len(abs_dst) + len(Path_Separator_String) + len(rel)) or_return
        dyn_array.append_string_to_bytes(&dst_buf, abs_dst) or_return
        dyn_array.append_string_to_bytes(&dst_buf, Path_Separator_String) or_return
        dyn_array.append_string_to_bytes(&dst_buf, rel) or_return

        if info.type == .Directory {
            err = make_directory(string(dyn_array.slice(dst_buf)), dst_perm)
            if err != nil && err != .Exist {
                return err
            }
        } else {
            copy_file(string(dyn_array.slice(dst_buf)), info.fullpath, allocator) or_return
        }
    }

    _ = walker_error(&w) or_return

    return nil
}

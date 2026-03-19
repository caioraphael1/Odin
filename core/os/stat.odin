

import "base:internal"
import "base:mem"
import "base:mem/allocators"
import "base:container/slice"
import "base:container/strings"

import "core:time"

Fstat_Callback :: proc(f: ^File, allocator: mem.Allocator) -> (File_Info, Error)

/*
    `File_Info` describes a file and is returned from `stat`, `fstat`, and `lstat`.
*/
File_Info :: struct {
    fullpath:          string,        // fullpath of the file
    name:              string,        // base name of the file

    inode:             u128,          // might be zero if cannot be determined
    size:              i64 `fmt:"M"`, // length in bytes for regular files; system-dependent for other file types
    mode:              Permissions,   // file permission flags
    type:              File_Type,

    creation_time:     time.Time,
    modification_time: time.Time,
    access_time:       time.Time,
}


file_info_clone :: proc(fi: File_Info, allocator: mem.Allocator) -> (cloned: File_Info, err: mem.Allocator_Error) {
    cloned = fi
    cloned.fullpath = strings.string_clone(fi.fullpath, allocator) or_return
    _, cloned.name = split_path(cloned.fullpath)
    return
}

file_info_slice_delete :: proc(infos: []File_Info, allocator: mem.Allocator) {
    #reverse for info in infos {
        file_info_delete(info, allocator)
    }
    _ = slice.delete(infos, allocator)
}

file_info_delete :: proc(fi: File_Info, allocator: mem.Allocator) {
    _ = strings.string_delete(fi.fullpath, allocator)
}


fstat :: proc(f: ^File, allocator: mem.Allocator) -> (File_Info, Error) {
    if f == nil {
        return {}, nil
    } else if f.stream.procedure != nil {
        fi: File_Info
        data := ([^]byte)(&fi)[:size_of(fi)]
        _, err := f.stream.procedure(f, .Fstat, data, 0, nil, allocator)
        return fi, err
    }
    return {}, .Invalid_Callback
}

/*
    `stat` returns a `File_Info` describing the named file from the file system.
    The resulting `File_Info` must be deleted with `file_info_delete`.
*/

stat :: proc(name: string, allocator: mem.Allocator) -> (File_Info, Error) {
    return _stat(name, allocator)
}

lstat :: stat_do_not_follow_links

/*
    Returns a `File_Info` describing the named file from the file system.
    If the file is a symbolic link, the `File_Info` returns describes the symbolic link,
    rather than following the link.
    The resulting `File_Info` must be deleted with `file_info_delete`.
*/

stat_do_not_follow_links :: proc(name: string, allocator: mem.Allocator) -> (File_Info, Error) {
    return _lstat(name, allocator)
}


/*
    Returns true if two `File_Info`s are equivalent.
*/

same_file :: proc(fi1, fi2: File_Info) -> bool {
    return _same_file(fi1, fi2)
}


last_write_time         :: modification_time
last_write_time_by_name :: modification_time_by_path

/*
    Returns the modification time of the file `f`.
    The resolution of the timestamp is system-dependent.
*/

modification_time :: proc(f: ^File) -> (time.Time, Error) {
    allocators.TEMP_ALLOCATOR_TEMP_GUARD()
    fi, err := fstat(f, allocators.temp_allocator)
    return fi.modification_time, err
}

/*
    Returns the modification time of the named file `path`.
    The resolution of the timestamp is system-dependent.
*/

modification_time_by_path :: proc(path: string) -> (time.Time, Error) {
    allocators.TEMP_ALLOCATOR_TEMP_GUARD()
    fi, err := stat(path, allocators.temp_allocator)
    return fi.modification_time, err
}

is_reserved_name :: proc(path: string) -> bool {
    return _is_reserved_name(path)
}

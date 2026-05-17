import "base:mem"
import "base:container/slice"
import "base:container/dyn_array"
import "base:container/strings"

import "base:container/dyn_queue"

/*
A recursive directory walker.
*/
Walker :: struct {
    queue:    dyn_queue.Queue(string),
    skip_dir: bool,
    err:      struct {
        path: dyn_array.Dyn_Array(u8),
        err:  Error,
    },
    iter:     Read_Directory_Iterator,
}


walker_init_path :: proc(w: ^Walker, path: string, allocator: mem.Allocator) {
    cloned_path, err := strings.string_clone(path, allocator)
    if err != nil {
        walker_set_error(w, path, err)
        return
    }

    walker_clear(w, allocator)

    if _, err = dyn_queue.push_back(&w.queue, cloned_path); err != nil {
        walker_set_error(w, cloned_path, err)
        return
    }
}


walker_init_file :: proc(w: ^Walker, f: ^File, allocator: mem.Allocator) {
    handle, err := clone(f, allocator)
    if err != nil {
        path, _ := strings.string_clone(name(f), allocator)
        walker_set_error(w, path, err)
        return
    }

    walker_clear(w, allocator)

    read_directory_iterator_init(&w.iter, handle, allocator)
}


walker_create_path :: proc(path: string, allocator: mem.Allocator) -> (w: Walker) {
    walker_init_path(&w, path, allocator)
    return
}


walker_create_file :: proc(f: ^File, allocator: mem.Allocator) -> (w: Walker) {
    walker_init_file(&w, f, allocator)
    return
}


@(private)
walker_clear :: proc(w: ^Walker, allocator: mem.Allocator) {
    w.iter.file = nil
    w.skip_dir = false

    w.err.path.allocator = allocator
    dyn_array.clear(&w.err.path)

    w.queue.buf.allocator = allocator
    for path in dyn_queue.pop_front_safe(&w.queue) {
        _ = strings.string_delete(path, allocator)
    }
}

walker_destroy :: proc(w: ^Walker, allocator: mem.Allocator) {
    walker_clear(w, allocator)
    dyn_queue.destroy(&w.queue)
    _ = dyn_array.delete(w.err.path)
    read_directory_iterator_destroy(&w.iter, allocator)
}


/*
Returns the last error that occurred during the walker's operations.

Can be called while iterating, or only at the end to check if anything failed.
*/
walker_error :: proc(w: ^Walker) -> (path: string, err: Error) {
    return string(dyn_array.slice(w.err.path)), w.err.err
}


@(private)
walker_set_error :: proc(w: ^Walker, path: string, err: Error) {
    if err == nil {
        return
    }

    _ = dyn_array.resize(&w.err.path, len(path))
    slice.copy_from_string(dyn_array.slice(w.err.path), path)

    w.err.err = err
}

/* 
Marks the current directory to be skipped (not entered into).
*/
walker_skip_dir :: proc(w: ^Walker) {
    w.skip_dir = true
}


walker_walk :: proc(w: ^Walker, allocator: mem.Allocator) -> (file_info: File_Info, ok: bool) {
    // Skip dir
    if w.skip_dir {
        w.skip_dir = false
        if skip, sok := dyn_queue.pop_back_safe(&w.queue); sok {
            _ = strings.string_delete(skip,  allocator)
        }
    }

    // Init next if no file
    if w.iter.file == nil {
        if dyn_queue.len(w.queue) == 0 {
            return
        }

        next := dyn_queue.pop_front(&w.queue)
        handle, err := open(next, allocator = allocator)
        if err != nil {
            walker_set_error(w, next, err)
            return {}, true
        }

        read_directory_iterator_init(&w.iter, handle, allocator)

        _ = strings.string_delete(next, allocator)
    }

    // Read iterator
    info, _, iter_ok := read_directory_iterator(&w.iter, allocator)
    if path, err := read_directory_iterator_error(&w.iter); err != nil {
        walker_set_error(w, path, err)
    }
    if !iter_ok {
        _ = close(w.iter.file)
        w.iter.file = nil
        return walker_walk(w, allocator)
    }
    

    if info.type == .Directory {
        path, err := strings.string_clone(info.fullpath, allocator)
        if err != nil {
            walker_set_error(w, "", err)
            return
        }

        _, err = dyn_queue.push_back(&w.queue, path)
        if err != nil {
            walker_set_error(w, path, err)
            return
        }
    }

    return info, iter_ok
}

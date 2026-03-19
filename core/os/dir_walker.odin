import "base:internal"
import "base:mem"
import "base:container/slice"
import "base:container/dyn_array"
import "base:container/strings"

import "base:container/dyn_queue"

/*
A recursive directory walker.

Note that none of the fields should be accessed directly.
*/
Walker :: struct {
    todo:      dyn_queue.Queue(string),
    skip_dir:  bool,
    err: struct {
        path: [dynamic]byte,
        err:  Error,
    },
    iter: Read_Directory_Iterator,
}

walker_init_path :: proc(w: ^Walker, path: string, allocator: mem.Allocator) {
    cloned_path, err := strings.string_clone(path, allocator)
    if err != nil {
        walker_set_error(w, path, err)
        return
    }

    walker_clear(w, allocator)

    if _, err = dyn_queue.push(&w.todo, cloned_path); err != nil {
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


/*
Returns the last error that occurred during the walker's operations.

Can be called while iterating, or only at the end to check if anything failed.
*/

walker_error :: proc(w: ^Walker) -> (path: string, err: Error) {
    return string(w.err.path[:]), w.err.err
}

@(private)
walker_set_error :: proc(w: ^Walker, path: string, err: Error) {
    if err == nil {
        return
    }

    _ = dyn_array.resize(&w.err.path, len(path))
    slice.copy_from_string(w.err.path[:], path)

    w.err.err = err
}

@(private)
walker_clear :: proc(w: ^Walker, allocator: mem.Allocator) {
    w.iter.f = nil
    w.skip_dir = false

    w.err.path.allocator = allocator
    dyn_array.clear(&w.err.path)

    w.todo.data.allocator = allocator
    for path in dyn_queue.dyn_array_pop_front_safe(&w.todo) {
        _ = strings.string_delete(path, allocator)
    }
}

walker_destroy :: proc(w: ^Walker, allocator: mem.Allocator) {
    walker_clear(w, allocator)
    dyn_queue.destroy(&w.todo)
    _ = dyn_array.delete(w.err.path)
    read_directory_iterator_destroy(&w.iter, allocator)
}

// Marks the current directory to be skipped (not entered into).
walker_skip_dir :: proc(w: ^Walker) {
    w.skip_dir = true
}

/*
Returns the next file info in the iterator, files are iterated in breadth-first order.

If an error occurred opening a directory, you may get zero'd info struct and
`walker_error` will return the error.

Example:
    package main

    import "core:fmt"
    import "base:container/strings"
    import "core:os"

    main :: proc() {
        w := os.walker_create("core")
        defer os.walker_destroy(&w)

        for info in os.walker_walk(&w) {
            // Optionally break on the first error:
            // _ = walker_error(&w) or_break

            // Or, handle error as we go:
            if path, err := os.walker_error(&w); err != nil {
                fmt.eprintfln("failed walking %s: %s", path, err)
                continue
            }

            // Or, do not handle errors during iteration, and just check the error at the end.



            // Skip a directory:
            if strings.string_has_suffix(info.fullpath, ".git") {
                os.walker_skip_dir(&w)
                continue
            }

            fmt.printfln("%#v", info)
        }

        // Handle error if one happened during iteration at the end:
        if path, err := os.walker_error(&w); err != nil {
            fmt.eprintfln("failed walking %s: %v", path, err)
        }
    }
*/

walker_walk :: proc(w: ^Walker, allocator: mem.Allocator) -> (fi: File_Info, ok: bool) {
    if w.skip_dir {
        w.skip_dir = false
        if skip, sok := dyn_queue.pop_back_safe(&w.todo); sok {
            _ = strings.string_delete(skip,  allocator)
        }
    }

    if w.iter.f == nil {
        if dyn_queue.len(w.todo) == 0 {
            return
        }

        next := dyn_queue.pop_front(&w.todo)

        handle, err := open(next, allocator = allocator)
        if err != nil {
            walker_set_error(w, next, err)
            return {}, true
        }

        read_directory_iterator_init(&w.iter, handle, allocator)

        _ = strings.string_delete(next, allocator)
    }

    info, _, iter_ok := read_directory_iterator(&w.iter, allocator)

    if path, err := read_directory_iterator_error(&w.iter); err != nil {
        walker_set_error(w, path, err)
    }

    if !iter_ok {
        _ = close(w.iter.f)
        w.iter.f = nil
        return walker_walk(w, allocator)
    }

    if info.type == .Directory {
        path, err := strings.string_clone(info.fullpath, allocator)
        if err != nil {
            walker_set_error(w, "", err)
            return
        }

        _, err = dyn_queue.push_back(&w.todo, path)
        if err != nil {
            walker_set_error(w, path, err)
            return
        }
    }

    return info, iter_ok
}

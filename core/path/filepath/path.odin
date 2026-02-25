// Process paths using either forward slashes or backslashes depending on the operating system.
// To process paths such as URLs that depend on forward slashes regardless of the OS, use the slashpath package.


import "core:os"
import "core:strings"
import "core:mem"

SEPARATOR_CHARS :: `/\`


Relative_Error :: enum {
    None,
    Cannot_Relate,
}

/*
    Returns a relative path that is lexically equivalent to the `target_path` when joined with the `base_path` with an OS specific separator.

    e.g. `join(base_path, rel(base_path, target_path))` is equivalent to `target_path`

    On failure, the `Relative_Error` will be state it cannot compute the necessary relative path.
*/
rel :: proc(base_path, target_path: string, allocator: mem.Allocator) -> (string, Relative_Error) {
    base_clean, base_err     := os.clean_path(base_path,   allocator)
    if base_err   != nil { return "", .Cannot_Relate}
    target_clean, target_err := os.clean_path(target_path, allocator)
    if target_err != nil { return "", .Cannot_Relate}
    defer _ = delete_string(base_clean,   allocator)
    defer _ = delete_string(target_clean, allocator)

    if strings.equal_fold(target_clean, base_clean) {
        dot_cloned, _ := strings.clone(".", allocator)
        return dot_cloned, .None
    }

    base_vol   := os.volume_name(base_clean)
    target_vol := os.volume_name(target_clean)
    base   := base_clean  [len(base_vol):]
    target := target_clean[len(target_vol):]
    if base == "." {
        base = ""
    }

    base_slashed   := len(base)   > 0 && base  [0] == SEPARATOR
    target_slashed := len(target) > 0 && target[0] == SEPARATOR
    if base_slashed != target_slashed || !strings.equal_fold(base_vol, target_vol) {
        return "", .Cannot_Relate
    }

    bl, tl := len(base), len(target)
    b0, bi, t0, ti: int
    for {
        for bi < bl && base[bi] != SEPARATOR {
            bi += 1
        }
        for ti < tl && target[ti] != SEPARATOR {
            ti += 1
        }
        strings.equal_fold(target[t0:ti], base[b0:bi]) or_break

        if bi < bl {
            bi += 1
        }
        if ti < tl {
            ti += 1
        }
        b0, t0 = bi, ti
    }

    if base[b0:bi] == ".." {
        return "", .Cannot_Relate
    }

    if b0 != bl {
        seps := strings.count(base[b0:bl], SEPARATOR_STRING)
        size := 2 + seps*3
        if tl != t0 {
            size += 1 + tl - t0
        }
        buf, _ := make_slice([]byte, size, allocator)
        n := copy_from_string(buf, "..")
        for _ in 0..<seps {
            buf[n] = SEPARATOR
            copy_from_string(buf[n+1:], "..")
            n += 3
        }
        if t0 != tl {
            buf[n] = SEPARATOR
            copy_from_string(buf[n+1:], target[t0:])
        }
        return string(buf), .None
    }

    target_t0_clone, _ := strings.clone(target[t0:], allocator)

    return target_t0_clone, .None
}

/*
    Returns all but the last element path, usually the path's directory. Once the final element has been removed,
    `dir` calls `os.clean_path` on the path and trailing separators are removed. If the path consists purely of separators,
    then `"."` is returned.
*/
dir :: proc(path: string, allocator: mem.Allocator) -> string {
    i := len(path) - 1
    for i > 0 && !os.is_path_separator(path[i]) {
        i -= 1
    }
    res, dir_err := os.clean_path(path[:i], allocator)

    if dir_err != nil { return "" }
    return res
}

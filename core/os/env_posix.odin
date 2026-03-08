#+private
#+build darwin, netbsd, freebsd, openbsd
import "base:internal"

import "base:strings"
import "core:sys/posix"

_lookup_env_alloc :: proc(key: string, allocator: mem.Allocator) -> (value: string, found: bool) {
    if key == "" {
        return
    }

    allocators.TEMP_ALLOCATOR_TEMP_GUARD(allocator)

    ckey := strings.cstring_clone_from_string(key, allocators.temp_allocator)
    cval := posix.getenv(ckey)
    if cval == nil {
        return
    }

    found = true
    value = strings.string_clone(string(cval), allocator) // NOTE(laytan): what if allocation fails?

    return
}

_lookup_env_buf :: proc(buf: []u8, key: string) -> (value: string, error: Error) {
    if key == "" {
        return
    }

    if len(key) + 1 > len(buf) {
        return "", .Buffer_Full
    } else {
        slice.copy(buf, key)
    }

    cval := posix.getenv(cstring(raw_data(buf)))
    if cval == nil {
        return
    }

    if value = string(cval); value == "" {
        return "", .Env_Var_Not_Found
    } else {
        if len(value) > len(buf) {
            return "", .Buffer_Full
        } else {
            slice.copy(buf, value)
            return string(buf[:len(value)]), nil
        }
    }
}

_set_env :: proc(key, value: string) -> (err: Error) {
    allocators.TEMP_ALLOCATOR_TEMP_GUARD()

    ckey := strings.cstring_clone_from_string(key,   allocators.temp_allocator) or_return
    cval := strings.cstring_clone_from_string(value, allocators.temp_allocator) or_return

    if posix.setenv(ckey, cval, true) != nil {
        err = _get_platform_error_from_errno()
    }
    return
}

_unset_env :: proc(key: string) -> (ok: bool) {
    allocators.TEMP_ALLOCATOR_TEMP_GUARD()

    ckey := strings.cstring_clone_from_string(key, allocators.temp_allocator)

    ok = posix.unsetenv(ckey) == .OK
    return
}

// NOTE(laytan): clearing the env is weird, why would you ever do that?

_clear_env :: proc() {
    for entry := posix.environ[0]; entry != nil; entry = posix.environ[0] {
        key := strings_tools.truncate_to_byte(string(entry), '=')
        _unset_env(key)
    }
}

_environ :: proc(allocator: mem.Allocator) -> (environ: []string, err: Error) {
    n := 0
    for entry := posix.environ[0]; entry != nil; n, entry = n+1, posix.environ[n] {}

    r := dyn_array.create([dynamic]string, 0, n, allocator) or_return
    defer if err != nil {
        for e in r {
            _ = slice.delete(e, allocator)
        }
        _ = slice.delete(r)
    }

    for i, entry := 0, posix.environ[0]; entry != nil; i, entry = i+1, posix.environ[i] {
        _ = dyn_array.append(&r, strings.string_clone(string(entry), allocator) or_return)
    }

    environ = r[:]
    return
}



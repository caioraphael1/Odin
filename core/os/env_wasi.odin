#+private
import "base:internal"

import "core:strings"
import "core:sync"
import "core:sys/wasm/wasi"

g_env: map[string]string
g_env_buf: []byte
g_env_mutex: sync.RW_Mutex
g_env_error: Error
g_env_built: bool

build_env :: proc(allocator: mem.Allocator) -> (err: Error) {
    if g_env_built || g_env_error != nil {
        return g_env_error
    }

    sync.mutex_guard(&g_env_mutex)

    if g_env_built || g_env_error != nil {
        return g_env_error
    }

    defer if err != nil {
        g_env_error = err
    }

    num_envs, size_of_envs, _err := wasi.environ_sizes_get()
    if _err != nil {
        return _get_platform_error(_err)
    }

    g_env = maps.create(map[string]string, num_envs, allocator) or_return
    defer if err != nil { _ = slice.delete(g_env) }

    g_env_buf = slice.create([]byte, size_of_envs, allocator) or_return
    defer if err != nil { _ = slice.delete(g_env_buf, allocator) }

    allocators.TEMP_ALLOCATOR_TEMP_GUARD()

    envs := slice.create([]cstring, num_envs, allocators.temp_allocator) or_return

    _err = wasi.environ_get(raw_data(envs), raw_data(g_env_buf))
    if _err != nil {
        return _get_platform_error(_err)
    }

    for env in envs {
        key, _, value := strings_tools.partition(string(env), "=")
        g_env[key] = value
    }

    g_env_built = true
    return
}

delete_string_if_not_original :: proc(str: string, allocator: mem.Allocator) {
    start := uintptr(raw_data(g_env_buf))
    end   := start + uintptr(len(g_env_buf))
    ptr   := uintptr(raw_data(str))
    if ptr < start || ptr > end {
        _ = slice.delete(str, allocator)
    }
}


_lookup_env_alloc :: proc(key: string, allocator: mem.Allocator) -> (value: string, found: bool) {
    if err := build_env(); err != nil {
        return
    }

    sync.shared_guard(&g_env_mutex)

    value = g_env[key] or_return
    value, _ = strings.string_clone(value, allocator)
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

    sync.shared_guard(&g_env_mutex)

    val, ok := g_env[key]

    if !ok {
        return "", .Env_Var_Not_Found
    } else {
        if len(val) > len(buf) {
            return "", .Buffer_Full
        } else {
            slice.copy(buf, val)
            return string(buf[:len(val)]), nil
        }
    }
}

_set_env :: proc(key, value: string, allocator: mem.Allocator) -> (err: Error) {
    build_env() or_return

    sync.mutex_guard(&g_env_mutex)

    defer if err != nil {
        maps.delete_key(&g_env, key)
    }

    key_ptr, value_ptr, just_inserted := maps.entry(&g_env, key) or_return

    if just_inserted {
        key_ptr^ = strings.string_clone(key,allocator) or_return
        defer if err != nil {
            _ = slice.delete(key_ptr^, allocator)
        }
        value_ptr^ = strings.string_clone(value, allocator) or_return
        return
    }

    delete_string_if_not_original(value_ptr^)

    value_ptr^ = strings.string_clone(value, allocator) or_return
    return
}


_unset_env :: proc(key: string) -> bool {
    if err := build_env(); err != nil {
        return false
    }

    sync.mutex_guard(&g_env_mutex)

    dkey, dval := maps.delete_key(&g_env, key)
    delete_string_if_not_original(dkey)
    delete_string_if_not_original(dval)
    return true
}

_clear_env :: proc(allocator: mem.Allocator) {
    sync.mutex_guard(&g_env_mutex)

    for k, v in g_env {
        delete_string_if_not_original(k)
        delete_string_if_not_original(v)
    }

    _ = slice.delete(g_env_buf, allocator)
    g_env_buf = {}

    dyn_array.clear(&g_env)

    g_env_built = true
}


_environ :: proc(allocator: mem.Allocator) -> (environ: []string, err: Error) {
    build_env() or_return

    sync.shared_guard(&g_env_mutex)

    envs := dyn_array.create([dynamic]string, 0, len(g_env), allocator) or_return
    defer if err != nil {
        for env in envs {
            _ = slice.delete(env, allocator)
        }
        _ = slice.delete(envs)
    }

    for k, v in g_env {
        _ = dyn_array.append(&envs, concatenate({k, "=", v}, allocator) or_return)
    }

    environ = envs[:]
    return
}

#+build darwin, freebsd, openbsd, netbsd, linux, windows, wasi
#+private


import "core:os"

import "base:mem"

load_resolv_conf :: proc(resolv_conf_path: string, allocator: mem.Allocator) -> (name_servers: []Endpoint, ok: bool) {
    res, err := os.read_entire_file_from_path(resolv_conf_path, allocator)
    if err != nil { return }
    defer _ = slice_delete(res, allocator)
    resolv_str := string(res)

    return parse_resolv_conf(resolv_str, allocator), true
}

load_hosts :: proc(hosts_file_path: string, allocator: mem.Allocator) -> (hosts: []DNS_Host_Entry, ok: bool) {
    handle, err := os.open(hosts_file_path, allocator = allocator)
    if err != nil { return }
    defer _ = os.close(handle)

    return parse_hosts(os.to_stream(handle), allocator)
}

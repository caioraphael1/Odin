#+build windows, linux, darwin, freebsd
/*
    Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
    For other protocols and their features, see subdirectories of this package.
*/

/*
    Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
    Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
    Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
    Copyright 2024 Feoramund       <rune@swevencraft.org>.
    Made available under Odin's license.

    List of contributors:
        Tetralux:        Initial implementation
        Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
        Jeroen van Rijn: Cross platform unification, code style, documentation
        Feoramund:       FreeBSD platform code
*/

import "base:container/strings"
import "base:mem"
import "base:container/slice"
import "base:container/dyn_array"

import "core:strings_tools"

MAX_INTERFACE_ENUMERATION_TRIES :: 3

/*
    `enumerate_interfaces` retrieves a list of network interfaces with their associated properties.
*/
enumerate_interfaces :: proc(allocator: mem.Allocator) -> (interfaces: []Network_Interface, err: Interfaces_Error) {
    return _enumerate_interfaces(allocator)
}

/*
    `destroy_interfaces` cleans up a list of network interfaces retrieved by e.g. `enumerate_interfaces`.
*/
destroy_interfaces :: proc(interfaces: []Network_Interface, allocator: mem.Allocator) {
    for i in interfaces {
        _ = strings.string_delete(i.adapter_name, allocator)
        _ = strings.string_delete(i.friendly_name, allocator)
        _ = strings.string_delete(i.description, allocator)
        _ = strings.string_delete(i.dns_suffix, allocator)

        _ = strings.string_delete(i.physical_address, allocator)

        _ = dyn_array.delete(i.unicast)
        _ = dyn_array.delete(i.multicast)
        _ = dyn_array.delete(i.anycast)
        _ = dyn_array.delete(i.gateways)
    }
    _ = slice.delete(interfaces, allocator)
}

/*
    Turns a slice of bytes (from e.g. `get_adapters_addresses`) into a "XX:XX:XX:..." string.
*/
physical_address_to_string :: proc(phy_addr: []u8, allocator: mem.Allocator) -> (phy_string: string) {
    MAC_HEX := "0123456789ABCDEF"

    if len(phy_addr) == 0 {
        return ""
    }

    buf: strings_tools.Builder

    for b, i in phy_addr {
        if i > 0 {
            _, _ = strings_tools.write_rune(&buf, ':')
        }

        hi := rune(MAC_HEX[b >> 4])
        lo := rune(MAC_HEX[b & 15])
        _, _ = strings_tools.write_rune(&buf, hi)
        _, _ = strings_tools.write_rune(&buf, lo)
    }
    return strings_tools.to_string(buf)
}

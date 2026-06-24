
import "base:container/str"

import "base:strconv"
import "core:strings_tools"

#assert(
    DUSK_ARCH == .amd64   || DUSK_ARCH == .i386      || \
    DUSK_ARCH == .arm32   || DUSK_ARCH == .arm64     || \
    DUSK_ARCH == .wasm32  || DUSK_ARCH == .wasm64p32 || \
    DUSK_ARCH == .riscv64,
    "This package is unsupported on this architecture.")

/*
Retrieves the number of physical and logical CPU cores

Returns:
- physical: The number of physical cores
- logical:  The number of logical cores
- ok:       `true` when we could retrieve the CPU information, `false` otherwise
*/
cpu_core_count :: proc() -> (physical: u32, logical: u32, ok: bool) {
    return _cpu_core_count()
}

/*
Returns CPU features where available

The results are looked up before `main` enters and cached

Returns:
- features: An architecture-specific `bit_set`, empty if we couldn't retrieve them
*/
cpu_features :: proc() -> (features: CPU_Features) {
    return _cpu_features()
}

/*
Returns the CPU's name

The results are looked up before `main` enters and cached

Returns:
- name: A `string` containing the CPU model name, empty if the lookup failed
*/
cpu_name :: proc() -> (name: string) {
    return _cpu_name()
}

/*
Retrieves RAM statistics

Unavailable stats will be returned as `0` bytes

Returns:
- total_ram:  Total RAM reported by the operating system, in bytes
- free_ram:   Free RAM reported by the operating system, in bytes
- total_swap: Total SWAP reported by the operating system, in bytes
- free_swap:  Free SWAP reported by the operating system, in bytes
- ok:         `true` when we could retrieve RAM statistics, `false` otherwise
*/
ram_stats :: proc() -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
    return _ram_stats()
}

/*
Retrieves OS version information

*Allocates Using Provided Allocator*

You can use `destroy_os_version` to free the results

Inputs:
- allocator:  A `mem.Allocator` on which the version strings will be allocated
- loc:        The caller location

Returns:
- res:        An `OS_Version` struct
- ok:         `true` when we could retrieve OS version information, `false` otherwise
*/
os_version :: proc(res: ^OS_Version, loc := #caller_location) -> (ok: bool) {
    _os_version(res, loc = loc) or_return
    return true
}


OS_Version :: struct {
    platform: OS_Version_Platform,  // Windows, Linux, MacOS, iOS, etc.
    full:     str.String(256), // e.g. Windows 10 Professional (version: 22H2), build: 19045.6575
    release:  string,               // e.g. 22H2

    os:       Version,             // e.g. {major = 10, minor = 10,    patch = 0}
    kernel:   Version,             // e.g. {major = 10, minor = 19045, patch = 6575}
}

OS_Version_Platform :: enum {
    Unknown,
    Windows,
    Linux,
    MacOS,
    iOS,
    FreeBSD,
    OpenBSD,
    NetBSD,
}

Version :: struct {
    major, minor, patch: int,
}

/*
Iterates over GPU adapters

On Windows: Enumerates `Computer\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`
Elsewhere:  Unsupported at the moment, returns `{}, 0, false`

Important: The `vendor` name, `model` name and `driver` version strings are backed by the `GPU_Iterator`.
Clone them if you want to these to persist.

Inputs:
- it:           A pointer to a `GPU_Iterator`
- minimum_vram: The number of bytes of VRAM an adapter has to have to be considered, default 256 MiB
                (This excludes most screen mirroring / remote desktop drivers)

Returns:
    gpu:    A `GPU` struct which contains `vendor` name, `model` name, `driver` version and `vram` in bytes
    index:  Loop index, optional
    ok:     `true` if this was a success and we should continue, `false` otherwise
*/
iterate_gpus :: proc(it: ^GPU_Iterator, minimum_vram := i64(256 * 1024 * 1024)) -> (gpu: GPU, index: int, ok: bool) {
    when DUSK_OS == .Windows {
        return _iterate_gpus(it, minimum_vram)
    } else {
        // Not implemented on another OS, yet
        return {}, 0, false
    }
}

GPU :: struct {
    vendor: string,
    model:  string,
    driver: string,
    vram:   i64,
}

GPU_Iterator :: struct {
    // Public iterator index
    index:  int,

    // Internal buffer + index
    _buffer: [512]u8,
    _index:  int,
}

@(private)
_parse_version :: proc (str: string) -> (res: Version) {
    str := str
    i: int
    for part in strings_tools.split_iterator(&str, ".") {
        defer i += 1
        dst: ^int
        switch i {
        case 0: dst = &res.major
        case 1: dst = &res.minor
        case 2: dst = &res.patch
        case:   return
        }

        if num, num_ok := strconv.parse_int(part); !num_ok {
            return
        } else {
            dst^ = num
        }
    }
    return
}

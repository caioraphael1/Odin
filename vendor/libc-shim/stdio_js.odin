#+private

import "core:c"

foreign import "odin_env"

_fopen :: proc(path, mode: cstring) -> FILE {
    internal.unimplemented("vendor/libc: fopen in JS")
}

_fseek :: proc(file: FILE, offset: c.long, whence: i32) -> i32 {
    internal.unimplemented("vendor/libc: fseek in JS")
}

_ftell :: proc(file: FILE) -> c.long {
    internal.unimplemented("vendor/libc: ftell in JS")
}

_fclose :: proc(file: FILE) -> i32 {
    internal.unimplemented("vendor/libc: fclose in JS")
}

_fread :: proc(buffer: [^]byte, size: uint, count: uint, file: FILE) -> uint {
    internal.unimplemented("vendor/libc: fread in JS")
}

_fwrite :: proc(buffer: [^]byte, size: uint, count: uint, file: FILE) -> uint {
    fd, ok := _fd_specific(file)
    if !ok {
        return 0
    }

    __write(fd, buffer[:size*count])
    return count
}

_putchar :: proc(char: c.int) -> c.int {
    __write(1, {byte(char)})
    return char
}

_getchar :: proc() -> c.int {
    return EOF
}

@(private="file")
foreign odin_env {
    @(link_name="write")
    __write :: proc(fd: u32, p: []byte) ---
}

@(private="file")
_fd_specific :: proc(file: FILE) -> (u32, bool) {
    switch (uint(uintptr(file))) {
    case 2: return 1, true // stdout
    case 3: return 2, true // stderr
    case:   return 0, false
    }
}

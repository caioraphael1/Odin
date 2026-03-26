#+build freebsd, openbsd, netbsd
#+private
foreign import libc "system:c"
@(default_calling_convention="c")
foreign libc {
    @(link_name="write")
    _unix_write :: proc(fd: i32, buf: rawptr, size: int) -> int ---

    when ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {
        @(link_name="__errno") _error :: proc() -> ^i32 ---
    } else {
        @(link_name="__error") _error :: proc() -> ^i32 ---
    }
}

_stderr_write :: proc(data: []u8) -> (int, _OS_Errno) {
    ret := _unix_write(2, raw_data(data), len(data))
    if ret < len(data) {
        err := _error()
        return int(ret), _OS_Errno(err^ if err != nil else 0)
    }
    return int(ret), 0
}

_exit :: proc(code: int) -> ! {
    @(default_calling_convention="c")
    foreign libc {
        exit :: proc(status: i32) -> ! ---
    }
    exit(i32(code))
}

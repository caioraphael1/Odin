#+build js
#+private
foreign import "odin_env"


_stderr_write :: proc(data: []byte) -> (int, _OS_Errno) {
    foreign odin_env {
        write :: proc(fd: u32, p: []byte) ---
    }
    write(1, data)
    return len(data), 0
}

_exit :: proc(code: int) -> ! {
    trap()
}

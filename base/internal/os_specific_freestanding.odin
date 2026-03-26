#+build freestanding
#+private


// TODO(bill): reimplement `os.write`
_stderr_write :: proc(data: []u8) -> (int, _OS_Errno) {
    return 0, -1
}

_exit :: proc(code: int) -> ! {
    trap()
}

_OS_Errno :: distinct int

stderr_write :: proc(data: []u8) -> (int, _OS_Errno) {
    return _stderr_write(data)
}

exit :: proc(code: int) -> ! {
    _exit(code)
}

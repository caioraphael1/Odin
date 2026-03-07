_OS_Errno :: distinct int

stderr_write :: proc(data: []byte) -> (int, _OS_Errno) {
    return _stderr_write(data)
}

exit :: proc(code: int) -> ! {
    _exit(code)
}

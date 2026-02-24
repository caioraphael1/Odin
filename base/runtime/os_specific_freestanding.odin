#+build freestanding
#+private
_HAS_RAND_BYTES :: false

// TODO(bill): reimplement `os.write`
_stderr_write :: proc(data: []byte) -> (int, _OS_Errno) {
	return 0, -1
}

_exit :: proc(code: int) -> ! {
	trap()
}

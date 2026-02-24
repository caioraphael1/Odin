#+build !darwin
#+build !linux
#+build !freebsd
#+build !windows
#+build !netbsd
#+build !openbsd


_enumerate_interfaces :: proc(allocator: mem.Allocator) -> (interfaces: []Network_Interface, err: Interfaces_Error) {
	return
}

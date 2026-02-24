#+private
#+build js


_is_terminal :: proc(handle: any) -> bool {
	return true
}

_init_terminal :: proc() {
	color_depth = .None
}

_fini_terminal :: proc() { }

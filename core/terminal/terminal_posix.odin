#+private
#+build linux, darwin, netbsd, openbsd, freebsd, haiku

import "base:runtime"
import "core:os"

_is_terminal :: proc(f: ^os.File) -> bool {
	return os.is_tty(f)
}

_init_terminal :: proc() {
	color_depth = get_environment_color()
}

_fini_terminal :: proc() { }

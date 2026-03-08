#+build !freestanding
#+build !js

import "core:io"
import "core:os"
import "base:strings"

stdio_writer :: proc() -> io.Writer {
	return os.to_stream(os.stdout)
}

strings_builder_writer :: proc(b: ^strings_tools.Builder) -> io.Writer {
	return strings_tools.to_writer(b)
}

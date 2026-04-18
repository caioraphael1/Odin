#+build !freestanding
#+build !js

import "core:io"
import "core:os"

stdio_writer :: proc() -> io.Writer {
    return os.to_stream(os.stdout)
}

string_builder_writer :: proc(b: ^string_builder.Builder) -> io.Writer {
    return string_builder.to_writer(b)
}
